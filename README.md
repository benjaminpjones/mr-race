# Mr Race

A 3D mobile racing game built in Godot 4.6. Currently single-player free-roam with multiple selectable vehicles.

## Setup

Requires **Godot 4.6+** (standard build, not .NET). On macOS the engine lives at `/Applications/Godot.app`.

```sh
open -a Godot              # launches the editor
# Then: Import → /Users/benjamin/git/mr-race/project.godot → Edit
```

Headless re-import (useful from a script):

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --import --path /Users/benjamin/git/mr-race
```

## Running

In the editor, press **F5** to run. The main scene is `scenes/main.tscn`. The window opens in 1280×720 landscape.

## Controls

| Action       | Keyboard       | Touch / On-screen |
| ------------ | -------------- | ----------------- |
| Steer left   | ← / A          | `<` button        |
| Steer right  | → / D          | `>` button        |
| Gas          | ↑ / W          | `GAS` button      |
| Brake        | ↓ / S          | `BRAKE` button    |
| Switch car   | V or **Space** | `SWITCH` button   |
| Respawn      | R              | —                 |

The car also auto-respawns at the origin if its Y position drops below `-15` (configurable on the `Main` node).

## Vehicles

Cycle with SWITCH / V / Space. All four use the same `scripts/car.gd` with different `@export` parameters.

| Vehicle        | Scene                     | Notes                                                            |
| -------------- | ------------------------- | ---------------------------------------------------------------- |
| Car            | `scenes/car.tscn`         | Red box. AWD sports car — high power, grippy tires, sharp steering. |
| Bike           | `scenes/bike.tscn`        | 2 wheels + 2 invisible stabilizers; light, fast steering.        |
| Monster Truck  | `scenes/monster_truck.tscn` | Big wheels, heavy, AWD, lots of torque.                       |
| Grandma Car    | `scenes/grandma_car.tscn` | Yellow lifted box with round dome roof and "할머니" license plate. |

## Track

`scenes/track.tscn` — a 400×400 m flat plane with a striped checker texture, four reference pillars at ±40 m (yellow N/S, blue E/W), and one tilted brown ramp.

The ramp is at world z ≈ -27, 18 m long, sloped 15°. The high end (~4.7 m elevation) faces the spawn; drive past it, U-turn, and ramp up toward spawn to launch.

## Project structure

```
project.godot              Engine config: mobile renderer, landscape, gravity 20.
assets/
  NotoSansKR.ttf           Korean-capable font for the license plate (SIL OFL).
scenes/
  main.tscn                Top-level: Track + active vehicle + ChaseCamera + HUD.
  track.tscn               Ground plane, sun, pillars, ramp.
  car.tscn / bike.tscn /
  monster_truck.tscn /
  grandma_car.tscn         Vehicle scenes — all use car.gd.
  hud.tscn                 CanvasLayer with five Buttons.
scripts/
  main.gd                  Vehicle list, switch + respawn logic, key bindings.
  car.gd                   Per-vehicle physics input → engine/steer/brake.
  chase_camera.gd          Smooth follow camera, behind & above.
  hud.gd                   Forwards button events into Godot's input system.
```

## Common tuning knobs

**Per vehicle** (in each `scenes/<vehicle>.tscn` on the root node):
- `mass`, `engine_power`, `reverse_power`, `brake_force`
- `max_steer` (radians of wheel angle), `steer_speed` (how fast steering reaches target)
- Per-wheel: `wheel_radius`, `wheel_friction_slip`, `suspension_stiffness`, `suspension_max_force`

**Ramp** (`scenes/track.tscn` → `Ramp` node):
- Length: change the `BoxShape3D_ramp` and `BoxMesh_ramp` `size.z`.
- Slope: rebuild the basis with cos/sin of the desired angle. Current is 15°.
- Position: edit the `origin` portion of the ramp's `transform`.

**Camera** (`scenes/main.tscn` → `ChaseCamera`):
- `distance`, `height`, `look_height`, `smoothness`.

**Respawn** (`scenes/main.tscn` → `Main` node):
- `respawn_y_threshold` (default `-15`), `spawn_height` (default `1.5`).
