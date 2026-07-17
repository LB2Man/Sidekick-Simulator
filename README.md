# Hero's Butler Simulator

A polished, self-contained Godot 4 first-person vertical slice built entirely from native meshes, materials, lights, scripts, and UI. No external assets or packages are required.

You are the trusted butler to the theatrical superhero Raccoon Man. Explore his rain-darkened mansion and colorful underground headquarters while H.A.R.O.L.D., the manor AI, guides you through a morning of suspiciously ordinary hero support work.

## Play

Open `project.godot` in Godot 4.7 and press **F6/F5**. The complete map is available as normal editable nodes in `scenes/mansion_world.tscn`; it is instanced into `main.tscn` with editable children enabled.

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

- Draw the perfect bath
- Make Raccoon Man's breakfast
- Repair the Grapnel-9000 (wire-order and calibration minigames)
- Wash, dry, repair, polish, and display the hero suit
- Refuel, balance, wash, and stock the Raccoon Roadster
- Feed and sanitize Doctor Dreadful's cell

Jobs use reusable data-driven step definitions, persistent progression, deadlines with late-state rewards, contextual prompts, objective markers, a live minimap, subtitles, and H.A.R.O.L.D. intercom feedback.

## Architecture

- `scripts/main.gd` — session orchestration, clock, save/load, dialogue
- `scripts/task_manager.gd` — data-driven jobs, steps, rewards, deadlines
- `scenes/mansion_world.tscn` — baked, editor-editable rooms, lights, props, and stations
- `scripts/world_builder.gd` — source builder retained for intentional world rebakes
- `scripts/player_controller.gd` — first-person movement, crouch, sprint, interaction ray
- `scripts/interactable.gd` — reusable contextual world objects
- `scripts/butler_hud.gd` — HUD, task board, pause/settings, minigames
- `scripts/minimap.gd` — live floorplan, player heading, objective markers
- `tools/bake_world.gd` — regenerates the editable world scene when explicitly run
