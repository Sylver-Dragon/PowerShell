function Run-AsConsoleUser {
    Param (
        [Parameter(position=0, mandatory=$false)]
        $ApplicationPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
        [Parameter(position=1, mandatory=$false)]
        $CommandLine = "powershell.exe",
        [Parameter(position=2, mandatory=$false)]
        $WorkingDirectory = "C:\"
    )
#region define P/Invoke types dynamically
    # Reflection ModelBuilider
    $DynAssembly = New-Object System.Reflection.AssemblyName('Win32')
    $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('Win32', $False)

    # Builder for WtsApi32
    $TypeBuilder = $ModuleBuilder.DefineType('Win32.WtsApi32', 'Public, Class')
    $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
    $SetLastError = [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError')
    $SetLastErrorCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor,
        @('WtsApi32.dll'),
        [Reflection.FieldInfo[]]@($SetLastError),
        @($True))

    # Define [Win32.WtsApi32]::WTSEnumerateSessions
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('WTSEnumerateSessions',
        'WtsApi32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [Bool],
        [Type[]]@([IntPtr], [Int32], [Int32], [IntPtr].MakeByRefType(), [Int32].MakeByRefType()),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.WtsApi32]::WTSFreeMemory
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('WTSFreeMemory',
        'WtsApi32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [Void],
        [Type[]]@([IntPtr]),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.WtsApi32]::WTSQuerySessionInformation
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('WTSQuerySessionInformation',
        'WtsApi32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [Bool],
        [Type[]]@([Int32], [Int32], [Int32], [IntPtr].MakeByRefType(), [Int32].MakeByRefType()),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Define [Win32.WtsApi32]::WTSQueryUserToken
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('WTSQueryUserToken',
        'WtsApi32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [Bool],
        [Type[]]@([Int32], [IntPtr].MakeByRefType()),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    $WtsApi32 = $TypeBuilder.CreateType()

    # Builder for Kernel32
    $TypeBuilder = $ModuleBuilder.DefineType('Win32.Kernel32', 'Public, Class')
    $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
    $SetLastError = [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError')
    $SetLastErrorCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor,
        @('kernel32.dll'),
        [Reflection.FieldInfo[]]@($SetLastError),
        @($True))    
    
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

    # Define [Win32.Kernel32]::WTSGetActiveConsoleSessionId
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('WTSGetActiveConsoleSessionId',
        'kernel32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [IntPtr],
        $null,
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    $Kernel32 = $TypeBuilder.CreateType()

    # Define STARTUPINFO struct
    $Attributes = "AutoLayout, AnsiClass, Class, SequentialLayout, Sealed, BeforeFieldInit"
    $TypeBuilder = $ModuleBuilder.DefineType('STARTUPINFO', $Attributes, [System.ValueType])
    $TypeBuilder.DefineField('cb', [int], 'Public') | Out-Null
    $TypeBuilder.DefineField('lpReserved', [string], 'Public') | Out-Null
    $TypeBuilder.DefineField('lpDesktop', [string], 'Public') | Out-Null
    $TypeBuilder.DefineField('lpTitle', [string], 'Public') | Out-Null
    $TypeBuilder.DefineField('dwX', [int], 'Public') | Out-Null
    $TypeBuilder.DefineField('dwY', [int], 'Public') | Out-Null
    $TypeBuilder.DefineField('dwXSize', [int], 'Public') | Out-Null
    $TypeBuilder.DefineField('dwYSize', [int], 'Public') | Out-Null
    $TypeBuilder.DefineField('dwXCountChars', [int], 'Public') | Out-Null
    $TypeBuilder.DefineField('dwYCountChars', [int], 'Public') | Out-Null
    $TypeBuilder.DefineField('dwFillAttribute', [int], 'Public') | Out-Null
    $TypeBuilder.DefineField('dwFlags', [int], 'Public') | Out-Null
    $TypeBuilder.DefineField('wShowWindow', [int16], 'Public') | Out-Null
    $TypeBuilder.DefineField('cbReserved2', [int16], 'Public') | Out-Null
    $TypeBuilder.DefineField('lpReserved2', [IntPtr], 'Public') | Out-Null
    $TypeBuilder.DefineField('hStdInput', [IntPtr], 'Public') | Out-Null
    $TypeBuilder.DefineField('hStdOutput', [IntPtr], 'Public') | Out-Null
    $TypeBuilder.DefineField('hStdError', [IntPtr], 'Public') | Out-Null

    $STARTUPINFO = $TypeBuilder.CreateType()

    # Define PROCESSINFO Structure
    $Attributes = "AutoLayout, AnsiClass, Class, SequentialLayout, Sealed, BeforeFieldInit"
    $TypeBuilder = $ModuleBuilder.DefineType('PROCESSINFO', $Attributes, [System.ValueType])
    $TypeBuilder.DefineField('hProcess', [System.IntPtr], 'Public') | Out-Null
    $TypeBuilder.DefineField('hThread', [System.IntPtr], 'Public') | Out-Null
    $TypeBuilder.DefineField('dwProcessId', [int], 'Public') | Out-Null
    $TypeBuilder.DefineField('dwThreadId', [int], 'Public') | Out-Null

    $PROCESSINFO = $TypeBuilder.CreateType()

    # Builder for AdvApi32
    $TypeBuilder = $ModuleBuilder.DefineType('Win32.AdvApi32', 'Public, Class')
    $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
    $SetLastError = [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError')
    $SetLastErrorCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor,
        @('AdvApi32.dll'),
        [Reflection.FieldInfo[]]@($SetLastError),
        @($True))

    # Define [Win32.WtsApi32]::CreateProcessAsUser
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('CreateProcessAsUser',
        'AdvApi32.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [Bool],
        [Type[]]@([IntPtr], [string], [string], [IntPtr], [IntPtr], [int], [int], [IntPtr], [string], $STARTUPINFO, $PROCESSINFO.MakeByRefType()),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    $AdvApi32 = $TypeBuilder.CreateType()
    
    # Define WTS_CONNECTSTATE_CLASS Enum
    $EnumBuilder = $ModuleBuilder.DefineEnum('WTS_CONNECTSTATE_CLASS', 'Public', [int])
    $EnumBuilder.DefineLiteral('WTSActive', 0) | Out-Null
    $EnumBuilder.DefineLiteral('WTSConnected', 1) | Out-Null
    $EnumBuilder.DefineLiteral('WTSConnectQuery', 2) | Out-Null
    $EnumBuilder.DefineLiteral('WTSShadow', 3) | Out-Null
    $EnumBuilder.DefineLiteral('WTSDisconnected', 4) | Out-Null
    $EnumBuilder.DefineLiteral('WTSIdle', 5) | Out-Null
    $EnumBuilder.DefineLiteral('WTSListen', 6) | Out-Null
    $EnumBuilder.DefineLiteral('WTSReset', 7) | Out-Null
    $EnumBuilder.DefineLiteral('WTSDown', 8) | Out-Null
    $EnumBuilder.DefineLiteral('WTSInit', 9) | Out-Null

    $WTS_CONNECTSTATE_CLASS = $EnumBuilder.CreateType()

    # Define _WTS_SESSION_INFO struct
    $Attributes = "AutoLayout, AnsiClass, Class, SequentialLayout, Sealed, BeforeFieldInit"
    $TypeBuilder = $ModuleBuilder.DefineType('_WTS_SESSION_INFO', $Attributes, [System.ValueType])
    $TypeBuilder.DefineField('SessionID', [Int32], 'Public') | Out-Null
    $pWinStationName_Field = $TypeBuilder.DefineField('pWinStationName', [String], 'Public, HasFieldMarshal')
    $ConstructorInfo = [System.Runtime.InteropServices.MarshalAsAttribute].GetConstructors()[0]
    $ConstructorValue = [System.Runtime.InteropServices.UnmanagedType]::LPTStr
    $AttribBuilder = New-Object System.Reflection.Emit.CustomAttributeBuilder($ConstructorInfo, $ConstructorValue)
    $pWinStationName_Field.SetCustomAttribute($AttribBuilder)
    $TypeBuilder.DefineField('State', $WTS_CONNECTSTATE_CLASS, 'Public') | Out-Null

    $WTS_SESSION_INFO = $TypeBuilder.CreateType()

    # Builder for UserEnv
    $TypeBuilder = $ModuleBuilder.DefineType('Win32.UserEnv', 'Public, Class')
    $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
    $SetLastError = [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError')
    $SetLastErrorCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor,
        @('UserEnv.dll'),
        [Reflection.FieldInfo[]]@($SetLastError),
        @($True))

    
    # Define [Win32.UserEnv]::CreateEnvironmentBlock
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('CreateEnvironmentBlock',
        'UserEnv.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [Bool],
        [Type[]]@([IntPtr].MakeByRefType(), [IntPtr], [int]),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    

    # Define [Win32.UserEnv]::DestroyEnvironmentBlock
    $PInvokeMethod = $TypeBuilder.DefinePInvokeMethod('DestroyEnvironmentBlock',
        'UserEnv.dll',
        ([Reflection.MethodAttributes]::Public -bor [Reflection.MethodAttributes]::Static),
        [Reflection.CallingConventions]::Standard,
        [Bool],
        [Type[]]@([IntPtr]),
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Auto)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    $UserEnv = $TypeBuilder.CreateType()

#endregion

#region find user session
    $WTS_CURRENT_SERVER_HANDLE = [IntPtr]::Zero
    $WTSUserName = 5
    $WTSDomainName = 7
    $PtrNameBuffer = [IntPtr]::Zero
    $NameLength = [Uint32]0

    # Get Console User Information
    $ConsoleSessionId = $Kernel32::WTSGetActiveConsoleSessionId()
    $WtsApi32::WTSQuerySessionInformation($WTS_CURRENT_SERVER_HANDLE, $SessionId, $WTSUserName, [ref]$PtrNameBuffer, [ref]$NameLength) | Out-Null
    $UserName = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($PtrNameBuffer)
    $WtsApi32::WTSQuerySessionInformation($WTS_CURRENT_SERVER_HANDLE, $SessionId, $WTSDomainName, [ref]$PtrNameBuffer, [ref]$NameLength) | Out-Null
    $DomainName = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($PtrNameBuffer)
    $WtsApi32::WTSFreeMemory($PtrNameBuffer)

    # Get Session list
    # Not needed, but kept in case we want to deal with terminal servers at a later date.
    <#
    $WTS_CURRENT_SERVER_HANDLE = [IntPtr]::Zero
    $PtrToken = [IntPtr]::Zero
    $SessionId = [int]0
    $PtrSessionsBuffer = [IntPtr]::Zero
    $SessionsCount = [int]0
    $SessionInfoArray = @()
    $FindByUser = 'SomeUserName'
    $FindByDomain = 'SomeDomain'

    $WtsApi32::WTSEnumerateSessions($WTS_CURRENT_SERVER_HANDLE, 0, 1, [ref]$PtrSessionsBuffer, [ref]$SessionsCount) | Out-Null
    for($i = 0; $i -lt $SessionsCount; $i++)
    {
        $PtrCurrentSession = [IntPtr]($PtrSessionsBuffer.ToInt64() + [System.Runtime.InteropServices.Marshal]::SizeOf([Type]$WTS_SESSION_INFO) * $i)
        $SessionInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($PtrCurrentSession, [Type]$WTS_SESSION_INFO)
        #$SessionInfoArray += $SessionInfo
        if($SessionInfo.pWinStationName -eq 'Console')
        {
            $ConsoleSessionId = $SessionInfo.SessionID
        }
        $WtsApi32::WTSQuerySessionInformation($WTS_CURRENT_SERVER_HANDLE, $SessionId, $WTSUserName, [ref]$PtrNameBuffer, [ref]$NameLength) | Out-Null
        $UserName = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($PtrNameBuffer)
        $WtsApi32::WTSQuerySessionInformation($WTS_CURRENT_SERVER_HANDLE, $SessionId, $WTSDomainName, [ref]$PtrNameBuffer, [ref]$NameLength) | Out-Null
        $DomainName = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($PtrNameBuffer)
        if($UserName -eq $FindByUser -and $DomainName -eq $FindByDomain)
        {
            $ConsoleSessionId = $SessionInfo.SessionID
        }
    }
    $WtsApi32::WTSFreeMemory($PtrSessionsBuffer)
    #>
#endregion

#region Get User UserToken (note: This requires SeTcbPrivilege)
    $UserToken = [IntPtr]::Zero
    if($ConsoleSessionId -ne 0)
    {
        if($WtsApi32::WTSQueryUserToken($ConsoleSessionId, [ref]$UserToken)) {
            Write-Output "Got token handle: $UserToken starting PowerShell"
        } else {
            Write-Output "Unable to get console user token.  Do you have SeTcbPrivilege?"
        }
    }
#endregion

#region launch powershell as user 
    $Desktop = "WinSta0\\Default"
    $ProcessInf = [System.Activator]::CreateInstance($PROCESSINFO) | Out-Null
    $StartupInf = [System.Activator]::CreateInstance($STARTUPINFO) | Out-Null
    $NORMAL_PRIORITY_CLASS = 0x20
    $CREATE_UNICODE_ENVIRONMENT = 0x400
    $CREATE_NO_WINDOW = 0x08000000
    $CreationFlags = $NORMAL_PRIORITY_CLASS -bor $CREATE_UNICODE_ENVIRONMENT -bor $CREATE_NO_WINDOW
    $EnvBlock = [IntPtr]::Zero

    $UserEnv::CreateEnvironmentBlock([ref]$EnvBlock, $UserToken, 0) | Out-Null

    $AdvApi32::CreateProcessAsUser(
        $UserToken, $ApplicationPath, $CommandLine, [IntPtr]::Zero, 
        [IntPtr]::Zero, 0, $CreationFlags, $EnvBlock, $WorkingDirectory, 
        $StartupInf, [ref]$ProcessInf
    ) | Out-Null

    $UserEnv::DestroyEnvironmentBlock($EnvBlock)
    $Kernel32::CloseHandle($ProcessInf.hThread)
    $Kernel32::CloseHandle($ProcessInf.hProcess)

    Write-Output "Executed:`n$CommandLine`nas PID: $($ProcessInf.dwProcessId)"
#endregion
}