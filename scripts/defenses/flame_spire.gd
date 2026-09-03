class_name FlameSpire
extends Node3D

@export var cost: int = 10
@export var damage: int = 25
@export var attack_range: float = 11.0
@export var attack_cooldown: float = 2.4

@onready var flame_particles: GPUParticles3D = get_node_or_null("FlameParticles")
@onready var flame_light: OmniLight3D = get_node_or_null("FlameLight")

var _attack_timer: float = 0.0

func _ready() -> void:
	add_to_group("defenses")
	add_to_group("towers")

func _process(delta: float) -> void:
	_attack_timer += delta
	if _attack_timer >= attack_cooldown:
		if _has_enemies_in_range():
			_attack_timer = 0.0
			_burst_flames()

func _has_enemies_in_range() -> bool:
	var monsters = get_tree().get_nodes_in_group("monsters")
	for m in monsters:
		if is_instance_valid(m) and not (m.has_method("is_dead") and m.is_dead):
			if global_position.distance_to(m.global_position) <= attack_range:
				return true
	return false

func _burst_flames() -> void:
	if flame_particles:
		flame_particles.restart()
		flame_particles.emitting = true
	if flame_light:
		flame_light.light_energy = 5.0
		var t = create_tween()
		t.tween_property(flame_light, "light_energy", 1.0, 0.45)

	# Zásah všech monster v okruhu 11 metrů
	var monsters = get_tree().get_nodes_in_group("monsters")
	for m in monsters:
		if not is_instance_valid(m) or (m.has_method("is_dead") and m.is_dead):
			continue
		var dist = global_position.distance_to(m.global_position)
		if dist <= attack_range:
			if m.has_method("take_damage"):
				m.take_damage(damage)
				# Pushback od plamene
				if "velocity" in m:
					var push_dir = (m.global_position - global_position).normalized()
					m.velocity += push_dir * 4.0
