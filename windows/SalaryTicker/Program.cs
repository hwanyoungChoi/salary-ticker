using SalaryTicker.Core;

namespace SalaryTicker;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        // 두 번 실행해도 숫자 창은 하나만 뜬다.
        using var mutex = new Mutex(initiallyOwned: true, @"Local\SalaryTicker", out var isFirstInstance);
        if (!isFirstInstance)
        {
            return;
        }
        ApplicationConfiguration.Initialize();
        Application.Run(new TrayContext(new SettingsStore(SettingsStore.DefaultPath)));
    }
}
