#!/usr/bin/env python3
"""Fetch public portrait sources for manual identity/jersey review.

Network access to HLTV must be enabled through environment configuration.
Raw images deliberately stay outside the game project and never auto-install.
No login, challenge solving, mirror proxy, or network-policy bypass is used.
"""
import argparse
from datetime import datetime, timezone
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import time
from urllib.parse import urljoin, urlparse
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
SOURCES = Path(__file__).with_name("hltv_players.json")


class Profile(HTMLParser):
    def __init__(self):
        super().__init__()
        self.nickname = ""
        self.image = None
        self.read_nickname = False

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "playerNickname" in attrs.get("class", "").split():
            self.read_nickname = True
        if tag == "img" and "bodyshot-img" in attrs.get("class", "").split():
            self.image = attrs.get("src")

    def handle_data(self, value):
        if self.read_nickname:
            self.nickname += value.strip()

    def handle_endtag(self, tag):
        if tag in ("h1", "div", "span"):
            self.read_nickname = False


def fetch(url, maximum):
    parsed = urlparse(url)
    if parsed.scheme != "https" or parsed.hostname not in ("hltv.org", "www.hltv.org", "img-cdn.hltv.org"):
        raise ValueError("Unapproved portrait source host")
    request = Request(url, headers={"User-Agent": "CSTCG-alpha-portrait-preparation/0.5"})
    with urlopen(request, timeout=25) as response:
        final = urlparse(response.geturl())
        if final.scheme != "https" or final.hostname not in ("hltv.org", "www.hltv.org", "img-cdn.hltv.org"):
            raise ValueError("Portrait source redirected to an unapproved host")
        data = response.read(maximum + 1)
        if len(data) > maximum:
            raise ValueError("Portrait source exceeded the download limit")
        return data


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--players", nargs="*", help="Canonical game IDs; default is the whole alpha roster")
    parser.add_argument("--output", type=Path, default=ROOT.parent / "portrait-sources/hltv")
    parser.add_argument("--list", action="store_true", help="List candidate profile URLs without network access")
    args = parser.parse_args()
    sources = json.loads(SOURCES.read_text())
    players = args.players or list(sources)
    if any(player not in sources for player in players):
        raise ValueError("Unknown player ID")
    output = args.output.resolve()
    if output == ROOT or ROOT in output.parents:
        raise ValueError("Keep raw, unedited jersey photos outside the game project")
    records = {}
    for player in players:
        profile = sources[player]
        url = f"https://www.hltv.org/player/{profile['id']}/{player}"
        if args.list:
            print(player, url, "(candidate; verified against nickname when fetched)")
            continue
        page = Profile()
        page.feed(fetch(url, 2 * 1024 * 1024).decode("utf-8", errors="replace"))
        if page.nickname.casefold() != profile["handle"].casefold() or not page.image:
            raise ValueError(f"{player}: profile identity or bodyshot could not be verified; manual source review required")
        image_url = urljoin(url, page.image)
        if not re.search(r"/(playerbodyshot|playerprofilepicture)/", urlparse(image_url).path):
            raise ValueError(f"{player}: expected a player portrait, not a team or site image")
        data = fetch(image_url, 8 * 1024 * 1024)
        if data.startswith(b"\x89PNG\r\n\x1a\n"):
            suffix = ".png"
        elif data.startswith(b"\xff\xd8"):
            suffix = ".jpg"
        elif data.startswith(b"RIFF") and data[8:12] == b"WEBP":
            suffix = ".webp"
        else:
            raise ValueError(f"{player}: response is not a supported portrait image")
        output.mkdir(parents=True, exist_ok=True)
        path = output / (player + suffix)
        path.write_bytes(data)
        records[player] = {"hltv_id": profile["id"], "handle": profile["handle"],
                           "profile_url": url, "image_url": image_url,
                           "raw_file": path.name, "sha256": hashlib.sha256(data).hexdigest(),
                           "fetched_at_utc": datetime.now(timezone.utc).isoformat(),
                           "review_status": "raw; identity/jersey edit review required"}
        manifest = output / "sources.json"
        existing = json.loads(manifest.read_text()) if manifest.exists() else {}
        existing.update(records)
        manifest.write_text(json.dumps(existing, indent=2, ensure_ascii=False) + "\n")
        print("Downloaded for review:", player)
        time.sleep(0.5)


if __name__ == "__main__":
    main()
