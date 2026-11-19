using SalaryTicker.Core;

namespace SalaryTicker.Core.Tests;

public class TakeHomePayTests
{
    /// <summary>연봉 5,200만, 비과세 연 240만 → 과세 월급여 4,133,333원.</summary>
    [Fact]
    public void MonthlyDeductionsBreakdown()
    {
        var deductions = TakeHomePay.Monthly(52_000_000, 2_400_000);
        Assert.Equal(
            new TakeHomePay.MonthlyDeductions(
                NationalPension: 196_310,
                HealthInsurance: 148_590,
                LongTermCare: 19_520,
                EmploymentInsurance: 37_190,
                IncomeTax: 211_980,
                LocalIncomeTax: 21_190),
            deductions);
        Assert.Equal(634_780, deductions.Total);
        Assert.Equal(52_000_000 - 634_780 * 12, TakeHomePay.AnnualTakeHome(52_000_000, 2_400_000));
    }

    [Fact]
    public void PensionIsCapped()
    {
        Assert.Equal(313_020, TakeHomePay.Monthly(120_000_000, 0).NationalPension);
    }

    [Fact]
    public void TaxFreeLargerThanSalaryLeavesNoTaxablePay()
    {
        var deductions = TakeHomePay.Monthly(1_000_000, 5_000_000);
        Assert.Equal(0, deductions.IncomeTax);
        Assert.Equal(0, deductions.HealthInsurance);
    }

    [Fact]
    public void SettingsTextsUseTakeHome()
    {
        var settings = Settings.Default with { AnnualSalary = 52_000_000 };
        Assert.Equal("세후 월 3,649,743원", settings.MonthlyTakeHomeText);
        Assert.Equal("세후 월 3,698,553원", (settings with { AnnualTaxFree = 2_400_000 }).MonthlyTakeHomeText);
        Assert.Null(Settings.Default.MonthlyTakeHomeText);
        Assert.Equal("연봉을 입력하세요", Settings.Default.SetupNotice);
    }
}
