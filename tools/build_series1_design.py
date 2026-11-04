#!/usr/bin/env python3
"""Build the Series 1 design catalogue, pool sheets, exact odds and review gallery.

Design data only: this does not replace the playable alpha's catalogue or saves.
Uses Python's standard library. The optional PDF needs ReportLab.
"""

from __future__ import annotations

import argparse
import copy
import csv
import html
import json
import math
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/series_1"
RARITIES = ["Common", "Uncommon", "Semi-Rare", "Rare", "Legendary", "Peak"]
ROLES = ["ENTRY", "AWPER", "IGL", "SUPPORT", "LURKER"]
ATTRIBUTES = ["aim", "reaction", "positioning", "utility", "gamesense", "clutch", "teamwork", "consistency"]
COLORS = {"Common": "#9AA8AE", "Uncommon": "#93C99D", "Semi-Rare": "#65CED6", "Rare": "#729BF4", "Legendary": "#DDB56E", "Peak": "#F4E8CE"}
RELEASE = {"Common": 4, "Uncommon": 6, "Semi-Rare": 10, "Rare": 20, "Legendary": 75, "Peak": 200}
CORE_ODDS = dict(zip(RARITIES, [4500, 3000, 1800, 650, 45, 5]))
RARE_ODDS = dict(zip(RARITIES, [0, 0, 0, 9500, 490, 10]))
ELITE_ODDS = dict(zip(RARITIES, [0, 2500, 4000, 3000, 490, 10]))
LEGEND_ODDS = dict(zip(RARITIES, [0, 0, 0, 0, 9990, 10]))
ROLE_MOTIFS = {
    "ENTRY": "diagonal breach planes and a short broken contact line",
    "AWPER": "a narrow sightline, offset optic circle and a distant horizon",
    "IGL": "five connected route nodes and a folded tactical line",
    "SUPPORT": "overlapping protective arcs and a soft utility plume",
    "LURKER": "an offset doorway, negative space and a late converging path",
}
POSES = ["three-quarter portrait, shoulders square, direct eye line", "chest-up portrait, slight left turn, composed expression", "chest-up portrait, slight right turn, face unobstructed", "forward-facing portrait, relaxed shoulders, natural expression"]
TRAITS = {
    "first_contact": ["First Contact", "Takes the leading entry position on a committed site attack; teammates retain trade spacing."],
    "trade_runner": ["Trade Runner", "Follows the designated entry and prioritizes a visible refrag over an unsupported solo push."],
    "close_quarters": ["Close Quarters", "Prefers connected short-angle approaches when the chosen plan offers a legal route."],
    "angle_holder": ["Angle Holder", "Settles on a clear long angle rather than repeatedly moving during the opening contact."],
    "mobile_scope": ["Mobile Scope", "Seeks another connected holding position after a revealed shot, using acquired information."],
    "patient_pick": ["Patient Pick", "Waits for a settled legal sightline instead of taking a rushed moving first shot."],
    "site_caller": ["Site Caller", "Favors a synchronized site commitment and keeps the bomb with the main group."],
    "mid_reader": ["Mid Reader", "Values communicated mid information before choosing an available rotation."],
    "reset_call": ["Reset Call", "Prefers regrouping after a failed opening when the clock and a connected route permit it."],
    "flash_assist": ["Flash Assist", "Prioritizes a purchased flash supporting the next observed teammate contact."],
    "smoke_screen": ["Smoke Screen", "Prioritizes a purchased smoke for an exposed crossing rather than using it without a purpose."],
    "anchor": ["Anchor", "Prioritizes the assigned site, bomb security and a practical defuse-kit purchase."],
    "late_rotate": ["Late Rotate", "Delays the secondary-route move until contact or an explicit call makes the timing useful."],
    "flank_watch": ["Flank Watch", "Keeps a rear approach covered instead of joining every teammate at the same angle."],
    "postplant": ["Postplant", "After a plant, favors a connected position with useful bomb or approach coverage."],
}

# Role | stable identity | public handle | public name | country | rarity |
# eight authored gameplay stats | visible game tendency | collector title |
# individual art direction. These are synthetic game profiles, not live rankings.
ROSTER = """
ENTRY|yekindar|YEKINDAR|Mareks Gaļinskis|LV|Common|85 85 72 68 73 71 75 70|first_contact|Redline|A copper diagonal opening through three narrow dark panels; hard light from the left.
ENTRY|rain|rain|Håvard Nygaard|NO|Common|86 80 82 77 82 79 84 82|trade_runner|Steady Pressure|A restrained rain-line texture behind one broad forward plane; cool white rim light.
ENTRY|patsi|Patsi|Robert Isyanov|RU|Common|81 82 70 67 70 69 73 67|close_quarters|Corner Turn|An abrupt right-angle passage with a short amber edge; close crop and compact negative space.
ENTRY|boros|BOROS|Mohammad Malhas|JO|Common|85 86 68 63 67 70 68 64|first_contact|Open Lane|One vivid opening in a charcoal wall with two converging speed cuts; warm edge light.
ENTRY|brollan|Brollan|Ludvig Brolin|SE|Uncommon|85 84 79 74 77 75 79 75|trade_runner|Second Wave|Twin offset breach planes with the second line held in reserve; pale green side light.
ENTRY|im|iM|Ivan Mihai|RO|Uncommon|86 83 80 77 81 78 81 77|close_quarters|Inside Track|A clean inner-corner cut and a dotted support path; balanced light with a soft mint edge.
ENTRY|xantares|XANTARES|İsmail Dörtkardeş|TR|Semi-Rare|94 90 80 73 80 79 77 81|first_contact|Contact Point|A single bright horizontal contact slash across a wide dark opening; ice-cyan edge reflections.
ENTRY|elige|EliGE|Jonathan Jablonowski|US|Semi-Rare|91 87 84 80 84 81 85 83|trade_runner|Measured Burst|Three restrained parallel burst marks behind a stable vertical portrait; cyan-white rim light.
ENTRY|flamez|flameZ|Shahar Shushan|IL|Rare|89 91 82 80 83 80 87 81|first_contact|Ignition|A rising folded wedge with a small warm core and blue perimeter; no literal flames over the face.
ENTRY|xertion|xertioN|Dorian Berman|IL|Rare|88 89 84 83 85 81 86 80|close_quarters|Forward Cut|A descending set of blue stepped cuts pointing into a connected doorway; crisp right-side light.
ENTRY|donk|donk|Danil Kryshkovets|RU|Legendary|97 97 86 79 86 86 84 86|first_contact|Break Point|An energetic fractured gold plane kept behind the shoulders; concentrated stage light and intact typography.
ENTRY|niko|NiKo|Nikola Kovač|BA|Peak|97 94 95 86 94 94 88 94|first_contact|First Bullet|A single pearl-gold seam opening a matte graphite field; controlled warm key light and quiet background.
AWPER|syrson|syrsoN|Florian Rische|DE|Common|84 79 76 64 76 71 74 70|angle_holder|Quiet Scope|A long narrow horizon with a small offset optic mark; desaturated steel key light.
AWPER|smooya|smooya|Owen Butterfield|GB|Common|85 84 70 61 70 75 67 65|mobile_scope|Quick Window|Two displaced rectangular windows with an intervening dark strip; bright edge at the second opening.
AWPER|hades|hades|Aleksander Miśkiewicz|PL|Common|81 80 77 68 77 78 75 72|patient_pick|Held Breath|One small illuminated window in a broad quiet field; low-contrast silver side light.
AWPER|degster|degster|Abdul Gasanov|RU|Common|88 87 77 63 77 79 71 69|mobile_scope|New Angle|A pivoting optic ring between two legal-looking lanes; strong steel-white shoulder rim.
AWPER|broky|broky|Helvijs Saukants|LV|Uncommon|89 87 84 70 82 88 81 78|patient_pick|Last Window|A late-lit square inside an otherwise dark corridor; small green reflection on the frame.
AWPER|torzsi|torzsi|Ádám Torzsás|HU|Uncommon|86 85 80 70 78 76 80 76|angle_holder|Clear Line|A straight sightline and two fine green distance ticks; calm even portrait lighting.
AWPER|m0nesy|m0NESY|Ilya Osipov|RU|Semi-Rare|96 97 87 73 86 91 82 84|mobile_scope|Snap Line|A displaced cyan optic arc and sharp opposing horizon cuts; bright controlled rim light.
AWPER|wonderful|w0nderful|Ihor Zhdanov|UA|Semi-Rare|90 90 87 72 84 84 82 80|patient_pick|Still Frame|A rectangular sight window floating in a broad dark field; cyan-white upper edge.
AWPER|sh1ro|sh1ro|Dmitriy Sokolov|RU|Rare|93 89 94 77 92 94 87 92|patient_pick|No Rush|A long empty horizontal sightline with one decisive blue point; soft frontal portrait light.
AWPER|device|device|Nicolai Reedtz|DK|Rare|92 88 96 82 96 91 94 94|angle_holder|Perfect Angle|A precisely aligned nested rectangle and clean horizon; even blue-white reflections.
AWPER|zywoo|ZywOo|Mathieu Herbaut|FR|Legendary|97 96 95 83 96 96 93 94|patient_pick|The Answer|A wide calm gold aperture with one central contact marker; soft premium stage light.
AWPER|s1mple|s1mple|Oleksandr Kostyliev|UA|Peak|99 99 94 80 97 98 88 92|mobile_scope|Long Sight|An interrupted pearl optic circle and a fine distant horizon; neutral skin and warm shoulder rim.
IGL|gla1ve|gla1ve|Lukas Rossander|DK|Common|70 69 84 86 89 77 90 82|site_caller|Five Together|Five steel nodes converging at one visible decision point; clear even light.
IGL|alex|ALEX|Alex McMeekin|GB|Common|72 70 79 82 84 73 84 75|reset_call|Second Plan|A folded route that returns to one calm central node; restrained steel-blue reflections.
IGL|dexter|dexter|Christopher Nong|AU|Common|74 74 77 77 79 75 80 74|mid_reader|Read the Gap|A central crossing with a narrow open information lane; balanced light from the right.
IGL|snappi|Snappi|Marco Pfeiffer|DK|Common|68 68 83 85 87 72 90 78|site_caller|Set the Pace|Five staggered nodes arriving at a broad entry plane; warm-neutral portrait lighting.
IGL|siuhy|siuhy|Kamil Szkaradek|PL|Uncommon|79 80 85 86 88 77 91 81|mid_reader|New Read|A fresh green branch separating from a simple route tree; soft white face light.
IGL|chopper|chopper|Leonid Vishnyakov|RU|Uncommon|78 77 83 84 86 78 89 80|reset_call|Hold the Shape|A compact five-node polygon held inside two parallel lanes; green-white frame reflections.
IGL|karrigan|karrigan|Finn Andersen|DK|Semi-Rare|72 70 88 91 95 82 98 85|site_caller|The Switch|Two site paths meeting at a bright late decision node; cyan route emphasis behind the portrait.
IGL|tabsen|tabseN|Johannes Wodarz|DE|Semi-Rare|85 81 85 86 86 80 88 84|mid_reader|Center Control|A broad central axis holding four smaller routes; firm cyan-white side light.
IGL|aleksib|Aleksib|Aleksi Virolainen|FI|Rare|78 78 91 94 95 84 98 90|site_caller|Round Blueprint|Five clean blue routes arriving in sequence around an open central lane; ordered edge lighting.
IGL|jame|Jame|Dzhami Ali|RU|Rare|86 80 94 82 96 90 85 87|reset_call|Time in Hand|A spare blue route, a closing arc and preserved empty space; calm high-side lighting.
IGL|apex|apEX|Dan Madesclaire|FR|Legendary|80 80 89 94 94 84 96 87|site_caller|All In Sync|Five gold directional rays joining one firm site outline; energetic shoulder light.
IGL|fallen|FalleN|Gabriel Toledo|BR|Peak|91 87 95 96 97 92 99 92|mid_reader|Round Architect|A pearl-gold tactical fan with five supported branches; wide calm light and a grounded portrait.
SUPPORT|rush|RUSH|William Wierzba|US|Common|72 72 79 85 78 73 88 79|flash_assist|Open for Others|One protective arc opening a clear lane for a second line; soft steel-white reflected light.
SUPPORT|interz|interz|Timofey Yakushin|RU|Common|71 73 82 88 80 75 89 80|anchor|Stay Ready|A compact site outline with a stable defensive arc; silver edge and generous negative space.
SUPPORT|styko|STYKO|Martin Styk|SK|Common|73 72 83 87 83 76 91 81|smoke_screen|Safe Passage|A soft smoke-shaped background opening one clean crossing; neutral skin tones and steel rim.
SUPPORT|es3tag|es3tag|Patrick Hansen|DK|Common|76 76 81 83 81 77 86 77|flash_assist|Link Up|Two interlocking support arcs and a fine third-player path; even steel-white lighting.
SUPPORT|perfecto|Perfecto|Ilya Zalutskiy|RU|Uncommon|82 80 90 94 88 91 93 88|anchor|Hold the Site|An unbroken green site boundary with one guarded entrance; quiet frontal light.
SUPPORT|amanek|AMANEK|François Delaunay|FR|Uncommon|79 77 84 90 85 80 93 81|smoke_screen|The Crossing|Two pale-green shields framing a soft utility plume; bright face with a restrained background.
SUPPORT|xyp9x|Xyp9x|Andreas Højsleth|DK|Semi-Rare|80 76 93 90 94 98 93 87|anchor|Still Here|One surviving cyan arc inside a larger fading outline; composed low-side light.
SUPPORT|sjuush|sjuush|Rasmus Beck|DK|Semi-Rare|82 81 89 93 86 83 92 87|flash_assist|Set the Trade|A short cyan flash arc crossing behind a protected teammate lane; clean upper rim.
SUPPORT|krimz|KRIMZ|Freddy Johansson|SE|Rare|88 82 94 90 91 89 93 91|anchor|Solid Ground|A broad blue base plane and two stable protective arcs; low warm-white key light.
SUPPORT|naf|NAF|Keith Markovic|CA|Rare|91 84 94 85 93 97 90 92|anchor|No Easy Round|A quiet blue pocket of cover beside a clear objective route; steady frontal portrait lighting.
SUPPORT|magisk|Magisk|Emil Reif|DK|Legendary|89 86 95 96 93 90 96 94|smoke_screen|The Foundation|Layered gold defensive planes beneath a soft smoke crescent; strong even stage light.
SUPPORT|twistzz|Twistzz|Russel Van Dulken|CA|Peak|97 95 94 94 94 94 97 96|flash_assist|Clean Execution|A precise pearl support arc and five small synchronized highlights; crisp warm edge lighting.
LURKER|jks|jks|Justin Savage|AU|Common|83 77 88 80 85 88 82 83|postplant|Quiet Finish|A dark doorway opening onto a small protected objective line; soft steel edge light.
LURKER|f1ku|F1KU|Maciej Miklas|PL|Common|77 77 78 74 76 75 77 72|flank_watch|Back Line|One clear rear lane beside a quiet forward route; cool even lighting and spare geometry.
LURKER|faven|faveN|Josef Baumann|DE|Common|82 80 82 75 79 77 77 73|late_rotate|Side Door|A narrow offset doorway and a late converging steel path; side-lit shoulders.
LURKER|dycha|dycha|Paweł Dycha|PL|Common|85 82 79 77 78 76 79 75|flank_watch|Wide Watch|A wider dark flank corridor with one fine peripheral line; clean silver frame reflections.
LURKER|nertz|NertZ|Guy Iluz|IL|Uncommon|89 88 86 80 85 85 84 81|late_rotate|Late Signal|A pale-green delayed route arriving beyond the main contact; bright upper-left light.
LURKER|blamef|blameF|Benjamin Bremer|DK|Uncommon|90 80 93 77 91 93 82 86|postplant|Deep Cover|A large protected pocket and one visible objective route; dense green-white lower rim.
LURKER|ropz|ropz|Robin Kool|EE|Semi-Rare|94 89 98 84 96 96 88 94|late_rotate|The Long Way|A long cyan route around a dark central void; face kept clean against offset door geometry.
LURKER|frozen|frozen|David Čerňanský|SK|Semi-Rare|93 89 94 84 91 92 88 90|flank_watch|Cold Angle|A faceted cyan doorway with a clean outer approach; cool quiet portrait lighting.
LURKER|kscerato|KSCERATO|Kaike Cerato|BR|Rare|94 88 95 83 93 96 91 93|postplant|Last Light|A small blue objective glow held beyond deep cover; warm-neutral face and cool shoulder rim.
LURKER|ax1le|Ax1Le|Sergey Rykhtorov|RU|Rare|94 90 91 82 89 89 85 84|late_rotate|Outside In|A circular blue flank route cut by a single diagonal entry; clean contrast behind the shoulders.
LURKER|spinx|Spinx|Lotan Giladi|IL|Legendary|94 91 96 87 94 94 93 91|late_rotate|Unseen Route|A gold path appearing from deep negative space; restrained stage light and no busy face overlay.
LURKER|get_right|GeT_RiGhT|Christopher Alesund|SE|Peak|95 90 99 87 99 99 92 94|late_rotate|Unseen Pressure|A pearl late-route line arriving behind a dark doorway; timeless warm-white portrait lighting.
"""


def rounded(value: float) -> int:
    return math.floor(value + 0.5)


def build_data() -> dict:
    players, cards = [], []
    for index, line in enumerate(ROSTER.strip().splitlines()):
        role, identity, handle, name, country, rarity, values, trait, title, art = line.split("|")
        stats = dict(zip(ATTRIBUTES, map(int, values.split()), strict=True))
        player = {"player_id": identity, "handle": handle, "name": name, "country": country,
                  "role": role, "rarity": rarity, "stats": stats, "overall": rounded(sum(stats.values()) / 8),
                  "summary": {"aim": stats["aim"], "iq": rounded(sum(stats[k] for k in ["positioning", "gamesense", "clutch", "consistency"]) / 4),
                              "util": rounded((stats["utility"] + stats["teamwork"]) / 2)},
                  "tendency_id": trait, "tendency": TRAITS[trait][0], "tendency_rule": TRAITS[trait][1],
                  "collector_title": title, "art_direction": art, "pose": POSES[index % len(POSES)]}
        players.append(player)
        cards.append(make_card(player, len(cards) + 1, "base"))
    for role in ROLES:
        members = [p for p in players if p["role"] == role]
        for index in [10, 11]:
            cards.append(make_card(members[index], len(cards) + 1, "showcase"))
    for role in ROLES:
        members = [p for p in players if p["role"] == role]
        for index in [6, 8, 10, 11]:
            cards.append(make_card(members[index], len(cards) + 1, "beta_event"))
    base_by_role = {role: [c for c in cards if c["role"] == role and c["finish"] == "base"] for role in ROLES}
    alpha = [c["card_id"] for role in ROLES for i, c in enumerate(base_by_role[role]) if i not in [3, 5]]
    bravo = [c["card_id"] for role in ROLES for i, c in enumerate(base_by_role[role]) if i not in [2, 4]]
    elite = [c["card_id"] for role in ROLES for i, c in enumerate(base_by_role[role]) if i >= 4]
    elite += [c["card_id"] for c in cards if c["finish"] == "showcase"]
    beta = [base_by_role[role][i]["card_id"] for j, role in enumerate(ROLES) for i in [0, 4 + j % 2, 6 + j % 2, 8 + j % 2, 10, 11]]
    beta += [c["card_id"] for c in cards if c["finish"] == "beta_event"]
    packs = [
        pack("alpha", "Alpha", "FIRST CONTACT", 3, 240, "#F36C3D", "#E9E2D0", "split A / forward slash", alpha, CORE_ODDS, RARE_ODDS, None, "1 RARE OR BETTER", "Your first five starts here."),
        pack("bravo", "Bravo", "THE NEXT MOVE", 3, 240, "#4BB7E8", "#C6F3FF", "double chevron / folded B", bravo, CORE_ODDS, RARE_ODDS, None, "1 RARE OR BETTER", "Find another way to win."),
        pack("elite", "Elite", "THE HEADLINERS", 5, 1000, "#DDB56E", "#F4E6BB", "faceted five-point crest", elite, ELITE_ODDS, LEGEND_ODDS, "showcase", "1 LEGENDARY+ SHOWCASE", "The names. The stage. The moment."),
        pack("beta_event", "Beta Event", "FIRST CIRCUIT", 5, None, "#A28AF5", "#65E3CC", "split beta glyph / event ribbon", beta, CORE_ODDS, RARE_ODDS, "beta_event", "1 RARE+ EVENT EDITION", "Be part of the first circuit."),
    ]
    by_id = {c["card_id"]: c for c in cards}
    for product in packs:
        product["pool_count"] = len(product["pool"])
        product["rarity_counts"] = dict(Counter(by_id[c]["rarity"] for c in product["pool"]))
        product["role_counts"] = dict(Counter(by_id[c]["role"] for c in product["pool"]))
        probabilities = card_probabilities(product, by_id)
        product["probabilities"] = probabilities
        product["peak_pack_percent"] = 100 * (1 - math.prod(1 - slot["rarity_weights_bp"]["Peak"] / 10000 for slot in product["slots"]))
        product["expected_release_credits"] = sum(sum(slot["rarity_weights_bp"][r] / 10000 * RELEASE[r] for r in RARITIES) for slot in product["slots"])
    for card in cards:
        card["available_in"] = [p["pack_id"] for p in packs if card["card_id"] in p["pool"]]
    data = {"schema": "cstcg.series1.design.v1", "status": "content and art specification; not installed in alpha 0.2",
            "series": "CSTCG Series 1", "master_card_count": len(cards), "player_count": len(players),
            "rarities": RARITIES, "attributes": ATTRIBUTES, "rarity_colors": COLORS, "release_credit_candidates": RELEASE,
            "players": players, "cards": cards, "packs": packs,
            "overlap": {a["pack_id"]: {b["pack_id"]: len(set(a["pool"]) & set(b["pool"])) for b in packs} for a in packs},
            "layout": {"artboard": [840, 1200], "safe_margin": 40, "portrait": [192, 94, 600, 590],
                       "overall": [48, 102, 150, 146], "role_country": [50, 260, 144, 100],
                       "player_handle": [48, 710, 744, 84], "full_name": [50, 796, 740, 36],
                       "edition_strip": [48, 848, 744, 46], "headline_stats": [48, 920, 744, 112],
                       "tendency": [50, 1060, 740, 44], "collector_footer": [48, 1130, 744, 30]},
            "trade_rules": {"max_lineup_instances_per_player_id": 1, "alternate_finish_stat_delta": 0,
                            "printed_tier": "T5", "pool_sampling": "rarity then uniform eligible card definition, with replacement",
                            "per_instance_rolls": "deferred; the Series 1 alpha uses the fixed authored templates"}}
    validate(data)
    return data


def make_card(player: dict, number: int, finish: str) -> dict:
    card = copy.deepcopy(player)
    card.update({"card_id": f"s1.{finish}.{player['player_id']}", "template_id": f"s1.profile.{player['player_id']}",
                 "collector_number": f"S1-{number:03d}/090", "number": number, "finish": finish,
                 "edition": {"base": "SERIES 1 / ORIGINAL", "showcase": "ELITE SHOWCASE", "beta_event": "BETA EVENT / FIRST CIRCUIT"}[finish],
                 "tier": "T5", "finish_stat_delta": 0, "role_motif": ROLE_MOTIFS[player["role"]],
                 "portrait_status": "art direction defined; production portrait asset not assigned"})
    if finish == "showcase":
        card["art_direction"] = (f"Elite Showcase / {player['collector_title']}: alternate portrait take; black-glass stage, "
                                 "raised champagne nameplate, five very fine spotlight rays, and the player's original role motif. "
                                 "Natural skin tones; autograph-free; rarity rail stays visible. Same stats as the base edition.")
    elif finish == "beta_event":
        card["art_direction"] = (f"First Circuit / {player['collector_title']}: alternate portrait take, violet contour-map background, "
                                 "mint perimeter ribbon, beta glyph and FIRST CIRCUIT stamp. "
                                 f"Retain the personal motif: {player['art_direction']} Keep all effects behind the face. Same stats as base.")
    return card


def pack(key, name, line, count, price, color, second, emblem, pool, normal, final, finish, guarantee, copy_line):
    slots = [{"number": i + 1, "rarity_weights_bp": dict(normal if i < count - 1 else final),
              "finish_filter": finish if i == count - 1 else None} for i in range(count)]
    return {"pack_id": f"s1.{key}", "name": f"CSTCG Series 1 {name}", "short_name": name,
            "tagline": line, "copy": copy_line, "cards_per_opening": count,
            "price_credits_candidate": price, "acquisition": "earned event track; no credit price" if price is None else "earned Credits or disclosed match rewards",
            "color": color, "secondary_color": second, "emblem": emblem, "guarantee": guarantee,
            "pool": pool, "slots": slots, "pool_version": "s1.0"}


def card_probabilities(product: dict, by_id: dict) -> dict:
    per_card = {key: [] for key in product["pool"]}
    for slot in product["slots"]:
        slot_probabilities = dict.fromkeys(product["pool"], 0.0)
        for rarity in RARITIES:
            eligible = [key for key in product["pool"] if by_id[key]["rarity"] == rarity
                        and (not slot["finish_filter"] or by_id[key]["finish"] == slot["finish_filter"])]
            weight = slot["rarity_weights_bp"][rarity]
            if weight and not eligible:
                raise ValueError(f"Empty weighted pool: {product['pack_id']} slot {slot['number']} {rarity}")
            for key in eligible:
                slot_probabilities[key] = weight / 10000 / len(eligible)
        for key in per_card:
            per_card[key].append(slot_probabilities[key])
    return {key: {"per_slot": values, "at_least_one_percent": 100 * (1 - math.prod(1 - p for p in values)),
                  "expected_copies": sum(values)} for key, values in per_card.items()}


def validate(data: dict) -> None:
    cards, players, packs = data["cards"], data["players"], data["packs"]
    assert len(players) == 60 and len(cards) == 90
    assert len({p["player_id"] for p in players}) == 60
    assert len({c["card_id"] for c in cards}) == 90
    assert Counter(c["finish"] for c in cards) == {"base": 60, "showcase": 10, "beta_event": 20}
    profiles = {p["player_id"]: p for p in players}
    for card in cards:
        assert card["rarity"] in RARITIES and card["role"] in ROLES
        assert set(card["stats"]) == set(ATTRIBUTES) and all(0 <= v <= 100 for v in card["stats"].values())
        assert card["stats"] == profiles[card["player_id"]]["stats"]
        assert card["tendency_id"] in TRAITS and card["finish_stat_delta"] == 0
    reachable = set()
    for product in packs:
        assert len(product["pool"]) == len(set(product["pool"])) == 50
        assert product["role_counts"] == dict.fromkeys(ROLES, 10)
        for slot in product["slots"]:
            assert sum(slot["rarity_weights_bp"].values()) == 10000
        assert math.isclose(sum(p["expected_copies"] for p in product["probabilities"].values()), product["cards_per_opening"])
        for slot_index in range(product["cards_per_opening"]):
            assert math.isclose(sum(p["per_slot"][slot_index] for p in product["probabilities"].values()), 1.0)
        assert 0 < product["peak_pack_percent"] <= 0.5
        for key, value in product["probabilities"].items():
            assert len(value["per_slot"]) == product["cards_per_opening"]
            assert value["expected_copies"] > 0, (product["pack_id"], key)
            reachable.add(key)
        price = product["price_credits_candidate"]
        assert price is None or product["expected_release_credits"] < price
    assert reachable == {c["card_id"] for c in cards}
    assert data["overlap"]["s1.alpha"]["s1.bravo"] == 40


def write_csvs(data: dict) -> None:
    with (OUT / "card_checklist.csv").open("w", newline="", encoding="utf-8-sig") as f:
        fields = ["collector_number", "card_id", "player_id", "handle", "name", "country", "role", "rarity", "finish", "tier", "overall", *ATTRIBUTES,
                  "headline_aim", "headline_iq", "headline_util", "tendency", "tendency_rule", "collector_title", "pose", "art_direction", "available_in"]
        writer = csv.DictWriter(f, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for card in data["cards"]:
            row = {key: card.get(key, "") for key in fields}
            row.update(card["stats"])
            row.update({f"headline_{key}": value for key, value in card["summary"].items()})
            row["available_in"] = "; ".join(card["available_in"])
            writer.writerow(row)
    by_id = {c["card_id"]: c for c in data["cards"]}
    with (OUT / "pack_pools.csv").open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(["pack", "card_id", "number", "player", "role", "rarity", "finish", "at_least_one_per_opening_percent", "expected_copies_per_opening"])
        for product in data["packs"]:
            for key in product["pool"]:
                c, probability = by_id[key], product["probabilities"][key]
                writer.writerow([product["name"], key, c["collector_number"], c["handle"], c["role"], c["rarity"], c["finish"], f"{probability['at_least_one_percent']:.8f}", f"{probability['expected_copies']:.8f}"])
    with (OUT / "slot_odds.csv").open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(["pack", "slot", "finish_filter", *[r + "_percent" for r in RARITIES]])
        for p in data["packs"]:
            for s in p["slots"]:
                writer.writerow([p["name"], s["number"], s["finish_filter"] or "any eligible", *[s["rarity_weights_bp"][r] / 100 for r in RARITIES]])


def esc(value) -> str:
    return html.escape(str(value), quote=True)


def pack_svg(p: dict) -> str:
    color, secondary, short = p["color"], p["secondary_color"], p["short_name"].upper()
    glyph = {"Alpha": "A", "Bravo": "B", "Elite": "✦", "Beta Event": "β"}[p["short_name"]]
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 840 1200" role="img" aria-label="{esc(p['name'])} wrapper front">
<defs><linearGradient id="foil" x2="1" y2="1"><stop stop-color="#1E2632"/><stop offset=".45" stop-color="#0D131C"/><stop offset=".8" stop-color="#283141"/><stop offset="1" stop-color="#10151D"/></linearGradient></defs>
<path d="M44 20H796L820 1180H20Z" fill="url(#foil)" stroke="{color}" stroke-width="3"/>
<path d="M44 20H796V75H42ZM21 1125H819V1180H20Z" fill="{color}"/>
{''.join(f'<path d="M{x} 26v42M{x} 1132v40" stroke="#0A111A" stroke-opacity=".45" stroke-width="4"/>' for x in range(60,800,22))}
<path d="M65 395L760 710V835L65 520Z" fill="{color}" opacity=".12"/>
<path d="M65 840L765 495M65 920L765 575" stroke="{secondary}" opacity=".2" stroke-width="2"/>
<text x="80" y="173" fill="#F0F0E8" font-family="DejaVu Sans, sans-serif" font-size="76" font-weight="bold">CSTCG</text>
<text x="82" y="222" fill="{color}" font-family="sans-serif" font-size="27" letter-spacing="7">SERIES 1</text>
<rect x="80" y="267" width="680" height="2" fill="{color}" opacity=".45"/>
<text x="420" y="705" fill="{color}" font-family="DejaVu Sans, sans-serif" font-size="430" font-weight="bold" text-anchor="middle">{glyph}</text>
<text x="80" y="868" fill="#F3F1E8" font-family="DejaVu Sans Condensed, sans-serif" font-size="{62 if len(short)>8 else 86}" font-weight="bold">{short}</text>
<text x="82" y="918" fill="{secondary}" font-family="sans-serif" font-size="23" letter-spacing="4">{esc(p['tagline'])}</text>
<path d="M80 960H760" stroke="{color}" stroke-width="2"/>
<text x="82" y="1015" fill="#F3F1E8" font-family="sans-serif" font-size="32" font-weight="bold">{p['cards_per_opening']} PLAYER CARDS</text>
<text x="82" y="1060" fill="{color}" font-family="sans-serif" font-size="24">{esc(p['guarantee'])}</text>
<text x="82" y="1100" fill="#A1AAB5" font-family="sans-serif" font-size="19">50-CARD POOL  /  S1.0</text></svg>'''


def card_svg(c: dict) -> str:
    col = COLORS[c["rarity"]]
    finish = c["finish"]
    accent = "#A28AF5" if finish == "beta_event" else ("#DDB56E" if finish == "showcase" else col)
    monogram = c["handle"][:2].upper()
    motif = ROLES.index(c["role"])
    nodes = ''.join(f'<circle cx="{260+i*105}" cy="{270+((i+motif)%3)*120}" r="12" fill="{accent}" opacity=".38"/>' for i in range(5))
    lines = ''.join(f'<path d="M{195+i*95} 650L{360+i*95} 130" stroke="{accent}" stroke-opacity=".15" stroke-width="2"/>' for i in range(5))
    decor = '<path d="M790 80V660H730" fill="none" stroke="#65E3CC" stroke-width="8"/>' if finish == "beta_event" else ''
    ticks = ''.join(f'<path d="M{52+i*20} 376l10 -10" stroke="{col}" stroke-width="5"/>' for i in range(RARITIES.index(c["rarity"]) + 1))
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 840 1200" role="img" aria-label="{esc(c['handle'])}, {esc(c['edition'])}, {esc(c['rarity'])}">
<rect x="3" y="3" width="834" height="1194" rx="30" fill="#111922" stroke="{accent}" stroke-width="6"/>
<rect x="23" y="23" width="794" height="1154" rx="18" fill="none" stroke="{col}" opacity=".25"/>
<text x="50" y="70" fill="#ECEDE6" font-family="sans-serif" font-size="25" font-weight="bold">CSTCG</text>
<text x="790" y="70" fill="{col}" font-family="sans-serif" font-size="24" text-anchor="end">SERIES 1</text>
<path d="M194 100H790V680H194Z" fill="{accent}" opacity=".07"/>{lines}{nodes}{decor}{ticks}
<circle cx="490" cy="345" r="130" fill="#18222E" stroke="{accent}" stroke-opacity=".35" stroke-width="2"/>
<text x="490" y="373" fill="{accent}" text-anchor="middle" font-family="DejaVu Sans, sans-serif" font-weight="bold" font-size="100" opacity=".7">{esc(monogram)}</text>
<text x="490" y="530" fill="#8E99A5" text-anchor="middle" font-family="sans-serif" font-size="17" letter-spacing="2">PORTRAIT POSITION</text>
<text x="50" y="221" fill="#F3F1E8" font-family="DejaVu Sans Condensed, sans-serif" font-size="118" font-weight="bold">{c['overall']}</text>
<text x="53" y="257" fill="#94A2AD" font-family="sans-serif" font-size="22">OVR</text>
<text x="53" y="305" fill="{col}" font-family="sans-serif" font-size="29" font-weight="bold">{c['role']}</text>
<text x="53" y="349" fill="#DDE2E4" font-family="sans-serif" font-size="25">{c['country']}  ·  T5</text>
<rect x="50" y="410" width="6" height="220" fill="{col}"/>
<text x="77" y="450" fill="{col}" font-family="sans-serif" font-size="21">{esc(c['rarity'].upper())}</text>
<path d="M48 690H792" stroke="{accent}" stroke-width="3"/>
<text x="48" y="781" fill="#F3F1E8" font-family="DejaVu Sans Condensed, sans-serif" font-weight="bold" font-size="{65 if len(c['handle'])>8 else 80}">{esc(c['handle'])}</text>
<text x="51" y="825" fill="#B1BAC5" font-family="sans-serif" font-size="28">{esc(c['name'])}</text>
<rect x="48" y="852" width="744" height="44" rx="4" fill="{accent}" opacity=".1"/>
<text x="62" y="882" fill="{accent}" font-family="sans-serif" font-size="22" letter-spacing="1">{esc(c['edition'])}</text>
{''.join(f'<text x="{x}" y="1000" fill="#F3F1E8" font-family="DejaVu Sans Condensed, sans-serif" font-weight="bold" font-size="78">{c["summary"][key]}</text><text x="{x}" y="1037" fill="{col}" font-family="sans-serif" font-size="26">{label}</text>' for x,key,label in [(53,'aim','AIM'),(300,'iq','IQ'),(547,'util','UTIL')])}
<text x="53" y="1097" fill="#C1CBD2" font-family="sans-serif" font-size="28">{esc(c['tendency'])}</text>
<path d="M48 1121H792" stroke="#34414D"/>
<text x="51" y="1158" fill="#91A0AD" font-family="sans-serif" font-size="22">{c['collector_number']}</text>
<text x="790" y="1158" fill="{col}" text-anchor="end" font-family="sans-serif" font-size="19">{esc(c['collector_title'].upper())}</text></svg>'''


def write_reverse_examples(data: dict) -> None:
    c = next(c for c in data["cards"] if c["card_id"] == "s1.base.niko")
    rows = []
    for i, key in enumerate(ATTRIBUTES):
        x, y = 52 + (i % 2) * 380, 340 + (i // 2) * 116
        rows.append(f'<text x="{x}" y="{y}" fill="#A4B0BD" font-family="sans-serif" font-size="25">{key.upper()}</text><text x="{x+320}" y="{y}" fill="#F3F1E8" font-family="sans-serif" font-size="36" font-weight="bold" text-anchor="end">{c["stats"][key]}</text><rect x="{x}" y="{y+20}" width="320" height="7" fill="#293543"/><rect x="{x}" y="{y+20}" width="{c["stats"][key]*3.2}" height="7" fill="#DDB56E"/>')
    reverse = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 840 1200" role="img" aria-label="NiKo revealed inspection reverse">
<rect x="3" y="3" width="834" height="1194" rx="30" fill="#111922" stroke="#F4E8CE" stroke-width="6"/>
<text x="52" y="78" fill="#F1F0E8" font-family="sans-serif" font-weight="bold" font-size="27">CSTCG / SERIES 1</text>
<text x="52" y="178" fill="#F1F0E8" font-family="DejaVu Sans Condensed, sans-serif" font-weight="bold" font-size="70">NiKo</text>
<text x="52" y="224" fill="#DDB56E" font-family="sans-serif" font-size="27">ENTRY · PEAK · T5 · SERIES 1 ORIGINAL</text>
<path d="M52 260H788" stroke="#394553"/>
<text x="52" y="296" fill="#8D9BAA" font-family="sans-serif" font-size="20" letter-spacing="2">NATURAL PROFILE / EIGHT ATTRIBUTES</text>
{''.join(rows)}
<text x="52" y="824" fill="#DDB56E" font-family="sans-serif" font-size="30" font-weight="bold">FIRST CONTACT</text>
<text x="52" y="870" fill="#CFD8DE" font-family="sans-serif" font-size="25">Takes the leading entry position on a committed</text>
<text x="52" y="908" fill="#CFD8DE" font-family="sans-serif" font-size="25">site attack; teammates retain trade spacing.</text>
<path d="M52 956H788" stroke="#394553"/>
<text x="52" y="1000" fill="#9AA8B4" font-family="sans-serif" font-size="24">AIM 97 / IQ 94 / UTIL 87 · OVR 93</text>
<text x="52" y="1045" fill="#9AA8B4" font-family="sans-serif" font-size="23">Alternate artwork adds zero attribute points.</text>
<text x="52" y="1106" fill="#F4E8CE" font-family="sans-serif" font-size="24">S1-012/090 · FIRST BULLET</text>
<text x="52" y="1155" fill="#8292A2" font-family="sans-serif" font-size="20">Revealed inspection view / acquisition and build stay in UI</text></svg>'''
    (OUT / "vectors/inspection-example.svg").write_text(reverse)
    (OUT / "vectors/sealed-sleeve.svg").write_text('''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 840 1200" role="img" aria-label="Uniform concealed CSTCG Series 1 sleeve">
<rect x="3" y="3" width="834" height="1194" rx="30" fill="#101720" stroke="#687884" stroke-width="6"/>
<rect x="35" y="35" width="770" height="1130" rx="16" fill="none" stroke="#364450" stroke-width="2"/>
<path d="M70 1010L770 190M70 1090L770 270M70 930L770 110" stroke="#243441" stroke-width="3"/>
<circle cx="420" cy="510" r="182" fill="#14202A" stroke="#526676" stroke-width="3"/>
<text x="420" y="535" text-anchor="middle" fill="#E8E9E1" font-family="DejaVu Sans Condensed, sans-serif" font-weight="bold" font-size="81">CSTCG</text>
<text x="420" y="620" text-anchor="middle" fill="#91A1AD" font-family="sans-serif" font-size="31" letter-spacing="7">SERIES 1</text>
<path d="M175 864H665" stroke="#4D6273"/>
<text x="420" y="925" text-anchor="middle" fill="#B6C3CB" font-family="sans-serif" font-size="31">YOUR NEXT POSSIBILITY</text>
<text x="420" y="1100" text-anchor="middle" fill="#7D8E9C" font-family="sans-serif" font-size="20" letter-spacing="3">THE CLUB STARTS WITH THE CARDS</text></svg>''')


def write_gallery(data: dict) -> None:
    (OUT / "vectors/packs").mkdir(parents=True, exist_ok=True)
    (OUT / "vectors/cards").mkdir(parents=True, exist_ok=True)
    for p in data["packs"]:
        (OUT / f"vectors/packs/{p['pack_id']}.svg").write_text(pack_svg(p))
    for c in data["cards"]:
        (OUT / f"vectors/cards/{c['card_id']}.svg").write_text(card_svg(c))
    write_reverse_examples(data)
    payload = json.dumps(data, ensure_ascii=False).replace("</", "<\\/")
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>CSTCG / Series 1 design catalogue</title><style>
:root{color-scheme:dark;--ink:#f0f0e8;--muted:#96a2b2;--line:#2d3845;--accent:#f36c3d}*{box-sizing:border-box}body{margin:0;background:#0b1017;color:var(--ink);font:15px/1.6 system-ui,sans-serif}main{max-width:1480px;margin:auto;padding:34px}h1{font-size:clamp(28px,4vw,55px);line-height:1.1;margin:10px 0 18px}h2{font-size:24px}.kicker{color:#f36c3d;font-size:12px;font-weight:800;letter-spacing:.18em}.muted{color:var(--muted)}.intro{max-width:900px}.packs{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:18px;margin:32px 0}.pack{padding:22px;background:#141c27;border:1px solid var(--line);border-radius:16px;cursor:pointer;text-align:left;color:inherit;font:inherit}.pack:hover,.pack[aria-pressed=true]{border-color:var(--color);box-shadow:0 0 0 1px var(--color)}.pack img{width:100%;height:270px;object-fit:contain}.pack strong{display:block;font-size:22px;margin-top:12px}.pack small{display:block;color:var(--muted)}.toolbar{position:sticky;top:0;z-index:2;display:flex;gap:12px;align-items:center;flex-wrap:wrap;padding:14px 0;background:#0b1017ee;backdrop-filter:blur(12px)}button,input,select{font:inherit}input,select,.all{background:#18222f;border:1px solid var(--line);color:var(--ink);border-radius:7px;padding:10px 12px}input{flex:1;min-width:180px}button{cursor:pointer}.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(205px,1fr));gap:20px;margin-top:22px}.card{background:transparent;border:0;color:inherit;padding:0;text-align:left}.card:hover img{transform:translateY(-5px)}.card:focus-visible{outline:3px solid #f36c3d;border-radius:8px}.card img{display:block;width:100%;transition:transform .18s}.card span{display:block;color:var(--muted);font-size:12px;margin:6px}.detail{display:grid;grid-template-columns:minmax(210px,360px) 1fr;gap:28px}dialog{max-width:1050px;width:92vw;max-height:90vh;border:1px solid #526171;border-radius:16px;background:#111b27;color:var(--ink);padding:28px}dialog::backdrop{background:#02060bc9}dialog img{width:100%}.stats{display:grid;grid-template-columns:1fr 1fr;gap:8px 24px}.stat{display:flex;justify-content:space-between;border-bottom:1px solid var(--line);padding:8px 0}.tag{color:#f36c3d;font-size:12px;letter-spacing:.1em}.close{float:right;background:#223045;border:1px solid #718095;color:white;border-radius:5px;padding:6px 16px}#empty{padding:30px;border:1px solid var(--line)}a{color:#9fd5ff}footer{margin-top:42px;padding-top:24px;border-top:1px solid var(--line)}.rules{display:grid;grid-template-columns:repeat(3,1fr);gap:25px}.rules section{padding:20px;border:1px solid var(--line);border-radius:10px}.pill{padding:3px 8px;border:1px solid var(--line);border-radius:4px;font-size:11px}.legend{padding:14px 0;color:var(--muted);font-size:13px}#pool-note{min-height:50px}.links{display:flex;gap:20px;flex-wrap:wrap} @media(max-width:800px){main{padding:20px}.packs{grid-template-columns:1fr 1fr}.pack img{height:210px}.rules{grid-template-columns:1fr}.detail{grid-template-columns:1fr}.detail>img{max-width:280px;margin:auto}.cards{grid-template-columns:repeat(2,minmax(0,1fr))}.pack{padding:12px}.card span{font-size:10px}}@media(prefers-reduced-motion:reduce){*{transition:none!important;scroll-behavior:auto!important}}@media print{.toolbar,dialog{display:none}.cards{grid-template-columns:repeat(4,1fr)}body{background:white;color:black}.card{break-inside:avoid}.packs{break-after:page}}
</style><main><p class="kicker">CSTCG / COLLECTION DESIGN 1.0</p><h1>One series.<br>Four ways to build your club.</h1><p class="intro muted">60 real player identities. 90 collectible designs. Exactly 50 eligible cards in each pack. Choose a pack to inspect its actual pool, then open a card for all eight attributes and its individual art brief.</p><p class="intro"><span class="pill">DESIGN SPECIFICATION</span> The vectors are precise layout proofs with portrait positions. The accompanying generated art boards establish the portrait and material direction. This catalogue does not change the alpha 0.2 game.</p><div class="packs" id="packs"></div><div class="rules"><section><b>Same player, same profile</b><p class="muted">Base, Elite Showcase and Beta Event editions share all eight natural values. A lineup can field one version of a professional.</p></section><section><b>Readable first, collectible second</b><p class="muted">Large handle, portrait, role and tier; three summary indices on the face. Eight attributes and the complete game tendency on inspection.</p></section><section><b>Rarity is discovery</b><p class="muted">Common, Uncommon, Semi-Rare, Rare, Legendary and Peak. Rarity is separate from tier, finish, and a player’s suitability for your plan.</p></section></div><div class="toolbar"><button class="all" id="all">All 90 designs</button><input id="search" aria-label="Search cards" placeholder="Search a player, title or tendency"><select id="role" aria-label="Role"><option value="">All roles</option></select><select id="rarity" aria-label="Rarity"><option value="">All rarities</option></select><select id="finish" aria-label="Finish"><option value="">All finishes</option><option value="base">Base</option><option value="showcase">Elite Showcase</option><option value="beta_event">Beta Event</option></select><select id="sort" aria-label="Sort cards"><option value="number">Collector number</option><option value="overall">Overall</option><option value="handle">Player name</option></select></div><h2 id="pool-title">All 90 card designs</h2><p class="muted" id="pool-note"></p><p class="legend" id="count" aria-live="polite"></p><div class="cards" id="cards"></div><p id="empty" hidden>No cards match these filters. Clear the filters or choose another pack.</p><footer><p class="links"><a href="DESIGN_SPEC.md">Full design specification</a><a href="CARD_DETAILS.md">All individual card briefs</a><a href="card_checklist.csv">90-card spreadsheet</a><a href="pack_pools.csv">200 pool memberships and per-card odds</a><a href="series1_manifest.json">Structured manifest</a></p><p class="muted">Authored gameplay profiles across several eras; no claim of current rankings, contracts or official team affiliations. Names and numbers remain text layers; portrait and foil are separate art assets.</p></footer></main><dialog id="detail"><button class="close" id="close">Close</button><div id="detail-body"></div></dialog><script>const DATA=__DATA__;
const $=id=>document.getElementById(id);let active='';let lastFocus=null;const text=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
for(const p of DATA.packs){const b=document.createElement('button');b.className='pack';b.style.setProperty('--color',p.color);b.setAttribute('aria-pressed','false');b.dataset.pack=p.pack_id;b.innerHTML=`<img src="vectors/packs/${p.pack_id}.svg" alt="${text(p.name)} wrapper"><strong>${text(p.short_name)}</strong><small>${p.cards_per_opening} cards · 50-card pool</small><small>${text(p.guarantee)}</small>`;b.onclick=()=>{active=p.pack_id;render()};$('packs').append(b)}
for(const r of ['ENTRY','AWPER','IGL','SUPPORT','LURKER'])$('role').add(new Option(r,r));for(const r of DATA.rarities)$('rarity').add(new Option(r,r));
function render(){const p=DATA.packs.find(p=>p.pack_id===active);document.querySelectorAll('.pack').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.pack===active)));$('pool-title').textContent=p?p.name:'All 90 card designs';$('pool-note').textContent=p?`${p.cards_per_opening} cards per opening. ${p.guarantee}. ${p.price_credits_candidate===null?'Earned from the Beta Event track.':p.price_credits_candidate+' earned Credits (balance candidate).'} Peak in at least one slot: ${p.peak_pack_percent.toFixed(4)}%. Draws allow repeats; each rarity samples uniformly among eligible designs.`:'60 base cards + 10 Elite Showcase + 20 Beta Event editions. Alpha and Bravo share 40 cards, with ten unique to each pool.';const q=$('search').value.toLowerCase().trim();let list=DATA.cards.filter(c=>(!p||p.pool.includes(c.card_id))&&(!$('role').value||c.role===$('role').value)&&(!$('rarity').value||c.rarity===$('rarity').value)&&(!$('finish').value||c.finish===$('finish').value)&&(!q||[c.handle,c.name,c.collector_title,c.tendency].join(' ').toLowerCase().includes(q)));list.sort((a,b)=>$('sort').value==='overall'?b.overall-a.overall||a.number-b.number:$('sort').value==='handle'?a.handle.localeCompare(b.handle):a.number-b.number);$('count').textContent=`${list.length} designs shown · ${new Set(list.map(c=>c.player_id)).size} player identities`;$('empty').hidden=list.length!==0;$('cards').replaceChildren();for(const c of list){const b=document.createElement('button');b.className='card';b.setAttribute('aria-label',`${c.handle}, ${c.rarity}, ${c.edition}: inspect card`);b.innerHTML=`<img loading="lazy" src="vectors/cards/${c.card_id}.svg" alt="${text(c.handle)} ${text(c.edition)} layout proof"><span>${text(c.collector_number)} · ${text(c.rarity)}</span>`;b.onclick=()=>inspect(c,b);$('cards').append(b)}}
function inspect(c,button){lastFocus=button;const probabilities=DATA.packs.filter(p=>p.pool.includes(c.card_id)).map(p=>`<li>${text(p.short_name)}: ${p.probabilities[c.card_id].at_least_one_percent.toFixed(5)}% per opening for this exact design</li>`).join('');$('detail-body').innerHTML=`<div class="detail"><img src="vectors/cards/${c.card_id}.svg" alt="${text(c.handle)} front layout"><div><p class="tag">${text(c.collector_number)} / ${text(c.edition)}</p><h2>${text(c.handle)} — ${text(c.collector_title)}</h2><p>${text(c.name)} · ${text(c.country)} · ${text(c.role)} · ${text(c.rarity)} · T5</p><div class="stats">${DATA.attributes.map(k=>`<div class="stat"><span>${k[0].toUpperCase()+k.slice(1)}</span><strong>${c.stats[k]}</strong></div>`).join('')}</div><p><b>${text(c.tendency)}</b><br>${text(c.tendency_rule)}</p><p><b>Portrait direction</b><br>${text(c.pose)}</p><p><b>Individual art brief</b><br>${text(c.art_direction)}</p><p class="muted">Face: AIM ${c.summary.aim} / IQ ${c.summary.iq} / UTIL ${c.summary.util}. OVR is the rounded eight-attribute mean, not a win chance. Alternate artwork adds zero stat points.</p><ul>${probabilities}</ul></div></div>`;$('detail').showModal();$('close').focus()}
function closeDetail(){$('detail').close();lastFocus?.focus()}$('close').onclick=closeDetail;$('detail').addEventListener('cancel',()=>setTimeout(()=>lastFocus?.focus(),0));$('detail').addEventListener('click',e=>{if(e.target===$('detail')){const r=$('detail').getBoundingClientRect();if(e.clientX<r.left||e.clientX>r.right||e.clientY<r.top||e.clientY>r.bottom)closeDetail()}});for(const id of ['search','role','rarity','finish','sort'])$(id).addEventListener('input',render);$('all').onclick=()=>{active='';for(const id of ['search','role','rarity','finish'])$(id).value='';render()};render();
</script></html>'''.replace("__DATA__", payload)
    boards = '''<section aria-label="Visual direction boards" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:18px;margin:30px 0"><figure style="margin:0"><a href="art/pack-family.png"><img src="art/pack-family.png" alt="The orange Alpha, blue Bravo, black-and-gold Elite, and violet Beta Event foil wrappers" style="width:100%;border-radius:10px"></a><figcaption class="muted">The four-pack wrapper family.</figcaption></figure><figure style="margin:0"><a href="art/card-direction.png"><img src="art/card-direction.png" alt="NiKo original, Aleksib original, s1mple Elite Showcase, and ropz Beta Event card treatments" style="width:100%;border-radius:10px"></a><figcaption class="muted">Generated portrait/material references. Accurate live text and profiles are specified below.</figcaption></figure></section>'''
    page = page.replace('<div class="packs" id="packs"></div>', boards + '<div class="packs" id="packs"></div>')
    (OUT / "index.html").write_text(page, encoding="utf-8")


def write_card_briefs(data: dict) -> None:
    lines = ["# CSTCG Series 1 — individual card design register", "", "90 collectible definitions; 60 mechanical player profiles. Each entry has its own global number, exact attributes, pack availability and production art brief. Rarity and role are assigned game-content labels, not official current rankings or contracts.", ""]
    for c in data["cards"]:
        available = ", ".join(p["short_name"] for p in data["packs"] if p["pack_id"] in c["available_in"])
        lines += [f"## {c['collector_number']} · {c['handle']} · {c['collector_title']}", "",
                  f"**{c['edition']} · {c['rarity']} · {c['role']} · T5 · {c['country']}**", "",
                  f"Public identity: {c['name']}. Stable player ID: `{c['player_id']}`. Card definition: `{c['card_id']}`.", "",
                  f"OVR **{c['overall']}**. Face indices: **AIM {c['summary']['aim']} / IQ {c['summary']['iq']} / UTIL {c['summary']['util']}**.", "",
                  " | ".join(f"{k.title()} {c['stats'][k]}" for k in ATTRIBUTES), "",
                  f"**Game tendency — {c['tendency']}:** {c['tendency_rule']}", "",
                  f"**Portrait:** {c['pose']}. Use an identity-accurate approved photograph or commissioned illustration; keep neutral skin tones and an unbranded jersey.", "",
                  f"**Art:** {c['art_direction']}", "",
                  f"**Role motif:** {c['role_motif']}. Rarity rail `{COLORS[c['rarity']]}`; finish `{c['finish']}`.", "",
                  f"**Pools:** {available}. All versions use template `{c['template_id']}`; alternate finishes do not change its attributes or tendency.", ""]
    (OUT / "CARD_DETAILS.md").write_text("\n".join(lines), encoding="utf-8")


def write_analysis(data: dict) -> None:
    lines = ["# Series 1 — pool and odds validation", "", "Generated analytically from `series1_manifest.json`; percentages refer to exact collectible designs unless stated otherwise. Repeated results are allowed.", "",
             "| Product | Pool | Opening | Common | Uncommon | Semi-Rare | Rare | Legendary | Peak | At least one Peak | Expected release |", "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |"]
    for p in data["packs"]:
        counts = " | ".join(str(p["rarity_counts"].get(r, 0)) for r in RARITIES)
        lines.append(f"| {p['short_name']} | 50 | {p['cards_per_opening']} | {counts} | {p['peak_pack_percent']:.6f}% | {p['expected_release_credits']:.4f} CR |")
    lines += ["", "Each pack contains ten eligible designs for each of the five assigned roles. Every definition is reachable under a nonzero slot distribution. Each slot sums to exactly 10,000 basis points. Across four pools there are 200 memberships and 90 unique designs.", "", "## Exact pool overlap", "", "| Pool | Alpha | Bravo | Elite | Beta Event |", "| --- | ---: | ---: | ---: | ---: |"]
    for p in data["packs"]:
        lines.append("| " + p["short_name"] + " | " + " | ".join(str(data["overlap"][p["pack_id"]][q["pack_id"]]) for q in data["packs"]) + " |")
    lines += ["", "Alpha and Bravo have identical slot odds, prices and rarity counts. Their twenty total pool-exclusive definitions contain five Common and five Uncommon cards per product. Neither product is a power tier above the other.", "", "## Reading individual odds", "", "For slot s and exact design c, P(c,s) = rarity_weight(s,c.rarity) / eligible_design_count(s,c.rarity). A finish-filtered guaranteed slot only counts eligible editions in that finish. The chance of at least one copy in the opening is 1 − product_s(1 − P(c,s)). Expected copies is sum_s P(c,s).", "", "Two editions of one player are separate collectible results, so that player's combined identity odds can exceed the odds of a single design. Per-design opening probabilities need not sum to 100%; expected-copy counts sum to the opening size. `pack_pools.csv` lists both values for every one of the 200 memberships.", "", "## Supply and release limits", "", "Release candidates are Common 4, Uncommon 6, Semi-Rare 10, Rare 20, Legendary 75 and Peak 200 Credits. Finish adds no release multiplier. The expected direct release return is below every proposed purchasable pack price; this is a narrow direct-buy/release check, not a full market, promotion or live-economy proof. Beta Event is an earned reward with no ordinary purchase loop. Credit prices, target reward rates and release values remain playtest candidates.", "", "No empty weighted pool, unreachable advertised card, repeated definition inside a product pool, per-product role imbalance, attribute mismatch between finishes, or nonunit slot table was found.", ""]
    (OUT / "POOL_ANALYSIS.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pdf", action="store_true", help="Also build the printable lookbook with ReportLab")
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    data = build_data()
    (OUT / "series1_manifest.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    write_csvs(data)
    write_gallery(data)
    write_card_briefs(data)
    write_analysis(data)
    if args.pdf:
        from series1_lookbook import build_pdf
        build_pdf(data, OUT)
    print("CSTCG_SERIES1: 60 identities, 90 definitions, 4 pools of 50, 200 memberships; valid exact odds and finish parity")


if __name__ == "__main__":
    main()
