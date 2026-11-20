using Microsoft.Win32;

namespace SalaryTicker;

/// <summary>
/// "Windows 시작 시 실행". 현재 사용자의 시작 프로그램 목록(HKCU\...\Run)에 이 exe 경로를 넣고 뺀다.
/// 관리자 권한이 필요 없다. exe를 옮기면 예전 경로는 켜진 것으로 보지 않는다.
/// </summary>
internal static class StartupRegistration
{
    private const string RunKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string ValueName = "SalaryTicker";

    private static string Command => $"\"{Environment.ProcessPath}\"";

    public static bool IsEnabled
    {
        get
        {
            using var key = Registry.CurrentUser.OpenSubKey(RunKeyPath);
            return key?.GetValue(ValueName) as string == Command;
        }
    }

    public static void SetEnabled(bool isEnabled)
    {
        using var key = Registry.CurrentUser.CreateSubKey(RunKeyPath);
        if (isEnabled)
        {
            key.SetValue(ValueName, Command);
        }
        else
        {
            key.DeleteValue(ValueName, throwOnMissingValue: false);
        }
    }
}
