#include "MonoLogo.h"

#include <QPainter>
#include <QPainterPath>

namespace ws::monologo {

namespace {

// Luma's four-point star in 1024-unit icon coordinates.
QPainterPath panes()
{
    QPainterPath p;
    p.moveTo(512, 100);
    p.cubicTo(575, 325, 700, 449, 924, 512);
    p.cubicTo(698, 573, 574, 698, 512, 924);
    p.cubicTo(449, 699, 325, 575, 100, 512);
    p.cubicTo(324, 450, 450, 324, 512, 100);
    p.closeSubpath();
    return p;
}
} // namespace

QImage image(int pixels, const QColor& color)
{
    QImage image(pixels, pixels, QImage::Format_ARGB32_Premultiplied);
    image.fill(Qt::transparent);
    QPainter painter(&image);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.scale(pixels / 1024.0, pixels / 1024.0);
    painter.setPen(Qt::NoPen);
    painter.setBrush(color);
    painter.drawPath(panes());
    return image;
}

HICON icon(int pixels, const QColor& color)
{
    return image(pixels, color).toHICON();
}

bool lightTaskbar()
{
    DWORD value = 1; // not set: light, Windows 11's default
    DWORD size = sizeof value;
    ::RegGetValueW(HKEY_CURRENT_USER, L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
        L"SystemUsesLightTheme", RRF_RT_REG_DWORD, nullptr, &value, &size);
    return value != 0;
}

QColor taskbarInk()
{
    HIGHCONTRASTW contrast {sizeof contrast};
    if (::SystemParametersInfoW(SPI_GETHIGHCONTRAST, sizeof contrast, &contrast, 0)
        && (contrast.dwFlags & HCF_HIGHCONTRASTON)) {
        const COLORREF ink = ::GetSysColor(COLOR_WINDOWTEXT);
        return QColor(GetRValue(ink), GetGValue(ink), GetBValue(ink));
    }
    // Windows 11's taskbar icons: white on dark, near black on light.
    return lightTaskbar() ? QColor(0x1B, 0x1B, 0x1B) : QColor(Qt::white);
}

} // namespace ws::monologo
