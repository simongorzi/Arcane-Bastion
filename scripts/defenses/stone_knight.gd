class_name StoneKnight
extends CharacterBody3D

signal knight_defeated()

@export var cost: int = 12
@export var max_health: int = 140
var current_health: int = 140

@export var damage: int = 35
@export var attack_range: float = 2.8
@export var attack_cooldown: float = 1.2

@onready var model_holder: Node3D = get_node_or_null("ModelHolder")
@onready var slash_particles: GPUParticles3D = get_node_or_null("SlashParticles")
@onready var hp_label: Label3D = get_node_or_null("HPLabel")

var anim_player: AnimationPlayer = null
var _attack_timer: float = 0.0
var _current_target: Node3D = null

func _ready() -> void:
	current_health = max_health
	add_to_group("defenses")
	add_to_group("stone_knights")
	_setup_animations()
	_update_ui()

func _setup_animations() -> void:
	var lib = Monster.get_shared_anim_lib()
	if not model_holder:
		return
		
	var warrior_model = model_holder.get_child(0) if model_holder.get_child_count() > 0 else null
	if warrior_model and lib:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimPlayer"
		warrior_model.add_child(anim_player)
		anim_player.root_node = anim_player.get_path_to(warrior_model)
		anim_player.add_animation_library("", lib)
		
		# Přehrát bojovou pozici
		if anim_player.has_animation("Idle_A"):
			anim_player.play("Idle_A")
		elif anim_player.has_animation("Walking_A"):
			anim_player.play("Walking_A")

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
	var monsters = get_tree().get_nodes_in_group("enemies")
	if monsters.is_empty():
		monsters = get_tree().get_nodes_in_group("monsters")
		
	var closest: Node3D = null
	var min_dist = attack_range + 0.8
	
	for m in monsters:
		if not is_instance_valid(m) or (m.has_method("is_dead") and m.is_dead):
			continue
		var dist = global_position.distance_to(m.global_position)
		if dist <= min_dist:
			min_dist = dist
			closest = m
			
	_current_target = closest

func _perform_slash(target: Node3D) -> void:
	if slash_particles:
		slash_particles.restart()
		slash_particles.emitting = true
		
	if anim_player:
		if anim_player.has_animation("Attack_A"):
			anim_player.play("Attack_A")
			anim_player.queue("Idle_A")
		elif anim_player.has_animation("1H_Melee_Attack"):
			anim_player.play("1H_Melee_Attack")
			anim_player.queue("Idle_A")
		
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	_update_ui()
	
	if anim_player and anim_player.has_animation("Hit_A"):
		anim_player.play("Hit_A")
		anim_player.queue("Idle_A")
	
	# Zásahový záškub
	var t = create_tween()
	t.tween_property(self, "scale", Vector3(1.15, 0.9, 1.15), 0.06)
	t.tween_property(self, "scale", Vector3.ONE, 0.1)
	
	if current_health <= 0:
		_die()

func _die() -> void:
	emit_signal("knight_defeated")
	queue_free()

func _update_ui() -> void:
	if hp_label:
		hp_label.text = "⚔️ Guardian Knight\n%d / %d HP" % [current_health, max_health]
		var ratio = float(current_health) / float(max_health)
		hp_label.modulate = Color(0.3, 0.9, 1.0) if ratio > 0.4 else Color(1.0, 0.3, 0.3)
