class_name BallistaTower
extends Node3D

@export var cost: int = 8
@export var damage: int = 45
@export var attack_range: float = 18.0
@export var attack_cooldown: float = 1.6

@onready var ballista_head: Node3D = $BallistaMesh
@onready var fire_particles: GPUParticles3D = get_node_or_null("MuzzleFlash")
@onready var fire_light: OmniLight3D = get_node_or_null("FireLight")

var _attack_timer: float = 0.0
var _current_target: Node3D = null

func _ready() -> void:
	add_to_group("defenses")
	add_to_group("towers")

func _process(delta: float) -> void:
	_attack_timer += delta
	_find_target()
	
	if _current_target and is_instance_valid(_current_target):
		var target_pos = _current_target.global_position + Vector3(0, 0.9, 0)
		var look_dir = (target_pos - ballista_head.global_position).normalized()
		var target_yaw = atan2(look_dir.x, look_dir.z)
		ballista_head.rotation.y = lerp_angle(ballista_head.rotation.y, target_yaw, 10.0 * delta)
		
		if _attack_timer >= attack_cooldown:
			_attack_timer = 0.0
			_fire_bolt(target_pos)

func _find_target() -> void:
	var monsters = get_tree().get_nodes_in_group("monsters")
	var closest: Node3D = null
	var min_dist = attack_range
	
	for m in monsters:
		if not is_instance_valid(m):
			continue
		if m.has_method("is_dead") and m.is_dead:
			continue
		var dist = global_position.distance_to(m.global_position)
		if dist <= min_dist:
			min_dist = dist
			closest = m
			
	_current_target = closest

func _fire_bolt(target_pos: Vector3) -> void:
	if fire_particles:
		fire_particles.restart()
		fire_particles.emitting = true
	if fire_light:
		fire_light.light_energy = 3.5
		var t = create_tween()
		t.tween_property(fire_light, "light_energy", 0.0, 0.15)
		
	# Vystřelení magického šípu (Spell projektil)
	var spell_scene = load("res://scenes/spell.tscn")
	if spell_scene:
		var bolt = spell_scene.instantiate()
		var scene_root = get_tree().current_scene if get_tree().current_scene else get_parent()
		scene_root.add_child(bolt)
		bolt.global_position = ballista_head.global_position + Vector3(0, 0.8, 0)
		bolt.damage = damage
		bolt.speed = 36.0
		bolt.direction = (target_pos - bolt.global_position).normalized()
