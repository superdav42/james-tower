extends Node2D

const STARTING_MANA := 20.0
const MANA_PER_SECOND := 2.0
const SUMMON_COST := 5.0
const ENEMY_MAX_HP := 100.0
const ENEMY_SPEED := 72.0
const BASE_HEALTH := 10
const ATTACK_RANGE := 235.0
const ATTACK_INTERVAL := 1.0

const ELECTRIC := "Electric Mage"
const ICE := "Ice Mage"
const FIRE := "Fire Mage"
const ARCHER := "Archer"
const REAPER := "The Reaper"
const DEFENDER_TYPES := [ELECTRIC, ICE, FIRE, ARCHER, REAPER]
const DEFENDER_COLORS := {
	ELECTRIC: Color("7dd3fc"),
	ICE: Color("a5f3fc"),
	FIRE: Color("fb923c"),
	ARCHER: Color("bef264"),
	REAPER: Color("c4b5fd"),
}
const DEFENDER_LETTERS := {
	ELECTRIC: "E",
	ICE: "I",
	FIRE: "F",
	ARCHER: "A",
	REAPER: "R",
}

var path_points := PackedVector2Array([
	Vector2(360, 160), Vector2(90, 160),
	Vector2(90, 375), Vector2(630, 375),
	Vector2(630, 615), Vector2(90, 615),
	Vector2(90, 855), Vector2(630, 855),
	Vector2(630, 1045), Vector2(360, 1075),
])
var summon_slots := PackedVector2Array([
	Vector2(170, 265), Vector2(265, 265), Vector2(360, 265), Vector2(455, 265), Vector2(550, 265),
	Vector2(170, 490), Vector2(265, 490), Vector2(360, 490), Vector2(455, 490), Vector2(550, 490),
	Vector2(170, 735), Vector2(265, 735), Vector2(360, 735), Vector2(455, 735), Vector2(550, 735),
	Vector2(170, 955), Vector2(265, 955), Vector2(360, 955), Vector2(455, 955), Vector2(550, 955),
])

var mana := STARTING_MANA
var base_health := BASE_HEALTH
var kills := 0
var elapsed_time := 0.0
var spawn_countdown := 1.0
var path_length := 0.0
var defenders: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var game_over := false

@onready var mana_label: Label = $Hud/ManaLabel
@onready var base_label: Label = $Hud/BaseLabel
@onready var kills_label: Label = $Hud/KillsLabel
@onready var status_label: Label = $Hud/StatusLabel
@onready var summon_button: Button = $Hud/SummonButton
@onready var merge_button: Button = $Hud/MergeButton
@onready var restart_button: Button = $Hud/RestartButton
@onready var game_over_panel: Panel = $Hud/GameOverPanel
@onready var game_over_label: Label = $Hud/GameOverPanel/GameOverLabel


func _ready() -> void:
	randomize()
	for index in range(path_points.size() - 1):
		path_length += path_points[index].distance_to(path_points[index + 1])
	summon_button.pressed.connect(_summon_defender)
	merge_button.pressed.connect(_merge_matching_towers)
	restart_button.pressed.connect(_restart_game)
	_update_hud()
	queue_redraw()


func _process(delta: float) -> void:
	if game_over:
		return

	elapsed_time += delta
	mana = minf(99.0, mana + MANA_PER_SECOND * delta)
	spawn_countdown -= delta
	if spawn_countdown <= 0.0:
		_spawn_enemy()
		spawn_countdown = maxf(0.65, 1.75 - elapsed_time * 0.008)

	_update_enemies(delta)
	_update_defenders(delta)
	_update_effects(delta)
	_update_hud()
	queue_redraw()


func _summon_defender() -> void:
	if game_over:
		return
	if mana < SUMMON_COST:
		_set_status("You need 5 mana to summon.", Color("fca5a5"))
		return
	var open_tile := _find_open_tile()
	if open_tile < 0:
		_set_status("All defender spaces are full!", Color("fde68a"))
		return

	mana -= SUMMON_COST
	var defender_type: String = DEFENDER_TYPES.pick_random()
	defenders.append({
		"type": defender_type,
		"tile": open_tile,
		"position": summon_slots[open_tile],
		"level": 1,
		"cooldown": randf_range(0.1, 0.55),
	})
	_set_status("Summoned %s!" % defender_type, DEFENDER_COLORS[defender_type])
	_update_hud()
	queue_redraw()


func _find_open_tile() -> int:
	for tile_index in range(summon_slots.size()):
		var occupied := false
		for defender in defenders:
			if defender.tile == tile_index:
				occupied = true
				break
		if not occupied:
			return tile_index
	return -1


func _merge_matching_towers() -> void:
	if game_over:
		return
	for first_index in range(defenders.size()):
		for second_index in range(first_index + 1, defenders.size()):
			var first := defenders[first_index]
			var second := defenders[second_index]
			if first.type == second.type and first.level == second.level:
				first.level += 1
				first.cooldown = 0.1
				defenders.remove_at(second_index)
				_set_status("Merged two %s towers into level %d!" % [first.type, first.level], DEFENDER_COLORS[first.type])
				_update_hud()
				queue_redraw()
				return
	_set_status("You need two matching towers of the same level.", Color("fde68a"))


func _spawn_enemy() -> void:
	var speed_bonus := minf(38.0, elapsed_time * 0.22)
	enemies.append({
		"progress": 0.0,
		"position": path_points[0],
		"hp": ENEMY_MAX_HP,
		"speed": ENEMY_SPEED + speed_bonus,
		"slow_remaining": 0.0,
		"burn_remaining": 0.0,
		"burn_tick": 0.0,
	})


func _update_enemies(delta: float) -> void:
	var escaped: Array[int] = []
	for index in range(enemies.size()):
		var enemy := enemies[index]
		if enemy.slow_remaining > 0.0:
			enemy.slow_remaining = maxf(0.0, enemy.slow_remaining - delta)
		if enemy.burn_remaining > 0.0:
			enemy.burn_remaining = maxf(0.0, enemy.burn_remaining - delta)
			enemy.burn_tick -= delta
			if enemy.burn_tick <= 0.0:
				enemy.hp -= 5.0
				enemy.burn_tick = 0.5
				effects.append({"kind": "burn", "position": enemy.position, "ttl": 0.3})
		var speed_multiplier := 0.48 if enemy.slow_remaining > 0.0 else 1.0
		enemy.progress += enemy.speed * speed_multiplier * delta
		enemy.position = _point_on_path(enemy.progress)
		if enemy.progress >= path_length:
			escaped.append(index)

	for index in range(escaped.size() - 1, -1, -1):
		enemies.remove_at(escaped[index])
		base_health -= 1
		_set_status("An enemy reached the crystal!", Color("fca5a5"))
	if base_health <= 0:
		_end_game()
	_remove_defeated_enemies()


func _update_defenders(delta: float) -> void:
	for defender in defenders:
		defender.cooldown -= delta
		if defender.cooldown > 0.0:
			continue
		var target_index := _find_target(defender.position)
		if target_index < 0:
			continue
		defender.cooldown = ATTACK_INTERVAL / (1.0 + 0.12 * float(defender.level - 1))
		_attack(defender, target_index)
	_remove_defeated_enemies()


func _find_target(origin: Vector2) -> int:
	var result := -1
	var furthest_progress := -1.0
	for index in range(enemies.size()):
		var enemy := enemies[index]
		if enemy.hp > 0.0 and origin.distance_to(enemy.position) <= ATTACK_RANGE and enemy.progress > furthest_progress:
			result = index
			furthest_progress = enemy.progress
	return result


func _attack(defender: Dictionary, target_index: int) -> void:
	if target_index >= enemies.size():
		return
	var defender_type: String = defender.type
	var base_damage := 25.0 if defender_type == ARCHER else 20.0
	var damage: float = base_damage * (1.0 + 0.75 * float(defender.level - 1))
	var target := enemies[target_index]
	if defender_type == REAPER and randf() < 0.05:
		target.hp = 0.0
		_set_status("The Reaper harvested a soul in one strike!", DEFENDER_COLORS[REAPER])
	else:
		target.hp -= damage
	effects.append({
		"kind": defender_type,
		"from": defender.position,
		"to": target.position,
		"ttl": 0.18,
	})

	if defender_type == ELECTRIC:
		_chain_lightning(target_index)
	elif defender_type == ICE:
		target.slow_remaining = 2.5
	elif defender_type == FIRE:
		target.burn_remaining = 3.0
		target.burn_tick = 0.5


func _chain_lightning(first_index: int) -> void:
	var previous_index := first_index
	var hit_indices: Array[int] = [first_index]
	for _jump in range(2):
		var next_index := -1
		var nearest_distance := 145.0
		for index in range(enemies.size()):
			if index in hit_indices or enemies[index].hp <= 0.0:
				continue
			var distance: float = enemies[previous_index].position.distance_to(enemies[index].position)
			if distance < nearest_distance:
				nearest_distance = distance
				next_index = index
		if next_index < 0:
			break
		enemies[next_index].hp -= 20.0
		effects.append({
			"kind": ELECTRIC,
			"from": enemies[previous_index].position,
			"to": enemies[next_index].position,
			"ttl": 0.18,
		})
		hit_indices.append(next_index)
		previous_index = next_index


func _remove_defeated_enemies() -> void:
	for index in range(enemies.size() - 1, -1, -1):
		if enemies[index].hp <= 0.0:
			effects.append({"kind": "defeat", "position": enemies[index].position, "ttl": 0.35})
			enemies.remove_at(index)
			kills += 1


func _update_effects(delta: float) -> void:
	for index in range(effects.size() - 1, -1, -1):
		effects[index].ttl -= delta
		if effects[index].ttl <= 0.0:
			effects.remove_at(index)


func _point_on_path(progress: float) -> Vector2:
	var remaining := clampf(progress, 0.0, path_length)
	for index in range(path_points.size() - 1):
		var start := path_points[index]
		var finish := path_points[index + 1]
		var segment_length := start.distance_to(finish)
		if remaining <= segment_length:
			return start.lerp(finish, remaining / segment_length)
		remaining -= segment_length
	return path_points[-1]


func _restart_game() -> void:
	mana = STARTING_MANA
	base_health = BASE_HEALTH
	kills = 0
	elapsed_time = 0.0
	spawn_countdown = 1.0
	defenders.clear()
	enemies.clear()
	effects.clear()
	game_over = false
	game_over_panel.visible = false
	summon_button.visible = true
	merge_button.visible = true
	status_label.text = "Summon defenders before the horde arrives!"
	status_label.modulate = Color.WHITE
	_update_hud()
	queue_redraw()


func _end_game() -> void:
	game_over = true
	base_health = 0
	summon_button.visible = false
	merge_button.visible = false
	game_over_panel.visible = true
	game_over_label.text = "THE CRYSTAL FELL\n\nYou defeated %d enemies" % kills
	_update_hud()


func _set_status(message: String, color: Color) -> void:
	status_label.text = message
	status_label.modulate = color


func _update_hud() -> void:
	mana_label.text = "MANA  %d / 99   +2/sec" % floori(mana)
	base_label.text = "CRYSTAL  %d / %d" % [base_health, BASE_HEALTH]
	kills_label.text = "DEFEATED  %d" % kills
	summon_button.text = "SUMMON  •  5 MANA"
	summon_button.disabled = mana < SUMMON_COST or _find_open_tile() < 0
	merge_button.disabled = defenders.size() < 2


func _draw() -> void:
	_draw_background()
	_draw_path()
	_draw_tower_tiles()
	_draw_crystal()
	for defender in defenders:
		_draw_defender(defender)
	for enemy in enemies:
		_draw_enemy(enemy)
	for effect in effects:
		_draw_effect(effect)


func _draw_background() -> void:
	draw_rect(Rect2(0, 0, 720, 1280), Color("07151f"), true)
	for row in range(7):
		for column in range(5):
			var center := Vector2(72 + column * 145 + (row % 2) * 28, 220 + row * 135)
			draw_circle(center, 2.0, Color(0.28, 0.55, 0.52, 0.2))
	draw_rect(Rect2(0, 150, 720, 930), Color("0b2530"), true)


func _draw_path() -> void:
	draw_polyline(path_points, Color(0.0, 0.0, 0.0, 0.35), 76.0, true)
	draw_polyline(path_points, Color("244653"), 62.0, true)
	draw_polyline(path_points, Color("315b65"), 3.0, true)
	for point in path_points:
		draw_circle(point, 31.0, Color("244653"))


func _draw_tower_tiles() -> void:
	var occupied_tiles: Array[int] = []
	for defender in defenders:
		occupied_tiles.append(defender.tile)
	for tile_index in range(summon_slots.size()):
		var position := summon_slots[tile_index]
		var fill := Color(0.04, 0.15, 0.19, 0.72) if tile_index not in occupied_tiles else Color(0.06, 0.22, 0.25, 0.7)
		draw_rect(Rect2(position - Vector2(38, 38), Vector2(76, 76)), fill, true)
		draw_rect(Rect2(position - Vector2(38, 38), Vector2(76, 76)), Color(0.24, 0.55, 0.57, 0.7), false, 2.0)


func _draw_crystal() -> void:
	var center: Vector2 = path_points[-1]
	draw_circle(center, 46.0, Color(0.15, 0.9, 0.83, 0.12))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -36), center + Vector2(25, -5),
		center + Vector2(16, 31), center + Vector2(-16, 31),
		center + Vector2(-25, -5),
	]), Color("5eead4"))
	draw_polyline(PackedVector2Array([center + Vector2(0, -36), center + Vector2(25, -5), center + Vector2(16, 31)]), Color("ccfbf1"), 3.0)


func _draw_defender(defender: Dictionary) -> void:
	var position: Vector2 = defender.position
	var defender_type: String = defender.type
	var color: Color = DEFENDER_COLORS[defender_type]
	draw_circle(position + Vector2(0, 7), 31.0, Color(0.0, 0.0, 0.0, 0.35))
	draw_circle(position, 30.0, Color("102e3b"))
	draw_circle(position, 28.0, color.darkened(0.35))
	draw_circle(position, 25.0, color, false, 3.0)
	draw_string(ThemeDB.fallback_font, position + Vector2(-18, 11), DEFENDER_LETTERS[defender_type], HORIZONTAL_ALIGNMENT_CENTER, 36.0, 30, Color.WHITE)
	if defender.level > 1:
		var badge_position := position + Vector2(27, -27)
		draw_circle(badge_position, 13.0, Color("f8fafc"))
		draw_string(ThemeDB.fallback_font, badge_position + Vector2(-10, 6), str(defender.level), HORIZONTAL_ALIGNMENT_CENTER, 20.0, 16, Color("172033"))


func _draw_enemy(enemy: Dictionary) -> void:
	var position: Vector2 = enemy.position
	var body_color := Color("93a4aa")
	if enemy.slow_remaining > 0.0:
		body_color = Color("67e8f9")
	elif enemy.burn_remaining > 0.0:
		body_color = Color("fb923c")
	draw_circle(position + Vector2(0, 5), 22.0, Color(0.0, 0.0, 0.0, 0.4))
	draw_circle(position, 21.0, Color("13252b"))
	draw_circle(position, 17.0, body_color)
	draw_line(position + Vector2(-7, -4), position + Vector2(-2, 0), Color("07151f"), 3.0)
	draw_line(position + Vector2(7, -4), position + Vector2(2, 0), Color("07151f"), 3.0)
	var hp_ratio: float = clampf(enemy.hp / ENEMY_MAX_HP, 0.0, 1.0)
	draw_rect(Rect2(position + Vector2(-25, -32), Vector2(50, 6)), Color("3f1d25"), true)
	draw_rect(Rect2(position + Vector2(-25, -32), Vector2(50 * hp_ratio, 6)), Color("fb7185"), true)


func _draw_effect(effect: Dictionary) -> void:
	var kind: String = effect.kind
	if kind == "defeat":
		draw_circle(effect.position, 36.0 * effect.ttl / 0.35, Color(0.98, 0.72, 0.35, 0.6), false, 5.0)
	elif kind == "burn":
		draw_circle(effect.position, 25.0, Color(1.0, 0.35, 0.08, 0.55), false, 5.0)
	elif kind == ELECTRIC:
		draw_line(effect.from, effect.to, Color("e0f2fe"), 7.0)
		draw_line(effect.from, effect.to, DEFENDER_COLORS[ELECTRIC], 3.0)
	elif kind == ICE:
		draw_line(effect.from, effect.to, DEFENDER_COLORS[ICE], 5.0)
	elif kind == FIRE:
		draw_line(effect.from, effect.to, DEFENDER_COLORS[FIRE], 6.0)
	elif kind == REAPER:
		var midpoint: Vector2 = effect.from.lerp(effect.to, 0.65)
		draw_line(effect.from, effect.to, DEFENDER_COLORS[REAPER], 3.0)
		draw_arc(midpoint, 13.0, -1.4, 1.4, 12, Color("f5f3ff"), 4.0)
	else:
		draw_line(effect.from, effect.to, DEFENDER_COLORS[ARCHER], 3.0)


func get_game_state() -> Dictionary:
	return {
		"mana": mana,
		"base_health": base_health,
		"kills": kills,
		"defender_count": defenders.size(),
		"enemy_count": enemies.size(),
		"game_over": game_over,
	}
