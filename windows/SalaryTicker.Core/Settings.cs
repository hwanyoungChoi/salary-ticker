namespace SalaryTicker.Core;

/// <summary>사용자가 정한 값. 연봉 미입력이면 <see cref="AnnualSalary"/>가 null이다.</summary>
public sealed record Settings(
    long? AnnualSalary, long AnnualTaxFree, WorkSchedule Schedule, int? WindowX = null, int? WindowY = null)
{
    public static readonly Settings Default = new(null, 0, WorkSchedule.Standard);

    /// <summary>1년 실수령액(세후). 오늘 번 돈과 초당 금액은 이 값으로 센다. 연봉 미입력이면 null.</summary>
    public long? AnnualTakeHome =>
        AnnualSalary is long salary ? TakeHomePay.AnnualTakeHome(salary, AnnualTaxFree) : null;

    public long EarnedToday(DateTime now) => SalaryCalculator.EarnedToday(AnnualTakeHome ?? 0, Schedule, now);

    /// <summary>아직 셀 수 없는 이유. 둘 다 비어 있으면 연봉 미입력을 먼저 알린다.</summary>
    public string? SetupNotice =>
        AnnualSalary is null ? "연봉을 입력하세요"
        : Schedule.WorkdayMask == 0 ? "근무 요일을 선택하세요"
        : null;

    /// <summary>세후 초당 금액 문구. 셀 수 없으면 그 이유를 대신 보인다.</summary>
    public string PerSecondText(DateTime now) =>
        SetupNotice ?? MoneyFormat.PerSecond(SalaryCalculator.PerSecond(AnnualTakeHome ?? 0, Schedule, now));

    /// <summary>세후 월급 문구. 연봉 미입력이면 null.</summary>
    public string? MonthlyTakeHomeText =>
        AnnualTakeHome is long annual ? $"세후 월 {MoneyFormat.Amount(annual / 12)}원" : null;
}
