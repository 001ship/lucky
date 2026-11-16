"""生成 Lucky 品牌图标（单色 L 字标，透明背景）。

输出：
  web/public/logo.png      1024x1024 透明
  web/src/app/icon.png     512x512  透明
  web/src/app/favicon.ico  16/32/48/64 多尺寸
"""

from pathlib import Path

from PIL import Image, ImageDraw

INK = (23, 23, 23, 255)  # #171717
ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / "web"


def draw_mark(size: int, margin_ratio: float = 0.0) -> Image.Image:
    """在 size x size 透明画布上画 L 字标。"""
    ss = 4  # 超采样
    s = size * ss
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # 以 1024 设计稿为基准的比例坐标
    def px(v: float) -> float:
        return v / 1024.0 * s

    stem_w = px(124)
    stem_x0, stem_y0 = px(294), px(224)
    stem_y1 = px(800)
    foot_w = px(436)
    foot_h = px(124)
    r = px(34)

    # 竖笔
    d.rounded_rectangle(
        [stem_x0, stem_y0, stem_x0 + stem_w, stem_y1], radius=r, fill=INK
    )
    # 横笔（与竖笔重叠形成 L，重叠部分自然融合）
    d.rounded_rectangle(
        [stem_x0, stem_y1 - foot_h, stem_x0 + foot_w, stem_y1], radius=r, fill=INK
    )

    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    # 1) 主 logo（透明背景）
    logo = draw_mark(1024)
    logo.save(WEB / "public" / "logo.png")

    # 2) Next.js 应用图标
    icon = draw_mark(512)
    icon.save(WEB / "src" / "app" / "icon.png")

    # 3) favicon 多尺寸
    favicon_sizes = [16, 32, 48, 64]
    base = draw_mark(64)
    base.save(
        WEB / "src" / "app" / "favicon.ico",
        format="ICO",
        sizes=[(n, n) for n in favicon_sizes],
    )

    # 4) SVG 版本（几何与 PNG 一致）
    svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" role="img" aria-label="Lucky">
  <title>Lucky</title>
  <g fill="#171717">
    <rect x="294" y="224" width="124" height="576" rx="34"/>
    <rect x="294" y="676" width="436" height="124" rx="34"/>
  </g>
</svg>
"""
    (WEB / "public" / "logo.svg").write_text(svg, encoding="utf-8")

    for p in [
        WEB / "public" / "logo.png",
        WEB / "public" / "logo.svg",
        WEB / "src" / "app" / "icon.png",
        WEB / "src" / "app" / "favicon.ico",
    ]:
        print(f"{p.relative_to(ROOT)}  {p.stat().st_size / 1024:.1f} KB")


if __name__ == "__main__":
    main()
