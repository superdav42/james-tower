# James Tower

**Arcane Defense** is a portrait-oriented Godot 4.7 tower-defense game. Summon a random defender, hold the winding path, and stop the horde from reaching the crystal.

## Rules

- You begin with **20 mana**, gain **2 mana every second**, and can hold up to 99.
- The battlefield has exactly **20 tower tiles**, arranged inside a path that winds around each row of tiles.
- Press **Summon** to spend **5 mana** and place a random Electric Mage, Ice Mage, Fire Mage, Archer, or Reaper on the next open tile.
- Every enemy begins with **100 HP** and continuously advances toward the crystal.
- Electric, Ice, and Fire Mages deal **20 damage** per attack.
- The **Electric Mage** chains lightning through as many as two nearby extra enemies.
- The **Ice Mage** slows its target for 2.5 seconds.
- The **Fire Mage** burns its target for damage over time.
- The **Archer** deals **25 damage**, five more than each mage.
- **The Reaper** throws scythes for **20 damage** and has a **5% chance to defeat its target in one strike**.
- Press **Merge Matching** to combine the first two towers with the same type and level. The merged tower gains a level, deals 75% more damage per added level, attacks slightly faster, and frees one tile.
- Each escaped enemy removes one of the crystal's 10 health points. The run ends when crystal health reaches zero.
- Enemy movement and spawn frequency gradually increase during a run.

## Run locally

Requires Godot 4.7.x.

```text
godot --path .
```

Headless smoke check:

```text
godot --headless --path . --quit-after 2
```

## Project layout

- `project.godot`: portrait mobile project settings.
- `scenes/main.tscn`: heads-up display and game scene.
- `scripts/main.gd`: mana, summoning, enemies, combat effects, and drawing.
- `DESIGN.md`: visual direction and interaction rules.
- `docs/mobile-notes.md`: Android/iOS export notes.
