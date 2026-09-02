# Arcane Bastion: Siege of the Undead

A fast-paced first-person dark fantasy horde defense game developed with Godot Engine 4. Players step into the role of a fortress battlemage defending an ancient stronghold against endless waves of the undead. Through tactical positioning, spellcraft, dynamic fortress unlocks, and roguelite card upgrades, you must repel the skeletal invasion.

---

## Table of Contents

1. [Overview](#overview)
2. [Core Gameplay Mechanics](#core-gameplay-mechanics)
3. [Controls](#controls)
4. [Architecture and Codebase Structure](#architecture-and-codebase-structure)
5. [Visual and Atmospheric Design](#visual-and-atmospheric-design)
6. [Getting Started](#getting-started)
7. [Steam Release Roadmap](#steam-release-roadmap)
8. [Credits and Licenses](#credits-and-licenses)

---

## Overview

Arcane Bastion merges fast-paced first-person shooter responsiveness with roguelite progression and dynamic arena expansion. Set in a twilight-shrouded fortress surrounded by ancient forests and cliffs, players defend the citadel courtyard and its elevated central tower before unlocking deeper sanctums of the stronghold.

---

## Core Gameplay Mechanics

### 1. Dynamic Fortress Expansion (Zone System)
Rather than confining combat to a static arena, the citadel dynamically expands based on wave progression:
* **Zone 1 (The Courtyard and Central Tower):** The initial defensive position. Enemies assault through the South, East, and West perimeter gates while the player utilizes the central stone tower for vantage and cover.
* **Zone 2 (The Inner Sanctum):** Completing Wave 3 triggers a camera rumble and raises the massive northern portcullis, opening access to a vaulted stone cathedral.
* **The Healing Well:** Located at the heart of Zone 2, this sacred font features a rotating arcane crystal that restores player health once per wave.

### 2. Wave Management and Scaling
* **Dynamic Wave Scaling:** The `WaveManager` controls enemy quotas, spawn intervals, movement speed, and health pools as waves advance.
* **Tactical Spawning:** Spawn points are intelligently gated to ensure monsters only spawn from active fortress entrances, preventing enemies from getting trapped behind closed barriers.
* **HUD Banners:** Wave transitions are announced via animated gothic banners with clear objectives and remaining enemy counts.

### 3. Roguelite Upgrade System
At the conclusion of each wave, the game transitions into a card selection phase presenting three randomized enchantments:
* **Fireball:** Projectiles detonate on impact, dealing area-of-effect damage to clustered foes.
* **Chain Lightning:** Impacts discharge an electric arc chaining to up to three nearby targets.
* **Frost Nova:** Freezes enemies on impact, reducing their movement speed by 50% for four seconds.
* **Multishot:** Adds additional magical bolts in an angled spread per cast.
* **Arcane Haste:** Decreases staff cast cooldown by 28%.
* **Critical Surge:** Grants a 25% chance to land critical strikes dealing 2.5x damage.
* **Arcane Blink:** Enables a rapid directional dash on the Shift key.
* **Titan's Vitality:** Increases maximum health by +30 and instantly heals the player to full.

### 4. Tactical AI Pathfinding
* Skeletons utilize hierarchical waypoint routing to navigate gates, flank the central tower, and climb stairs.
* Floor snapping and custom slope normals prevent agents and players from breaking ground contact while traversing ramps.

---

## Controls

| Action | Input | Description |
| :--- | :--- | :--- |
| Move Forward / Backward | W / S | Standard movement |
| Strafe Left / Right | A / D | Lateral movement |
| Look / Aim | Mouse | Camera orientation |
| Cast Spell | Left Mouse Button | Fires magic bolts from staff tip |
| Jump | Space | Jumps onto platforms or stairs |
| Arcane Blink (Dash) | Left Shift | Instant 6-meter dash (when unlocked) |
| Pause / Menu | Escape | Opens pause and settings interface |

---

## Architecture and Codebase Structure

The project follows a decoupled, node-driven architecture adhering to Godot 4 best practices:

```
FPS/
├── assets/                  # 3D models, textures, animations, and sound
│   ├── castle/              # Modular fortress walls, towers, gates, props
│   ├── fantasy-town/        # Architectural pillars, arches, stairs, foliage
│   ├── pirate-kit/          # Rocks, barrels, crates, foliage
│   └── skeletons/           # Animated 3D skeletal characters and rigs
├── scenes/                  # Compiled Godot scene files (.tscn)
│   ├── main.tscn            # Master world scene combining all components
│   ├── player.tscn          # First-person character controller and staff rig
│   ├── monster.tscn         # Enemy CharacterBody3D with animations and AI
│   ├── spell.tscn           # Magic projectile Area3D with elemental triggers
│   ├── spawner.tscn         # Wave spawner and waypoint container
│   ├── zone_gate.tscn       # Animated portcullis with physics collision
│   ├── healing_well.tscn    # Interactive restorative font with light FX
│   ├── upgrade_menu.tscn    # Roguelite card selection modal UI
│   └── hud.tscn             # CanvasLayer HUD, top bar, and pause menu
├── scripts/                 # GDScript game logic (.gd)
│   ├── player.gd            # Movement, weapon sway, recoil, spells, blink
│   ├── monster.gd           # State machine, pathfinding, health, attacks
│   ├── spell.gd             # Velocity, collision detection, elemental AoE
│   ├── wave_manager.gd      # Wave progression, difficulty scaling, triggers
│   ├── spawner.gd           # Interval management and point selection
│   ├── zone_gate.gd         # Tween-based gate lifting and camera shake
│   ├── healing_well.gd      # Proximity healing logic and wave recharge
│   ├── upgrade_menu.gd      # Deck shuffling, card binding, pause control
│   └── hud.gd               # Score tracking, health bars, banner tweening
├── shaders/                 # Custom GLSL / Godot shaders
│   └── ground.gdshader      # Procedural multi-frequency grass/dirt/stone
├── project.godot            # Godot engine project configuration
└── README.md                # Project documentation
```

---

## Visual and Atmospheric Design

* **Renderer:** Godot 4 Forward+ Vulkan pipeline.
* **Atmospheric Enclosure:** Depth-based distance fog and volumetric fog confine player visibility to the fortress and immediate tree line, eliminating void horizons and creating an authentic dark fantasy mood.
* **Lighting and Shadows:** Directional moonlight with volumetric light scattering combined with point lights at gates, brazier sconces, and arcane staff crystals.
* **Procedural Ground Shader:** Multi-layered procedural blending between damp soil, meadow grass, and cobblestone pathways without repetitive tiling artifacts.

---

## Getting Started

### Prerequisites
* **Engine:** Godot Engine 4.2 or later (standard 64-bit build).
* **Hardware:** GPU supporting Vulkan 1.2+ (Forward+ renderer) or OpenGL 3 (Compatibility renderer).

### Running the Project
1. Clone the repository:
   ```bash
   git clone https://github.com/simongorzi/FPS.git
   cd FPS
   ```
2. Open Godot Engine.
3. Click **Import**, browse to the cloned folder, and select `project.godot`.
4. Press **F5** or click **Run Project** in the upper-right corner.

---

## Steam Release Roadmap

* [x] Core first-person movement and spell combat.
* [x] Animated skeletal horde with modular animation blending.
* [x] Wave progression system with HUD indicators.
* [x] Dynamic fortress expansion (Zone 1 Courtyard to Zone 2 Cathedral).
* [x] Roguelite upgrade deck (8 distinct magical enhancements).
* [x] Volumetric atmospheric fog and perimeter backdrops.
* [ ] Additional enemy archetypes (Armored Skeleton Knight, Skeletal Archer).
* [ ] Wave 5 Miniboss (Skeleton Commander) and Wave 10 Boss (Bone Goliath).
* [ ] Zone 3 Expansion (Outer Bastions with activatable catapult defenses).
* [ ] Sound design (arcane spell cast audio, skeletal bone rattles, ambient wind).
* [ ] Steamworks SDK integration (Achievements, Leaderboards, Cloud Saves).

---

## Credits and Licenses

* **3D Assets and Environments:**
  * Kenney (Castle Kit, Fantasy Town Kit, Pirate Kit) - Creative Commons Zero (CC0).
  * Kay Lousberg (KayKit Skeletons 1.1) - Creative Commons Zero (CC0).
* **Game Development:**
  * Created by Simon Gorzi.
