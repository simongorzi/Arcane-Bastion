class_name DamageNumber
extends Node3D

@onready var label: Label3D = $Label3D

var _velocity: Vector3 = Vector3.ZERO
var _duration: float = 0.75
var _elapsed: float = 0.0

func _ready() -> void:
	# Náhodný rozptyl do stran pro přirozený výskok
	_velocity = Vector3(
		randf_range(-1.2, 1.2),
		randf_range(2.8, 4.2),
		randf_range(-1.2, 1.2)
	)

func setup(amount: int, is_crit: bool = false, is_fire: bool = false, is_frost: bool = false) -> void:
	if not is_node_ready():
		await ready
		
	if is_crit:
		label.text = "💥 " + str(amount) + " CRIT!"
		label.modulate = Color(1.0, 0.85, 0.2, 1.0) # Zlatá barva
		label.outline_modulate = Color(0.6, 0.2, 0.0, 1.0)
		label.font_size = 40
		scale = Vector3(1.4, 1.4, 1.4)
	elif is_fire:
		label.text = "🔥 " + str(amount)
		label.modulate = Color(1.0, 0.45, 0.1, 1.0) # Ohnivá oranžová
		label.font_size = 32
	elif is_frost:
		label.text = "❄️ " + str(amount)
		label.modulate = Color(0.3, 0.9, 1.0, 1.0) # Ledově azurová
		label.font_size = 32
	else:
		label.text = str(amount)
		label.modulate = Color(1.0, 1.0, 1.0, 1.0) # Čistě bílá
		label.font_size = 28

	# Animace zvětšení a zmizení
	var tween = create_tween()
	tween.tween_property(self, "scale", scale * 1.25, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.6).set_delay(0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(queue_free)

func _process(delta: float) -> void:
	_elapsed += delta
	# Pohyb nahoru s lehkou gravitací
	_velocity.y -= 3.5 * delta
	global_position += _velocity * delta
