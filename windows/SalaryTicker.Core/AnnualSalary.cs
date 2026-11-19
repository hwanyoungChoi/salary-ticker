namespace SalaryTicker.Core;

/// <summary>금액 입력 규칙. 원 단위 정수, 1조 이하만 유효하다. 연봉은 1 이상, 비과세는 0도 된다.</summary>
public static class AnnualSalary
{
    public const long Maximum = 1_000_000_000_000;

    public static bool IsValid(long value) => value is >= 1 and <= Maximum;

    /// <summary>연봉. 0이나 빈 값은 null.</summary>
    public static long? Parse(string text) => ParseAmount(text) is > 0 and var value ? value : null;

    /// <summary>0 이상 1조 이하 금액. 앞뒤 공백과 쉼표를 허용한다. 소수점·부호·문자, 상한 초과는 null.</summary>
    public static long? ParseAmount(string text)
    {
        var digits = text.Trim().Replace(",", "");
        if (digits.Length == 0 || !digits.All(char.IsAsciiDigit))
        {
            return null;
        }
        return long.TryParse(digits, out var value) && value <= Maximum ? value : null;
    }
}
