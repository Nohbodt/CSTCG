"""Printable Series 1 art/content lookbook; called by build_series1_design.py."""

from __future__ import annotations

from pathlib import Path
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph, Table, TableStyle

ROOT = Path(__file__).resolve().parents[1]
W, H = A4
INK = colors.HexColor("#15212D")
MUTED = colors.HexColor("#536170")
ORANGE = colors.HexColor("#CF592E")
DARK = colors.HexColor("#10151D")
PALE = colors.HexColor("#F2F4F5")


def text(c, value, x, top, width, size=9.5, color=INK, bold=False):
    style = ParagraphStyle("s1", fontName="S1Bold" if bold else "S1Text", fontSize=size,
                           leading=size * 1.4, textColor=color, spaceAfter=0)
    p = Paragraph(escape(str(value)).replace("\n", "<br/>"), style)
    _, height = p.wrap(width, 2000)
    p.drawOn(c, x, top - height)
    return top - height


def start(c, title, kicker="CSTCG / SERIES 1 DESIGN 1.0"):
    c.setFillColor(colors.white)
    c.rect(0, 0, W, H, fill=1, stroke=0)
    text(c, kicker, 36, H - 30, W - 72, 8, ORANGE, True)
    text(c, title, 36, H - 54, W - 72, 24, INK, True)
    c.setStrokeColor(colors.HexColor("#DDE3E7"))
    c.line(36, H - 106, W - 36, H - 106)


def end(c):
    c.setFont("S1Text", 7)
    c.setFillColor(MUTED)
    c.drawString(36, 22, "CSTCG Series 1 / design specification / authored game profiles")
    c.drawRightString(W - 36, 22, str(c.getPageNumber()))
    c.showPage()


def image_fit(c, path, x, top, width, max_height):
    image = ImageReader(str(path))
    iw, ih = image.getSize()
    scale = min(width / iw, max_height / ih)
    ww, hh = iw * scale, ih * scale
    c.drawImage(image, x + (width - ww) / 2, top - hh, ww, hh, mask="auto")
    return top - hh


def table(c, rows, x, top, widths, size=8):
    style = ParagraphStyle("cell", fontName="S1Text", fontSize=size, leading=size * 1.35, textColor=INK)
    cells = [[Paragraph(escape(str(v)), style) for v in row] for row in rows]
    t = Table(cells, colWidths=widths, repeatRows=1, hAlign="LEFT")
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E6EBEF")),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F7F8F9")]),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6), ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 7), ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
        ("LINEBELOW", (0, 0), (-1, 0), .8, colors.HexColor("#A4B3C0")),
        ("LINEBELOW", (0, 1), (-1, -1), .3, colors.HexColor("#E0E5E9")),
    ]))
    _, height = t.wrap(sum(widths), 2000)
    t.drawOn(c, x, top - height)
    return top - height


def draw_card(c, card, x, y, width, palette):
    scale = width / 840
    c.saveState()
    c.translate(x, y)
    c.scale(scale, scale)
    col = colors.HexColor(palette[card["rarity"]])
    accent = colors.HexColor("#A28AF5") if card["finish"] == "beta_event" else (colors.HexColor("#DDB56E") if card["finish"] == "showcase" else col)
    c.setFillColor(DARK)
    c.setStrokeColor(accent)
    c.setLineWidth(6)
    c.roundRect(3, 3, 834, 1194, 28, fill=1, stroke=1)
    c.setStrokeColor(colors.HexColor("#344251"))
    c.setLineWidth(2)
    c.roundRect(24, 24, 792, 1152, 18, fill=0, stroke=1)
    c.setFont("S1Bold", 25)
    c.setFillColor(colors.HexColor("#F1F0E8"))
    c.drawString(50, 1130, "CSTCG")
    c.setFont("S1Text", 23)
    c.setFillColor(col)
    c.drawRightString(788, 1130, "SERIES 1")
    c.setFillColor(colors.HexColor("#18222E"))
    c.rect(194, 520, 596, 580, fill=1, stroke=0)
    c.setStrokeColor(accent)
    c.setLineWidth(1)
    for i in range(5):
        c.line(205 + i * 100, 550, 360 + i * 100, 1040)
    c.setFillColor(accent)
    c.setFont("S1Display", 96)
    c.drawCentredString(495, 810, card["handle"][:2].upper())
    c.setFont("S1Text", 18)
    c.drawCentredString(495, 720, "PORTRAIT POSITION")
    c.setFillColor(colors.HexColor("#F1F0E8"))
    c.setFont("S1Display", 118)
    c.drawString(50, 980, str(card["overall"]))
    c.setFillColor(MUTED)
    c.setFont("S1Text", 22)
    c.drawString(52, 943, "OVR")
    c.setFillColor(col)
    c.setFont("S1Bold", 27)
    c.drawString(52, 894, card["role"])
    c.setFont("S1Text", 24)
    c.drawString(52, 850, card["country"] + " / T5")
    c.setFont("S1Bold", 19)
    c.drawString(52, 750, card["rarity"].upper())
    c.setStrokeColor(accent)
    c.line(48, 510, 792, 510)
    c.setFillColor(colors.HexColor("#F1F0E8"))
    c.setFont("S1Display", 64 if len(card["handle"]) > 8 else 80)
    c.drawString(48, 420, card["handle"])
    c.setFillColor(colors.HexColor("#AEB9C4"))
    c.setFont("S1Text", 27)
    c.drawString(50, 374, card["name"])
    c.setFillColor(accent)
    c.setFont("S1Bold", 21)
    c.drawString(52, 320, card["edition"])
    for xx, key, label in [(52, "aim", "AIM"), (300, "iq", "IQ"), (547, "util", "UTIL")]:
        c.setFillColor(colors.HexColor("#F1F0E8"))
        c.setFont("S1Display", 78)
        c.drawString(xx, 198, str(card["summary"][key]))
        c.setFillColor(col)
        c.setFont("S1Bold", 25)
        c.drawString(xx, 158, label)
    c.setFont("S1Text", 26)
    c.setFillColor(colors.HexColor("#C7D0D8"))
    c.drawString(52, 100, card["tendency"])
    c.setStrokeColor(colors.HexColor("#344251"))
    c.line(48, 76, 792, 76)
    c.setFont("S1Text", 21)
    c.drawString(52, 39, card["collector_number"])
    c.setFillColor(col)
    c.setFont("S1Text", 17)
    c.drawRightString(790, 39, card["collector_title"].upper())
    c.restoreState()


def build_pdf(data: dict, out: Path):
    for name, file in [("S1Text", "OpenSans-Regular.ttf"), ("S1Bold", "OpenSans-Semibold.ttf"), ("S1Display", "DejaVuSansCondensed-Bold.ttf")]:
        pdfmetrics.registerFont(TTFont(name, str(ROOT / "assets/fonts" / file)))
    filename = out / "CSTCG_Series_1_Design_Lookbook.pdf"
    c = canvas.Canvas(str(filename), pagesize=A4, pageCompression=1, invariant=1)
    c.setTitle("CSTCG Series 1 — four packs, ninety card designs")
    c.setAuthor("CSTCG design workspace")
    c.setFillColor(DARK)
    c.rect(0, 0, W, H, fill=1, stroke=0)
    text(c, "CSTCG / LAUNCH COLLECTION", 36, H - 40, W - 72, 9, colors.HexColor("#F36C3D"), True)
    text(c, "SERIES 1", 34, H - 90, W - 68, 58, colors.HexColor("#F1F0E8"), True)
    text(c, "One series. Four ways to build your club.", 38, H - 185, W - 76, 18, colors.HexColor("#C8D1DA"))
    image_fit(c, out / "art/pack-family.png", 28, H - 260, W - 56, 310)
    text(c, "60 player profiles / 90 collectible designs", 38, 220, W - 76, 20, colors.HexColor("#F1F0E8"), True)
    text(c, "Alpha and Bravo: 3-card openings. Elite and Beta Event: 5-card openings. Every product has exactly 50 eligible card definitions.", 38, 170, W - 76, 12, colors.HexColor("#C8D1DA"))
    text(c, "Design specification 1.0. Includes individual card attributes, art direction, exact pools and opening probabilities. Runtime installation and combat balance are separate implementation work.", 38, 98, W - 76, 9, colors.HexColor("#8E9DAA"))
    c.showPage()

    start(c, "One face. Three finishes.")
    y = image_fit(c, out / "art/card-direction.png", 28, H - 125, W - 56, 400) - 22
    y = text(c, "Original, Elite Showcase and Beta Event share the same player profile. The artwork changes; the stats do not.", 36, y, W - 72, 13, INK, True) - 16
    y = text(c, "Portrait first, large handle, clear role and tier, separate rarity rail, three readable headline indices. Eight exact attributes and the complete game policy remain available in inspection.", 36, y, W - 72, 11) - 16
    text(c, "Generated reference illustrations establish composition and materials. Final spellings, numbers and tiers come from the manifest as separate text layers. The following catalogue uses precise layout proofs with portrait positions, not ninety completed portrait assets.", 36, y, W - 72, 9, MUTED)
    end(c)

    start(c, "The four launch products")
    y = H - 130
    for p in data["packs"]:
        c.setFillColor(colors.HexColor(p["color"]))
        c.roundRect(36, y - 127, 7, 120, 3, fill=1, stroke=0)
        top = text(c, p["name"], 58, y, W - 100, 16, INK, True) - 8
        top = text(c, f"{p['cards_per_opening']} player cards / 50-card pool / {p['guarantee']}", 58, top, W - 100, 10.5) - 6
        price = "Earned from the First Circuit event track" if p["price_credits_candidate"] is None else f"{p['price_credits_candidate']:,} earned Credits (balance candidate)"
        top = text(c, price, 58, top, W - 100, 10, MUTED) - 7
        text(c, f"{p['tagline']} / {p['emblem']} / Peak in at least one slot: {p['peak_pack_percent']:.4f}%", 58, top, W - 100, 9, MUTED)
        y -= 150
    end(c)

    start(c, "Rarity, tier and useful roles")
    y = table(c, [["Rarity", "Frame", "Material"], ["Common", "Single steel rail", "Matte"], ["Uncommon", "Double sage notch", "Satin"], ["Semi-Rare", "Three cyan segments", "Brushed foil"], ["Rare", "Blue aperture + four ticks", "Blue foil"], ["Legendary", "Gold cap + five ticks", "Embossed metal"], ["Peak", "Pearl arch + six ticks", "Interference foil"]], 36, H - 130, [105, 220, W - 397]) - 22
    y = text(c, "All Series 1 designs begin at T5. Floor and Divine are excluded from these products. The prototype's Epic label is legacy-only. Rarity is a discovery label, tier is development, and finish is an artwork treatment.", 36, y, W - 72, 10.5) - 18
    y = text(c, "Eight natural attributes", 36, y, W - 72, 15, INK, True) - 7
    y = text(c, "Aim / Reaction / Positioning / Utility / Gamesense / Clutch / Teamwork / Consistency", 36, y, W - 72, 11) - 12
    y = text(c, "OVR = rounded eight-attribute mean. AIM = Aim. IQ = rounded mean of Positioning, Gamesense, Clutch and Consistency. UTIL = rounded mean of Utility and Teamwork. OVR is not a match-win predictor.", 36, y, W - 72, 10) - 18
    text(c, "A useful low-rarity card: Common RUSH has AIM 72 / IQ 77 / UTIL 87. Peak NiKo also has UTIL 87, with AIM 97. Rare Aleksib has UTIL 96. Cards perform different jobs instead of following one universal power ladder.", 36, y, W - 72, 11, INK, True)
    end(c)

    start(c, "Exact pools and opening rules")
    headers = ["Pool", "C", "U", "SR", "R", "L", "P", "Cards"]
    rows = [headers]
    for p in data["packs"]:
        rows.append([p["short_name"], *[p["rarity_counts"].get(r, 0) for r in data["rarities"]], p["cards_per_opening"]])
    y = table(c, rows, 36, H - 130, [115, 46, 46, 46, 46, 46, 46, W - 463]) - 20
    y = text(c, "Each pool has ten designs per role. Alpha and Bravo share forty definitions; together they contain all sixty originals. Elite has forty originals and ten Showcases. Beta Event has thirty originals and twenty Event editions.", 36, y, W - 72, 10) - 18
    rows = [["Slot table", "C", "U", "SR", "R", "L", "P"], ["Alpha/Bravo 1–2; Event 1–4", "45", "30", "18", "6.5", ".45", ".05"], ["Alpha/Bravo 3; Event 5", "0", "0", "0", "95", "4.9", ".1"], ["Elite 1–4", "0", "25", "40", "30", "4.9", ".1"], ["Elite 5", "0", "0", "0", "0", "99.9", ".1"]]
    y = table(c, rows, 36, y, [193, 55, 55, 55, 55, 55, W - 540], 7.5) - 18
    y = text(c, "All entries are percentages. Final Elite slot filters to Showcase only; final Event slot filters to Beta Event editions. Rarity is selected first, then one eligible definition uniformly. Repeats are possible. Per-card probabilities are supplied for all 200 memberships.", 36, y, W - 72, 9.5) - 16
    text(c, "Whole-opening Peak chance: Alpha/Bravo 0.1999%; Elite 0.4990%; Beta Event 0.2997%. Direct choice rewards and the guaranteed welcome Peak are separate from these ordinary odds. Prices, reward cadence and release values remain balance candidates.", 36, y, W - 72, 9.5, MUTED)
    end(c)

    start(c, "Art and implementation handoff")
    y = H - 130
    items = [
        ("Portrait and frame", "840 × 1,200 px face artboard, 40 px safe margin. Portrait/background, cutout mask, rarity frame and foil mask are separate layers. Keep skin neutral and text clear. Preserve source assets."),
        ("Live information", "Names, handles, country, role, tier, stats, rarity, collector number, provenance and ownership labels come from structured data. No baked price, invented match fact, fake autograph or unique serial."),
        ("Concealment and inspection", "Opening sleeves have one uniform CSTCG Series 1 back. Revealed cards have an inspection reverse with eight values and the full policy. Hidden opening covers do not reveal identity or rarity."),
        ("Collection identity", "60 player IDs, 60 immutable profile templates and 90 collectible card IDs. Alternate finishes share their template. Only one version of a professional fits a lineup. Future owned instance IDs remain separate."),
        ("Implementation scope", "The current runtime remains alpha 0.2. A future installation adds six rarity tiers, three/five-card openings, finish-aware guarantees, eight-attribute inspection, policy behavior and an explicit legacy-save migration."),
        ("Validation", "The design builder checks all pool sizes and role counts, 10,000-basis-point slot sums, every weighted eligibility cell, every advertised design's reachability, finish stat parity, overlaps and expected direct release returns."),
    ]
    for heading, body in items:
        y = text(c, heading, 36, y, W - 72, 12, INK, True) - 5
        y = text(c, body, 36, y, W - 72, 10) - 19
    end(c)

    cards = data["cards"]
    for offset in range(0, len(cards), 2):
        start(c, "Individual card register", f"CSTCG / SERIES 1 / DEFINITIONS {offset+1:02d}–{min(offset+2,len(cards)):02d}")
        for j, card in enumerate(cards[offset:offset + 2]):
            top = H - 128 - j * 343
            draw_card(c, card, 36, top - 242, 166, data["rarity_colors"])
            x, width = 220, W - 256
            y = text(c, f"{card['collector_number']} / {card['handle']}", x, top, width, 12, INK, True) - 5
            y = text(c, card["collector_title"] + " / " + card["edition"], x, y, width, 9, ORANGE, True) - 5
            y = text(c, f"{card['name']} / {card['country']} / {card['role']} / {card['rarity']} / T5", x, y, width, 8.5, MUTED) - 8
            values = card["stats"]
            stat_text = "\n".join(f"{a.title()} {values[a]}     {b.title()} {values[b]}" for a, b in [("aim", "reaction"), ("positioning", "utility"), ("gamesense", "clutch"), ("teamwork", "consistency")])
            y = text(c, stat_text, x, y, width, 8.5) - 7
            y = text(c, card["tendency"] + ": " + card["tendency_rule"], x, y, width, 8.3) - 8
            y = text(c, "ART: " + card["art_direction"], x, y, width, 8.2) - 6
            names = [p["short_name"] for p in data["packs"] if p["pack_id"] in card["available_in"]]
            text(c, "POOLS: " + ", ".join(names) + ".\nID: " + card["card_id"], x, y, width, 7.5, MUTED)
            if j == 0:
                c.setStrokeColor(colors.HexColor("#DDE3E7"))
                c.line(36, top - 319, W - 36, top - 319)
        end(c)
    c.save()
    print(f"CSTCG_SERIES1_LOOKBOOK: {filename.name}; 51 pages")
