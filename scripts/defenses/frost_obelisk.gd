class_name FrostObelisk
extends Node3D

@export var cost: int = 7
@export var damage: int = 15
@export var slow_factor: float = 0.55 # Zpomalí na 55 % (zpomalení o 45 %)
@export var slow_duration: float = 3.0
@export var attack_range: float = 14.0
@export var attack_cooldown: float = 3.2

@onready var frost_particles: GPUParticles3D = get_node_or_null("FrostParticles")
@onready var frost_light: OmniLight3D = get_node_or_null("FrostLight")
@onready var crystal_mesh: Node3D = get_node_or_null("CrystalMesh")

var _attack_timer: float = 0.0
var _anim_time: float = 0.0

func _ready() -> void:
	add_to_group("defenses")
	add_to_group("towers")

func _process(delta: float) -> void:
	_attack_timer += delta
	_anim_time += delta * 2.5
	
	if crystal_mesh:
		crystal_mesh.rotate_y(delta * 2.0)
		crystal_mesh.position.y = 2.4 + sin(_anim_time) * 0.12

	if _attack_timer >= attack_cooldown:
		if _has_enemies_in_range():
			_attack_timer = 0.0
			_pulse_freeze()

func _has_enemies_in_range() -> bool:
	var monsters = get_tree().get_nodes_in_group("monsters")
	for m in monsters:
		if is_instance_valid(m) and not (m.has_method("is_dead") and m.is_dead):
			if global_position.distance_to(m.global_position) <= attack_range:
				return true
	return false

func _pulse_freeze() -> void:
	if frost_particles:
		frost_particles.restart()
		frost_particles.emitting = true
	if frost_light:
		frost_light.light_energy = 4.5
		var t = create_tween()
		t.tween_property(frost_light, "light_energy", 0.6, 0.4)

	var monsters = get_tree().get_nodes_in_group("monsters")
	for m in monsters:
		if not is_instance_valid(m) or (m.has_method("is_dead") and m.is_dead):
			continue
		var dist = global_position.distance_to(m.global_position)
		if dist <= attack_range:
			if m.has_method("take_damage"):
				m.take_damage(damage)
			# Aplikace mrazivého zpomalení
			if m.has_method("apply_slow"):
				m.apply_slow(slow_factor, slow_duration)
			elif "speed" in m:
				var orig_speed = m.speed
				m.speed *= slow_factor
				get_tree().create_timer(slow_duration).timeout.connect(func():
					if is_instance_valid(m):
						m.speed = orig_speed
				)
