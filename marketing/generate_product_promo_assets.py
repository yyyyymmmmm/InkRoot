from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "marketing/real/raw"
OUT = ROOT / "marketing/real/promo-product"
OUT_XHS = OUT / "xiaohongshu"
OUT_SSPAI = OUT / "sspai"
OUT_WIDE = OUT / "wide"
LOGO_PATH = ROOT / "assets/images/logo.png"

for directory in (OUT, OUT_XHS, OUT_SSPAI, OUT_WIDE):
    directory.mkdir(parents=True, exist_ok=True)


PRIMARY = (44, 150, 120)  # #2C9678
PRIMARY_LIGHT = (93, 183, 159)  # #5DB79F
PRIMARY_DARK = (26, 117, 89)  # #1A7559
ACCENT = (71, 185, 149)  # #47B995
BG = (245, 244, 247)  # #F5F4F7
SURFACE = (255, 255, 255)
TEXT = (45, 47, 51)  # #2D2F33
TEXT_SECONDARY = (108, 110, 114)  # #6C6E72


def rgba(color: tuple[int, int, int], alpha: int = 255) -> tuple[int, int, int, int]:
    return color + (alpha,)


def blend(a: tuple[int, int, int], b: tuple[int, int, int], ratio: float) -> tuple[int, int, int]:
    return tuple(round(a[i] * (1 - ratio) + b[i] * ratio) for i in range(3))


SUBTLE_ACCENT = blend(SURFACE, ACCENT, 0.12)
SUBTLE_PRIMARY = blend(SURFACE, PRIMARY, 0.10)
SOFT_BORDER = blend(SURFACE, TEXT_SECONDARY, 0.16)
SOFT_TEXT_BORDER = blend(SURFACE, TEXT_SECONDARY, 0.10)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/STHeiti Medium.ttc" if bold else "/System/Library/Fonts/STHeiti Light.ttc",
        "/System/Library/Fonts/SFNS.ttf",
        "/Library/Fonts/Arial Unicode.ttf",
    ]
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    return ImageFont.load_default()


def open_rgb(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    base = Image.new("RGBA", image.size, rgba(SURFACE))
    base.alpha_composite(image)
    return base.convert("RGB")


def save_rgb(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(path, "PNG", optimize=True)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def crop_to_cover(image: Image.Image, target: tuple[int, int], crop: tuple[int, int, int, int] | None = None) -> Image.Image:
    if crop is not None:
        image = image.crop(crop)
    target_w, target_h = target
    scale = max(target_w / image.width, target_h / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    left = max(0, (resized.width - target_w) // 2)
    top = max(0, (resized.height - target_h) // 2)
    return resized.crop((left, top, left + target_w, top + target_h))


def shadow(
    canvas: Image.Image,
    box: tuple[int, int, int, int],
    radius: int,
    alpha: int = 24,
    blur: int = 30,
    offset: int = 18,
) -> None:
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    left, top, right, bottom = box
    draw.rounded_rectangle((left, top + offset, right, bottom + offset), radius=radius, fill=rgba(TEXT, alpha))
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))


def paste_round(canvas: Image.Image, image: Image.Image, xy: tuple[int, int], radius: int) -> None:
    canvas.paste(image, xy, rounded_mask(image.size, radius))


def paste_screenshot_card(
    canvas: Image.Image,
    raw_name: str,
    box: tuple[int, int, int, int],
    *,
    crop: tuple[int, int, int, int] | None = None,
    radius: int = 24,
    shadow_alpha: int = 24,
    border: bool = True,
) -> None:
    raw = open_rgb(RAW_DIR / raw_name).convert("RGBA")
    left, top, right, bottom = box
    shot = crop_to_cover(raw, (right - left, bottom - top), crop).convert("RGBA")
    draw = ImageDraw.Draw(canvas)
    shadow(canvas, box, radius, alpha=shadow_alpha)
    if border:
        draw.rounded_rectangle((left - 1, top - 1, right + 1, bottom + 1), radius=radius + 1, fill=rgba(SURFACE), outline=SOFT_BORDER, width=2)
    paste_round(canvas, shot, (left, top), radius)


def logo_mark(size: int) -> Image.Image:
    logo = Image.open(LOGO_PATH).convert("RGBA")
    pixels = logo.load()
    min_x, min_y = logo.width, logo.height
    max_x, max_y = 0, 0
    for y in range(logo.height):
        for x in range(logo.width):
            r, g, b, a = pixels[x, y]
            if a and (r < 245 or g < 245 or b < 245):
                min_x, min_y = min(min_x, x), min(min_y, y)
                max_x, max_y = max(max_x, x), max(max_y, y)
    logo = logo.crop((min_x, min_y, max_x + 1, max_y + 1))
    logo.thumbnail((size, size), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.alpha_composite(logo, ((size - logo.width) // 2, (size - logo.height) // 2))
    return out


def base(size: tuple[int, int]) -> Image.Image:
    canvas = Image.new("RGBA", size, rgba(SURFACE))
    draw = ImageDraw.Draw(canvas)
    width, height = size
    draw.rectangle((0, 0, width, height), fill=rgba(SURFACE))
    return canvas


def draw_brand(draw: ImageDraw.ImageDraw, canvas: Image.Image, x: int, y: int, scale: float = 1.0, tagline: bool = True) -> None:
    mark_size = round(32 * scale)
    canvas.alpha_composite(logo_mark(mark_size), (x, y))
    draw.text((x + round(46 * scale), y - round(2 * scale)), "InkRoot", font=font(round(26 * scale), True), fill=TEXT)
    if tagline:
        draw.text((x + round(46 * scale), y + round(31 * scale)), "静待沉淀，蓄势而鸣", font=font(round(15 * scale)), fill=TEXT_SECONDARY)


def draw_wrapped(
    draw: ImageDraw.ImageDraw,
    text: str,
    xy: tuple[int, int],
    max_width: int,
    text_font: ImageFont.ImageFont,
    fill: tuple[int, int, int],
    spacing: int = 8,
) -> int:
    lines: list[str] = []
    for paragraph in text.split("\n"):
        current = ""
        for char in paragraph:
            trial = current + char
            if not current or draw.textlength(trial, font=text_font) <= max_width:
                current = trial
            else:
                lines.append(current)
                current = char
        if current:
            lines.append(current)
    content = "\n".join(lines)
    draw.multiline_text(xy, content, font=text_font, fill=fill, spacing=spacing)
    box = draw.multiline_textbbox(xy, content, font=text_font, spacing=spacing)
    return box[3] - box[1]


def title_block(
    draw: ImageDraw.ImageDraw,
    x: int,
    y: int,
    title: str,
    subtitle: str,
    width: int,
    *,
    title_size: int,
    subtitle_size: int,
) -> int:
    draw.rounded_rectangle((x, y, x + 84, y + 6), radius=3, fill=ACCENT)
    title_top = y + 34
    title_h = draw_wrapped(draw, title, (x, title_top), width, font(title_size, True), TEXT, spacing=6)
    sub_top = title_top + title_h + 22
    sub_h = draw_wrapped(draw, subtitle, (x, sub_top), width, font(subtitle_size), TEXT_SECONDARY, spacing=9)
    return sub_top + sub_h


def chip(draw: ImageDraw.ImageDraw, x: int, y: int, text: str, *, filled: bool = False, size: int = 24) -> int:
    fnt = font(size, True)
    width = round(draw.textlength(text, font=fnt)) + 38
    height = size + 24
    fill = PRIMARY if filled else SUBTLE_ACCENT
    fg = SURFACE if filled else PRIMARY_DARK
    draw.rounded_rectangle((x, y, x + width, y + height), radius=height // 2, fill=fill)
    draw.text((x + 19, y + round((height - size) / 2) - 2), text, font=fnt, fill=fg)
    return width


def draw_chips(draw: ImageDraw.ImageDraw, x: int, y: int, labels: list[str]) -> None:
    for index, label in enumerate(labels):
        x += chip(draw, x, y, label, filled=index == 0) + 14


def draw_xhs_header(
    canvas: Image.Image,
    draw: ImageDraw.ImageDraw,
    index: str,
    title: str,
    subtitle: str,
    chips: list[str],
    *,
    title_size: int = 72,
) -> None:
    draw_brand(draw, canvas, 68, 56, 1.0)
    draw.text((945, 58), index, font=font(30, True), fill=PRIMARY_LIGHT)
    title_block(draw, 68, 150, title, subtitle, 900, title_size=title_size, subtitle_size=31)
    draw_chips(draw, 68, 398, chips)


def feature_panel(draw: ImageDraw.ImageDraw, top: int = 488) -> None:
    draw.rounded_rectangle((46, top, 1034, 1392), radius=34, fill=BG)
    draw.rounded_rectangle((46, top, 1034, 1392), radius=34, outline=SOFT_TEXT_BORDER, width=1)


def make_cover() -> None:
    canvas = base((1080, 1440))
    draw = ImageDraw.Draw(canvas)
    draw_xhs_header(
        canvas,
        draw,
        "01",
        "轻记录，服务器自己选",
        "官方服务器开箱即用，也能连接自部署 Memos。",
        ["官方可用", "自部署"],
        title_size=78,
    )
    feature_panel(draw, 486)
    paste_screenshot_card(canvas, "01-home.png", (170, 520, 910, 1380), crop=(0, 170, 1206, 1880), radius=26, shadow_alpha=28)
    save_rgb(canvas, OUT_XHS / "01-cover-1080x1440.png")


def make_server_choice() -> None:
    canvas = base((1080, 1440))
    draw = ImageDraw.Draw(canvas)
    draw_xhs_header(
        canvas,
        draw,
        "02",
        "官方 / 自部署可选",
        "新手用官方服务器；已有 Memos 的用户，填自己的服务器地址。",
        ["官方服务器", "自部署 Memos"],
        title_size=68,
    )
    feature_panel(draw, 486)
    paste_screenshot_card(canvas, "05-settings.png", (146, 522, 934, 1380), crop=(0, 520, 1206, 1780), radius=26, shadow_alpha=24)
    paste_screenshot_card(canvas, "05-settings.png", (90, 822, 990, 1088), crop=(0, 940, 1206, 1360), radius=22, shadow_alpha=26)
    save_rgb(canvas, OUT_XHS / "02-server-choice-1080x1440.png")


def make_tags() -> None:
    canvas = base((1080, 1440))
    draw = ImageDraw.Draw(canvas)
    draw_xhs_header(
        canvas,
        draw,
        "03",
        "标签长成回看路径",
        "从 #灵感 到 #工作/复盘，记录会自然形成结构。",
        ["层级标签", "回看"],
    )
    feature_panel(draw, 486)
    paste_screenshot_card(canvas, "02-tags.png", (136, 520, 884, 1380), crop=(0, 210, 1206, 1850), radius=26, shadow_alpha=24)
    paste_screenshot_card(canvas, "01-home.png", (590, 1042, 1008, 1298), crop=(70, 1340, 1136, 1745), radius=20, shadow_alpha=20)
    save_rgb(canvas, OUT_XHS / "03-tags-1080x1440.png")


def make_sync_backup() -> None:
    canvas = base((1080, 1440))
    draw = ImageDraw.Draw(canvas)
    draw_xhs_header(
        canvas,
        draw,
        "04",
        "WebDAV 备份与恢复",
        "自部署之外，还能把笔记和附件备份到自己的 WebDAV。",
        ["备份恢复", "WebDAV"],
    )
    feature_panel(draw, 486)
    paste_screenshot_card(canvas, "04-webdav.png", (146, 520, 934, 1380), crop=(0, 180, 1206, 1780), radius=26, shadow_alpha=22)
    paste_screenshot_card(canvas, "04-webdav.png", (88, 1020, 992, 1368), crop=(0, 1760, 1206, 2470), radius=22, shadow_alpha=26)
    save_rgb(canvas, OUT_XHS / "04-sync-backup-1080x1440.png")


def make_ai_control() -> None:
    canvas = base((1080, 1440))
    draw = ImageDraw.Draw(canvas)
    draw_xhs_header(
        canvas,
        draw,
        "05",
        "模型和接口由你决定",
        "AI 是工具，服务商、模型和提示词都可以按需配置。",
        ["AI 可控", "自定义模型"],
        title_size=68,
    )
    feature_panel(draw, 486)
    paste_screenshot_card(canvas, "03-ai-settings.png", (136, 520, 944, 1380), crop=(0, 300, 1206, 2180), radius=26, shadow_alpha=24)
    paste_screenshot_card(canvas, "03-ai-settings.png", (98, 990, 982, 1308), crop=(40, 1480, 1166, 2080), radius=22, shadow_alpha=22)
    save_rgb(canvas, OUT_XHS / "05-ai-control-1080x1440.png")


def make_workflow() -> None:
    canvas = base((1080, 1440))
    draw = ImageDraw.Draw(canvas)
    draw_xhs_header(
        canvas,
        draw,
        "06",
        "记录不被平台锁住",
        "官方服务器、自部署 Memos、WebDAV 备份，按自己的路径使用。",
        ["自部署 Memos", "WebDAV"],
        title_size=68,
    )
    feature_panel(draw, 486)
    paste_screenshot_card(canvas, "01-home.png", (82, 526, 690, 900), crop=(40, 330, 1166, 1160), radius=22, shadow_alpha=24)
    paste_screenshot_card(canvas, "05-settings.png", (300, 808, 998, 1128), crop=(0, 900, 1206, 1380), radius=22, shadow_alpha=22)
    paste_screenshot_card(canvas, "04-webdav.png", (104, 1070, 900, 1370), crop=(20, 1750, 1186, 2360), radius=22, shadow_alpha=22)
    save_rgb(canvas, OUT_XHS / "06-workflow-1080x1440.png")


def make_xhs() -> None:
    make_cover()
    make_server_choice()
    make_tags()
    make_sync_backup()
    make_ai_control()
    make_workflow()


def make_sspai() -> None:
    canvas = base((1420, 708))
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, 1420, 708), fill=rgba(SURFACE))
    draw_brand(draw, canvas, 70, 56, 1.0)
    title_block(
        draw,
        70,
        168,
        "自部署 Memos 也能用\n的轻量记录客户端",
        "官方服务器、自部署 Memos、WebDAV 备份和自填 AI 接口。",
        560,
        title_size=58,
        subtitle_size=28,
    )
    draw_chips(draw, 70, 530, ["自部署 Memos", "官方服务器", "WebDAV"])
    draw.rounded_rectangle((628, 38, 1368, 670), radius=34, fill=BG, outline=SOFT_TEXT_BORDER, width=1)
    paste_screenshot_card(canvas, "01-home.png", (676, 70, 1070, 650), crop=(0, 170, 1206, 1940), radius=24, shadow_alpha=28)
    paste_screenshot_card(canvas, "05-settings.png", (852, 428, 1326, 608), crop=(0, 900, 1206, 1360), radius=20, shadow_alpha=18)
    save_rgb(canvas, OUT_SSPAI / "inkroot-sspai-cover-1420x708.png")


def make_wide() -> None:
    canvas = base((1920, 1080))
    draw = ImageDraw.Draw(canvas)
    draw_brand(draw, canvas, 110, 92, 1.15)
    title_block(
        draw,
        110,
        260,
        "轻量记录，服务器自己选",
        "官方服务器开箱即用；也支持自部署 Memos、WebDAV 备份和自填 AI 接口。",
        760,
        title_size=82,
        subtitle_size=36,
    )
    draw_chips(draw, 110, 642, ["官方服务器", "自部署 Memos", "WebDAV 备份"])
    draw.rounded_rectangle((880, 58, 1780, 1018), radius=42, fill=BG, outline=SOFT_TEXT_BORDER, width=1)
    paste_screenshot_card(canvas, "02-tags.png", (1290, 142, 1680, 840), crop=(0, 210, 1206, 1890), radius=24, shadow_alpha=16)
    paste_screenshot_card(canvas, "01-home.png", (946, 92, 1402, 996), crop=(0, 170, 1206, 2200), radius=26, shadow_alpha=30)
    paste_screenshot_card(canvas, "05-settings.png", (1220, 758, 1748, 946), crop=(0, 900, 1206, 1360), radius=22, shadow_alpha=20)
    save_rgb(canvas, OUT_WIDE / "inkroot-hero-1920x1080.png")

    og = base((1200, 630))
    og_draw = ImageDraw.Draw(og)
    draw_brand(og_draw, og, 62, 48, 1.0)
    title_block(
        og_draw,
        62,
        172,
        "InkRoot：服务器自己选",
        "官方 / 自部署 Memos / WebDAV / AI 可选",
        470,
        title_size=48,
        subtitle_size=24,
    )
    draw_chips(og_draw, 62, 454, ["自部署", "轻记录"])
    og_draw.rounded_rectangle((592, 54, 1124, 582), radius=30, fill=BG, outline=SOFT_TEXT_BORDER, width=1)
    paste_screenshot_card(og, "01-home.png", (594, 126, 1138, 550), crop=(0, 330, 1206, 1260), radius=22, shadow_alpha=24)
    save_rgb(og, OUT_WIDE / "inkroot-og-1200x630.png")


def make_contact_sheet() -> None:
    paths = [
        *sorted(OUT_XHS.glob("*.png")),
        OUT_SSPAI / "inkroot-sspai-cover-1420x708.png",
        OUT_WIDE / "inkroot-hero-1920x1080.png",
        OUT_WIDE / "inkroot-og-1200x630.png",
    ]
    thumbs = []
    label_font = font(16)
    for path in paths:
        image = Image.open(path).convert("RGB")
        width = 226
        thumb = image.resize((width, round(image.height * width / image.width)), Image.Resampling.LANCZOS)
        thumbs.append((path.name, thumb))

    cols = 5
    cell_w = 226
    gap = 24
    label_h = 34
    rows = (len(thumbs) + cols - 1) // cols
    row_h = max(thumb.height for _, thumb in thumbs) + label_h
    sheet = Image.new("RGB", (gap + cols * cell_w + (cols - 1) * gap + gap, gap + rows * row_h + (rows - 1) * gap + gap), BG)
    draw = ImageDraw.Draw(sheet)

    for idx, (label, thumb) in enumerate(thumbs):
        row = idx // cols
        col = idx % cols
        x = gap + col * (cell_w + gap)
        y = gap + row * (row_h + gap)
        sheet.paste(thumb, (x, y))
        draw.text((x, y + thumb.height + 8), label, font=label_font, fill=TEXT_SECONDARY)

    sheet.save(OUT / "promo-product-contact-sheet.jpg", "JPEG", quality=92, optimize=True)


def main() -> None:
    for directory in (OUT_XHS, OUT_SSPAI, OUT_WIDE):
        for path in directory.glob("*.png"):
            path.unlink()
    make_xhs()
    make_sspai()
    make_wide()
    make_contact_sheet()
    for path in sorted(OUT.glob("**/*.png")):
        image = Image.open(path)
        print(f"{path.relative_to(ROOT)} {image.size[0]}x{image.size[1]} {image.mode}")


if __name__ == "__main__":
    main()
