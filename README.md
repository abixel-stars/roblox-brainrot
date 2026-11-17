# Pasar Malam Brainrot

[![make.fun](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/abixel-stars/roblox-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/abixel-stars/roblox-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A 3D brainrot game for make.fun's **roblox-brainrot-01** bounty, built in Roblox Studio with Rojo. One theme all the way through: an Indonesian night market at dusk, where absurd meme food characters walk the conveyor, get bought, earn money on your base, and get stolen by your neighbours.

## How to play

1. Brainrots walk down the conveyor in the middle of the market. Click one (or buy it from the **Beli** menu) to buy it.
2. The brainrot you bought walks to your base and earns money every second at its rate.
3. Spend the money on the next, more expensive tier. There are 9 rarities, from **Biasa** to **Rahasia**, 18 characters in total.
4. Other players (and the 3 bots) can steal brainrots from your base. Lock your base with **Kunci Base (L)** and slap thieves with **Tampar (F)** to make them drop what they stole.
5. Fuse 3 identical brainrots into 1 mutated one, buy a **Kucing Pasar** to guard your base, spin the **Roda Keberuntungan** every 10 minutes, and rebirth once your lifetime earnings are high enough for a permanent income multiplier.

## The loop

Buy on the conveyor → brainrot walks to your base → money ticks up per second → buy the next tier → protect your base from thieves → rebirth and climb again. Periodic events shake the market up: rare rain, double pay, the lantern parade, and a wave that sends everyone running home.

## Features

- **18 brainrot characters** across 9 rarity tiers, each a distinct 3D model (shape, colour, accessory) with a readable name, rarity and $/second label.
- **Mutations**: Emas (x2), Beku (x4), Api (x3), Pelangi (x5), rolled when a brainrot spawns.
- **Steal, lock and slap**: carry a stolen brainrot home on your head, lock your base for 10+ seconds, slap a thief to drop their catch.
- **Rebirth** with a permanent +50% income multiplier per rebirth.
- **Upgrades**: Sepatu Kilat (walk speed), Dompet Ajaib (income), Kunci Besi (lock time), Slot Ekstra (base slots), Tangan Cepat (slap cooldown).
- **Events every few minutes**: Hujan Langka, Gajian Ganda, Parade Lampion, Gelombang Lari.
- **3 bots** (BudiBot, SitiBot, JokoBot) who buy, carry and steal, so the market feels alive solo.
- **Full 3D world**: night market ground, glowing conveyor, 8 fenced bases with slots, food stalls, lantern posts, welcome arch, moon and clouds, warm dusk lighting.

## Menus (all working)

Main menu, Cara Bermain, Beli (shop), Base, Koleksi (index), Upgrade, Rebirth, Fusion, Event, Leaderboard, Hadiah Harian & Roda, Misi Harian, Pengaturan (volume, shadows, reset camera). Quick buttons for lock (L) and slap (F) sit above the menu bar. The HUD stays clear of the top-left corner, where Roblox puts its own menu buttons.

## Unique features (not in the original Steal a Brainrot)

1. **Fusion**: combine 3 identical brainrots into 1 mutated copy that earns 1.5x more on top of its mutation.
2. **Kucing Pasar (base guard)**: a market cat you buy in the Upgrade menu. It patrols your base and chases thieves out on its own, knocking the stolen brainrot out of them.
3. **Parade Lampion**: a periodic event where a row of rare brainrots walks the conveyor at once and every player scrambles to buy them. Plus the **Roda Keberuntungan**, a free spin every 10 minutes for cash, a random brainrot or a mutation.

## Running the game

The place is built with Rojo 7.7.1:

```
rojo build default.project.json --output game.rbxl
```

Open `game.rbxl` in Roblox Studio and press Play. To run the entry program (what make.fun grades):

```
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Run it twice: the two outputs are byte-identical.

## Screenshots

`PLAY.json` still holds placeholder zeros and `screenshots/` is filled in Studio by the account owner after publishing (see below). Do not submit with placeholder screenshots.

### Screenshot plan (take these in Studio, game running, 1280x720)

1. **1-cover.png** (cover and Roblox thumbnail): wide shot from the spawn arch looking down the conveyor, brainrots walking, lanterns lit, a player buying. This is the first by name, so it leads the entry.
2. **2-play.png**: close shot inside a base, owned brainrots on their slots, money HUD visible top-right, income ticking.
3. **3-steal.png**: a player carrying a stolen brainrot over their head near a base, lock gate up, Kucing Pasar nearby.
4. **4-menus.png** (optional): the shop or upgrade menu open over the 3D market.

## PLAY.json — MUST be filled in before submitting

`PLAY.json` currently names no place (`place_id` and `universe_id` are 0). Before submitting, the account owner must publish this place from Roblox Studio as a Public experience, put the make.fun play code in the experience description, upload an icon and a thumbnail (the thumbnail must be the same picture as one of the screenshots), then write the real play URL, place id and universe id into `PLAY.json`. The gate refuses zeros. See the kit's RULES.txt ("Before you submit") for the exact steps.

## Layout

- `main.ts` — the entry program (Node 22, stdlib only).
- `default.project.json` — the Rojo project.
- `game.rbxl` — the binary place Rojo builds.
- `src/shared/` — `BrainrotData.luau` (cast, tiers, mutations) and `Config.luau` (all tuning).
- `src/server/` — `init.server.luau` (boot), `GameState.luau` (the one state store), `Conveyor.luau` (spawning and walking), `BrainrotFactory.luau` (3D models), `WorldBuilder.luau` (the market), `Bots.luau`, `GameEvents.luau`, `Guards.luau`, `Remotes.luau`.
- `src/client/` — `Game.client.luau` (boot, key bindings), `UiBuilder.luau` (all menus), `ClientFx.luau` (sounds and bursts).
- `vendor/makefun-roblox.ts` — the kit's library, unchanged.
- `.makefun/owner.json` — the payout wallet.

## License

MIT. See `LICENSE`.
