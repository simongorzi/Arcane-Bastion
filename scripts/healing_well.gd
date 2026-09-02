class_name HealingWell
extends Node3D

@onready var light: OmniLight3D = $Light
@onready var particles: GPUParticles3D = $Particles
@onready var crystal: MeshInstance3D = $CrystalMesh
@onready var area: Area3D = $Area3D

var is_charged: bool = true
var _bob_time: float = 0.0

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	var wave_mgr = get_tree().get_first_node_in_group("wave_manager")
	if wave_mgr:
		wave_mgr.wave_started.connect(_on_wave_started)

func _process(delta: float) -> void:
	if crystal:
		_bob_time += delta * 2.0
		crystal.position.y = 1.6 + sin(_bob_time) * 0.15
		crystal.rotate_y(delta * 1.5)

func _on_wave_started(_wave_num: int, _total: int) -> void:
	# Dobití fontány na novou vlnu
	is_charged = true
	if light:
		light.light_energy = 3.0
	if particles:
		particles.emitting = true

func _on_body_entered(body: Node3D) -> void:
	if not is_charged:
		return
		
	if body.is_in_group("player") and body.has_method("heal"):
		body.heal(60)
		is_charged = false
		if light:
			light.light_energy = 0.3
		if particles:
			particles.emitting = false
	elif body.is_in_group("player"):
		body.current_health = min(body.max_health, body.current_health + 60)
		body.emit_signal("health_changed", body.current_health, body.max_health)
		is_charged = false
		if light:
			light.light_energy = 0.3
		if particles:
			particles.emitting = false
