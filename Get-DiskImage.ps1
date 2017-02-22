function Get-DiskImage {
<#
.SYNOPSIS

    Disk imaging utility which creates a byte for byte image of a physical drive.

    PowerSploit Function: Get-DiskImage.ps1
    Author: John Laska
    License: BSD 3-Clause
    Required Dependencies: None
    Optional Dependencies: None
 
.DESCRIPTION

    Get-DiskImage is a utility to grab a byte for byte image of a physical disk.
    This utility must be run with administrative permissions on the system, and
    will have a performance impact on the system while the utility is running.

.PARAMETER Path

    Specifies the path for the image file.  Network object names allowed.

.PARAMETER Disk

    Specifies the index of the physical disk to image.  Index can be verified with
    Get-WmiObject -class Win32_DiskDrive

.PARAMETER BlockSize

    The number of bytes to process at a time.  Larger numbers should be faster but 
    can have more corruption in the case of errors.  Deafult is 4MB.

.EXAMPLE

    Get-DiskImage -Path \\server\share\cdrive.raw -Disk 0

.NOTES

    This funtion will work on system and currently active drives. 
    This function does not throttle itself in any way and it will 
    lead to a lot of read activity on the drive.

    There is currently no sanity checking for the Path.  If you 
    attempt to place the image file on the same disk you are imaging 
    you are going to fill the disk and not get an image.

    Images include all slack space. Images will always be the
    size of the physical drive being imaged.

#>

<#
    The P/Invoke and [Win32.Kernel] building code below is copied from 
    the Mayhem.psm1 module which was written by Matthew Graeber (@mattifestation) 
    and Chris Campbell (@obscuresec) with some minor modifications by 
    John Laska to include the ReadFile and RtlZeroMemory methods. 
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName='Local')]
        $Path,

        [Parameter(Mandatory=$True, ParameterSetName='Network')]
        $IpAddress,

        [Parameter(Mandatory=$True, ParameterSetName='Network')]
        $Port,

        [Parameter(Mandatory=$True)]
        $Disk,

        [Parameter(Mandatory=$False)]
        $BlockSize = 4MB

    )
    #region define P/Invoke types dynamically
    $DynAssembly = New-Object System.Reflection.AssemblyName('Win32')
    $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('Win32', $False)

    $TypeBuilder = $ModuleBuilder.DefineType('Win32.Kernel32', 'Public, Class')
    $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
    $SetLastError = [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError')
    $SetLastErrorCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor,
        @('kernel32.dll'),
        [Reflection.FieldInfo[]]@($SetLastError),
        @($True))

    # Define [Win32.Kernel32]::DeviceIoControl
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('DeviceIoControl',
        'kernel32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [Bool],
        [Type[]]@([IntPtr], [UInt32], [IntPtr], [UInt32], [IntPtr], [UInt32], [UInt32].MakeByRefType(), [IntPtr]),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.Kernel32]::CreateFile
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('CreateFile',
        'kernel32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [IntPtr],
        [Type[]]@([String], [Int32], [UInt32], [IntPtr], [UInt32], [UInt32], [IntPtr]),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Ansi)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    #Define [Win32.Kernel32]::ReadFile
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('ReadFile',
        'kernel32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [Bool],
        [Type[]]@([IntPtr], [IntPtr], [uint32], [uint32].MakeByRefType(), [IntPtr] ),

        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Ansi)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.Kernel32]::CloseHandle
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('CloseHandle',
        'kernel32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [Bool],
        [Type[]]@([IntPtr]),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.Kernel32]::RtlZeroMemory
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('RtlZeroMemory',
        'kernel32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [void],
        [Type[]]@([IntPtr], [uint32]),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)


    $Kernel32 = $TypeBuilder.CreateType()
    #endregion

    # Get the device info of the selected disk
    $Device = Get-WmiObject -Class Win32_DiskDrive -Filter "Index = $Disk"

    if($Device -eq $null) 
    {
        throw "Unable to locate disk $Disk"
    }
    
    # Create buffers
    $ReadBuffer = [Runtime.InteropServices.Marshal]::AllocHGlobal($BlockSize)
    $FileBuffer = New-Object byte[] $BlockSize
    $DumpBuffer = New-Object byte[] 4096
    $Kernel32::RtlZeroMemory($ReadBuffer, $BlockSize)
    $BlockCount = [System.Math]::Ceiling($Device.Size / $BlockSize)
    $BytesReturned      =   [UInt32] 0
    $BytesWritten       =   [UInt32] 0

    # File Access Rights
    $GENERIC_READ      =   0x80000000
    $GENERIC_WRITE     =   0x40000000
    $GENERIC_READWRITE =   $GENERIC_READ -bor $GENERIC_WRITE

    # File Share Righs
    $FILE_SHARE_READ   =   1
    $FILE_SHARE_WRITE  =   2
    $FILE_SHARE_READWRITE = $FILE_SHARE_READ -bor $FILE_SHARE_WRITE

    # Open Type
    $OPEN_EXISTING     =   3

    # Pointer Move Method
    $FILE_BEGIN        =   0
    $FILE_CURRENT      =   1
    $FILE_END          =   2

    # Drive Control Commands
    $FSCTL_LOCK_VOLUME  =   0x00090018
    $FSCTL_UNLOCK_VOLUME =  0x0009001C


    # Obtain a read handle to the raw disk
    $DriveHandle = $Kernel32::CreateFile($Device.DeviceID, $GENERIC_READWRITE, $FILE_SHARE_READWRITE, 0, $OPEN_EXISTING, 0, 0)

    if ($DriveHandle -eq ([IntPtr] 0xFFFFFFFF))
    {
        throw "Unable to obtain read/write handle to $($Device.DeviceID)" 
    }

    try {
        # Open target stream
        switch($PSCmdlet.ParameterSetName)
        {
            "Local" 
            { 
                $OutputStream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Create) 
            }
            "Network"
            {
                $TcpClient = New-Object System.Net.Sockets.TcpClient($IpAddress, $Port)
                if($TcpClient.Connected)
                {
                    $OutputStream = $TcpClient.GetStream()
                }
            }
        }    

        # Lock the physical drive for reading
        $null = $Kernel32::DeviceIoControl(
            $DriveHandle, 
            $FSCTL_LOCK_VOLUME, 
            0, 0, 0, 0, 
            [Ref] $BytesReturned, 
            0
        )
        for($i = 0; $i -lt $BlockCount; $i++)
        {
            # Read the drive in $BlockSize chunks
            $null = $Kernel32::ReadFile(
                $DriveHandle, 
                $ReadBuffer, 
                $BlockSize, 
                [Ref] $BytesReturned, 
                [IntPtr]::Zero
            )

            # Copy data from the unmanaged byte buffer to the output stream and zero the buffers
            [System.Runtime.InteropServices.Marshal]::Copy(
                $ReadBuffer, 
                $FileBuffer, 
                0, 
                $BytesReturned
            )

            # Server listener sends bytes to test the connection, dump these in the bit-bucket
            while($OutputStream.DataAvailable)
            {
                $OutputStream.Read($DumpBuffer, 0, $DumpBuffer.Length) | Out-Null
                $DumpBuffer.Clear()
            }
            $OutputStream.Write($FileBuffer, 0, $BytesReturned)
            $Kernel32::RtlZeroMemory($ReadBuffer, $BlockSize)
            $FileBuffer.Clear()
        }
    }
    catch
    {
        throw $_
    }
    finally 
    {
        # Unlock the drive
        $null = $Kernel32::DeviceIoControl(
            $DriveHandle, 
            $FSCTL_UNLOCK_VOLUME, 
            0, 0, 0, 0, 
            [Ref] $BytesReturned, 
            0
        )

        # Cleanup
        $null = $Kernel32::CloseHandle($DriveHandle)
        if($PSCmdlet.ParameterSetName -eq 'Network')
        {
            $TcpClient.Close()
        }
        $OutputStream.Close()
    }
}