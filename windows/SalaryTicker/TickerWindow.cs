namespace SalaryTicker;

/// <summary>
/// 오늘 번 돈을 숫자만으로 보이는 작은 창. Windows 알림 영역에는 글자를 띄울 수 없어서,
/// 작업표시줄 위에 항상 위에 떠 있는 창을 둔다. 끌어서 옮길 수 있고, 위치는 저장한다.
/// 포커스를 뺏지 않고 Alt+Tab 목록에도 나오지 않는다.
/// </summary>
internal sealed class TickerWindow : Form
{
    private const int WindowExToolWindow = 0x0000_0080;
    private const int WindowExNoActivate = 0x0800_0000;

    private readonly Label amountLabel;
    private readonly int? savedX;
    private readonly int? savedY;
    private Point dragOffset;
    private bool isDragging;

    public event Action<Point>? LocationCommitted;

    public TickerWindow(ContextMenuStrip menu, int? savedX, int? savedY)
    {
        this.savedX = savedX;
        this.savedY = savedY;
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        TopMost = true;
        StartPosition = FormStartPosition.Manual;
        AutoSize = true;
        AutoSizeMode = AutoSizeMode.GrowAndShrink;
        BackColor = Color.FromArgb(32, 32, 32);
        Padding = new Padding(10, 4, 10, 4);
        ContextMenuStrip = menu;

        amountLabel = new Label
        {
            AutoSize = true,
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 12f, FontStyle.Bold),
            Margin = Padding.Empty,
            Text = "0",
            ContextMenuStrip = menu,
        };
        Controls.Add(amountLabel);

        foreach (var control in new Control[] { this, amountLabel })
        {
            control.MouseDown += HandleMouseDown;
            control.MouseMove += HandleMouseMove;
            control.MouseUp += HandleMouseUp;
        }
    }

    public void ShowAmount(string text)
    {
        amountLabel.Text = text;
    }

    protected override bool ShowWithoutActivation => true;

    protected override CreateParams CreateParams
    {
        get
        {
            var parameters = base.CreateParams;
            parameters.ExStyle |= WindowExToolWindow | WindowExNoActivate;
            return parameters;
        }
    }

    /// <summary>저장한 위치가 지금 화면 안이면 그 자리, 아니면 주 화면 작업 영역의 오른쪽 아래.</summary>
    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        if (savedX is int x && savedY is int y
            && Screen.AllScreens.Any(screen => screen.WorkingArea.Contains(x, y)))
        {
            Location = new Point(x, y);
        }
        else
        {
            var area = Screen.PrimaryScreen!.WorkingArea;
            Location = new Point(area.Right - Width - 16, area.Bottom - Height - 16);
        }
    }

    private void HandleMouseDown(object? sender, MouseEventArgs e)
    {
        if (e.Button != MouseButtons.Left)
        {
            return;
        }
        isDragging = true;
        dragOffset = new Point(Cursor.Position.X - Left, Cursor.Position.Y - Top);
    }

    private void HandleMouseMove(object? sender, MouseEventArgs e)
    {
        if (isDragging)
        {
            Location = new Point(Cursor.Position.X - dragOffset.X, Cursor.Position.Y - dragOffset.Y);
        }
    }

    private void HandleMouseUp(object? sender, MouseEventArgs e)
    {
        if (!isDragging)
        {
            return;
        }
        isDragging = false;
        LocationCommitted?.Invoke(Location);
    }
}
