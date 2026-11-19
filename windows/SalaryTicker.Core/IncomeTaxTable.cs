namespace SalaryTicker.Core;

/// <summary>
/// 근로소득 간이세액표(소득세법 시행령 별표2, 2026.2.27 개정) 중 공제대상가족 1명(본인) 열.
/// </summary>
/// <remarks>
/// 표의 각 세액은 월급여액 구간의 가운데 값으로 근로소득공제, 기본공제, 특별소득공제 등(별표2 1호 계산식),
/// 연금보험료공제, 세율, 근로소득세액공제를 차례로 적용해 만든 값이다. 같은 순서로 다시 계산하며,
/// 표의 여러 구간 값과 같은지 테스트로 확인한다. 표에 맞춘 값(별표2에 적혀 있지 않은 것):
/// 연금보험료공제는 월급여 × 4.5%(월 449만 원 상한), 근로소득세액공제는 산출세액 50만 원까지 55%, 넘는 부분 30%.
/// 비율이 들어가는 단계는 1/10,000원 단위 정수로 계산해 소수 오차가 없다. macOS 앱의 IncomeTaxTable.swift와 같은 계산이다.
/// </remarks>
public static class IncomeTaxTable
{
    /// <summary>표가 시작하는 월급여(원). 이보다 적으면 세액이 없다.</summary>
    private const long TableStart = 770_000;

    /// <summary>월급여 1,000만 원인 경우의 세액(표의 "10,000천원" 행).</summary>
    private const long TaxAtTenMillion = 1_507_400;

    /// <summary>1/10,000원 단위.</summary>
    private const long Unit = 10_000;

    /// <summary>
    /// 월 소득세(원, 10원 미만 버림). <paramref name="pay"/>는 비과세를 뺀 월급여(원)다.
    /// 1,000원 미만이면 걷지 않는다(소액부징수).
    /// </summary>
    public static long MonthlyIncomeTax(long pay)
    {
        var tax = pay switch
        {
            < TableStart => 0,
            < 10_000_000 => TableTax(Midpoint(pay)),
            10_000_000 => TaxAtTenMillion,
            _ => TaxAbove10Million(pay),
        };
        var truncated = tax / 10 * 10;
        return truncated < 1_000 ? 0 : truncated;
    }

    /// <summary>월급여가 속한 구간의 가운데 값(원). 구간 폭은 150만 원 미만 5천 원, 300만 원 미만 1만 원, 그 위 2만 원.</summary>
    private static long Midpoint(long pay)
    {
        var thousands = pay / 1_000;
        var (origin, width) = thousands switch
        {
            < 1_500 => (770L, 5L),
            < 3_000 => (1_500L, 10L),
            _ => (3_000L, 20L),
        };
        var lower = origin + (thousands - origin) / width * width;
        return lower * 1_000 + width * 500;
    }

    /// <summary>구간 가운데 값의 월 세액(원, 버림 전).</summary>
    private static long TableTax(long midpoint)
    {
        var annualPay = midpoint * 12;
        var pensionDeduction = Math.Min(midpoint, 4_490_000) * 45 / 1_000 * 12;
        var taxBase = Math.Max(
            0,
            annualPay - EarnedIncomeDeduction(annualPay) - 1_500_000 - pensionDeduction
                - SpecialDeduction(annualPay));
        var computed = ProgressiveTax(taxBase);
        var credit = Math.Min(EarnedIncomeTaxCredit(computed), CreditLimit(annualPay) * Unit);
        return Math.Max(0, computed - credit) / 12 / Unit;
    }

    /// <summary>근로소득공제(원). 연간 총급여 1억 2천만 원까지만 쓰이므로 공제 한도(2천만 원)에 닿지 않는다.</summary>
    private static long EarnedIncomeDeduction(long pay) => pay switch
    {
        <= 5_000_000 => pay * 70 / 100,
        <= 15_000_000 => 3_500_000 + (pay - 5_000_000) * 40 / 100,
        <= 45_000_000 => 7_500_000 + (pay - 15_000_000) * 15 / 100,
        <= 100_000_000 => 12_000_000 + (pay - 45_000_000) * 5 / 100,
        _ => 14_750_000 + (pay - 100_000_000) * 2 / 100,
    };

    /// <summary>별표2 1호의 "특별소득공제 및 특별세액공제 중 일부", 공제대상가족 1명(원).</summary>
    private static long SpecialDeduction(long pay) => pay switch
    {
        <= 30_000_000 => 3_100_000 + pay * 4 / 100,
        <= 45_000_000 => 3_100_000 + pay * 4 / 100 - (pay - 30_000_000) * 5 / 100,
        <= 70_000_000 => 3_100_000 + pay * 15 / 1_000,
        _ => 3_100_000 + pay * 5 / 1_000,
    };

    /// <summary>종합소득 기본세율로 낸 산출세액(1/10,000원).</summary>
    private static long ProgressiveTax(long taxBase)
    {
        var (percent, deduction) = taxBase switch
        {
            <= 14_000_000 => (6L, 0L),
            <= 50_000_000 => (15L, 1_260_000L),
            <= 88_000_000 => (24L, 5_760_000L),
            <= 150_000_000 => (35L, 15_440_000L),
            <= 300_000_000 => (38L, 19_940_000L),
            <= 500_000_000 => (40L, 25_940_000L),
            <= 1_000_000_000 => (42L, 35_940_000L),
            _ => (45L, 65_940_000L),
        };
        return taxBase * percent * 100 - deduction * Unit;
    }

    /// <summary>근로소득세액공제(1/10,000원, 한도 적용 전).</summary>
    private static long EarnedIncomeTaxCredit(long computed)
    {
        const long threshold = 500_000 * Unit;
        return computed <= threshold
            ? computed * 55 / 100
            : threshold * 55 / 100 + (computed - threshold) * 30 / 100;
    }

    /// <summary>근로소득세액공제 한도(원).</summary>
    private static long CreditLimit(long pay) => pay switch
    {
        <= 33_000_000 => 740_000,
        <= 70_000_000 => Math.Max(740_000 - (pay - 33_000_000) * 8 / 1_000, 660_000),
        <= 120_000_000 => Math.Max(660_000 - (pay - 70_000_000) / 2, 500_000),
        _ => Math.Max(500_000 - (pay - 120_000_000) / 2, 200_000),
    };

    /// <summary>월급여 1,000만 원 초과(별표2 6호 표 끝의 산식, 원·버림 전).</summary>
    private static long TaxAbove10Million(long pay)
    {
        var (start, extra, percent, ratio) = pay switch
        {
            <= 14_000_000 => (10_000_000L, 25_000L, 35L, 98L),
            <= 28_000_000 => (14_000_000L, 1_397_000L, 38L, 98L),
            <= 30_000_000 => (28_000_000L, 6_610_600L, 40L, 98L),
            <= 45_000_000 => (30_000_000L, 7_394_600L, 40L, 100L),
            <= 87_000_000 => (45_000_000L, 13_394_600L, 42L, 100L),
            _ => (87_000_000L, 31_034_600L, 45L, 100L),
        };
        return TaxAtTenMillion + extra + (pay - start) * ratio * percent / Unit;
    }
}
