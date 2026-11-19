using SalaryTicker.Core;

namespace SalaryTicker;

/// <summary>
/// 앱 전체. 알림 영역 아이콘(설정·종료 메뉴)과 오늘 번 돈을 보이는 숫자 창을 띄우고,
/// 시계의 다음 정각 초마다 숫자를 다시 계산한다(누적하지 않음).
/// </summary>
internal sealed class TrayContext : ApplicationContext
{
    private readonly SettingsStore store;
    private readonly NotifyIcon trayIcon;
    private readonly TickerWindow tickerWindow;
    private readonly System.Windows.Forms.Timer timer = new();
    private Settings settings;
    private bool isSettingsOpen;

    public TrayContext(SettingsStore store)
    {
        this.store = store;
        settings = store.Load();

        var menu = new ContextMenuStrip();
        menu.Items.Add("설정…", null, (_, _) => ShowSettings());
        menu.Items.Add("종료", null, (_, _) => ExitThread());

        trayIcon = new NotifyIcon
        {
            Icon = AppIcon.Create(),
            ContextMenuStrip = menu,
            Text = "salary-ticker",
            Visible = true,
        };
        trayIcon.MouseClick += (_, e) =>
        {
            if (e.Button == MouseButtons.Left)
            {
                ShowSettings();
            }
        };

        tickerWindow = new TickerWindow(menu, settings.WindowX, settings.WindowY);
        tickerWindow.LocationCommitted += location =>
        {
            settings = settings with { WindowX = location.X, WindowY = location.Y };
            store.Save(settings);
        };
        tickerWindow.Show();

        timer.Tick += (_, _) => Tick();
        Tick();

        if (settings.AnnualSalary is null)
        {
            ShowSettings();
        }
    }

    private void Tick()
    {
        var now = DateTime.Now;
        tickerWindow.ShowAmount(MoneyFormat.Amount(settings.EarnedToday(now)));
        trayIcon.Text = settings.SetupNotice ?? "salary-ticker";
        // 1초 고정 간격은 조금씩 밀리므로, 매번 다음 정각 초까지 남은 시간만큼만 기다린다.
        timer.Stop();
        timer.Interval = Math.Max(1, 1000 - now.Millisecond);
        timer.Start();
    }

    private void ShowSettings()
    {
        if (isSettingsOpen)
        {
            return;
        }
        isSettingsOpen = true;
        using var form = new SettingsForm(settings);
        if (form.ShowDialog() == DialogResult.OK && form.Result is { } result)
        {
            settings = result;
            store.Save(settings);
            Tick();
        }
        isSettingsOpen = false;
    }

    protected override void ExitThreadCore()
    {
        timer.Dispose();
        trayIcon.Visible = false;
        trayIcon.Dispose();
        tickerWindow.Close();
        base.ExitThreadCore();
    }
}
