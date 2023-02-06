$code = @"
using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

public static class Win32 
{
    public delegate bool EnumedWindow(IntPtr handleWindow, ArrayList handles);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool EnumWindows(EnumedWindow lpEnumFunc, ArrayList lParam);

    private static bool GetWindowHandle(IntPtr windowHandle, ArrayList windowHandles)
    {
        windowHandles.Add(windowHandle);
        return true;
    }

    public static ArrayList GetWindows()
    {    
        ArrayList windowHandles = new ArrayList();
        EnumedWindow callBackPtr = GetWindowHandle;
        EnumWindows(callBackPtr, windowHandles);

        return windowHandles;    
    }
}
"@

if($null -like ([System.AppDomain]::CurrentDomain.GetAssemblies() | 
    Where-Object{$_ -match "Win32"})) 
{
    Add-Type -TypeDefinition $code
}

function Enum-Windows {
    return [Win32]::GetWindows()
}