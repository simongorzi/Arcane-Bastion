class_name FortressGate
extends Node3D

signal gate_health_changed(current_hp: int, max_hp: int)
signal gate_destroyed()

@export var max_health: int = 100
var current_health: int = 100
var is_destroyed: bool = false

@onready var gate_mesh: Node3D = get_node_or_null("GateMesh")
@onready var hit_sparks: GPUParticles3D = get_node_or_null("HitSparks")
@onready var health_label: Label3D = get_node_or_null("HealthLabel")

func _ready() -> void:
	current_health = max_health
	add_to_group("fortress_gate")
	_update_ui()

func take_damage(amount: int) -> void:
	if is_destroyed:
		return
		
	current_health = max(0, current_health - amount)
	emit_signal("gate_health_changed", current_health, max_health)
	_update_ui()
	
	# Zvukový/vizuální otřes
	if hit_sparks:
		hit_sparks.restart()
		hit_sparks.emitting = true
		
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_screenshake"):
		player.add_screenshake(0.12)
		
	# Červený zásahový efekt brány
	if gate_mesh:
		var t = create_tween()
		t.tween_property(gate_mesh, "position:z", -0.15, 0.05)
		t.tween_property(gate_mesh, "position:z", 0.0, 0.1)

	if current_health <= 0:
		_destroy_gate()

func _destroy_gate() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	emit_signal("gate_destroyed")
	
	if health_label:
		health_label.text = "💥 BREACHED!"
		health_label.modulate = Color(1, 0.2, 0.2)
		
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("on_gate_destroyed"):
		hud.on_gate_destroyed()

func _update_ui() -> void:
	if health_label:
		health_label.text = "🏰 Fortress Gate\n%d / %d HP" % [current_health, max_health]
		var ratio = float(current_health) / float(max_health)
		if ratio > 0.6:
			health_label.modulate = Color(0.3, 0.9, 1.0)
		elif ratio > 0.3:
			health_label.modulate = Color(1.0, 0.8, 0.2)
		else:
			health_label.modulate = Color(1.0, 0.3, 0.3)
