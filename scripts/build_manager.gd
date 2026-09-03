class_name BuildManager
extends Node3D

signal build_mode_toggled(is_active: bool)
signal defense_selected(index: int)
signal tower_built(current_count: int, max_count: int)

enum DefenseType { BALLISTA = 0, FLAME = 1, FROST = 2, KNIGHT = 3 }

const DEFENSE_INFO = [
	{"name": "Arcane Ballista", "cost": 8, "scene": "res://scenes/defenses/ballista_tower.tscn", "icon": "🏹"},
	{"name": "Flame Spire", "cost": 10, "scene": "res://scenes/defenses/flame_spire.tscn", "icon": "🔥"},
	{"name": "Frost Obelisk", "cost": 7, "scene": "res://scenes/defenses/frost_obelisk.tscn", "icon": "❄️"},
	{"name": "Stone Knight", "cost": 12, "scene": "res://scenes/defenses/stone_knight.tscn", "icon": "⚔️"}
]

var is_build_mode: bool = false
var selected_type: DefenseType = DefenseType.BALLISTA

@onready var player: Node3D = get_tree().get_first_node_in_group("player")
@onready var hud: HUD = get_tree().get_first_node_in_group("hud")

var _hologram: MeshInstance3D = null
var _hologram_mat: StandardMaterial3D = null
var _last_valid_pos: Vector3 = Vector3.ZERO
var _is_placement_valid: bool = false

func _ready() -> void:
	add_to_group("build_manager")
	_create_hologram()

func _create_hologram() -> void:
	_hologram = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.3
	cyl.bottom_radius = 1.3
	cyl.height = 0.3
	_hologram.mesh = cyl
	
	_hologram_mat = StandardMaterial3D.new()
	_hologram_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_hologram_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_hologram_mat.albedo_color = Color(0.2, 0.9, 0.3, 0.6)
	_hologram.material_override = _hologram_mat
	_hologram.visible = false
	add_child(_hologram)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			toggle_build_mode()
			get_viewport().set_input_as_handled()
		elif is_build_mode:
			if event.keycode == KEY_1:
				select_defense(DefenseType.BALLISTA)
			elif event.keycode == KEY_2:
				select_defense(DefenseType.FLAME)
			elif event.keycode == KEY_3:
				select_defense(DefenseType.FROST)
			elif event.keycode == KEY_4:
				select_defense(DefenseType.KNIGHT)
			elif event.keycode == KEY_ESCAPE:
				set_build_mode(false)

	if is_build_mode and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place_defense()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			set_build_mode(false)
			get_viewport().set_input_as_handled()

func toggle_build_mode() -> void:
	set_build_mode(not is_build_mode)

func set_build_mode(active: bool) -> void:
	is_build_mode = active
	if _hologram:
		_hologram.visible = is_build_mode
	emit_signal("build_mode_toggled", is_build_mode)
	
	var h = get_tree().get_first_node_in_group("hud")
	if h and h.has_method("set_build_bar_visible"):
		h.set_build_bar_visible(is_build_mode, int(selected_type))

func select_defense(type: DefenseType) -> void:
	selected_type = type
	emit_signal("defense_selected", int(selected_type))
	var h = get_tree().get_first_node_in_group("hud")
	if h and h.has_method("set_build_bar_visible"):
		h.set_build_bar_visible(is_build_mode, int(selected_type))

func get_max_towers_for_wave(wave: int) -> int:
	if wave <= 1:
		return 2
	elif wave == 2:
		return 4
	elif wave == 3:
		return 6
	else:
		return 8

func _process(_delta: float) -> void:
	if not is_build_mode:
		return
		
	_update_hologram_position()

func _update_hologram_position() -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
		
	var from = camera.global_position
	var to = from + camera.project_ray_normal(get_viewport().get_mouse_position()) * 16.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to, 1) # Layer 1: Environment
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_pos = result.position
		_hologram.visible = true
		_hologram.global_position = hit_pos + Vector3(0, 0.15, 0)
		_last_valid_pos = hit_pos
		
		_is_placement_valid = _validate_placement(hit_pos)
		if _hologram_mat:
			_hologram_mat.albedo_color = Color(0.2, 0.9, 0.3, 0.6) if _is_placement_valid else Color(0.9, 0.2, 0.2, 0.6)
	else:
		_hologram.visible = false
		_is_placement_valid = false

func _validate_placement(pos: Vector3) -> bool:
	var h = get_tree().get_first_node_in_group("hud")
	var essences = h.soul_essences if (h and "soul_essences" in h) else 0
	var cost = DEFENSE_INFO[int(selected_type)]["cost"]
	
	# 1. Kontrola esencí
	if essences < cost:
		return false
		
	# 2. Kontrola limitu věží na vlnu
	var wave_mgr = get_tree().get_first_node_in_group("wave_manager")
	var current_wave = wave_mgr.current_wave if wave_mgr else 1
	var max_towers = get_max_towers_for_wave(current_wave)
	var active_towers = get_tree().get_nodes_in_group("towers").size()
	if selected_type != DefenseType.KNIGHT and active_towers >= max_towers:
		return false

	# 3. Kontrola vzdálenosti od jiných věží
	var existing = get_tree().get_nodes_in_group("defenses")
	for def in existing:
		if is_instance_valid(def) and def.global_position.distance_to(pos) < 2.4:
			return false

	# 4. Omezení silnice: Stacionární věže (Ballista, Flame, Frost) nesmí stát přímo na cestě
	if selected_type != DefenseType.KNIGHT:
		var waypoints = [
			Vector3(0, 0, 48),
			Vector3(-14, 0, 36),
			Vector3(12, 0, 22),
			Vector3(0, 0, 10),
			Vector3(0, 0, -4),
			Vector3(0, 0, -16)
		]
		for wp in waypoints:
			if pos.distance_to(wp) < 2.8:
				return false
				
	return true

func _try_place_defense() -> void:
	if not _is_placement_valid:
		return
		
	var info = DEFENSE_INFO[int(selected_type)]
	var cost = info["cost"]
	var h = get_tree().get_first_node_in_group("hud")
	if not h or not h.has_method("spend_essence"):
		return
		
	if not h.spend_essence(cost):
		return
		
	var scene = load(info["scene"])
	if not scene:
		return
		
	var inst = scene.instantiate()
	var scene_root = get_tree().current_scene if get_tree().current_scene else get_parent()
	scene_root.add_child(inst)
	inst.global_position = _last_valid_pos
	
	# Efekt postavení (Scale punch)
	inst.scale = Vector3(0.1, 0.1, 0.1)
	var t = create_tween()
	t.tween_property(inst, "scale", Vector3(1.2, 1.2, 1.2), 0.15)
	t.tween_property(inst, "scale", Vector3.ONE, 0.12)
	
	# Zvuk/vibrace a aktualizace HUD
	var wave_mgr = get_tree().get_first_node_in_group("wave_manager")
	var current_wave = wave_mgr.current_wave if wave_mgr else 1
	var max_towers = get_max_towers_for_wave(current_wave)
	var active_towers = get_tree().get_nodes_in_group("towers").size()
	emit_signal("tower_built", active_towers, max_towers)
	
	if h and h.has_method("update_tower_count"):
		h.update_tower_count(active_towers, max_towers)
