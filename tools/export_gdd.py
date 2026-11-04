#!/usr/bin/env python3
"""Export the unified Markdown design as a readable PDF and editable Word file.

Requires reportlab and python-docx in the document-authoring environment only.
The Godot game has no dependency on these packages.
"""

from __future__ import annotations

import html
import re
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, Frame, KeepTogether, NextPageTemplate, PageBreak,
    PageTemplate, Paragraph, Spacer, Table, TableStyle,
)
from reportlab.platypus.tableofcontents import TableOfContents

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/ESPORTS_CSTCG_Master_GDD_v3_0.md"
OUTPUT = SOURCE.with_suffix("")
INK = colors.HexColor("#17212b")
MUTED = colors.HexColor("#52616d")
ORANGE = colors.HexColor("#c65b2c")
NAVY = colors.HexColor("#101a26")
PALE = colors.HexColor("#f1f4f6")


def inline(text: str) -> str:
    text = html.escape(text)
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"\1", text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"`([^`]+)`", r'<font color="#52616d">\1</font>', text)
    return text


def blocks(text: str):
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line or line == "---":
            i += 1
            continue
        if line.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                raw = lines[i].strip()
                if not re.match(r"^\|[\s:|-]+\|$", raw):
                    rows.append([cell.strip() for cell in raw.strip("|").split("|")])
                i += 1
            yield "table", rows
            continue
        if line.startswith("#"):
            heading = re.match(r"^(#+)\s+(.+)", line)
            yield "heading", (len(heading[1]), heading[2])
        elif re.match(r"^\d+\.\s", line):
            number, value = line.split(". ", 1)
            yield "number", (number, value)
        elif line.startswith("- "):
            yield "bullet", line[2:]
        else:
            yield "paragraph", line
        i += 1


def register_fonts():
    font_dir = ROOT / "assets/fonts"
    pdfmetrics.registerFont(TTFont("Club", str(font_dir / "OpenSans-Regular.ttf")))
    pdfmetrics.registerFont(TTFont("ClubBold", str(font_dir / "OpenSans-Semibold.ttf")))
    pdfmetrics.registerFont(TTFont("ClubDisplay", str(font_dir / "DejaVuSansCondensed-Bold.ttf")))
    pdfmetrics.registerFontFamily("Club", normal="Club", bold="ClubBold", italic="Club", boldItalic="ClubBold")


def draw_cover(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(NAVY)
    canvas.rect(0, 0, 612, 792, fill=1, stroke=0)
    canvas.setStrokeColor(colors.HexColor("#273647"))
    for i in range(13):
        canvas.line(300 + i * 30, 792, 60 + i * 30, 0)
    canvas.setFillColor(colors.HexColor("#ee8b59"))
    canvas.rect(48, 729, 46, 4, fill=1, stroke=0)
    canvas.setFont("ClubBold", 9)
    canvas.drawString(48, 705, "MASTER GAME DESIGN / RECOMMENDED SYNTHESIS")
    canvas.setFillColor(colors.HexColor("#f5f1e7"))
    canvas.setFont("ClubDisplay", 52)
    canvas.drawString(46, 620, "ESPORTS:")
    canvas.drawString(46, 560, "CSTCG")
    canvas.setFont("ClubBold", 12)
    canvas.setFillColor(colors.HexColor("#ee8b59"))
    canvas.drawString(48, 518, "COLLECT THE TALENT. BUILD THE CLUB. MAKE THE CALL.")
    p = Paragraph(
        "The collection excitement of Ultimate Team, the club-building choices of a manager, "
        "and the tactical tension of Counter-Strike.",
        ParagraphStyle("CoverBody", fontName="Club", fontSize=16, leading=25,
                       textColor=colors.HexColor("#cbd3db")),
    )
    _, height = p.wrap(430, 150)
    p.drawOn(canvas, 48, 390 - height)
    canvas.setFont("ClubDisplay", 145)
    canvas.setFillColor(colors.HexColor("#273647"))
    canvas.drawRightString(565, 130, "03")
    canvas.setFillColor(colors.HexColor("#ee8b59"))
    canvas.setFont("ClubBold", 11)
    canvas.drawString(48, 190, "UNIFIED GAME DESIGN / VERSION 3.0")
    canvas.setFillColor(colors.HexColor("#cbd3db"))
    canvas.setFont("Club", 9)
    for index, text in enumerate([
        "2 NOVEMBER 2026 · GODOT 4 · PC FIRST / MOBILE TARGET",
        "SOURCES: MASTER GDD v2.0 + CLUB CIRCUIT PROTOTYPE",
        "Proposed legacy changes are marked. Candidate numbers require playtesting.",
        "This design document does not certify new features as implemented.",
    ]):
        canvas.drawString(48, 164 - index * 19, text)
    canvas.restoreState()


def draw_body(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor("#d7dfe5"))
    canvas.line(48, 752, 564, 752)
    canvas.line(48, 38, 564, 38)
    canvas.setFont("ClubBold", 7)
    canvas.setFillColor(MUTED)
    canvas.drawString(48, 763, "ESPORTS: CSTCG / UNIFIED MASTER GDD")
    canvas.drawRightString(564, 763, "VERSION 3.0 · DESIGN RECOMMENDATION")
    canvas.setFont("Club", 7)
    canvas.drawString(48, 24, "COLLECT · BUILD · COACH · COMPETE")
    canvas.drawRightString(564, 24, str(doc.page))
    canvas.restoreState()


class MasterDoc(BaseDocTemplate):
    def afterFlowable(self, flowable):
        if isinstance(flowable, Paragraph) and flowable.style.name == "Section":
            title = flowable.getPlainText()
            key = "section-" + re.sub(r"\W+", "-", title.lower())
            self.canv.bookmarkPage(key)
            self.canv.addOutlineEntry(title, key, 0, False)
            self.notify("TOCEntry", (0, title, self.page, key))


def export_pdf(text: str):
    register_fonts()
    body = ParagraphStyle("ClubBody", fontName="Club", fontSize=9.3, leading=14,
                          textColor=INK, spaceAfter=7, splitLongWords=True,
                          allowWidows=0, allowOrphans=0)
    section = ParagraphStyle("Section", parent=body, fontName="ClubDisplay", fontSize=19,
                             leading=25, textColor=INK, spaceBefore=18, spaceAfter=13,
                             keepWithNext=True)
    sub = ParagraphStyle("Subsection", parent=body, fontName="ClubBold", fontSize=11.1,
                         leading=16, spaceBefore=10, spaceAfter=6, textColor=ORANGE,
                         keepWithNext=True)
    cell = ParagraphStyle("Cell", parent=body, fontSize=7.7, leading=11, spaceAfter=0)
    head = ParagraphStyle("HeadCell", parent=cell, fontName="ClubBold", textColor=colors.white)
    compact_head = ParagraphStyle("CompactHead", parent=head, fontSize=6.7, leading=10)
    bullet = ParagraphStyle("ClubBullet", parent=body, leftIndent=15, bulletIndent=0,
                            spaceAfter=6)
    doc = MasterDoc(str(OUTPUT.with_suffix(".pdf")), pagesize=letter,
                    leftMargin=48, rightMargin=48, topMargin=52, bottomMargin=52,
                    title="ESPORTS: CSTCG — Unified Master GDD v3.0",
                    author="CSTCG Design", subject="Collection and tactical club management design")
    frame = Frame(48, 52, 516, 688, leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)
    doc.addPageTemplates([
        PageTemplate(id="Cover", frames=[frame], onPage=draw_cover),
        PageTemplate(id="Body", frames=[frame], onPage=draw_body),
    ])
    toc = TableOfContents()
    toc.levelStyles = [ParagraphStyle("TOCEntry", fontName="Club", fontSize=10,
                                     leading=17, textColor=INK, spaceAfter=4)]
    story = [NextPageTemplate("Body"), Spacer(1, 20), PageBreak(),
             Paragraph("Inside the design", ParagraphStyle("TOCTitle", parent=section)),
             Paragraph("One recommended game, explicit legacy changes, and a clear separation "
                       "between the target and today's prototype.", body),
             Spacer(1, 10), toc, PageBreak()]
    started = False
    for kind, value in blocks(text):
        if kind == "heading" and value[1].startswith("01 ·"):
            started = True
        if not started:
            continue
        if kind == "heading":
            level, title = value
            story.append(Paragraph(inline(title), section if level == 2 else sub))
        elif kind == "paragraph":
            story.append(Paragraph(inline(value), body))
        elif kind == "number":
            number, content = value
            story.append(Paragraph(inline(content), bullet, bulletText=number + "."))
        elif kind == "bullet":
            story.append(Paragraph(inline(value), bullet, bulletText="•"))
        elif kind == "table":
            count = len(value[0])
            if count == 9:
                widths = [116] + [50] * 8
            else:
                weights = []
                for index in range(count):
                    longest = max(len(re.sub(r"[*`]", "", row[index])) for row in value)
                    weights.append(max(10, min(72, longest)) ** 0.65)
                if count > 2:
                    weights[0] *= 0.88
                widths = [516 * weight / sum(weights) for weight in weights]
            header_style = compact_head if count == 9 else head
            rows = [[Paragraph(inline(content), header_style if i == 0 else cell)
                     for content in row] for i, row in enumerate(value)]
            table = Table(rows, colWidths=widths, repeatRows=1, hAlign="LEFT")
            table.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0), NAVY),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [PALE, colors.white]),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LINEBELOW", (0, 0), (-1, 0), 1.5, ORANGE),
                ("LINEBELOW", (0, 1), (-1, -1), 0.4, colors.HexColor("#d7dfe5")),
                ("LEFTPADDING", (0, 0), (-1, -1), 4 if count == 9 else 7),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4 if count == 9 else 7),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]))
            if count == 9:
                # Keep the guarantee row with its odds table, heading, and intro.
                intro = story.pop()
                heading = story.pop()
                story.append(KeepTogether([heading, intro, Spacer(1, 3), table, Spacer(1, 10)]))
            else:
                story.extend([Spacer(1, 3), table, Spacer(1, 10)])
    doc.multiBuild(story)


def add_runs(paragraph, text: str):
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"\1", text)
    for part in re.split(r"(\*\*.*?\*\*|`[^`]+`)", text):
        run = paragraph.add_run(part.strip("*") if part.startswith("**") else part.strip("`"))
        run.bold = part.startswith("**")
        if part.startswith("`"):
            run.font.name = "DejaVu Sans Mono"
            run.font.size = Pt(8)


def export_docx(text: str):
    doc = Document()
    section = doc.sections[0]
    section.page_width, section.page_height = Inches(8.5), Inches(11)
    section.top_margin = section.bottom_margin = Inches(0.75)
    section.left_margin = section.right_margin = Inches(0.7)
    for name in ["Normal", "Body Text", "List Bullet", "List Number"]:
        style = doc.styles[name]
        style.font.name = "Open Sans"
        style.font.size = Pt(10)
        style.font.color.rgb = RGBColor.from_string("17212B")
        style.paragraph_format.space_after = Pt(7)
        style.paragraph_format.line_spacing = 1.15
    for name, size in [("Title", 36), ("Heading 1", 20), ("Heading 2", 13)]:
        doc.styles[name].font.name = "Open Sans"
        doc.styles[name].font.size = Pt(size)
        doc.styles[name].font.color.rgb = RGBColor.from_string("17212B" if name != "Heading 2" else "C65B2C")
    header = section.header.paragraphs[0]
    header.text = "ESPORTS: CSTCG  /  UNIFIED MASTER GDD v3.0"
    header.runs[0].font.size = Pt(8)
    footer = section.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    footer.add_run("DESIGN RECOMMENDATION  /  ").font.size = Pt(8)
    field = OxmlElement("w:fldSimple")
    field.set(qn("w:instr"), "PAGE")
    footer._p.append(field)
    doc.add_heading("ESPORTS: CSTCG", 0)
    doc.add_paragraph("UNIFIED GAME DESIGN · VERSION 3.0", "Subtitle")
    doc.add_paragraph("COLLECT THE TALENT. BUILD THE CLUB. MAKE THE CALL.")
    started = False
    for kind, value in blocks(text):
        if kind == "heading" and value[1].startswith("01 ·"):
            started = True
            doc.add_page_break()
        if not started:
            if kind == "paragraph" and not value.startswith("**COLLECT"):
                add_runs(doc.add_paragraph(), value)
            continue
        if kind == "heading":
            level, title = value
            doc.add_heading(title, 1 if level == 2 else 2)
        elif kind == "paragraph":
            add_runs(doc.add_paragraph(), value)
        elif kind in ["number", "bullet"]:
            content = value[1] if kind == "number" else value
            add_runs(doc.add_paragraph(style="List Number" if kind == "number" else "List Bullet"), content)
        elif kind == "table":
            table = doc.add_table(rows=0, cols=len(value[0]))
            table.style = "Light Shading Accent 1"
            for index, row in enumerate(value):
                cells = table.add_row().cells
                for i, content in enumerate(row):
                    paragraph = cells[i].paragraphs[0]
                    add_runs(paragraph, content)
                    for run in paragraph.runs:
                        run.font.size = Pt(8 if len(row) < 8 else 7)
                        if index == 0:
                            run.bold = True
                if index == 0:
                    repeat = OxmlElement("w:tblHeader")
                    table.rows[-1]._tr.get_or_add_trPr().append(repeat)
            doc.add_paragraph()
    doc.core_properties.title = "ESPORTS: CSTCG — Unified Master GDD v3.0"
    doc.core_properties.subject = "Collection and tactical club management design"
    doc.core_properties.author = "CSTCG Design"
    doc.save(OUTPUT.with_suffix(".docx"))


if __name__ == "__main__":
    source = SOURCE.read_text()
    export_pdf(source)
    export_docx(source)
    for suffix in [".pdf", ".docx"]:
        path = OUTPUT.with_suffix(suffix)
        print(f"Created {path.name}: {path.stat().st_size:,} bytes")
