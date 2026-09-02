class_name Spell
extends Area3D

@export_group("Vlastnosti kouzla")
@export var speed: float = 32.0
@export var damage: int = 45
@export var lifetime: float = 4.0

# Odkazy na poduzly
@onready var trail_particles: GPUParticles3D = get_node_or_null("TrailParticles")
@onready var impact_particles: GPUParticles3D = get_node_or_null("ImpactParticles")
@onready var light: OmniLight3D = get_node_or_null("OmniLight3D")
@onready var core_mesh: MeshInstance3D = get_node_or_null("CoreMesh")
@onready var shell_mesh: MeshInstance3D = get_node_or_null("ShellMesh")
@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")

var _direction: Vector3 = Vector3.FORWARD
var _has_hit: bool = false
var _pulse_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	var timer: SceneTreeTimer = get_tree().create_timer(lifetime)
	timer.timeout.connect(func():
		if is_inside_tree() and not _has_hit:
			destroy_spell()
	)

func _physics_process(delta: float) -> void:
	if _has_hit:
		return
		
	# Let kouzla
	global_position += _direction * speed * delta
	
	# Magická pulsace světla a obalu kouzla
	_pulse_timer += delta * 12.0
	if shell_mesh:
		shell_mesh.scale = Vector3.ONE * (1.0 + sin(_pulse_timer) * 0.15)
	if light:
		light.light_energy = 3.5 + sin(_pulse_timer * 1.5) * 1.0

func setup_direction(dir: Vector3) -> void:
	_direction = dir.normalized()
	if _direction != Vector3.ZERO:
		look_at(global_position + _direction, Vector3.UP)

var is_fireball: bool = false
var is_chain_lightning: bool = false
var is_frost: bool = false
var is_crit: bool = false

func _on_body_entered(body: Node3D) -> void:
	if _has_hit or body is Player:
		return
		
	var final_damage = damage
	if is_crit:
		final_damage = int(final_damage * 2.5)
	
	if body.has_method("take_damage"):
		body.take_damage(final_damage)
	elif body.is_in_group("enemies") and body.has_method("hit"):
		body.hit(final_damage)
		
	# Mrazivý efekt
	if is_frost and body.has_method("apply_slow"):
		body.apply_slow(0.5, 4.0)
		
	# Ohnivý výbuch (AoE)
	if is_fireball:
		_trigger_fireball_aoe(global_position, final_damage)
		
	# Řetězový blesk
	if is_chain_lightning:
		_trigger_chain_lightning(body, int(final_damage * 0.7))
		
	destroy_spell()

func _on_area_entered(area: Area3D) -> void:
	if _has_hit:
		return
	var parent = area.get_parent()
	if parent and parent.has_method("take_damage") and not (parent is Player):
		var final_damage = damage
		if is_crit:
			final_damage = int(final_damage * 2.5)
		parent.take_damage(final_damage)
		if is_frost and parent.has_method("apply_slow"):
			parent.apply_slow(0.5, 4.0)
		if is_fireball:
			_trigger_fireball_aoe(global_position, final_damage)
		if is_chain_lightning:
			_trigger_chain_lightning(parent, int(final_damage * 0.7))
		destroy_spell()

func _trigger_fireball_aoe(pos: Vector3, aoe_damage: int) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			var dist = pos.distance_to(enemy.global_position)
			if dist <= 3.5:
				enemy.take_damage(int(aoe_damage * 0.8))

func _trigger_chain_lightning(initial_target: Node3D, lightning_damage: int) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy != initial_target and enemy.has_method("take_damage"):
			var dist = initial_target.global_position.distance_to(enemy.global_position)
			if dist <= 8.0:
				enemy.take_damage(lightning_damage)
				hit_count += 1
				if hit_count >= 3:
					break

## Magický výbuch při dopadu (Impact burst)
func destroy_spell() -> void:
	_has_hit = true
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	# Skryjeme kouli
	if core_mesh:
		core_mesh.visible = false
	if shell_mesh:
		shell_mesh.visible = false

	# Zastavíme stopu za letem
	if trail_particles:
		trail_particles.emitting = false

	# Spustíme explozivní spršku jisker a záblesk světla
	if impact_particles:
		impact_particles.emitting = true
		
	if light:
		var light_tween = create_tween()
		light_tween.tween_property(light, "light_energy", 6.0, 0.05)
		light_tween.tween_property(light, "light_energy", 0.0, 0.35)

	await get_tree().create_timer(0.5).timeout
	queue_free()
