# Arcane Defense design

## Direction

The game uses a compact, readable magical-defense look designed for a 720×1280 portrait viewport. Deep blue-green terrain keeps the battlefield calm while cyan, orange, lime, and teal effects make each defender readable without external art assets.

## Layout

- A fixed top panel shows mana regeneration, crystal health, defeated enemies, and short event feedback.
- The enemy path snakes around four rows containing exactly five tower tiles each, for 20 total positions.
- A fixed bottom panel explains the five roles and keeps the primary **Summon** action within comfortable thumb reach.
- The crystal is the clear destination at the end of the path.

## Unit language

- **E / pale blue:** Electric Mage; chain lightning.
- **I / ice cyan:** Ice Mage; slowing attacks.
- **F / orange:** Fire Mage; burning attacks.
- **A / lime:** Archer; higher direct damage.
- **R / violet:** The Reaper; thrown scythes and a 5% one-strike defeat chance.
- Enemies use a dark circular silhouette, a visible health bar, and ice/fire recoloring while affected.

## Interaction

- Summoning is one tap and immediately communicates the resulting defender in the status line.
- The Summon button disables when the player has less than 5 mana or all positions are occupied.
- **Merge Matching** combines two towers with an identical role and level, strengthens the survivor, and opens the consumed tower's tile.
- A small white level badge distinguishes merged towers.
- Combat is automatic so the player can focus on summon timing and mana.
- Restart is always visible; a centered panel reports the final defeated-enemy count after a loss.
