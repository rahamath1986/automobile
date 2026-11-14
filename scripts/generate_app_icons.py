import os
from PIL import Image, ImageDraw, ImageFont

def create_master_icon(size=1024):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Background Rounded Rectangle with Gradient
    # Deep Navy Blue to Electric Cobalt
    c_top = (15, 23, 42)       # Slate 900
    c_bottom = (30, 58, 138)   # Blue 900
    c_accent = (14, 165, 233)  # Sky 500

    # Draw vertical gradient
    for y in range(size):
        ratio = y / size
        r = int(c_top[0] * (1 - ratio) + c_bottom[0] * ratio)
        g = int(c_top[1] * (1 - ratio) + c_bottom[1] * ratio)
        b = int(c_top[2] * (1 - ratio) + c_bottom[2] * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    # Mask with rounded corners
    corner_radius = int(size * 0.22) # Apple-style squircle / 22%
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([(0, 0), (size, size)], radius=corner_radius, fill=255)

    base = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    base.paste(img, (0, 0), mask=mask)
    draw = ImageDraw.Draw(base)

    # 2. Glowing Outer Ring Accent
    cx, cy = size // 2, size // 2
    r_outer = int(size * 0.40)
    draw.ellipse(
        [(cx - r_outer, cy - r_outer), (cx + r_outer, cy + r_outer)],
        outline=(14, 165, 233, 160),
        width=int(size * 0.015)
    )

    # 3. Dynamic Motorcycle / Speed Wing Geometry
    # Left wheel
    wheel_radius = int(size * 0.12)
    lw_x, lw_y = int(size * 0.32), int(size * 0.65)
    draw.ellipse([(lw_x - wheel_radius, lw_y - wheel_radius), (lw_x + wheel_radius, lw_y + wheel_radius)],
                 outline=(255, 255, 255, 240), width=int(size * 0.03))
    draw.ellipse([(lw_x - int(wheel_radius * 0.4), lw_y - int(wheel_radius * 0.4)),
                  (lw_x + int(wheel_radius * 0.4), lw_y + int(wheel_radius * 0.4))],
                 fill=(14, 165, 233, 255))

    # Right wheel
    rw_x, rw_y = int(size * 0.68), int(size * 0.65)
    draw.ellipse([(rw_x - wheel_radius, rw_y - wheel_radius), (rw_x + wheel_radius, rw_y + wheel_radius)],
                 outline=(255, 255, 255, 240), width=int(size * 0.03))
    draw.ellipse([(rw_x - int(wheel_radius * 0.4), rw_y - int(wheel_radius * 0.4)),
                  (rw_x + int(wheel_radius * 0.4), rw_y + int(wheel_radius * 0.4))],
                 fill=(14, 165, 233, 255))

    # Chassis & Tank Lines (Aggressive superbike / sport styling)
    # Headlight / front cowl: (size*0.72, size*0.42)
    # Handlebar / windshield: (size*0.62, size*0.35)
    # Fuel tank: (size*0.50, size*0.38)
    # Rider seat: (size*0.40, size*0.48)
    # Tail section: (size*0.28, size*0.42)
    body_points = [
        (int(size * 0.28), int(size * 0.44)),  # Tail tip
        (int(size * 0.40), int(size * 0.48)),  # Seat
        (int(size * 0.50), int(size * 0.38)),  # Tank top
        (int(size * 0.62), int(size * 0.34)),  # Windshield
        (int(size * 0.74), int(size * 0.42)),  # Front beak/fairing
        (int(size * 0.68), lw_y),              # Front axle connection
        (int(size * 0.58), int(size * 0.55)),  # Engine bay
        (int(size * 0.32), lw_y),              # Swingarm / rear axle
    ]
    draw.line(body_points, fill=(255, 255, 255, 255), width=int(size * 0.032), joint="curve")

    # Aerodynamic Speed Fin / Accent
    fin_points = [
        (int(size * 0.46), int(size * 0.44)),
        (int(size * 0.66), int(size * 0.40)),
        (int(size * 0.56), int(size * 0.52))
    ]
    draw.polygon(fin_points, fill=(14, 165, 233, 220))

    # "M" Monogram crest at the top center
    m_top = int(size * 0.18)
    m_left = int(size * 0.40)
    m_right = int(size * 0.60)
    m_mid_x = int(size * 0.50)
    m_bot = int(size * 0.28)
    m_v = int(size * 0.24)

    m_poly = [
        (m_left, m_bot),
        (m_left, m_top),
        (m_mid_x, m_v),
        (m_right, m_top),
        (m_right, m_bot),
        (int(m_right - size*0.03), m_bot),
        (int(m_right - size*0.03), int(m_top + size*0.04)),
        (m_mid_x, int(m_v + size*0.04)),
        (int(m_left + size*0.03), int(m_top + size*0.04)),
        (int(m_left + size*0.03), m_bot),
    ]
    draw.polygon(m_poly, fill=(255, 255, 255, 255))

    return base

def create_horizontal_logo(width=800, height=220, dark=False):
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Emblem on the left (square icon scaled down)
    emblem_size = int(height * 0.85)
    pad = int((height - emblem_size) / 2)
    emblem = create_master_icon(512).resize((emblem_size, emblem_size), Image.Resampling.LANCZOS)
    img.paste(emblem, (pad + 10, pad), mask=emblem)

    # Typography: MotoSaaS
    # Left margin for text:
    text_x = pad + emblem_size + 24
    
    # Try default font or draw stylized text
    text_color_main = (255, 255, 255) if dark else (15, 23, 42)
    accent_color = (14, 165, 233)

    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(height * 0.36))
        font_small = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(height * 0.16))
    except Exception:
        font_large = ImageFont.load_default()
        font_small = ImageFont.load_default()

    draw.text((text_x, int(height * 0.20)), "Moto", fill=text_color_main, font=font_large)
    # Estimate width for "Moto"
    bbox_moto = draw.textbbox((text_x, int(height * 0.20)), "Moto", font=font_large)
    moto_w = bbox_moto[2] - bbox_moto[0]
    draw.text((text_x + moto_w, int(height * 0.20)), "SaaS", fill=accent_color, font=font_large)

    draw.text((text_x + 2, int(height * 0.62)), "DEALERSHIP OPERATIONS & 3D CLOUD", fill=(148, 163, 184) if dark else (100, 116, 139), font=font_small)

    return img

def main():
    root = "/Users/rahamathalikhan/Downloads/automobile/mobile/customer_app"
    assets_icons = os.path.join(root, "assets", "icons")
    assets_images = os.path.join(root, "assets", "images")
    os.makedirs(assets_icons, exist_ok=True)
    os.makedirs(assets_images, exist_ok=True)

    master = create_master_icon(1024)
    master.save(os.path.join(assets_icons, "app_icon.png"), "PNG")
    print("Master app icon saved to assets/icons/app_icon.png")

    logo_light = create_horizontal_logo(800, 220, dark=False)
    logo_light.save(os.path.join(assets_images, "motosaas_logo.png"), "PNG")
    print("Horizontal logo saved to assets/images/motosaas_logo.png")

    logo_dark = create_horizontal_logo(800, 220, dark=True)
    logo_dark.save(os.path.join(assets_images, "motosaas_logo_dark.png"), "PNG")
    print("Dark logo saved to assets/images/motosaas_logo_dark.png")

    # Android mipmap icons
    android_res = os.path.join(root, "android", "app", "src", "main", "res")
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, dim in densities.items():
        target_dir = os.path.join(android_res, folder)
        if os.path.isdir(target_dir):
            scaled = master.resize((dim, dim), Image.Resampling.LANCZOS)
            scaled.save(os.path.join(target_dir, "ic_launcher.png"), "PNG")
            print(f"Saved Android {folder}/ic_launcher.png ({dim}x{dim})")

    # iOS AppIcon.appiconset
    ios_set = os.path.join(root, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    if os.path.isdir(ios_set):
        ios_sizes = {
            "Icon-App-1024x1024@1x.png": 1024,
            "Icon-App-20x20@1x.png": 20,
            "Icon-App-20x20@2x.png": 40,
            "Icon-App-20x20@3x.png": 60,
            "Icon-App-29x29@1x.png": 29,
            "Icon-App-29x29@2x.png": 58,
            "Icon-App-29x29@3x.png": 87,
            "Icon-App-40x40@1x.png": 40,
            "Icon-App-40x40@2x.png": 80,
            "Icon-App-40x40@3x.png": 120,
            "Icon-App-60x60@2x.png": 120,
            "Icon-App-60x60@3x.png": 180,
            "Icon-App-76x76@1x.png": 76,
            "Icon-App-76x76@2x.png": 152,
            "Icon-App-83.5x83.5@2x.png": 167,
        }
        for filename, dim in ios_sizes.items():
            scaled = master.resize((dim, dim), Image.Resampling.LANCZOS)
            scaled.save(os.path.join(ios_set, filename), "PNG")
            print(f"Saved iOS {filename} ({dim}x{dim})")

    # Web icons
    web_icons = os.path.join(root, "web", "icons")
    if os.path.isdir(web_icons):
        master.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons, "Icon-192.png"), "PNG")
        master.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons, "Icon-512.png"), "PNG")
        master.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons, "Icon-maskable-192.png"), "PNG")
        master.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons, "Icon-maskable-512.png"), "PNG")
        print("Saved Web icons (192, 512, maskable)")

    web_dir = os.path.join(root, "web")
    if os.path.isdir(web_dir):
        master.resize((32, 32), Image.Resampling.LANCZOS).save(os.path.join(web_dir, "favicon.png"), "PNG")
        print("Saved web/favicon.png")

if __name__ == "__main__":
    main()

