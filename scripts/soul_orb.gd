class_name SoulOrb
extends Node3D

@export var score_value: int = 50
@export var collect_radius: float = 2.4

@onready var mesh: Node3D = $MeshInstance3D
@onready var ground_ring: MeshInstance3D = get_node_or_null("GroundRing")

var _player: Node3D = null
var _is_landing: bool = false
var _is_being_drawn: bool = false
var _fly_speed: float = 4.0
var _bob_timer: float = 0.0
var _base_y: float = 0.4
var _collected: bool = false

func _ready() -> void:
	_bob_timer = randf_range(0.0, 6.28)
	_player = get_tree().get_first_node_in_group("player")

## Inicializace pozice shozu přímo na místě smrti monstra
func setup(spawn_pos: Vector3, value: int = 50) -> void:
	score_value = value
	global_position = spawn_pos + Vector3(0, 0.4, 0)
	
	var floor_target = Vector3(
		spawn_pos.x + randf_range(-0.6, 0.6),
		0.4,
		spawn_pos.z + randf_range(-0.6, 0.6)
	)
	var peak_pos = Vector3(
		(spawn_pos.x + floor_target.x) * 0.5,
		spawn_pos.y + randf_range(0.8, 1.4),
		(spawn_pos.z + floor_target.z) * 0.5
	)
	
	_is_landing = true
	var drop_tween = create_tween()
	drop_tween.tween_property(self, "global_position", peak_pos, 0.22)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	drop_tween.tween_property(self, "global_position", floor_target, 0.3)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)
	drop_tween.finished.connect(func():
		_is_landing = false
		_base_y = global_position.y
	)

func _process(delta: float) -> void:
	if _collected:
		return
		
	# Rotace krystalu a prstence na zemi
	if mesh:
		mesh.rotate_y(3.0 * delta)
	if ground_ring:
		ground_ring.rotate_y(-1.5 * delta)

	# Klidové vznášení nad dlažbou
	if not _is_landing and not _is_being_drawn:
		_bob_timer += delta * 3.5
		position.y = _base_y + sin(_bob_timer) * 0.1

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return

	var player_target = _player.global_position + Vector3(0, 1.1, 0)
	var dist = global_position.distance_to(player_target)

	# Fyzický sběr – až když hráč přijde na 2.4 metru
	if dist <= collect_radius or _is_being_drawn:
		_is_being_drawn = true
		_fly_speed = minf(26.0, _fly_speed + 32.0 * delta)
		var dir = (player_target - global_position).normalized()
		global_position += dir * _fly_speed * delta

		if dist <= 0.8:
			_collect()

func _collect() -> void:
	if _collected:
		return
	_collected = true

	# Přidání esence a skóre do HUD
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		if hud.has_method("add_essence"):
			hud.add_essence(1)
		if hud.has_method("add_soul_gem"):
			hud.add_soul_gem(score_value)
		elif hud.has_method("add_score"):
			hud.add_score(score_value)

	# Vizuální plovoucí nápis "+1 Essence 💎" na místě sběru
	_spawn_floating_pickup_text()

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.06)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.1)
	tween.finished.connect(queue_free)

func _spawn_floating_pickup_text() -> void:
	var label = Label3D.new()
	var scene_root = get_tree().current_scene if get_tree().current_scene else get_parent()
	scene_root.add_child(label)
	label.global_position = global_position + Vector3(0, 0.6, 0)
	label.text = "+1 Essence 💎"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 25
	label.font_size = 28
	label.modulate = Color(0.25, 0.95, 1.0, 1.0)
	label.outline_render_priority = 24
	label.outline_size = 6
	label.outline_modulate = Color(0, 0, 0, 0.9)

	var tween = label.create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y + 1.2, 0.6)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)\
		.set_delay(0.2)
	tween.finished.connect(label.queue_free)
