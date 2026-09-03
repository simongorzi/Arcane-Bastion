class_name SoulOrb
extends Node3D

@export var score_value: int = 50
@export var magnet_radius: float = 6.5
@export var collect_radius: float = 0.85

@onready var mesh: Node3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D
@onready var particles: GPUParticles3D = get_node_or_null("Particles")

var _player: Node3D = null
var _is_being_drawn: bool = false
var _fly_speed: float = 2.0
var _bob_timer: float = 0.0
var _initial_y: float = 0.0
var _collected: bool = false

func _ready() -> void:
	_bob_timer = randf_range(0.0, 6.28)
	_initial_y = global_position.y
	_player = get_tree().get_first_node_in_group("player")
	
	# Počáteční malý výskok nahoru a rozptyl
	var target_pos = global_position + Vector3(randf_range(-0.8, 0.8), randf_range(0.6, 1.2), randf_range(-0.8, 0.8))
	var drop_tween = create_tween()
	drop_tween.tween_property(self, "global_position", target_pos, 0.35)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	drop_tween.tween_property(self, "global_position:y", 0.6, 0.35)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)
	drop_tween.finished.connect(func():
		_initial_y = global_position.y
	)

func _process(delta: float) -> void:
	if _collected:
		return
		
	# Rotace krystalu a jemné vznášení
	rotate_y(3.0 * delta)
	_bob_timer += delta * 4.0
	if not _is_being_drawn:
		position.y = _initial_y + sin(_bob_timer) * 0.15

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return

	var player_target = _player.global_position + Vector3(0, 1.2, 0)
	var dist = global_position.distance_to(player_target)

	# Magnetismus – přitahování k hráči
	if dist <= magnet_radius or _is_being_drawn:
		_is_being_drawn = true
		_fly_speed = minf(28.0, _fly_speed + 35.0 * delta)
		var dir = (player_target - global_position).normalized()
		global_position += dir * _fly_speed * delta

		# Sebrání krystalu
		if dist <= collect_radius:
			_collect()

func _collect() -> void:
	if _collected:
		return
	_collected = true

	# Přidání skóre a bodu do komba přes HUD
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("add_soul_gem"):
		hud.add_soul_gem(score_value)
	elif hud and hud.has_method("add_score"):
		hud.add_score(score_value)

	# Částicový záblesk a zvětšení při sebrání
	if light:
		light.light_energy = 5.0
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.8, 1.8, 1.8), 0.1)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.15)
	tween.finished.connect(queue_free)
