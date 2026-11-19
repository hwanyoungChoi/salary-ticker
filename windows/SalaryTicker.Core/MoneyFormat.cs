using System.Globalization;

namespace SalaryTicker.Core;

/// <summary>표시 형식. 기기 언어와 무관하게 쉼표 구분을 쓴다.</summary>
public static class MoneyFormat
{
    /// <summary>숫자 창. 천 단위 쉼표, 단위 없음.</summary>
    public static string Amount(long value) => value.ToString("N0", CultureInfo.InvariantCulture);

    /// <summary>설정 창의 세후 초당 금액. 예: "세후 초당 6.2원".</summary>
    public static string PerSecond(double value) =>
        $"세후 초당 {value.ToString("N1", CultureInfo.InvariantCulture)}원";
}
