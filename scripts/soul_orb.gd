class_name SoulOrb
extends Node3D

@export var score_value: int = 50
@export var collect_radius: float = 2.2

@onready var mesh: Node3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D
@onready var light_beam: MeshInstance3D = get_node_or_null("LightBeam")
@onready var particles: GPUParticles3D = get_node_or_null("Particles")

var _player: Node3D = null
var _is_landing: bool = true
var _is_being_drawn: bool = false
var _fly_speed: float = 3.0
var _bob_timer: float = 0.0
var _base_y: float = 0.5
var _collected: bool = false

func _ready() -> void:
	_bob_timer = randf_range(0.0, 6.28)
	_player = get_tree().get_first_node_in_group("player")
	
	# Počáteční výskok a reálný pád na zem (Y = 0.45)
	var floor_target = Vector3(
		global_position.x + randf_range(-0.7, 0.7),
		0.45,
		global_position.z + randf_range(-0.7, 0.7)
	)
	var peak_pos = Vector3(
		(global_position.x + floor_target.x) * 0.5,
		maxf(global_position.y, 1.0) + randf_range(0.3, 0.7),
		(global_position.z + floor_target.z) * 0.5
	)
	
	var drop_tween = create_tween()
	drop_tween.tween_property(self, "global_position", peak_pos, 0.25)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	drop_tween.tween_property(self, "global_position", floor_target, 0.35)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)
	drop_tween.finished.connect(func():
		_is_landing = false
		_base_y = global_position.y
	)

func _process(delta: float) -> void:
	if _collected:
		return
		
	# Rotace krystalu kolem svislé osy
	if mesh:
		mesh.rotate_y(2.5 * delta)
	if light_beam:
		light_beam.rotate_y(-1.2 * delta)

	# Klidové jemné vznášení nad dlažbou
	if not _is_landing and not _is_being_drawn:
		_bob_timer += delta * 3.5
		global_position.y = _base_y + sin(_bob_timer) * 0.12

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return

	var player_target = _player.global_position + Vector3(0, 1.1, 0)
	var dist = global_position.distance_to(player_target)

	# Sebrání nastane pouze když hráč přijde přímo k esenci (2.2 metru)
	if dist <= collect_radius or _is_being_drawn:
		_is_being_drawn = true
		_fly_speed = minf(22.0, _fly_speed + 28.0 * delta)
		var dir = (player_target - global_position).normalized()
		global_position += dir * _fly_speed * delta

		# Když doletí přímo k tělu hráče -> animovaný záblesk a zisk
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

	# Animovaný sběr: rychlé zmenšení se zábleskem světla
	if light:
		light.light_energy = 7.0
	if light_beam:
		light_beam.visible = false

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.6, 1.6, 1.6), 0.08)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.12)
	tween.finished.connect(queue_free)
