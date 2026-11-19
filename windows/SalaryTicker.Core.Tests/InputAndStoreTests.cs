using SalaryTicker.Core;

namespace SalaryTicker.Core.Tests;

public class InputAndStoreTests
{
    [Theory]
    [InlineData("52,000,000", 52_000_000)]
    [InlineData(" 52000000 ", 52_000_000)]
    [InlineData("1,000,000,000,000", 1_000_000_000_000)]
    public void ValidSalary(string text, long expected)
    {
        Assert.Equal(expected, AnnualSalary.Parse(text));
    }

    [Theory]
    [InlineData("")]
    [InlineData("0")]
    [InlineData("abc")]
    [InlineData("-1")]
    [InlineData("52.5")]
    [InlineData("５２")]
    [InlineData("1,000,000,000,001")]
    [InlineData("99999999999999999999")]
    public void InvalidSalary(string text)
    {
        Assert.Null(AnnualSalary.Parse(text));
    }

    [Fact]
    public void ZeroIsAValidAmount()
    {
        Assert.Equal(0, AnnualSalary.ParseAmount("0"));
    }

    [Fact]
    public void SavedSettingsSurviveReload()
    {
        var path = Path.Combine(Path.GetTempPath(), $"SalaryTickerTests-{Guid.NewGuid()}", "settings.json");
        try
        {
            var settings = new Settings(
                52_000_000,
                2_400_000,
                new WorkSchedule(WorkSchedule.MaskOf(DayOfWeek.Saturday, DayOfWeek.Sunday), 600, 1200, 690, 750),
                WindowX: 100,
                WindowY: 200);
            new SettingsStore(path).Save(settings);
            Assert.Equal(settings, new SettingsStore(path).Load());
        }
        finally
        {
            Directory.Delete(Path.GetDirectoryName(path)!, recursive: true);
        }
    }

    [Theory]
    [InlineData(null)]
    [InlineData("not json")]
    [InlineData("{\"AnnualSalary\": -1, \"AnnualTaxFree\": -5, \"Workdays\": [1, 9], \"StartMinutes\": 570, \"EndMinutes\": 1110, \"LunchStartMinutes\": 720, \"LunchEndMinutes\": 780}")]
    [InlineData("{\"AnnualSalary\": 1000000000001, \"Workdays\": [1], \"StartMinutes\": 600}")]
    public void MissingOrInvalidFileReadsAsDefault(string? content)
    {
        var directory = Path.Combine(Path.GetTempPath(), $"SalaryTickerTests-{Guid.NewGuid()}");
        var path = Path.Combine(directory, "settings.json");
        try
        {
            if (content is not null)
            {
                Directory.CreateDirectory(directory);
                File.WriteAllText(path, content);
            }
            Assert.Equal(Settings.Default, new SettingsStore(path).Load());
        }
        finally
        {
            if (Directory.Exists(directory))
            {
                Directory.Delete(directory, recursive: true);
            }
        }
    }
}
