using SalaryTicker.Core;

namespace SalaryTicker.Core.Tests;

/// <summary>
/// 1년 급여 5,200만 원, 2026년 11월(근무일 21일): 분모 = 12 × 21일 × 28,800초(점심 뺀 8시간) = 7,257,600.
/// 2026-11-09는 월요일, 14일은 토요일. macOS 테스트와 같은 기대값이다.
/// </summary>
public class SalaryCalculatorTests
{
    private const long Pay = 52_000_000;

    private static long Earned(DateTime now, WorkSchedule? schedule = null) =>
        SalaryCalculator.EarnedToday(Pay, schedule ?? WorkSchedule.Standard, now);

    [Theory]
    [InlineData(9, 29, 59, 0)]
    [InlineData(9, 30, 0, 0)]
    [InlineData(9, 30, 1, 7)]
    [InlineData(9, 30, 4, 28)]
    [InlineData(12, 0, 0, 64_484)]
    [InlineData(12, 59, 59, 64_484)]
    [InlineData(13, 0, 1, 64_491)]
    [InlineData(14, 0, 0, 90_277)]
    [InlineData(18, 29, 59, 206_342)]
    [InlineData(18, 30, 0, 206_349)]
    [InlineData(23, 59, 59, 206_349)]
    public void MondayByTime(int hour, int minute, int second, long expected)
    {
        Assert.Equal(expected, Earned(new DateTime(2026, 11, 9, hour, minute, second)));
    }

    [Fact]
    public void FractionalSecondsRoundDown()
    {
        Assert.Equal(21, Earned(new DateTime(2026, 11, 9, 9, 30, 3).AddMilliseconds(900)));
    }

    [Fact]
    public void SaturdayIsZero()
    {
        Assert.Equal(0, Earned(new DateTime(2026, 11, 14, 12, 0, 0)));
    }

    /// <summary>일급은 그 달 월급 ÷ 그 달 근무일 수. 근무일 23일인 12월은 21일인 11월보다 작다.</summary>
    [Fact]
    public void DailyWageFollowsWorkdaysInMonth()
    {
        Assert.Equal(206_349, Earned(new DateTime(2026, 11, 9, 18, 30, 0)));
        Assert.Equal(188_405, Earned(new DateTime(2026, 12, 1, 18, 30, 0)));
    }

    [Fact]
    public void PerSecond()
    {
        var perSecond = SalaryCalculator.PerSecond(Pay, WorkSchedule.Standard, new DateTime(2026, 11, 9));
        Assert.InRange(perSecond, 7.1648, 7.1650);
        Assert.Equal("세후 초당 7.2원", MoneyFormat.PerSecond(perSecond));
    }

    [Fact]
    public void MaximumPayDoesNotOverflow()
    {
        Assert.Equal(
            3_968_253_968,
            SalaryCalculator.EarnedToday(AnnualSalary.Maximum, WorkSchedule.Standard, new DateTime(2026, 11, 9, 18, 30, 0)));
    }

    /// <summary>점심 시작과 끝이 같으면 점심 없이 9시간을 센다.</summary>
    [Fact]
    public void EqualLunchTimesMeanNoLunch()
    {
        var noLunch = WorkSchedule.Standard with { LunchStartMinutes = 720, LunchEndMinutes = 720 };
        Assert.True(noLunch.IsValid);
        Assert.Equal(68_783, Earned(new DateTime(2026, 11, 9, 12, 30, 0), noLunch));
    }

    [Theory]
    [InlineData(570, 570, 720, 780)]
    [InlineData(600, 570, 720, 780)]
    [InlineData(570, 1110, 540, 600)]
    [InlineData(570, 1110, 1080, 1140)]
    [InlineData(570, 1110, 780, 720)]
    [InlineData(570, 1110, 570, 1110)]
    public void InvalidSchedules(int start, int end, int lunchStart, int lunchEnd)
    {
        var schedule = WorkSchedule.Standard with
        {
            StartMinutes = start,
            EndMinutes = end,
            LunchStartMinutes = lunchStart,
            LunchEndMinutes = lunchEnd,
        };
        Assert.False(schedule.IsValid);
        Assert.Equal(0, Earned(new DateTime(2026, 11, 9, 14, 0, 0), schedule));
    }

    [Fact]
    public void NoWorkdaysEarnsZero()
    {
        var schedule = WorkSchedule.Standard with { WorkdayMask = 0 };
        Assert.Equal(0, Earned(new DateTime(2026, 11, 9, 14, 0, 0), schedule));
    }
}
