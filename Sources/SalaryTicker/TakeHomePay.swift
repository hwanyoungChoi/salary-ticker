/// 세후(실수령) 계산. 매달 월급에서 4대보험 본인 부담분, 근로소득세(간이세액표, 본인 1명),
/// 지방소득세를 뺀다. 요율과 상·하한은 이 파일에만 둔다.
enum TakeHomePay {
  /// 아래 값들의 기준일. 패널에 함께 보인다.
  static let basisText = "2026년 7월 기준 4대보험·간이세액표(본인 1명)로 추정"

  /// 국민연금 본인 4.75%(보험료율 9.5%, 2026.1~). 기준소득월액 41만~659만 원(2026.7~2027.6,
  /// 보건복지부고시 제2026-31호), 천 원 미만 버림.
  private static let pensionPermyriad = 475
  private static let pensionBase = 410_000...6_590_000
  /// 건강보험 본인 3.595%(보험료율 7.19%, 2026). 장기요양은 건강보험료 × 0.9448 ÷ 7.19(2026).
  private static let healthPer100k = 3_595
  private static let longTermCareRate = (numerator: 9_448, denominator: 71_900)
  /// 고용보험(실업급여) 본인 0.9%.
  private static let employmentPermille = 9

  struct MonthlyDeductions: Equatable {
    var nationalPension: Int
    var healthInsurance: Int
    var longTermCare: Int
    var employmentInsurance: Int
    var incomeTax: Int
    var localIncomeTax: Int

    var total: Int {
      nationalPension + healthInsurance + longTermCare + employmentInsurance + incomeTax
        + localIncomeTax
    }
  }

  /// 한 달 공제액. 과세 월급여 = (연봉 - 연간 비과세) ÷ 12. 각 항목은 10원 미만 버림.
  static func monthlyDeductions(annualSalary: Int, annualTaxFree: Int) -> MonthlyDeductions {
    let taxable = max(0, annualSalary - annualTaxFree) / 12
    let pensionBase = min(
      max(taxable / 1_000 * 1_000, pensionBase.lowerBound), pensionBase.upperBound)
    let health = floorTen(taxable * healthPer100k / 100_000)
    let incomeTax = IncomeTaxTable.monthlyIncomeTax(monthlyTaxablePay: taxable)
    return MonthlyDeductions(
      nationalPension: floorTen(pensionBase * pensionPermyriad / 10_000),
      healthInsurance: health,
      longTermCare: floorTen(
        health * longTermCareRate.numerator / longTermCareRate.denominator),
      employmentInsurance: floorTen(taxable * employmentPermille / 1_000),
      incomeTax: incomeTax,
      localIncomeTax: floorTen(incomeTax / 10))
  }

  /// 1년 실수령액 = 연봉 - 한 달 공제액 × 12.
  static func annualTakeHome(annualSalary: Int, annualTaxFree: Int) -> Int {
    annualSalary - monthlyDeductions(annualSalary: annualSalary, annualTaxFree: annualTaxFree).total
      * 12
  }

  private static func floorTen(_ value: Int) -> Int { value / 10 * 10 }
}
