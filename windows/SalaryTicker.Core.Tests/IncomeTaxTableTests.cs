using SalaryTicker.Core;

namespace SalaryTicker.Core.Tests;

public class IncomeTaxTableTests
{
    /// <summary>
    /// 소득세법 시행령 별표2(2026.2.27 개정) 6호 표의 공제대상가족 1명 열에서 옮긴 값.
    /// (구간 하한 천 원, 세액 원). 구간 안 어느 금액이든 같은 세액이다. macOS 테스트와 같은 값이다.
    /// </summary>
    [Theory]
    [InlineData(1_245, 3_620)]
    [InlineData(1_370, 6_180)]
    [InlineData(2_030, 20_490)]
    [InlineData(2_100, 22_740)]
    [InlineData(2_200, 25_950)]
    [InlineData(2_550, 37_310)]
    [InlineData(2_590, 38_830)]
    [InlineData(2_600, 39_690)]
    [InlineData(2_700, 48_250)]
    [InlineData(2_800, 56_800)]
    [InlineData(3_660, 146_780)]
    [InlineData(3_760, 163_920)]
    [InlineData(4_120, 211_980)]
    [InlineData(4_180, 219_990)]
    [InlineData(4_320, 238_680)]
    [InlineData(7_300, 800_740)]
    [InlineData(7_800, 914_140)]
    [InlineData(8_860, 1_158_420)]
    [InlineData(9_380, 1_299_240)]
    [InlineData(9_980, 1_503_990)]
    public void MatchesTable(long lowerThousands, long tax)
    {
        Assert.Equal(tax, IncomeTaxTable.MonthlyIncomeTax(lowerThousands * 1_000));
        Assert.Equal(tax, IncomeTaxTable.MonthlyIncomeTax(lowerThousands * 1_000 + 4_999));
    }

    [Fact]
    public void BelowTableAndSmallAmountsAreZero()
    {
        Assert.Equal(0, IncomeTaxTable.MonthlyIncomeTax(0));
        Assert.Equal(0, IncomeTaxTable.MonthlyIncomeTax(769_999));
        Assert.Equal(0, IncomeTaxTable.MonthlyIncomeTax(1_000_000));
    }

    /// <summary>표 끝의 산식: 1,000만 원은 1,507,400원, 1,200만 원은 + 25,000 + 200만 × 98% × 35%.</summary>
    [Fact]
    public void AboveTenMillionUsesFormula()
    {
        Assert.Equal(1_507_400, IncomeTaxTable.MonthlyIncomeTax(10_000_000));
        Assert.Equal(2_218_400, IncomeTaxTable.MonthlyIncomeTax(12_000_000));
        Assert.True(IncomeTaxTable.MonthlyIncomeTax(AnnualSalary.Maximum / 12) > 0);
    }
}
