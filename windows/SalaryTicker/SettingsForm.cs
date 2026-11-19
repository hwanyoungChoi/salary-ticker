using SalaryTicker.Core;

namespace SalaryTicker;

/// <summary>
/// 설정 창. 알림 영역 아이콘을 눌러야 열려서, 평소에는 연봉이 화면에 보이지 않는다.
/// 입력하는 동안 세후 월급과 초당 금액을 미리 보여 주고, [저장]을 누를 때 검증해 저장한다.
/// 무효면 이유를 보이고 저장하지 않는다.
/// </summary>
internal sealed class SettingsForm : Form
{
    /// <summary>창에 그리는 요일 순서(월~일).</summary>
    private static readonly (DayOfWeek Day, string Label)[] WeekdayItems =
    [
        (DayOfWeek.Monday, "월"), (DayOfWeek.Tuesday, "화"), (DayOfWeek.Wednesday, "수"),
        (DayOfWeek.Thursday, "목"), (DayOfWeek.Friday, "금"), (DayOfWeek.Saturday, "토"),
        (DayOfWeek.Sunday, "일"),
    ];

    private readonly Settings original;
    private readonly TextBox salaryBox = new() { Width = 220 };
    private readonly TextBox taxFreeBox = new() { Width = 220 };
    private readonly CheckBox[] weekdayBoxes;
    private readonly DateTimePicker startPicker = TimePicker();
    private readonly DateTimePicker endPicker = TimePicker();
    private readonly DateTimePicker lunchStartPicker = TimePicker();
    private readonly DateTimePicker lunchEndPicker = TimePicker();
    private readonly Label previewLabel = new() { AutoSize = true };
    private readonly Label errorLabel = new() { AutoSize = true, ForeColor = Color.Firebrick, MaximumSize = new Size(320, 0) };

    private Settings? result;

    /// <summary>[저장]으로 닫혔을 때의 새 설정.</summary>
    public Settings? Result => result;

    public SettingsForm(Settings settings)
    {
        original = settings;
        Text = "salary-ticker 설정";
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        AutoSize = true;
        AutoSizeMode = AutoSizeMode.GrowAndShrink;
        Font = new Font("Segoe UI", 9.5f);
        Padding = new Padding(12);

        salaryBox.Text = settings.AnnualSalary is long salary ? MoneyFormat.Amount(salary) : "";
        salaryBox.PlaceholderText = "예: 52,000,000";
        taxFreeBox.Text = MoneyFormat.Amount(settings.AnnualTaxFree);
        taxFreeBox.PlaceholderText = "예: 2,400,000";
        weekdayBoxes = WeekdayItems
            .Select(item => new CheckBox
            {
                Text = item.Label,
                AutoSize = true,
                Checked = settings.Schedule.IsWorkday(item.Day),
            })
            .ToArray();
        SetMinutes(startPicker, settings.Schedule.StartMinutes);
        SetMinutes(endPicker, settings.Schedule.EndMinutes);
        SetMinutes(lunchStartPicker, settings.Schedule.LunchStartMinutes);
        SetMinutes(lunchEndPicker, settings.Schedule.LunchEndMinutes);

        var saveButton = new Button { Text = "저장", AutoSize = true, DialogResult = DialogResult.None };
        var cancelButton = new Button { Text = "취소", AutoSize = true, DialogResult = DialogResult.Cancel };
        saveButton.Click += (_, _) => Save();
        AcceptButton = saveButton;
        CancelButton = cancelButton;

        var weekdayRow = new FlowLayoutPanel { AutoSize = true, Margin = Padding.Empty, WrapContents = false };
        weekdayRow.Controls.AddRange(weekdayBoxes);
        var buttonRow = new FlowLayoutPanel
        {
            AutoSize = true,
            FlowDirection = FlowDirection.RightToLeft,
            Dock = DockStyle.Fill,
            Margin = new Padding(0, 8, 0, 0),
        };
        buttonRow.Controls.AddRange([cancelButton, saveButton]);

        var layout = new TableLayoutPanel { AutoSize = true, ColumnCount = 2 };
        AddRow(layout, "연봉 (원)", salaryBox);
        AddRow(layout, "연간 비과세 (원)", taxFreeBox);
        AddRow(layout, "", previewLabel);
        AddRow(layout, "", new Label
        {
            AutoSize = true,
            ForeColor = SystemColors.GrayText,
            Text = TakeHomePay.BasisText,
        });
        AddRow(layout, "근무 요일", weekdayRow);
        AddRow(layout, "출근", startPicker);
        AddRow(layout, "퇴근", endPicker);
        AddRow(layout, "점심 시작", lunchStartPicker);
        AddRow(layout, "점심 끝", lunchEndPicker);
        AddRow(layout, "", errorLabel);
        layout.Controls.Add(buttonRow);
        layout.SetColumnSpan(buttonRow, 2);
        Controls.Add(layout);

        foreach (var box in new[] { salaryBox, taxFreeBox })
        {
            box.TextChanged += (_, _) => UpdatePreview();
        }
        foreach (var weekdayBox in weekdayBoxes)
        {
            weekdayBox.CheckedChanged += (_, _) => UpdatePreview();
        }
        foreach (var picker in new[] { startPicker, endPicker, lunchStartPicker, lunchEndPicker })
        {
            picker.ValueChanged += (_, _) => UpdatePreview();
        }
        UpdatePreview();
    }

    private static DateTimePicker TimePicker() => new()
    {
        Format = DateTimePickerFormat.Custom,
        CustomFormat = "HH:mm",
        ShowUpDown = true,
        Width = 90,
    };

    private static void SetMinutes(DateTimePicker picker, int minutes)
    {
        picker.Value = DateTime.Today.AddMinutes(minutes);
    }

    private static int Minutes(DateTimePicker picker) => (int)picker.Value.TimeOfDay.TotalMinutes;

    private static void AddRow(TableLayoutPanel layout, string title, Control control)
    {
        layout.Controls.Add(new Label
        {
            Text = title,
            AutoSize = true,
            Anchor = AnchorStyles.Left,
            Margin = new Padding(0, 6, 12, 6),
        });
        control.Anchor = AnchorStyles.Left;
        layout.Controls.Add(control);
    }

    /// <summary>입력값으로 만든 설정과, 무효면 그 이유.</summary>
    private (Settings? Settings, string? Error) Read()
    {
        if (AnnualSalary.Parse(salaryBox.Text) is not long salary)
        {
            return (null, "연봉은 숫자와 쉼표만, 1조(1,000,000,000,000) 이하로 입력하세요");
        }
        var taxFreeText = taxFreeBox.Text.Trim();
        if ((taxFreeText.Length == 0 ? 0 : AnnualSalary.ParseAmount(taxFreeText)) is not long taxFree)
        {
            return (null, "연간 비과세는 숫자와 쉼표만, 1조 이하로 입력하세요");
        }
        var schedule = new WorkSchedule(
            WorkSchedule.MaskOf(WeekdayItems.Where((_, index) => weekdayBoxes[index].Checked).Select(item => item.Day).ToArray()),
            Minutes(startPicker),
            Minutes(endPicker),
            Minutes(lunchStartPicker),
            Minutes(lunchEndPicker));
        if (!schedule.IsValid)
        {
            return (null, schedule.StartMinutes >= schedule.EndMinutes
                ? "퇴근 시각은 출근 시각보다 늦어야 합니다"
                : "점심시간은 출근과 퇴근 사이, 근무 시간보다 짧게 정하세요");
        }
        return (original with { AnnualSalary = salary, AnnualTaxFree = taxFree, Schedule = schedule }, null);
    }

    private void UpdatePreview()
    {
        var (settings, _) = Read();
        previewLabel.Text = settings is null
            ? ""
            : $"{settings.MonthlyTakeHomeText}\n{settings.PerSecondText(DateTime.Now)}";
        errorLabel.Text = "";
    }

    private void Save()
    {
        var (settings, error) = Read();
        if (settings is null)
        {
            errorLabel.Text = error;
            return;
        }
        result = settings;
        DialogResult = DialogResult.OK;
        Close();
    }
}
