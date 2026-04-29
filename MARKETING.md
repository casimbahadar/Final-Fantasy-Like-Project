# Marketing groundwork

A draft of the public-facing materials you'll need for itch.io / Steam / mobile launches. None of this needs to ship today — it's here so when you're ready, you copy-paste from one place instead of writing it under launch-week pressure.

---

## Working pitch (one paragraph)

**Last Light of Auren** is a Final Fantasy-style JRPG of the long, slow end of a kingdom. 12 chapters, ATB battles, 23 jobs, 12 recruitable companions, four parallel postgame regions, and a true ending hidden behind the very first king. Built solo in Godot 4 for itch.io, Steam, and mobile from a single codebase.

## Working tagline (≤ 10 words)

*The kingdom you save is the one you remember.*

(Alternates: *Twelve chapters. Twelve heroes. One sunrise.* / *A JRPG of the long, slow end of a kingdom.*)

## Genre tags (Steam-ready)

JRPG · Turn-based · ATB · Pixel Art · Fantasy · Story-Rich · Class-Based · 1990s-Inspired · Singleplayer · Choices Matter

---

## Steam page draft

**Short description (≤ 300 chars):**
> A long, slow JRPG of the end of a kingdom. ATB battles, 23 classes, 12 recruitable heroes, parallel postgame regions, and a true ending hidden behind the very first king. The kingdom is dying. The Plague has roots. Walk all the way down them.

**Full description outline:**
1. **Hook (1 paragraph)** — set the tone of the world: the kingdom is dying, the crystals are silent, two travelers walk into the last whole town.
2. **What you do (3 bullets)** — explore, ATB-battle, recruit + customize.
3. **What's special (3 bullets)** — 23 jobs with subclassing, 12 recruitable companions across 12 chapters, postgame regions with three superbosses each AND a true ending that recontextualizes the whole kingdom.
4. **Scope (1 line)** — 40+ hours of main content, 55+ in completionist run with NG+.
5. **Quote-worthy promise** — pick one ("If you finished FF6, you finished what we started" / "The Plague has roots. We walked all the way down them.")

**Screenshots needed (8):**
1. Title screen.
2. Plaza overworld with NPCs visible.
3. ATB battle — full party (5+) vs a multi-enemy troop.
4. Boss intro — Crystal Wraith or Sovereign Eternal mid-dialogue.
5. Skill menu with 8+ skills visible (showcase variety).
6. World map / chapter map (if added — currently README-only).
7. Postgame Far Shore town.
8. True ending screen.

**Trailer (60–90 sec) — shot list:**
- 0:00–0:05 — black, "The kingdom of Auren has stood for two centuries." (white-on-black, fade to first scene).
- 0:05–0:15 — Plaza intro, Aldric and Lyra walking through. Brief NPC dialogue snippet.
- 0:15–0:25 — first random battle. Show ATB gauges filling, skill menu, damage popups.
- 0:25–0:35 — montage: 4 different region tilesets, one per chapter (forest / temple / mountain / sea). Caption: "Twelve chapters."
- 0:35–0:45 — boss intro flashes (3 of them, no dialogue), each with the boss name floating in. Caption: "Twelve bosses. Twelve more after."
- 0:45–0:55 — class menu: scroll through 23 classes. Caption: "Twenty-three jobs. Subclass any of them."
- 0:55–1:05 — postgame snippets: Glass Tower, Boss Rush, Far Shore, Riftgate. Caption: "Four parallel endgames."
- 1:05–1:15 — ending shot or true-ending hint. Caption: "Last Light of Auren. Coming [year]."
- 1:15–1:20 — wishlist Steam button + itch link.

---

## itch.io page draft

itch.io has more permissive style. Lean weirder, more text-forward.

**Title:** Last Light of Auren

**Subtitle:** A long, slow JRPG of the end of a kingdom.

**Body:** (3–5 paragraphs of in-character prose. Don't talk about features. Talk about *Auren*. Show, don't tell. The actual game's writing leans poetic — your store page should match.)

**Tags:** rpg · jrpg · turn-based · pixel-art · fantasy · story-rich · class-based

**Pricing:**
- Free with optional name-your-price tip (recommended for first launch — builds wishlist for Steam).
- Or $4.99 paid (low cap, generous bundles).

**Demo build:** the first chapter through the Crystal Wraith. ~45 minutes of gameplay. Set as a separate "Demo" file on the same page.

---

## Steam launch checklist

Pre-launch (3–6 months out):
- [ ] $100 Steam Direct fee paid.
- [ ] Steam page approved and visible (this can take 1–2 weeks of review back-and-forth).
- [ ] At least 8 screenshots + trailer + description on the page.
- [ ] Game added to **Steam Next Fest** for the demo period.
- [ ] Wishlist target: 7,000+ before launch (rule of thumb for indie JRPGs to have a sustainable launch week).

Launch week:
- [ ] 10–20% launch discount.
- [ ] Day-1 patch ready in case players find issues.
- [ ] Discord server with at least 1 mod available for the first weekend.
- [ ] Reddit + Twitter announcement posts ready.
- [ ] r/JRPG, r/IndieDev, r/IndieGaming threads ready (don't spam — pick 3 subreddits and post real, non-promotional posts a week before launch, then a launch day post that follows the rules of each sub).

Post-launch:
- [ ] Read all reviews in the first week. Reply to negative ones constructively.
- [ ] Patch within 2 weeks if there are repeat bug reports.
- [ ] Plan one content update at +30 days to bump up the "recent activity" curve on Steam.

---

## Mobile launch notes

The technical export from Godot to Android/iOS is straightforward (already documented in `README.md`). The market reality:

- **Premium pricing on mobile is dead** for unknown indie JRPGs. $4.99–$9.99 paid with no IAP gets ~50–500 downloads from organic traffic. Not a meaningful business.
- **Free with cosmetic IAP** — possible but the game wasn't designed with consumable economies in mind. Retrofitting "buy gold" feels gross and won't review well.
- **Realistic mobile path: free port of a Steam/itch success.** Wait until Steam launch generates word of mouth, then port to Android/iOS as a $4.99 "complete edition" for fans who want to play on commute.

If you do mobile day-one anyway:
- Test on a mid-range device (something like a Galaxy A52 or older iPhone). The game is 480×270 internally so performance should be fine.
- Read the touch controls thoroughly — small UI elements that work fine on desktop are unhittable on phones. The MENU button corner and ATB skill rows are the typical pain points.
- Apple's review process can take 1–2 weeks, especially for a first submission. Plan for it.

---

## Press / streamer outreach (when launch is real)

Send 50–80 personalized emails (one each, no template). Subject line: *"Last Light of Auren — solo-dev JRPG, would love your eyes on it"*. Body: short (3–5 sentences), one screenshot, one Steam link, one Discord invite, one game-key offer. Track responses in a spreadsheet.

Outlets that cover indie JRPGs in 2026:
- **RPG Site** (rpgsite.net) — coverage of every meaningful indie JRPG release.
- **Siliconera** — broader, but covers JRPGs heavily.
- **Hardcore Gamer** — has indie JRPG coverage.
- **JayIsGames** — itch-leaning, friendly to small releases.
- **Streamers** — search Twitch for "JRPG" tag, find streamers with 50–500 viewers (large enough to matter, small enough to actually read your email). Don't email the top 1%.

---

## What not to do

- **Don't** announce a release date until you have the build cert-signed, tested on three OS configurations, and 80% of the wishlist target. Slipping a public date kills wishlists.
- **Don't** run a Kickstarter unless you have a real composer/artist already attached. KS for an unfunded solo dev with placeholder art is a bad signal.
- **Don't** spend money on paid ads before launch. Ad ROI for indie games is bad — that money is better on assets.
- **Don't** call the game "Final Fantasy-inspired" anywhere user-facing on Steam. You can in interviews and blog posts; on the actual store page, lean on your own world (Auren) so Square Enix's lawyers don't write to you.

---

## Realistic forecast

Solo-dev JRPG with placeholder→consistent free pixel art + free music + decent presentation, on Steam, in 2026:
- **Bad case** (poor tags, no wishlist, weak trailer): 200–500 copies first month, $1–4K gross.
- **Median case**: 1500–4000 copies first month, $10–25K gross.
- **Good case** (one streamer picks it up, one positive review): 8K–20K copies first month, $50–150K gross.

itch.io as the primary platform with Steam later: **~10% of the above numbers**. itch is a great proving ground but not a paying market.

The hidden value of the project is **the codebase as a portfolio piece** if you're job-hunting in games. A solo-built 40+h JRPG in Godot with this much customization is worth the price of a real CV.
