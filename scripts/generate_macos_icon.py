#!/usr/bin/env python3
"""
生成符合 macOS 风格的圆角应用图标
macOS 图标使用连续曲线（continuous curve）圆角，半径约为图标尺寸的 22.37%
"""

from PIL import Image, ImageDraw
import os

def create_rounded_icon(input_path, output_path, size):
    """
    创建圆角图标
    
    Args:
        input_path: 输入图片路径
        output_path: 输出图片路径
        size: 输出尺寸
    """
    # 打开原始图片
    img = Image.open(input_path).convert('RGBA')
    
    # 调整大小
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    
    # 创建圆角遮罩
    # macOS 图标圆角半径约为 22.37% (使用连续曲线近似)
    radius = int(size * 0.2237)
    
    # 创建遮罩
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (size, size)], radius=radius, fill=255)
    
    # 创建输出图片
    output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    output.paste(img, (0, 0))
    output.putalpha(mask)
    
    # 保存
    output.save(output_path, 'PNG')
    print(f"✅ 生成 {size}x{size} 图标: {output_path}")

def main():
    # 项目根目录
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    # 输入图片路径
    input_image = os.path.join(project_root, 'assets/images/logo.png')
    
    # 输出目录
    output_dir = os.path.join(project_root, 'macos/Runner/Assets.xcassets/AppIcon.appiconset')
    
    if not os.path.exists(input_image):
        print(f"❌ 找不到源图标: {input_image}")
        return
    
    print(f"📦 源图标: {input_image}")
    print(f"📁 输出目录: {output_dir}")
    print()
    
    # 需要生成的尺寸
    sizes = {
        'app_icon_16.png': 16,
        'app_icon_32.png': 32,
        'app_icon_64.png': 64,
        'app_icon_128.png': 128,
        'app_icon_256.png': 256,
        'app_icon_512.png': 512,
        'app_icon_1024.png': 1024,
    }
    
    # 生成各个尺寸的图标
    for filename, size in sizes.items():
        output_path = os.path.join(output_dir, filename)
        create_rounded_icon(input_image, output_path, size)
    
    print()
    print("🎉 macOS 圆角图标生成完成！")
    print("💡 提示：需要重新编译应用才能看到新图标")
    print("   运行: flutter clean && flutter run -d macos")

if __name__ == '__main__':
    main()
