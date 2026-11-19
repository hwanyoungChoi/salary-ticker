using System.Text.Json;

namespace SalaryTicker.Core;

/// <summary>
/// 이 기기의 JSON 파일(%APPDATA%\SalaryTicker\settings.json)에만 저장한다. 네트워크로 보내지 않는다.
/// 읽을 때 규칙 밖 값은 기본값으로 읽는다. 시간표는 키 하나라도 없거나 무효면 통째로 기본 시간표다.
/// </summary>
public sealed class SettingsStore(string path)
{
    public static string DefaultPath => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "SalaryTicker", "settings.json");

    private static readonly JsonSerializerOptions JsonOptions = new() { WriteIndented = true };

    public Settings Load()
    {
        SettingsFile? file;
        try
        {
            file = JsonSerializer.Deserialize<SettingsFile>(File.ReadAllText(path), JsonOptions);
        }
        catch (Exception exception) when (exception is IOException or JsonException or UnauthorizedAccessException)
        {
            return Settings.Default;
        }
        if (file is null)
        {
            return Settings.Default;
        }
        return new Settings(
            file.AnnualSalary is long salary && AnnualSalary.IsValid(salary) ? salary : null,
            file.AnnualTaxFree is long taxFree and >= 0 and <= AnnualSalary.Maximum ? taxFree : 0,
            ReadSchedule(file),
            file.WindowX,
            file.WindowY);
    }

    public void Save(Settings settings)
    {
        var file = new SettingsFile
        {
            AnnualSalary = settings.AnnualSalary,
            AnnualTaxFree = settings.AnnualTaxFree,
            Workdays = Enum.GetValues<DayOfWeek>().Where(settings.Schedule.IsWorkday).Select(day => (int)day).ToArray(),
            StartMinutes = settings.Schedule.StartMinutes,
            EndMinutes = settings.Schedule.EndMinutes,
            LunchStartMinutes = settings.Schedule.LunchStartMinutes,
            LunchEndMinutes = settings.Schedule.LunchEndMinutes,
            WindowX = settings.WindowX,
            WindowY = settings.WindowY,
        };
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        var temporary = path + ".tmp";
        File.WriteAllText(temporary, JsonSerializer.Serialize(file, JsonOptions));
        File.Move(temporary, path, overwrite: true);
    }

    private static WorkSchedule ReadSchedule(SettingsFile file)
    {
        if (file.Workdays is not { } workdays
            || workdays.Any(day => day is < 0 or > 6)
            || file.StartMinutes is not int start
            || file.EndMinutes is not int end
            || file.LunchStartMinutes is not int lunchStart
            || file.LunchEndMinutes is not int lunchEnd)
        {
            return WorkSchedule.Standard;
        }
        var schedule = new WorkSchedule(
            WorkSchedule.MaskOf(workdays.Select(day => (DayOfWeek)day).ToArray()), start, end, lunchStart, lunchEnd);
        return schedule.IsValid ? schedule : WorkSchedule.Standard;
    }

    internal sealed class SettingsFile
    {
        public long? AnnualSalary { get; set; }
        public long? AnnualTaxFree { get; set; }
        public int[]? Workdays { get; set; }
        public int? StartMinutes { get; set; }
        public int? EndMinutes { get; set; }
        public int? LunchStartMinutes { get; set; }
        public int? LunchEndMinutes { get; set; }
        public int? WindowX { get; set; }
        public int? WindowY { get; set; }
    }
}
