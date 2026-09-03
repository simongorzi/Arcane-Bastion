class_name StoneKnight
extends CharacterBody3D

signal knight_defeated()

@export var cost: int = 12
@export var max_health: int = 140
var current_health: int = 140

@export var damage: int = 35
@export var attack_range: float = 2.6
@export var attack_cooldown: float = 1.2

@onready var sword: Node3D = get_node_or_null("SwordAnchor")
@onready var slash_particles: GPUParticles3D = get_node_or_null("SlashParticles")
@onready var hp_label: Label3D = get_node_or_null("HPLabel")

var _attack_timer: float = 0.0
var _current_target: Node3D = null
var _is_slashing: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("defenses")
	add_to_group("stone_knights")
	_update_ui()

func _physics_process(delta: float) -> void:
	_attack_timer += delta
	_find_target()
	
	if _current_target and is_instance_valid(_current_target):
		var target_pos = _current_target.global_position
		var look_dir = (target_pos - global_position).normalized()
		look_dir.y = 0
		if look_dir.length_squared() > 0.01:
			var target_yaw = atan2(look_dir.x, look_dir.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, 8.0 * delta)
			
		var dist = global_position.distance_to(target_pos)
		if dist <= attack_range and _attack_timer >= attack_cooldown:
			_attack_timer = 0.0
			_perform_slash(_current_target)

func _find_target() -> void:
	var monsters = get_tree().get_nodes_in_group("monsters")
	var closest: Node3D = null
	var min_dist = attack_range + 0.5
	
	for m in monsters:
		if not is_instance_valid(m) or (m.has_method("is_dead") and m.is_dead):
			continue
		var dist = global_position.distance_to(m.global_position)
		if dist <= min_dist:
			min_dist = dist
			closest = m
			
	_current_target = closest

func _perform_slash(target: Node3D) -> void:
	_is_slashing = true
	if slash_particles:
		slash_particles.restart()
		slash_particles.emitting = true
		
	# Animace seku meče
	if sword:
		var t = create_tween()
		t.tween_property(sword, "rotation:x", deg_to_rad(-60), 0.12)
		t.tween_property(sword, "rotation:x", deg_to_rad(45), 0.15)
		t.tween_property(sword, "rotation:x", 0.0, 0.2)
		
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	_update_ui()
	
	# Zásahový záškub
	var t = create_tween()
	t.tween_property(self, "scale", Vector3(1.1, 0.9, 1.1), 0.08)
	t.tween_property(self, "scale", Vector3.ONE, 0.12)
	
	if current_health <= 0:
		_die()

func _die() -> void:
	emit_signal("knight_defeated")
	queue_free()

func _update_ui() -> void:
	if hp_label:
		hp_label.text = "⚔️ Stone Knight\n%d / %d HP" % [current_health, max_health]
		var ratio = float(current_health) / float(max_health)
		hp_label.modulate = Color(0.4, 0.9, 1.0) if ratio > 0.4 else Color(1.0, 0.3, 0.3)
