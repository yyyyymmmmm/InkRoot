from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "marketing/real/raw"
OUT_APP_STORE = ROOT / "marketing/real/app-store"
OUT_GOOGLE_PLAY = ROOT / "marketing/real/google-play"
OUT_PROMO = ROOT / "marketing/real/promo"
OUT_XHS = OUT_PROMO / "xiaohongshu"
OUT_SSPAI = OUT_PROMO / "sspai"
ICON = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"

for directory in (OUT_APP_STORE, OUT_GOOGLE_PLAY, OUT_PROMO, OUT_XHS, OUT_SSPAI):
    directory.mkdir(parents=True, exist_ok=True)


SCREENSHOTS = [
    ("01-home", "01-home.png", "打开就写，保持原样", "待办、标签、摘录和图片都留在同一条时间线里。"),
    ("02-tags", "02-tags.png", "标签不是分类柜", "层级标签保留上下文，回看时更容易找回当时的线索。"),
    ("03-ai-settings", "03-ai-settings.png", "AI 由你掌控", "自定义模型、接口和提示词，适配自己的记录方式。"),
    ("04-webdav", "04-webdav.png", "笔记和附件一起备份", "WebDAV 备份覆盖文字、标签和图片资料，迁移更安心。"),
    ("05-settings", "05-settings.png", "设置集中管理", "账号、同步、导入导出和偏好设置放在清晰的位置。"),
]

PAPER = (245, 244, 247)
PAPER_LIGHT = (255, 255, 255)
INK = (45, 47, 51)
MOSS = (44, 150, 120)
MOSS_DARK = (26, 117, 89)
WARM_GRAY = (238, 238, 238)
CLAY = (71, 185, 149)
MUTED = (108, 110, 114)
LINE = (238, 238, 238)
SOFT_MINT = (231, 247, 242)
SOFT_GRAY = (238, 238, 238)
BG = PAPER
TEXT = INK
PRIMARY = MOSS
PRIMARY_DARK = MOSS_DARK


def font(
    size: int,
    bold: bool = False,
    serif: bool = False,
) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    if serif:
        candidates = [
            "/System/Library/Fonts/Supplemental/Songti.ttc",
            "/System/Library/Fonts/Supplemental/PTSerif.ttc",
            "/System/Library/Fonts/STHeiti Medium.ttc" if bold else "/System/Library/Fonts/STHeiti Light.ttc",
        ]
    else:
        candidates = [
            "/System/Library/Fonts/STHeiti Medium.ttc" if bold else "/System/Library/Fonts/STHeiti Light.ttc",
            "/System/Library/Fonts/PingFang.ttc",
            "/System/Library/Fonts/SFNS.ttf",
            "/Library/Fonts/Arial Unicode.ttf",
        ]
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    return ImageFont.load_default()


def sans(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    return font(size, bold=bold, serif=False)


def serif_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    return font(size, bold=bold, serif=True)


def open_rgb(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    base = Image.new("RGBA", image.size, (255, 255, 255, 255))
    base.alpha_composite(image)
    return base.convert("RGB")


def save_rgb(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if image.mode != "RGB":
        image = image.convert("RGB")
    image.save(path, "PNG", optimize=True)


def vertical_gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size, top)
    pixels = image.load()
    for y in range(height):
        t = y / max(1, height - 1)
        color = tuple(round(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(width):
            pixels[x, y] = color
    return image


def fit_contain(image: Image.Image, box: tuple[int, int], resample=Image.Resampling.LANCZOS) -> Image.Image:
    box_w, box_h = box
    scale = min(box_w / image.width, box_h / image.height)
    return image.resize((round(image.width * scale), round(image.height * scale)), resample)


def fit_cover(image: Image.Image, box: tuple[int, int]) -> Image.Image:
    box_w, box_h = box
    scale = max(box_w / image.width, box_h / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    left = max(0, (resized.width - box_w) // 2)
    top = max(0, (resized.height - box_h) // 2)
    return resized.crop((left, top, left + box_w, top + box_h))


def paste_center(canvas: Image.Image, image: Image.Image, box: tuple[int, int, int, int]) -> None:
    left, top, right, bottom = box
    x = left + (right - left - image.width) // 2
    y = top + (bottom - top - image.height) // 2
    canvas.paste(image, (x, y))


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def paste_rounded(canvas: Image.Image, image: Image.Image, xy: tuple[int, int], radius: int) -> None:
    canvas.paste(image, xy, rounded_mask(image.size, radius))


def add_shadow(canvas: Image.Image, box: tuple[int, int, int, int], radius: int, opacity: int = 34) -> None:
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    left, top, right, bottom = box
    draw.rounded_rectangle((left, top + 18, right, bottom + 18), radius=radius, fill=(0, 0, 0, opacity))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas.alpha_composite(shadow)


def draw_paper_texture(canvas: Image.Image, density: int = 22) -> None:
    draw = ImageDraw.Draw(canvas)
    width, height = canvas.size
    draw.rectangle((0, 0, width, height), fill=PAPER)
    draw.rectangle((0, 0, width, round(height * 0.48)), fill=PAPER_LIGHT)
    draw.rounded_rectangle(
        (round(width * 0.62), -round(height * 0.12), width + round(width * 0.18), round(height * 0.30)),
        radius=round(width * 0.08),
        fill=(232, 247, 242, 255),
    )


def draw_brand_mark(draw: ImageDraw.ImageDraw, x: int, y: int, scale: float = 1.0) -> None:
    size = round(22 * scale)
    draw.rounded_rectangle((x, y, x + size, y + size), radius=round(4 * scale), fill=MOSS)
    draw.rectangle((x + round(7 * scale), y + round(4 * scale), x + round(12 * scale), y + round(18 * scale)), fill=(255, 255, 255))
    draw.text((x + round(36 * scale), y - round(2 * scale)), "InkRoot", font=sans(round(24 * scale), True), fill=INK)
    draw.text((x + round(36 * scale), y + round(28 * scale)), "静待沉淀，蓄势而鸣", font=sans(round(14 * scale)), fill=MUTED)


def draw_chip(draw: ImageDraw.ImageDraw, x: int, y: int, text: str, fill=MOSS, fg=PAPER_LIGHT) -> int:
    chip_font = sans(26, True)
    width = round(draw.textlength(text, font=chip_font)) + 38
    draw.rounded_rectangle((x, y, x + width, y + 48), radius=24, fill=fill)
    draw.text((x + 19, y + 10), text, font=chip_font, fill=fg)
    return width


def draw_rule(draw: ImageDraw.ImageDraw, x: int, y: int, width: int, color=CLAY) -> None:
    draw.rounded_rectangle((x, y, x + width, y + 6), radius=3, fill=color)


def paste_screenshot_panel(
    canvas: Image.Image,
    raw_name: str,
    box: tuple[int, int, int, int],
    radius: int = 34,
    crop: bool = False,
    opacity: int = 28,
) -> None:
    raw = open_rgb(RAW_DIR / raw_name).convert("RGBA")
    target_size = (box[2] - box[0], box[3] - box[1])
    image = fit_cover(raw, target_size).convert("RGBA") if crop else fit_contain(raw, target_size).convert("RGBA")
    x = box[0] + (target_size[0] - image.width) // 2
    y = box[1] + (target_size[1] - image.height) // 2
    draw = ImageDraw.Draw(canvas)
    add_shadow(canvas, (x, y, x + image.width, y + image.height), radius, opacity=opacity)
    draw.rounded_rectangle(
        (x - 1, y - 1, x + image.width + 1, y + image.height + 1),
        radius=radius + 2,
        fill=(255, 255, 255, 255),
        outline=LINE,
        width=2,
    )
    paste_rounded(canvas, image, (x, y), radius)


def crop_raw(raw_name: str, crop_box: tuple[float, float, float, float]) -> Image.Image:
    image = open_rgb(RAW_DIR / raw_name)
    left = round(image.width * crop_box[0])
    top = round(image.height * crop_box[1])
    right = round(image.width * crop_box[2])
    bottom = round(image.height * crop_box[3])
    return image.crop((left, top, right, bottom))


def paste_detail_panel(
    canvas: Image.Image,
    raw_name: str,
    crop_box: tuple[float, float, float, float],
    xy: tuple[int, int],
    size: tuple[int, int],
    radius: int = 24,
) -> None:
    image = crop_raw(raw_name, crop_box)
    detail = fit_cover(image, size).convert("RGBA")
    x, y = xy
    draw = ImageDraw.Draw(canvas)
    add_shadow(canvas, (x, y, x + size[0], y + size[1]), radius, opacity=22)
    draw.rounded_rectangle((x - 1, y - 1, x + size[0] + 1, y + size[1] + 1), radius=radius + 2, fill=(255, 255, 255, 255), outline=LINE, width=2)
    paste_rounded(canvas, detail, (x, y), radius)


def draw_release_badge(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str) -> None:
    x, y = xy
    badge_font = font(28, True)
    width = round(draw.textlength(text, font=badge_font)) + 46
    draw.rounded_rectangle((x, y, x + width, y + 54), radius=27, fill=(225, 242, 237), outline=(199, 226, 218), width=1)
    draw.text((x + 23, y + 12), text, font=badge_font, fill=PRIMARY_DARK)


def draw_wrapped(
    draw: ImageDraw.ImageDraw,
    text: str,
    xy: tuple[int, int],
    max_width: int,
    text_font: ImageFont.ImageFont,
    fill: tuple[int, int, int],
    spacing: int = 10,
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


def make_app_store() -> None:
    """App Store screenshots: sales copy + real simulator screenshot, no fake device chrome."""
    width, height = 1320, 2868
    for index, (slug, filename, title, subtitle) in enumerate(SCREENSHOTS, start=1):
        raw = open_rgb(RAW_DIR / filename)
        canvas = vertical_gradient((width, height), (250, 252, 250), (230, 244, 239)).convert("RGBA")
        draw = ImageDraw.Draw(canvas)

        draw.rectangle((0, 0, width, 118), fill=(255, 255, 255, 120))
        icon = open_rgb(ICON).resize((86, 86), Image.Resampling.LANCZOS)
        paste_rounded(canvas, icon.convert("RGBA"), (92, 78), 20)
        draw.text((196, 85), "InkRoot", font=font(38, True), fill=TEXT)
        draw.text((198, 132), "静待沉淀，蓄势而鸣", font=font(24), fill=MUTED)
        draw_release_badge(draw, (92, 228), f"0{index}")

        title_font = font(76, True)
        subtitle_font = font(36)
        title_y = 318
        used = draw_wrapped(draw, title, (92, title_y), width - 184, title_font, TEXT, spacing=12)
        draw_wrapped(draw, subtitle, (96, title_y + used + 30), width - 192, subtitle_font, MUTED, spacing=10)

        shot_box = (86, 760, width - 86, height - 104)
        shot = fit_contain(raw, (shot_box[2] - shot_box[0], shot_box[3] - shot_box[1])).convert("RGBA")
        shot_x = shot_box[0] + (shot_box[2] - shot_box[0] - shot.width) // 2
        shot_y = shot_box[1] + (shot_box[3] - shot_box[1] - shot.height) // 2
        add_shadow(canvas, (shot_x, shot_y, shot_x + shot.width, shot_y + shot.height), 44, opacity=30)
        draw.rounded_rectangle(
            (shot_x - 1, shot_y - 1, shot_x + shot.width + 1, shot_y + shot.height + 1),
            radius=45,
            fill=(255, 255, 255, 255),
            outline=LINE,
            width=2,
        )
        paste_rounded(canvas, shot, (shot_x, shot_y), 42)

        save_rgb(canvas, OUT_APP_STORE / f"{slug}-1320x2868.png")


def make_google_play() -> None:
    """Google Play requires <= 2:1 ratio, so keep the full real screenshot centered."""
    for slug, filename, _, _ in SCREENSHOTS:
        raw = open_rgb(RAW_DIR / filename)
        canvas = Image.new("RGB", (1080, 1920), BG)
        fitted = fit_contain(raw, (canvas.width, canvas.height))
        paste_center(canvas, fitted, (0, 0, canvas.width, canvas.height))
        save_rgb(canvas, OUT_GOOGLE_PLAY / f"{slug}-1080x1920.png")


def new_canvas(size: tuple[int, int], paper: tuple[int, int, int] = PAPER_LIGHT) -> Image.Image:
    canvas = Image.new("RGBA", size, paper + (255,))
    draw_paper_texture(canvas)
    return canvas


def draw_title_block(
    draw: ImageDraw.ImageDraw,
    x: int,
    y: int,
    title: str,
    subtitle: str,
    width: int,
    title_size: int = 82,
    subtitle_size: int = 34,
    title_color=INK,
) -> int:
    draw_rule(draw, x, y, 90)
    title_y = y + 34
    used = draw_wrapped(draw, title, (x, title_y), width, sans(title_size, True), title_color, spacing=8)
    sub_y = title_y + used + 24
    sub_used = draw_wrapped(draw, subtitle, (x + 2, sub_y), width, sans(subtitle_size), MUTED, spacing=10)
    return sub_y + sub_used - y


def make_xhs_cover() -> None:
    canvas = new_canvas((1080, 1440), PAPER_LIGHT)
    draw = ImageDraw.Draw(canvas)
    draw_brand_mark(draw, 68, 58, 1.1)
    draw.rounded_rectangle((720, 56, 1012, 104), radius=24, fill=SOFT_MINT)
    draw.text((752, 70), "给喜欢轻量记录的人", font=sans(24, True), fill=MOSS_DARK)

    draw_title_block(
        draw,
        68,
        166,
        "别只记流水账",
        "把每天的碎片，慢慢沉淀成能回看的东西。",
        700,
        title_size=90,
        subtitle_size=34,
    )
    draw_chip(draw, 68, 424, "本地优先")
    draw_chip(draw, 228, 424, "AI 可控", fill=CLAY)

    draw.text((68, 510), "时间线 / 待办 / 标签", font=sans(30, True), fill=MOSS_DARK)
    draw.text((68, 558), "打开就写，回头还能看懂。", font=sans(27), fill=MUTED)
    paste_screenshot_panel(canvas, "01-home.png", (220, 620, 980, 1374), radius=34, crop=True, opacity=30)

    save_rgb(canvas, OUT_XHS / "01-cover-1080x1440.png")


def make_xhs_slide(
    filename: str,
    index: str,
    title: str,
    subtitle: str,
    raw_name: str,
    chips: list[str],
    detail: tuple[float, float, float, float] | None = None,
) -> None:
    canvas = new_canvas((1080, 1440), PAPER_LIGHT)
    draw = ImageDraw.Draw(canvas)
    draw_brand_mark(draw, 68, 58, 0.95)
    draw.text((930, 64), index, font=sans(34, True), fill=CLAY)
    draw_title_block(draw, 68, 160, title, subtitle, 900, title_size=74, subtitle_size=32)

    chip_x = 68
    for chip in chips:
        chip_x += draw_chip(
            draw,
            chip_x,
            420,
            chip,
            fill=MOSS if chip_x == 68 else SOFT_MINT,
            fg=(255, 255, 255) if chip_x == 68 else MOSS_DARK,
        ) + 14

    paste_screenshot_panel(canvas, raw_name, (104, 536, 976, 1372), radius=34, crop=True, opacity=28)
    if detail is not None:
        paste_detail_panel(canvas, raw_name, detail, (610, 1006), (360, 228), radius=24)
    save_rgb(canvas, OUT_XHS / filename)


def make_xhs_carousel() -> None:
    make_xhs_cover()
    make_xhs_slide(
        "02-local-first-1080x1440.png",
        "02",
        "记录先在本地",
        "不把长期笔记完全押在单一线上服务里。",
        "05-settings.png",
        ["本地优先", "导入导出"],
        detail=None,
    )
    make_xhs_slide(
        "03-tags-1080x1440.png",
        "03",
        "标签长成结构",
        "从 #灵感 到 #项目/复盘，回看时更有路径。",
        "02-tags.png",
        ["层级标签", "长期回看"],
        detail=None,
    )
    make_xhs_slide(
        "04-webdav-1080x1440.png",
        "04",
        "图片也能备份",
        "WebDAV 让笔记和附件一起进入长期保存。",
        "04-webdav.png",
        ["WebDAV", "图片备份"],
        detail=None,
    )
    make_xhs_slide(
        "05-ai-control-1080x1440.png",
        "05",
        "AI 不绑死模型",
        "模型、接口、提示词都能按自己的工作流设置。",
        "03-ai-settings.png",
        ["AI 可控", "提示词"],
        detail=None,
    )
    make_xhs_slide(
        "06-workflow-1080x1440.png",
        "06",
        "接上已有习惯",
        "Memos、WebDAV、导入导出，把迁移出口留给你。",
        "05-settings.png",
        ["Memos", "迁移出口"],
        detail=None,
    )


def make_sspai_cover() -> None:
    canvas = new_canvas((1420, 708), PAPER_LIGHT)
    draw = ImageDraw.Draw(canvas)
    draw_brand_mark(draw, 70, 56, 1.0)
    draw_title_block(
        draw,
        70,
        164,
        "给轻量记录\n更多掌控权",
        "本地优先、Memos 同步、WebDAV 备份与可控 AI。",
        560,
        title_size=70,
        subtitle_size=28,
    )
    draw_chip(draw, 70, 514, "Local-first")
    draw_chip(draw, 262, 514, "Memos", fill=SOFT_MINT, fg=MOSS_DARK)
    draw_chip(draw, 410, 514, "WebDAV", fill=SOFT_MINT, fg=MOSS_DARK)

    paste_screenshot_panel(canvas, "01-home.png", (656, 64, 1038, 650), radius=28, crop=True, opacity=26)
    paste_screenshot_panel(canvas, "02-tags.png", (972, 92, 1308, 620), radius=26, crop=True, opacity=18)
    draw.rectangle((0, 0, 1420, 708), outline=LINE, width=2)
    save_rgb(canvas, OUT_SSPAI / "inkroot-sspai-cover-1420x708.png")


def make_wide_assets() -> None:
    canvas = new_canvas((1920, 1080), PAPER_LIGHT)
    draw = ImageDraw.Draw(canvas)
    draw_brand_mark(draw, 110, 92, 1.2)
    draw_title_block(
        draw,
        110,
        260,
        "把记录留在自己手里",
        "轻量写下、标签回看、Memos 同步、WebDAV 备份、AI 可控。",
        760,
        title_size=80,
        subtitle_size=32,
    )
    draw_chip(draw, 110, 602, "本地优先")
    draw_chip(draw, 282, 602, "数据可控", fill=CLAY)
    paste_screenshot_panel(canvas, "01-home.png", (900, 82, 1310, 1014), radius=32, crop=True, opacity=26)
    paste_screenshot_panel(canvas, "03-ai-settings.png", (1230, 180, 1690, 920), radius=32, crop=True, opacity=20)
    save_rgb(canvas, OUT_PROMO / "inkroot-hero-1920x1080.png")

    og = new_canvas((1200, 630), PAPER_LIGHT)
    og_draw = ImageDraw.Draw(og)
    draw_brand_mark(og_draw, 62, 48, 1.0)
    draw_title_block(
        og_draw,
        62,
        176,
        "别只记流水账",
        "把碎片记录沉淀成可回看的线索。",
        500,
        title_size=58,
        subtitle_size=25,
    )
    paste_screenshot_panel(og, "01-home.png", (650, 44, 1050, 588), radius=26, crop=True, opacity=20)
    save_rgb(og, OUT_PROMO / "inkroot-og-1200x630.png")


def make_promo() -> None:
    make_xhs_carousel()
    make_sspai_cover()
    make_wide_assets()


def make_contact_sheet(paths: list[Path], output: Path, thumb_width: int = 260) -> None:
    thumbs = []
    label_font = font(16)
    for path in paths:
        image = Image.open(path).convert("RGB")
        scale = thumb_width / image.width
        thumb = image.resize((thumb_width, round(image.height * scale)), Image.Resampling.LANCZOS)
        thumbs.append((path.name, thumb))

    gap = 28
    label_h = 34
    sheet_w = gap + sum(thumb.width + gap for _, thumb in thumbs)
    sheet_h = max(thumb.height for _, thumb in thumbs) + label_h + gap * 2
    sheet = Image.new("RGB", (sheet_w, sheet_h), (250, 250, 250))
    draw = ImageDraw.Draw(sheet)
    x = gap
    for label, thumb in thumbs:
        sheet.paste(thumb, (x, gap))
        draw.text((x, gap + thumb.height + 8), label, font=label_font, fill=(36, 40, 44))
        x += thumb.width + gap
    save_rgb(sheet, output)


def verify_outputs() -> None:
    groups = [
        ("app-store", OUT_APP_STORE, (1320, 2868)),
        ("google-play", OUT_GOOGLE_PLAY, (1080, 1920)),
    ]
    for _, directory, expected_size in groups:
        for path in sorted(directory.glob("*.png")):
            image = Image.open(path)
            if image.size != expected_size:
                raise RuntimeError(f"{path} size {image.size}, expected {expected_size}")
            if image.mode != "RGB":
                raise RuntimeError(f"{path} mode {image.mode}, expected RGB")
    for path in sorted(OUT_PROMO.glob("*.png")):
        image = Image.open(path)
        if image.mode != "RGB":
            raise RuntimeError(f"{path} mode {image.mode}, expected RGB")


def main() -> None:
    for directory in (OUT_APP_STORE, OUT_GOOGLE_PLAY, OUT_PROMO):
        for old_file in directory.glob("*.png"):
            old_file.unlink()

    make_app_store()
    make_google_play()
    make_promo()
    verify_outputs()

    make_contact_sheet(
        sorted(OUT_APP_STORE.glob("*.png")),
        ROOT / "marketing/real/app-store-contact-sheet.jpg",
        thumb_width=220,
    )
    make_contact_sheet(
        sorted(OUT_GOOGLE_PLAY.glob("*.png")),
        ROOT / "marketing/real/google-play-contact-sheet.jpg",
        thumb_width=190,
    )
    make_contact_sheet(
        sorted(OUT_PROMO.glob("*.png")),
        ROOT / "marketing/real/promo-contact-sheet.jpg",
        thumb_width=300,
    )

    for directory in (OUT_APP_STORE, OUT_GOOGLE_PLAY, OUT_PROMO):
        for path in sorted(directory.glob("*.png")):
            image = Image.open(path)
            print(f"{path.relative_to(ROOT)} {image.size[0]}x{image.size[1]} {image.mode}")


if __name__ == "__main__":
    main()
