namespace SalaryTicker.Core;

/// <summary>
/// 세후(실수령) 계산. 매달 월급에서 4대보험 본인 부담분, 근로소득세(간이세액표, 본인 1명),
/// 지방소득세를 뺀다. 요율과 상·하한은 이 파일에만 둔다(macOS 앱의 TakeHomePay.swift와 같은 값).
/// </summary>
public static class TakeHomePay
{
    /// <summary>아래 값들의 기준일. 설정 창에 함께 보인다.</summary>
    public const string BasisText = "2026년 7월 기준 4대보험·간이세액표(본인 1명)로 추정";

    /// <summary>
    /// 국민연금 본인 4.75%(보험료율 9.5%, 2026.1~). 기준소득월액 41만~659만 원(2026.7~2027.6,
    /// 보건복지부고시 제2026-31호), 천 원 미만 버림.
    /// </summary>
    private const long PensionPermyriad = 475;
    private const long PensionBaseMin = 410_000;
    private const long PensionBaseMax = 6_590_000;

    /// <summary>건강보험 본인 3.595%(보험료율 7.19%, 2026). 장기요양은 건강보험료 × 0.9448 ÷ 7.19(2026).</summary>
    private const long HealthPer100K = 3_595;
    private const long LongTermCareNumerator = 9_448;
    private const long LongTermCareDenominator = 71_900;

    /// <summary>고용보험(실업급여) 본인 0.9%.</summary>
    private const long EmploymentPermille = 9;

    public sealed record MonthlyDeductions(
        long NationalPension,
        long HealthInsurance,
        long LongTermCare,
        long EmploymentInsurance,
        long IncomeTax,
        long LocalIncomeTax)
    {
        public long Total =>
            NationalPension + HealthInsurance + LongTermCare + EmploymentInsurance + IncomeTax + LocalIncomeTax;
    }

    /// <summary>한 달 공제액. 과세 월급여 = (연봉 - 연간 비과세) ÷ 12. 각 항목은 10원 미만 버림.</summary>
    public static MonthlyDeductions Monthly(long annualSalary, long annualTaxFree)
    {
        var taxable = Math.Max(0, annualSalary - annualTaxFree) / 12;
        var pensionBase = Math.Clamp(taxable / 1_000 * 1_000, PensionBaseMin, PensionBaseMax);
        var health = FloorTen(taxable * HealthPer100K / 100_000);
        var incomeTax = IncomeTaxTable.MonthlyIncomeTax(taxable);
        return new MonthlyDeductions(
            NationalPension: FloorTen(pensionBase * PensionPermyriad / 10_000),
            HealthInsurance: health,
            LongTermCare: FloorTen(health * LongTermCareNumerator / LongTermCareDenominator),
            EmploymentInsurance: FloorTen(taxable * EmploymentPermille / 1_000),
            IncomeTax: incomeTax,
            LocalIncomeTax: FloorTen(incomeTax / 10));
    }

    /// <summary>1년 실수령액 = 연봉 - 한 달 공제액 × 12.</summary>
    public static long AnnualTakeHome(long annualSalary, long annualTaxFree) =>
        annualSalary - Monthly(annualSalary, annualTaxFree).Total * 12;

    private static long FloorTen(long value) => value / 10 * 10;
}
