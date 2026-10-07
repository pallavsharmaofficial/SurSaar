"""Draws the SurSaar icon and the images the stores and the web need.

The mark is a chord box, the diagram every guitarist learns from: a card with
the nut across the top, strings and frets under it, and three finger dots
climbing in the app's own finger colours. It sits on the brand's blue-to-violet
ground, the same two stops the onboarding and the website use. Nothing here is
a photograph, so it scales from a 16 pixel favicon to a 1024 pixel store icon
without help.

Run it from the repository root, then let the tools turn its output into the
Android and iOS icons and splash screens. It writes the web icons itself:

    python3 tools/branding/make_icon.py
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create
"""
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

# The app's own colours: lib/core/theme/app_colors.dart and
# lib/widgets/teacher/finger_colors.dart.
PRIMARY = (45, 49, 250)
VIOLET = (124, 58, 237)
NAVY = (15, 23, 42)
SURFACE = (248, 250, 252)
CORAL = (255, 107, 107)
GOLD = (250, 204, 21)
SLATE = (148, 163, 184)
FINGERS = ((59, 130, 246), (34, 197, 94), (245, 158, 11))

OUT = os.path.join('assets', 'branding')
FONTS = os.path.join('tools', 'branding', 'fonts')


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def ground(width, height=None, start=PRIMARY, end=VIOLET):
    """A diagonal wash from the brand blue at the top left to violet."""
    height = height or width
    across = Image.linear_gradient('L').rotate(90).resize((width, height))
    down = Image.linear_gradient('L').resize((width, height))
    mask = ImageChops.add(across, down, scale=2)
    return Image.composite(
        Image.new('RGB', (width, height), end),
        Image.new('RGB', (width, height), start),
        mask,
    )


def bar(draw, x0, y0, x1, y1, colour):
    """A rounded bar. Pillow lines have square ends, and a string should not."""
    draw.rounded_rectangle([x0, y0, x1, y1], radius=min(x1 - x0, y1 - y0) / 2,
                           fill=colour)


def chord_box(draw, cx, cy, w, small=False, paper=SURFACE, nut=CORAL,
              strings=NAVY, frets=SLATE, dots=FINGERS, marks=True):
    """The mark: a chord box with a C major staircase of three fingers.

    Everything is a fraction of the card width `w`, so the same drawing serves
    every size. `small` is the optical size for 48 pixels and under: three
    strings instead of five, no fret lines, a heavier nut and bigger dots,
    because five strings and four frets turn to a grey smear that small.
    """
    h = w * 1.16
    left, top = cx - w / 2, cy - h / 2
    draw.rounded_rectangle([left, top, left + w, top + h], radius=w * 0.14,
                           fill=paper)
    if not marks:
        return
    if small:
        columns = (0.22, 0.5, 0.78)
        nut_top, nut_height, rows, row_height = 0.14, 0.10, 3, 0.255
        string_width, dot_radius = 0.045, 0.125
        fingers = ((2, 1), (1, 2), (0, 3))
        # Light strings, so the three dots are what a 48 pixel eye catches;
        # dark ones read as the sliders of a mixing desk.
        strings = (203, 213, 225)
        frets = None
    else:
        columns = tuple(0.17 + 0.165 * i for i in range(5))
        nut_top, nut_height, rows, row_height = 0.16, 0.06, 3, 0.26
        string_width, dot_radius = 0.022, 0.08
        # The shape of C, which is also the order the dots are coloured in:
        # index on the B string at the first fret, middle on D at the second,
        # ring on A at the third.
        fingers = ((3, 1), (1, 2), (0, 3))
    first, last = columns[0] * w, columns[-1] * w
    body_top = (nut_top + nut_height) * w
    body_bottom = body_top + rows * row_height * w
    half = string_width * w / 2
    # The strings start under the nut, so no rounded tip shows beneath it.
    for column in columns:
        x = left + column * w
        bar(draw, x - half, top + (nut_top + nut_height / 2) * w, x + half,
            top + body_bottom, strings)
    if frets is not None:
        thin = 0.008 * w
        for row in range(1, rows + 1):
            y = top + body_top + row * row_height * w
            bar(draw, left + first - half, y - thin, left + last + half,
                y + thin, frets)
    bar(draw, left + first - half, top + nut_top * w, left + last + half,
        top + (nut_top + nut_height) * w, nut)
    for (column, fret), colour in zip(fingers, dots):
        x = left + columns[column] * w
        y = top + body_top + (fret - 0.5) * row_height * w
        r = dot_radius * w
        draw.ellipse([x - r, y - r, x + r, y + r], fill=colour)


def supersample(size, draw_at, factor=2):
    """Draws at a multiple of the final size, then settles down to it, so the
    edges of the card and the dots are anti-aliased."""
    return draw_at(size * factor).resize((size, size), Image.LANCZOS)


def app_icon(size=1024, small=False):
    def draw_at(s):
        image = ground(s).convert('RGBA')
        w = s * (0.66 if small else 0.54)
        # A soft shadow under the card so it lifts off the ground.
        shadow = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        chord_box(ImageDraw.Draw(shadow), s / 2, s / 2 + s * 0.016, w,
                  small=small, paper=NAVY + (110,), marks=False)
        image = Image.alpha_composite(
            image, shadow.filter(ImageFilter.GaussianBlur(s * 0.016)))
        chord_box(ImageDraw.Draw(image), s / 2, s / 2, w, small=small)
        return image.convert('RGB')
    return supersample(size, draw_at, 4 if small else 2)


def foreground(size=1024):
    """Android adaptive foreground: the card alone, inside the safe circle.

    flutter_launcher_icons insets this by 16 percent, so the card can take
    most of the canvas and still clear the circle the launcher guarantees."""
    def draw_at(s):
        image = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        chord_box(ImageDraw.Draw(image), s / 2, s / 2, s * 0.56)
        return image
    return supersample(size, draw_at)


def monochrome(size=1024):
    """Android themed icons want one flat colour on transparent. The card is
    solid and the nut, strings and dots are cut out of it, so the chord still
    reads when the launcher tints the whole thing one colour."""
    def draw_at(s):
        alpha = Image.new('L', (s, s), 0)
        chord_box(ImageDraw.Draw(alpha), s / 2, s / 2, s * 0.56, paper=255,
                  nut=0, strings=0, frets=0, dots=(0, 0, 0))
        image = Image.new('RGBA', (s, s), (255, 255, 255, 0))
        image.putalpha(alpha)
        return image
    return supersample(size, draw_at)


def splash(size=768):
    """The launch mark: the card alone on transparent, for the splash.

    It stays inside the central third that Android 12 crops to a circle."""
    def draw_at(s):
        image = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        chord_box(ImageDraw.Draw(image), s / 2, s / 2, s * 0.40)
        return image
    return supersample(size, draw_at)


def maskable(size=512):
    """Web install icon: the card smaller, so a circular mask cannot clip it."""
    def draw_at(s):
        image = ground(s).convert('RGBA')
        chord_box(ImageDraw.Draw(image), s / 2, s / 2, s * 0.44)
        return image.convert('RGB')
    return supersample(size, draw_at)


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, name), size,
                              layout_engine=ImageFont.Layout.BASIC)


def fits(draw, xy, text, face, anchor, limit):
    """Raises if a line would run past `limit`, so a long edit cannot quietly
    push text off the card."""
    right = draw.textbbox(xy, text, font=face, anchor=anchor)[2]
    if right > limit:
        raise ValueError('%r runs to %d, past %d' % (text, right, limit))


def line(draw, xy, text, face, fill, limit):
    fits(draw, xy, text, face, 'ls', limit)
    draw.text(xy, text, font=face, fill=fill, anchor='ls')


def social_card(width=1200, height=630):
    """The card that shows when the link is shared.

    The wordmark is set in Poppins, the face the app itself uses, so the card
    and the app look like the same thing. It stays in Latin: Pillow here is
    built without Raqm, and unshaped Devanagari puts the matras in the wrong
    place, which is worse than not setting it at all. The Hindi name travels
    in the page's own Open Graph title beside the image.
    """
    image = ground(width, height).convert('RGBA')
    chord_box(ImageDraw.Draw(image), width * 0.2, height / 2, height * 0.5)
    draw = ImageDraw.Draw(image)
    x, edge = width * 0.40, width - 60
    line(draw, (x, height * 0.30), 'SurSaar', font('Poppins-SemiBold.ttf', 96),
         SURFACE, edge)
    draw.line([x, height * 0.37, x + width * 0.10, height * 0.37], fill=GOLD,
              width=6)
    line(draw, (x, height * 0.52), 'A guitar teacher that watches,',
         font('Poppins-SemiBold.ttf', 36), SURFACE, edge)
    line(draw, (x, height * 0.62), 'listens and corrects you',
         font('Poppins-SemiBold.ttf', 36), SURFACE, edge)
    line(draw, (x, height * 0.76), 'Chords · Strumming · Finger position · Tuner',
         font('Poppins-Regular.ttf', 24), (226, 232, 255), edge)
    # A navy pill, because small white type on violet loses its edges.
    label = 'Free · No account · Hindi and English'
    pill = font('Poppins-SemiBold.ttf', 23)
    xy = (x, height * 0.90)
    fits(draw, xy, label, pill, 'ls', edge)
    box = draw.textbbox(xy, label, font=pill, anchor='ls')
    draw.rounded_rectangle([box[0] - 18, box[1] - 11, box[2] + 18, box[3] + 11],
                           radius=26, fill=NAVY)
    draw.text(xy, label, font=pill, fill=SURFACE, anchor='ls')
    return image.convert('RGB')


def feature_graphic(width=1024, height=500):
    """The banner Play shows at the top of the listing."""
    image = ground(width, height).convert('RGBA')
    chord_box(ImageDraw.Draw(image), width * 0.2, height / 2, height * 0.5)
    draw = ImageDraw.Draw(image)
    x, edge = width * 0.40, width - 50
    line(draw, (x, height * 0.43), 'SurSaar', font('Poppins-SemiBold.ttf', 80),
         SURFACE, edge)
    line(draw, (x, height * 0.62), 'Learn guitar with a teacher',
         font('Poppins-SemiBold.ttf', 30), SURFACE, edge)
    line(draw, (x, height * 0.75), 'that watches, listens and corrects you',
         font('Poppins-Regular.ttf', 27), (226, 232, 255), edge)
    return image.convert('RGB')


def main():
    os.makedirs(OUT, exist_ok=True)
    app_icon().save(os.path.join(OUT, 'icon-1024.png'))
    foreground().save(os.path.join(OUT, 'icon-foreground.png'))
    monochrome().save(os.path.join(OUT, 'icon-monochrome.png'))
    maskable().save(os.path.join(OUT, 'icon-maskable-512.png'))
    app_icon(512).save(os.path.join(OUT, 'icon-512.png'))
    app_icon(192).save(os.path.join(OUT, 'icon-192.png'))
    app_icon(96).save(os.path.join(OUT, 'icon-96.png'))
    # The app is dark only (ThemeMode.dark), so the splash sits on the same
    # navy in either mode and one mark serves both; the pair of files keeps
    # flutter_native_splash configured the way the light and dark apps are.
    splash().save(os.path.join(OUT, 'splash-light.png'))
    splash().save(os.path.join(OUT, 'splash-dark.png'))
    social_card().save(os.path.join('site', 'og-image.png'))
    os.makedirs(os.path.join('store', 'play'), exist_ok=True)
    feature_graphic().save(os.path.join('store', 'play', 'feature-graphic.png'))
    app_icon(512).save(os.path.join('store', 'play', 'icon-512.png'))
    # Optical sizing: below about sixty pixels five strings and four frets
    # turn to mesh, so the small renders keep the card, the nut and the dots.
    for small in (16, 32, 48):
        app_icon(small, small=True).save(os.path.join(OUT, 'icon-%d.png' % small))
    # The web reads its icons from here, not from flutter_launcher_icons.
    app_icon(48, small=True).save(os.path.join('web', 'favicon.png'))
    app_icon(48, small=True).save(os.path.join('site', 'favicon.png'))
    app_icon(512).save(os.path.join('web', 'icons', 'Icon-512.png'))
    app_icon(192).save(os.path.join('web', 'icons', 'Icon-192.png'))
    maskable(512).save(os.path.join('web', 'icons', 'Icon-maskable-512.png'))
    maskable(192).save(os.path.join('web', 'icons', 'Icon-maskable-192.png'))
    print('wrote icons to %s, site/og-image.png and the web icons' % OUT)


if __name__ == '__main__':
    main()
