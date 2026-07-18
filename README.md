# Hero's Butler Simulator

A polished, self-contained Godot 4 first-person vertical slice built entirely from native meshes, materials, lights, scripts, and UI. No external assets or packages are required.

You are the trusted butler to the theatrical superhero Raccoon Man. Explore his rain-darkened mansion and colorful underground headquarters while H.A.R.O.L.D., the manor AI, guides you through a full day of suspiciously ordinary hero support work.

## Play

Open `project.godot` in Godot 4.7 and press **F6/F5**. The complete map is the editor-authored `scenes/mansion_world.tscn`, composed from independent editable scenes under `scenes/world/` and `scenes/stations/`. All bathroom meshes, collisions, labels, and interaction markers are authored scene nodes; gameplay scripts only change their state.

| Input | Action |
| --- | --- |
| WASD | Move |
| Mouse | First-person look |
| E | Context interaction |
| Shift | Sprint |
| Ctrl | Crouch |
| Space | Jump / confirm timing minigame |
| 1–4 | Select toolbelt item |
| T | Minimize / expand today's service panel |
| Tab or B | Daily task board |
| F5 / F9 | Save / load |
| Escape | Pause / settings |

## Vertical slice

The connected floorplan includes the grand foyer, kitchen, hero bathroom, gadget and suit workshop, Roadster garage, and a comedic secure prison cell. Six jobs can be completed in any order:

- Prepare the 20:00 recovery bath: mix exactly 38°C water, stop at the marked level, add salts, warm a towel, and restock the shower soap
- Make Raccoon Man's breakfast
- Repair the Grapnel-9000 (wire-order and calibration minigames)
- Wash, dry, repair, polish, and display the hero suit
- Refuel, balance, wash, and stock the Raccoon Roadster
- Feed and sanitize Doctor Dreadful's cell

Jobs use reusable data-driven step definitions, persistent progression, contextual prompts, objective markers, a live minimap, subtitles, and H.A.R.O.L.D. intercom feedback. Duties do not pay money: completed work changes Raccoon Man's success during his night patrol. At 00:00, a floating newspaper reports how every completed or missed duty affected the city.

## Architecture

- `scripts/main.gd` — session orchestration, clock, save/load, dialogue
- `scripts/task_manager.gd` — shared progression, timed availability, newspaper outcomes, and persistence
- `scripts/tasks/` — one data module per job, including steps, messages, and minigames
- `scenes/mansion_world.tscn` — editable map composition used at runtime
- `scenes/world/` — editable shared shell and lobby scenes
- `scenes/stations/` — one editable map scene per job station
- `scripts/mansion_world.gd` — interaction indexing and persistent bathroom visual-state updates
- `scripts/player_controller.gd` — first-person movement, crouch, sprint, interaction ray
- `scripts/interactable.gd` — reusable contextual world objects
- `scripts/butler_hud.gd` — HUD, task board, pause/settings, minigames
- `scripts/minimap.gd` — live floorplan, player heading, objective markers
- `scripts/world_builder.gd`, `scripts/world/`, and `tools/bake_world.gd` — optional legacy rebake tooling; not used by gameplay

## Parallel task development

Each job owns two files: its task definition and its world station. For example:

| Job | Task logic and dialogue | Editable map scene |
| --- | --- | --- |
| Bath | `scripts/tasks/bath_task.gd` | `scenes/stations/bath_station.tscn` |
| Car | `scripts/tasks/car_task.gd` | `scenes/stations/car_station.tscn` |

Bath and car branches can therefore be developed, tested, and committed without touching the same files. Open the appropriate station scene directly in Godot and edit its nodes normally. Change `task_manager.gd` or `scenes/mansion_world.tscn` only for behavior or composition shared by every job. The rebake tool overwrites station scenes, so use it only when intentionally recreating the native-mesh templates—not during ordinary map editing.
