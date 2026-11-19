namespace SalaryTicker.Core;

/// <summary>
/// 근무 시간표. 요일은 <see cref="DayOfWeek"/> 비트 묶음, 시각은 자정부터의 분.
/// 점심시간에는 돈이 쌓이지 않는다. 점심 시작과 끝이 같으면 점심시간이 없다.
/// </summary>
public sealed record WorkSchedule(
    int WorkdayMask, int StartMinutes, int EndMinutes, int LunchStartMinutes, int LunchEndMinutes)
{
    /// <summary>기본값: 월~금 09:30~18:30, 점심 12:00~13:00.</summary>
    public static readonly WorkSchedule Standard = new(
        MaskOf(DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday, DayOfWeek.Thursday, DayOfWeek.Friday),
        570, 1110, 720, 780);

    public static int MaskOf(params DayOfWeek[] days) => days.Aggregate(0, (mask, day) => mask | (1 << (int)day));

    public bool IsWorkday(DayOfWeek day) => (WorkdayMask & (1 << (int)day)) != 0;

    /// <summary>저장·계산에 쓸 수 있는 시간표인가. 요일이 비어 있는 것은 허용한다.</summary>
    public bool IsValid =>
        WorkdayMask is >= 0 and <= 0b111_1111
        && StartMinutes is >= 0 and <= 1439
        && EndMinutes is >= 0 and <= 1439
        && StartMinutes < EndMinutes
        && IsLunchValid;

    /// <summary>점심시간은 출근과 퇴근 사이에 있고, 근무 시간 전체를 덮지 않는다.</summary>
    public bool IsLunchValid =>
        StartMinutes <= LunchStartMinutes
        && LunchStartMinutes <= LunchEndMinutes
        && LunchEndMinutes <= EndMinutes
        && DailySeconds > 0;

    /// <summary>하루 근무 초(점심 제외).</summary>
    public int DailySeconds => ((EndMinutes - StartMinutes) - (LunchEndMinutes - LunchStartMinutes)) * 60;

    /// <summary>자정부터 <paramref name="secondOfDay"/>초까지 일한 초(점심 제외). 출근 전 0, 퇴근 뒤 하루 근무 초.</summary>
    public int WorkedSeconds(int secondOfDay)
    {
        int Elapsed(int start, int end) => Math.Min(Math.Max(secondOfDay, start * 60), end * 60) - start * 60;
        return Elapsed(StartMinutes, EndMinutes) - Elapsed(LunchStartMinutes, LunchEndMinutes);
    }

    /// <summary><paramref name="date"/>가 속한 달(1일~말일)의 근무 요일 수.</summary>
    public int WorkdaysInMonth(DateTime date)
    {
        var days = DateTime.DaysInMonth(date.Year, date.Month);
        return Enumerable.Range(1, days)
            .Count(day => IsWorkday(new DateTime(date.Year, date.Month, day).DayOfWeek));
    }
}
