class_name DefenseTurret
extends Node3D

@export var build_cost: int = 6
@export var upgrade_cost: int = 10
@export var attack_range: float = 22.0
@export var attack_damage: int = 55
@export var fire_interval: float = 1.3

enum State { UNBUILT, LEVEL_1, LEVEL_2 }
var state: State = State.UNBUILT

@onready var prompt_area: Area3D = $PromptArea
@onready var pedestal_mesh: Node3D = $PedestalMesh
@onready var turret_head: Node3D = $TurretHead
@onready var crystal: Node3D = $TurretHead/Crystal
@onready var crystal_light: OmniLight3D = $TurretHead/CrystalLight
@onready var build_particles: GPUParticles3D = $BuildParticles
@onready var fire_particles: GPUParticles3D = $TurretHead/MuzzleParticles
@onready var rune_marker: Node3D = $RuneMarker
@onready var status_label: Label3D = $StatusLabel

var _player_in_range: bool = false
var _player: Node3D = null
var _attack_timer: float = 0.0
var _current_target: Node3D = null
var _float_timer: float = 0.0

func _ready() -> void:
	prompt_area.body_entered.connect(_on_body_entered)
	prompt_area.body_exited.connect(_on_body_exited)
	
	turret_head.visible = false
	status_label.text = "[E] Build Turret\nCost: %d 💎 Essences" % build_cost
	status_label.modulate = Color(0.3, 0.9, 1.0)

func _process(delta: float) -> void:
	_float_timer += delta * 3.0
	
	if state == State.UNBUILT:
		# Pomalé vznášení a rotace neaktivní runy
		if rune_marker:
			rune_marker.rotate_y(1.5 * delta)
			rune_marker.position.y = 1.2 + sin(_float_timer) * 0.1
			
		# Kontrola stisku klávesy E pro stavbu
		if _player_in_range and (Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E)):
			_try_build()
			
	else:
		# Věž je postavena – rotace magického krystalu
		if crystal:
			crystal.rotate_y(3.5 * delta)
			crystal.position.y = 2.8 + sin(_float_timer * 1.5) * 0.15
			
		# Upgrade na úroveň 2
		if state == State.LEVEL_1 and _player_in_range and (Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E)):
			_try_upgrade()

		# Automatické vyhledávání cílů a střelba
		_handle_combat(delta)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player_in_range = true
		_player = body as Node3D
		_update_prompt()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player_in_range = false
		_update_prompt()

func _update_prompt() -> void:
	if not _player_in_range:
		if state == State.UNBUILT:
			status_label.text = "🏛️ Defense Turret\nCost: %d 💎" % build_cost
			status_label.modulate = Color(0.4, 0.8, 1.0, 0.8)
		elif state == State.LEVEL_1:
			status_label.text = "⚡ Arcane Turret Lv.1\n[E] Upgrade (%d 💎)" % upgrade_cost
			status_label.modulate = Color(0.9, 0.7, 0.2, 0.8)
		else:
			status_label.text = "👑 Arcane Turret Lv.2 MAX"
			status_label.modulate = Color(1.0, 0.8, 0.2, 0.8)
		return

	var hud = get_tree().get_first_node_in_group("hud")
	var essences = hud.soul_essences if (hud and "soul_essences" in hud) else 0

	if state == State.UNBUILT:
		if essences >= build_cost:
			status_label.text = "★ PRESS [E] TO BUILD TURRET! ★\n(Cost: %d 💎, Have: %d 💎)" % [build_cost, essences]
			status_label.modulate = Color(0.3, 1.0, 0.4)
		else:
			status_label.text = "Need %d 💎 Essences!\n(You have: %d 💎)" % [build_cost, essences]
			status_label.modulate = Color(1.0, 0.4, 0.3)
	elif state == State.LEVEL_1:
		if essences >= upgrade_cost:
			status_label.text = "★ PRESS [E] TO UPGRADE TO LV.2! ★\n(Cost: %d 💎 - Rapid Fire)" % upgrade_cost
			status_label.modulate = Color(1.0, 0.85, 0.2)
		else:
			status_label.text = "Upgrade to Lv.2 costs %d 💎!\n(You have: %d 💎)" % [upgrade_cost, essences]
			status_label.modulate = Color(0.9, 0.5, 0.3)

func _try_build() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud or not hud.has_method("spend_essence"):
		return
		
	if not hud.spend_essence(build_cost):
		_update_prompt()
		return

	# Úspěšná stavba
	state = State.LEVEL_1
	rune_marker.visible = false
	turret_head.visible = true
	
	if build_particles:
		build_particles.emitting = true
		
	if crystal_light:
		crystal_light.light_energy = 6.0
		var t = create_tween()
		t.tween_property(crystal_light, "light_energy", 3.0, 0.6)

	# Vystoupání krystalu nahoru
	turret_head.scale = Vector3(0.1, 0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(turret_head, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	_update_prompt()

func _try_upgrade() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud or not hud.has_method("spend_essence"):
		return
		
	if not hud.spend_essence(upgrade_cost):
		_update_prompt()
		return

	# Úspěšný upgrade na Lv.2
	state = State.LEVEL_2
	fire_interval = 0.8
	attack_damage = 75
	
	if build_particles:
		build_particles.emitting = true
		
	# Změna barvy krystalu na mocnou zlatofialovou
	if crystal_light:
		crystal_light.light_color = Color(0.9, 0.3, 1.0)
		crystal_light.light_energy = 5.0
		
	_update_prompt()

func _handle_combat(delta: float) -> void:
	_attack_timer += delta
	
	# Hledání nejbližšího živého nepřítele
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy: Node3D = null
	var min_dist: float = attack_range
	
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			var d = global_position.distance_to(enemy.global_position)
			if d < min_dist:
				min_dist = d
				nearest_enemy = enemy

	_current_target = nearest_enemy
	
	if is_instance_valid(_current_target):
		# Hladké otáčení hlavy věže k nepříteli
		var look_target = _current_target.global_position + Vector3(0, 0.8, 0)
		var target_transform = turret_head.global_transform.looking_at(look_target, Vector3.UP)
		turret_head.global_transform = turret_head.global_transform.interpolate_with(target_transform, minf(1.0, 8.0 * delta))
		
		# Vystřelení projektilu
		if _attack_timer >= fire_interval:
			_attack_timer = 0.0
			_fire_at_target(_current_target)

func _fire_at_target(target: Node3D) -> void:
	if not is_instance_valid(target):
		return
		
	if fire_particles:
		fire_particles.restart()
		fire_particles.emitting = true
		
	# Zvuk / vizuální záblesk
	if crystal_light:
		var lt = create_tween()
		lt.tween_property(crystal_light, "light_energy", 5.5, 0.06)
		lt.tween_property(crystal_light, "light_energy", 3.0, 0.25)
		
	# Vytvoření magického bleskového projektilu věže
	var spell_scene = load("res://scenes/spell.tscn")
	if spell_scene:
		var bolt = spell_scene.instantiate()
		var scene_root = get_tree().current_scene if get_tree().current_scene else get_parent()
		scene_root.add_child(bolt)
		
		var spawn_pos = crystal.global_position + (turret_head.global_transform.basis.z * -0.6)
		bolt.global_position = spawn_pos
		
		var aim_target = target.global_position + Vector3(0, 0.9, 0)
		var aim_dir = (aim_target - spawn_pos).normalized()
		bolt.setup_direction(aim_dir)
		bolt.damage = attack_damage
		bolt.speed = 36.0
		bolt.is_crit = (state == State.LEVEL_2)
