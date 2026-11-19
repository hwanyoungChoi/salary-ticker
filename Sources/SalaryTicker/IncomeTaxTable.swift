/// 근로소득 간이세액표(소득세법 시행령 별표2, 2026.2.27 개정) 중 공제대상가족 1명(본인) 열.
///
/// 표의 각 세액은 월급여액 구간의 가운데 값으로 근로소득공제, 기본공제, 특별소득공제 등(별표2 1호 계산식),
/// 연금보험료공제, 세율, 근로소득세액공제를 차례로 적용해 만든 값이다. 같은 순서로 다시 계산하며,
/// 표의 여러 구간 값과 같은지 테스트로 확인한다. 표에 맞춘 값(별표2에 적혀 있지 않은 것):
/// - 연금보험료공제: 월급여 × 4.5%(월 449만 원 상한)
/// - 근로소득세액공제: 산출세액 50만 원까지 55%, 넘는 부분 30%
///
/// 금액은 원 단위 정수로 계산하고, 비율이 들어가는 단계는 1/10,000원 단위 정수로 계산해 소수 오차가 없다.
enum IncomeTaxTable {
  /// 표가 시작하는 월급여(원). 이보다 적으면 세액이 없다.
  private static let tableStart = 770_000
  /// 월급여 1,000만 원인 경우의 세액(표의 "10,000천원" 행).
  private static let taxAtTenMillion = 1_507_400
  /// 1/10,000원 단위.
  private static let unit = 10_000

  /// 월 소득세(원, 10원 미만 버림). `monthlyTaxablePay`는 비과세를 뺀 월급여(원)다.
  /// 1,000원 미만이면 걷지 않는다(소액부징수).
  static func monthlyIncomeTax(monthlyTaxablePay pay: Int) -> Int {
    let tax: Int
    if pay < tableStart {
      tax = 0
    } else if pay < 10_000_000 {
      tax = tableTax(midpoint: midpoint(of: pay))
    } else if pay == 10_000_000 {
      tax = taxAtTenMillion
    } else {
      tax = taxAbove10Million(pay)
    }
    let truncated = tax / 10 * 10
    return truncated < 1_000 ? 0 : truncated
  }

  /// 월급여가 속한 구간의 가운데 값(원). 구간 폭은 150만 원 미만 5천 원, 300만 원 미만 1만 원, 그 위 2만 원.
  private static func midpoint(of pay: Int) -> Int {
    let thousands = pay / 1_000
    let (origin, width) =
      thousands < 1_500 ? (770, 5) : thousands < 3_000 ? (1_500, 10) : (3_000, 20)
    let lower = origin + (thousands - origin) / width * width
    return lower * 1_000 + width * 500
  }

  /// 구간 가운데 값의 월 세액(원, 버림 전).
  private static func tableTax(midpoint: Int) -> Int {
    let annualPay = midpoint * 12
    let pensionDeduction = min(midpoint, 4_490_000) * 45 / 1_000 * 12
    let taxBase = max(
      0,
      annualPay - earnedIncomeDeduction(annualPay) - 1_500_000 - pensionDeduction
        - specialDeduction(annualPay))
    let computed = progressiveTax(taxBase)
    let credit = min(earnedIncomeTaxCredit(computed), creditLimit(annualPay) * unit)
    return max(0, computed - credit) / 12 / unit
  }

  /// 근로소득공제(원). 연간 총급여 1억 2천만 원까지만 쓰이므로 공제 한도(2천만 원)에 닿지 않는다.
  private static func earnedIncomeDeduction(_ pay: Int) -> Int {
    switch pay {
    case ...5_000_000: pay * 70 / 100
    case ...15_000_000: 3_500_000 + (pay - 5_000_000) * 40 / 100
    case ...45_000_000: 7_500_000 + (pay - 15_000_000) * 15 / 100
    case ...100_000_000: 12_000_000 + (pay - 45_000_000) * 5 / 100
    default: 14_750_000 + (pay - 100_000_000) * 2 / 100
    }
  }

  /// 별표2 1호의 "특별소득공제 및 특별세액공제 중 일부", 공제대상가족 1명(원).
  private static func specialDeduction(_ pay: Int) -> Int {
    switch pay {
    case ...30_000_000: 3_100_000 + pay * 4 / 100
    case ...45_000_000: 3_100_000 + pay * 4 / 100 - (pay - 30_000_000) * 5 / 100
    case ...70_000_000: 3_100_000 + pay * 15 / 1_000
    default: 3_100_000 + pay * 5 / 1_000
    }
  }

  /// 종합소득 기본세율로 낸 산출세액(1/10,000원).
  private static func progressiveTax(_ base: Int) -> Int {
    let (percent, deduction): (Int, Int) =
      switch base {
      case ...14_000_000: (6, 0)
      case ...50_000_000: (15, 1_260_000)
      case ...88_000_000: (24, 5_760_000)
      case ...150_000_000: (35, 15_440_000)
      case ...300_000_000: (38, 19_940_000)
      case ...500_000_000: (40, 25_940_000)
      case ...1_000_000_000: (42, 35_940_000)
      default: (45, 65_940_000)
      }
    return base * percent * 100 - deduction * unit
  }

  /// 근로소득세액공제(1/10,000원, 한도 적용 전).
  private static func earnedIncomeTaxCredit(_ computed: Int) -> Int {
    let threshold = 500_000 * unit
    return computed <= threshold
      ? computed * 55 / 100 : threshold * 55 / 100 + (computed - threshold) * 30 / 100
  }

  /// 근로소득세액공제 한도(원).
  private static func creditLimit(_ pay: Int) -> Int {
    switch pay {
    case ...33_000_000: 740_000
    case ...70_000_000: max(740_000 - (pay - 33_000_000) * 8 / 1_000, 660_000)
    case ...120_000_000: max(660_000 - (pay - 70_000_000) / 2, 500_000)
    default: max(500_000 - (pay - 120_000_000) / 2, 200_000)
    }
  }

  /// 월급여 1,000만 원 초과(별표2 6호 표 끝의 산식, 원·버림 전).
  private static func taxAbove10Million(_ pay: Int) -> Int {
    let (start, extra, percent, ratio): (Int, Int, Int, Int) =
      switch pay {
      case ...14_000_000: (10_000_000, 25_000, 35, 98)
      case ...28_000_000: (14_000_000, 1_397_000, 38, 98)
      case ...30_000_000: (28_000_000, 6_610_600, 40, 98)
      case ...45_000_000: (30_000_000, 7_394_600, 40, 100)
      case ...87_000_000: (45_000_000, 13_394_600, 42, 100)
      default: (87_000_000, 31_034_600, 45, 100)
      }
    return taxAtTenMillion + extra + (pay - start) * ratio * percent / unit
  }
}
