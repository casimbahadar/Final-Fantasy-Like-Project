#!/usr/bin/env python3
"""Asset inventory tool — useful when swapping placeholder art for real art.

Walks the project, lists every sprite file under `assets/sprites/`, and for each
one reports which `.tres` files reference it. Output is a markdown table you can
paste into a planning doc — or pipe to a file and check off as you replace.

Usage (from project root):

    python3 tools/inventory_assets.py
    python3 tools/inventory_assets.py --missing       # only show sprites with NO references
    python3 tools/inventory_assets.py --orphan-tres   # only tres files with broken sprite refs
"""

import argparse
import pathlib
import re
import sys


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--missing", action="store_true",
                        help="only list sprites that no .tres references — candidates for deletion")
    parser.add_argument("--orphan-tres", action="store_true",
                        help="only list .tres files referencing sprites that don't exist")
    args = parser.parse_args()

    root = pathlib.Path(".").resolve()
    sprite_dir = root / "assets" / "sprites"
    if not sprite_dir.exists():
        print(f"no sprite dir at {sprite_dir}", file=sys.stderr)
        return 1

    sprites = sorted(p for p in sprite_dir.rglob("*") if p.is_file() and p.suffix in {".svg", ".png"})
    sprite_rel = {p: p.relative_to(root) for p in sprites}

    # Walk every .tres and .tscn, collect references to res:// paths under assets/sprites/
    refs_by_sprite: dict[pathlib.Path, list[pathlib.Path]] = {p: [] for p in sprites}
    orphan_refs: list[tuple[pathlib.Path, str]] = []
    # Match both `path="res://..."` strings (in .tres/.tscn) and `preload(...)`
    # arguments in .gd files. Both forms reference assets in the same way.
    sprite_path_re = re.compile(r'res://assets/sprites/[^"\')\s]+')
    for tres in list(root.rglob("*.tres")) + list(root.rglob("*.tscn")) + list(root.rglob("*.gd")):
        if "/.godot/" in str(tres):
            continue
        try:
            text = tres.read_text(errors="ignore")
        except Exception:
            continue
        for match in sprite_path_re.findall(text):
            ref = match.replace("res://", "")
            ref_path = root / ref
            if ref_path in refs_by_sprite:
                refs_by_sprite[ref_path].append(tres.relative_to(root))
            else:
                orphan_refs.append((tres.relative_to(root), match))

    if args.orphan_tres:
        if not orphan_refs:
            print("(no orphan tres references)")
            return 0
        print("# .tres files referencing sprites that don't exist\n")
        for tres, ref in orphan_refs:
            print(f"- `{tres}` → `{ref}`")
        return 0

    if args.missing:
        missing = [(p, refs) for p, refs in refs_by_sprite.items() if not refs]
        if not missing:
            print("(every sprite is referenced by at least one .tres / .tscn)")
            return 0
        print("# Sprites with no .tres / .tscn references\n")
        for p, _ in missing:
            print(f"- `{sprite_rel[p]}`")
        return 0

    # Default: full inventory grouped by category
    cats: dict[str, list[pathlib.Path]] = {}
    for p in sprites:
        rel = str(sprite_rel[p])
        if "player_" in rel: cats.setdefault("Actors / overworld", []).append(p)
        elif "npc_" in rel: cats.setdefault("NPCs", []).append(p)
        elif "enemy_" in rel: cats.setdefault("Enemies (battle)", []).append(p)
        elif "chest_" in rel: cats.setdefault("Props", []).append(p)
        else: cats.setdefault("Misc", []).append(p)

    print("# Sprite inventory\n")
    print(f"Total sprites: **{len(sprites)}**, total .tres+tscn references: **{sum(len(r) for r in refs_by_sprite.values())}**.\n")

    for cat in ("Actors / overworld", "NPCs", "Enemies (battle)", "Props", "Misc"):
        if cat not in cats:
            continue
        print(f"## {cat} ({len(cats[cat])})\n")
        print("| Sprite | Refs | Referenced by |")
        print("|---|---|---|")
        for p in cats[cat]:
            refs = refs_by_sprite[p]
            refs_str = ", ".join(f"`{r}`" for r in refs[:3])
            if len(refs) > 3:
                refs_str += f" *(+{len(refs)-3} more)*"
            print(f"| `{sprite_rel[p]}` | {len(refs)} | {refs_str or '—'} |")
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
