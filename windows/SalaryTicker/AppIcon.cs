using System.Drawing.Drawing2D;
using System.Drawing.Text;

namespace SalaryTicker;

/// <summary>알림 영역 아이콘. 파일 없이 파란 원에 ₩를 그린다. 앱이 켜질 때 한 번만 만든다.</summary>
internal static class AppIcon
{
    public static Icon Create()
    {
        using var bitmap = new Bitmap(32, 32);
        using (var graphics = Graphics.FromImage(bitmap))
        {
            graphics.SmoothingMode = SmoothingMode.AntiAlias;
            graphics.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
            using var background = new SolidBrush(Color.FromArgb(0, 120, 212));
            graphics.FillEllipse(background, 1, 1, 30, 30);
            using var font = new Font("Segoe UI", 18f, FontStyle.Bold, GraphicsUnit.Pixel);
            using var format = new StringFormat
            {
                Alignment = StringAlignment.Center,
                LineAlignment = StringAlignment.Center,
            };
            graphics.DrawString("₩", font, Brushes.White, new RectangleF(0, 0, 32, 32), format);
        }
        return Icon.FromHandle(bitmap.GetHicon());
    }
}
