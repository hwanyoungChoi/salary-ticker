import Foundation
import Testing

@testable import SalaryTicker

@Suite("근로소득 간이세액표(본인 1명)")
struct IncomeTaxTableTests {
  /// 소득세법 시행령 별표2(2026.2.27 개정) 6호 표의 공제대상가족 1명 열에서 옮긴 값.
  /// (구간 하한 천 원, 세액 원). 구간 안 어느 금액이든 같은 세액이다.
  @Test(
    "표의 값과 같다",
    arguments: [
      (1_245, 3_620), (1_370, 6_180), (2_030, 20_490), (2_100, 22_740), (2_200, 25_950),
      (2_550, 37_310), (2_590, 38_830), (2_600, 39_690), (2_700, 48_250), (2_800, 56_800),
      (3_660, 146_780), (3_760, 163_920), (4_120, 211_980), (4_180, 219_990), (4_320, 238_680),
      (7_300, 800_740), (7_800, 914_140), (8_860, 1_158_420), (9_380, 1_299_240),
      (9_980, 1_503_990),
    ])
  func matchesTable(lowerThousands: Int, tax: Int) {
    for pay in [lowerThousands * 1_000, lowerThousands * 1_000 + 4_999] {
      #expect(IncomeTaxTable.monthlyIncomeTax(monthlyTaxablePay: pay) == tax, "\(pay)원")
    }
  }

  @Test func belowTableAndSmallAmountsAreZero() {
    #expect(IncomeTaxTable.monthlyIncomeTax(monthlyTaxablePay: 0) == 0)
    #expect(IncomeTaxTable.monthlyIncomeTax(monthlyTaxablePay: 769_999) == 0)
    #expect(IncomeTaxTable.monthlyIncomeTax(monthlyTaxablePay: 1_000_000) == 0)
  }

  /// 표 끝의 산식: 1,000만 원은 1,507,400원, 1,200만 원은 + 25,000 + 200만 × 98% × 35%.
  @Test func aboveTenMillionUsesFormula() {
    #expect(IncomeTaxTable.monthlyIncomeTax(monthlyTaxablePay: 10_000_000) == 1_507_400)
    #expect(IncomeTaxTable.monthlyIncomeTax(monthlyTaxablePay: 12_000_000) == 2_218_400)
    // 1조 ÷ 12도 넘치지 않는다.
    #expect(
      IncomeTaxTable.monthlyIncomeTax(monthlyTaxablePay: AnnualSalary.maximum / 12) > 0)
  }
}

@Suite("세후 계산")
struct TakeHomePayTests {
  /// 연봉 5,200만, 비과세 연 240만 → 과세 월급여 4,133,333원.
  @Test func monthlyDeductionsBreakdown() {
    let deductions = TakeHomePay.monthlyDeductions(
      annualSalary: 52_000_000, annualTaxFree: 2_400_000)
    #expect(
      deductions
        == TakeHomePay.MonthlyDeductions(
          nationalPension: 196_310,  // 4,133,000 × 4.75%
          healthInsurance: 148_590,  // × 3.595%
          longTermCare: 19_520,  // 건강보험료 × 0.9448 ÷ 7.19
          employmentInsurance: 37_190,  // × 0.9%
          incomeTax: 211_980,  // 표 4,120~4,140천 원
          localIncomeTax: 21_190))
    #expect(deductions.total == 634_780)
    #expect(
      TakeHomePay.annualTakeHome(annualSalary: 52_000_000, annualTaxFree: 2_400_000)
        == 52_000_000 - 634_780 * 12)
  }

  /// 국민연금은 기준소득월액 상한(659만 원)까지만 걷는다.
  @Test func pensionIsCapped() {
    let deductions = TakeHomePay.monthlyDeductions(annualSalary: 120_000_000, annualTaxFree: 0)
    #expect(deductions.nationalPension == 313_020)  // 6,590,000 × 4.75% = 313,025 → 313,020
  }

  @Test func taxFreeLargerThanSalaryLeavesNoTaxablePay() {
    let deductions = TakeHomePay.monthlyDeductions(
      annualSalary: 1_000_000, annualTaxFree: 5_000_000)
    #expect(deductions.incomeTax == 0)
    #expect(deductions.healthInsurance == 0)
  }
}

@Suite("비과세 입력")
@MainActor
struct TaxFreeInputTests {
  @Test func taxFreeIsSavedAndRaisesTakeHome() {
    let suiteName = "SalaryTickerTaxFreeTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let model = TickerModel(store: SalaryStore(defaults: defaults), calendar: .current)
    #expect(model.annualTakeHome == nil)
    #expect(model.monthlyTakeHomeText == nil)

    #expect(model.submitAnnualSalary("52,000,000"))
    #expect(model.annualTaxFree == 0)
    #expect(model.monthlyTakeHomeText == "세후 월 3,649,743원")

    #expect(model.submitAnnualTaxFree("2,400,000"))
    #expect(model.monthlyTakeHomeText == "세후 월 3,698,553원")
    #expect(SalaryStore(defaults: defaults).annualTaxFree == 2_400_000)

    for text in ["abc", "-1", "1,000,000,000,001"] {
      #expect(!model.submitAnnualTaxFree(text))
    }
    #expect(model.annualTaxFree == 2_400_000)

    #expect(model.submitAnnualTaxFree(""))
    #expect(model.annualTaxFree == 0)
  }
}
