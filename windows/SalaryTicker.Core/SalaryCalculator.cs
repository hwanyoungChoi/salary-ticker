namespace SalaryTicker.Core;

/// <summary>
/// 1년 급여(세후) + 시간표 + 현재 시각 → 오늘 번 돈, 초당 금액.
/// 그 달 월급(1년 급여 ÷ 12)을 그 달 근무 초(근무일 수 × 점심 뺀 하루 근무 초)에 고르게 나눈다.
/// </summary>
public static class SalaryCalculator
{
    /// <summary>
    /// 오늘 출근 시각부터 <paramref name="now"/>까지 번 돈(원, 버림). 근무 요일이 아니거나 급여가 무효면 0.
    /// 점심시간에는 멈추고, 퇴근 뒤 자정까지는 일급에서 멈춘다.
    /// </summary>
    public static long EarnedToday(long annualPay, WorkSchedule schedule, DateTime now)
    {
        var monthlySeconds = MonthlySeconds(schedule, now);
        if (!AnnualSalary.IsValid(annualPay) || monthlySeconds <= 0 || !schedule.IsWorkday(now.DayOfWeek))
        {
            return 0;
        }
        var secondOfDay = (int)Math.Floor((now - now.Date).TotalSeconds);
        // 곱셈 먼저, 나눗셈 나중. 급여 상한(1조) × 하루 최대 86,340초는 long 안이다.
        return annualPay * schedule.WorkedSeconds(secondOfDay) / (12L * monthlySeconds);
    }

    /// <summary>초당 금액(원). 급여가 무효이거나 그 달 근무 초가 0이면 0.</summary>
    public static double PerSecond(long annualPay, WorkSchedule schedule, DateTime now)
    {
        var monthlySeconds = MonthlySeconds(schedule, now);
        if (!AnnualSalary.IsValid(annualPay) || monthlySeconds <= 0)
        {
            return 0;
        }
        return annualPay / (12.0 * monthlySeconds);
    }

    private static long MonthlySeconds(WorkSchedule schedule, DateTime now) =>
        schedule.IsValid ? (long)schedule.WorkdaysInMonth(now) * schedule.DailySeconds : 0;
}
