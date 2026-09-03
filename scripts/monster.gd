class_name Monster
extends CharacterBody3D

signal enemy_defeated(score_value: int)

@export_group("Atributy Monstra")
@export var max_hp: int = 70
@export var speed: float = 3.2
@export var attack_damage: int = 15
@export var attack_range: float = 1.6
@export var attack_cooldown: float = 1.2
@export var score_value: int = 100
@export var gravity: float = 12.0

# Odkazy na uzly
@onready var nav_agent: NavigationAgent3D = get_node_or_null("NavigationAgent3D")
@onready var death_particles: GPUParticles3D = get_node_or_null("DeathParticles")
@onready var model_holder: Node3D = get_node_or_null("ModelHolder")

var anim_player: AnimationPlayer = null
var current_hp: int = 70
var player: Node3D = null
var _can_attack: bool = true
var _attack_timer: float = 0.0
var _is_dying: bool = false

# Sdílená knihovna animací pro všechny kostlivce
static var _shared_anim_lib: AnimationLibrary = null

static func get_shared_anim_lib() -> AnimationLibrary:
	if _shared_anim_lib != null:
		return _shared_anim_lib
		
	var movement_path = "res://assets/skeletons/KayKit_Skeletons_1.1_FREE/Animations/gltf/Rig_Medium/Rig_Medium_MovementBasic.glb"
	if ResourceLoader.exists(movement_path):
		var m_scene = load(movement_path)
		if m_scene:
			var m_inst = m_scene.instantiate()
			var m_ap: AnimationPlayer = m_inst.find_child("AnimationPlayer", true, false)
			if m_ap:
				_shared_anim_lib = m_ap.get_animation_library("").duplicate()
				var walk_anim = _shared_anim_lib.get_animation("Walking_A")
				if walk_anim:
					walk_anim.loop_mode = Animation.LOOP_LINEAR
					
				var general_path = "res://assets/skeletons/KayKit_Skeletons_1.1_FREE/Animations/gltf/Rig_Medium/Rig_Medium_General.glb"
				if ResourceLoader.exists(general_path):
					var g_scene = load(general_path)
					if g_scene:
						var g_inst = g_scene.instantiate()
						var g_ap: AnimationPlayer = g_inst.find_child("AnimationPlayer", true, false)
						if g_ap:
							var g_lib = g_ap.get_animation_library("")
							for a_name in g_lib.get_animation_list():
								if not _shared_anim_lib.has_animation(a_name):
									_shared_anim_lib.add_animation(a_name, g_lib.get_animation(a_name))
	return _shared_anim_lib

func _ready() -> void:
	add_to_group("enemies")
	current_hp = max_hp
	player = get_tree().get_first_node_in_group("player")
	
	if nav_agent:
		nav_agent.path_desired_distance = 0.5
		nav_agent.target_desired_distance = attack_range

	# Plynulý pohyb po schodech nahoru i dolů bez zasekávání na hraně
	floor_snap_length = 0.4
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(42.0)

	_setup_skeleton_and_animations()

## Inicializace 3D modelu a připojení AnimationPlayeru
func _setup_skeleton_and_animations() -> void:
	if not model_holder:
		return
		
	var lib = get_shared_anim_lib()
	
	# Vyhledáme stažený model kostlivce v model_holderu
	var skel_model = model_holder.get_child(0) if model_holder.get_child_count() > 0 else null
	if skel_model and lib:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimPlayer"
		skel_model.add_child(anim_player)
		anim_player.root_node = anim_player.get_path_to(skel_model)
		anim_player.add_animation_library("", lib)
		anim_player.play("Walking_A")

func _physics_process(delta: float) -> void:
	if _is_dying:
		return

	# 1. Gravitace
	if not is_on_floor():
		velocity.y -= gravity * delta

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		move_and_slide()
		return

	var dist_to_player: float = global_position.distance_to(player.global_position)

	# 2. Útok na hráče při kontaktní vzdálenosti
	if dist_to_player <= attack_range:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		_handle_attack(delta)
	else:
		# 3. Pohyb směrem k hráči
		_navigate_to_player(delta)

	move_and_slide()

	if not _can_attack:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_can_attack = true

## Výpočet taktického cílového bodu (brány, obcházení věže, schody nahoru)
func get_tactical_target_pos() -> Vector3:
	if not is_instance_valid(player):
		return global_position
		
	var p_pos: Vector3 = player.global_position
	var my_pos: Vector3 = global_position
	
	var STAIRS_BOTTOM = Vector3(0.0, 0.0, 5.5)
	var STAIRS_TOP = Vector3(0.0, 2.4, 0.2)
	
	# 1. Průchod vnějšími hradbami – navedení k nejbližší otevřené bráně
	if my_pos.z > 26.5:
		return Vector3(0.0, 0.0, 23.5) # Jižní hlavní brána
	elif my_pos.x > 29.5:
		return Vector3(27.0, 0.0, 3.5) # Východní obchodní brána
	elif my_pos.x < -27.5:
		return Vector3(-25.5, 0.0, -2.5) # Západní výpadová branka
	elif my_pos.z < -24.5:
		return Vector3(0.0, 0.0, -21.0) # Severní brána svatyně
		
	# 2. Hráč je nahoře na věži (Y > 1.4)
	if p_pos.y > 1.4:
		# Pokud už je kostlivec nahoře na platformě věže
		if my_pos.y > 1.8:
			return p_pos
			
		# Pokud je na schodech – běží přímo nahoru
		if abs(my_pos.x) < 1.8 and my_pos.z <= 5.5 and my_pos.z >= 0.0:
			return STAIRS_TOP
			
		# Pokud je za věží na severu (Z < 2.5) – musí věž obejít z východu nebo západu
		if my_pos.z < 2.5:
			var bypass_x = 5.8 if my_pos.x >= 0.0 else -5.8
			var bypass_corner = Vector3(bypass_x, 0.0, 4.2)
			if my_pos.distance_to(bypass_corner) < 1.5:
				return STAIRS_BOTTOM
			return bypass_corner
			
		# Na jižní straně nádvoří – běží přímo k patě schodů
		return STAIRS_BOTTOM
		
	# 3. Hráč je dole na zemi
	# Pokud je kostlivec nahoře na věži nebo na schodišti:
	if my_pos.y > 0.5 and my_pos.z < 5.2:
		# Pokud je ještě na platformě věže (za schody), navedeme ho nejprve do ústí schodů
		if abs(my_pos.x) > 1.2 or my_pos.z < 0.2:
			return STAIRS_TOP
		# Již je v ústí schodů nebo na schodech -> seběhne rovně po schodech na zem
		return STAIRS_BOTTOM
		
	# Pokud věž blokuje přímou linii na hráče
	var blocks_tower = false
	if (my_pos.z < -2.0 and p_pos.z > 2.0) or (my_pos.z > 2.0 and p_pos.z < -2.0):
		if abs(my_pos.x) < 4.5 or abs(p_pos.x) < 4.5:
			blocks_tower = true
			
	if blocks_tower:
		var flank_x = 5.8 if my_pos.x >= 0.0 else -5.8
		return Vector3(flank_x, 0.0, 0.0)
		
	return p_pos

func _navigate_to_player(_delta: float) -> void:
	var target_pos: Vector3 = get_tactical_target_pos()
	var move_direction: Vector3 = (target_pos - global_position).normalized()
	move_direction.y = 0

	# 1. Jemná separace – kostlivci se vzájemně netlačí a neucpávají brány ani schody
	var enemies = get_tree().get_nodes_in_group("enemies")
	for other in enemies:
		if other != self and is_instance_valid(other):
			var dist = global_position.distance_to(other.global_position)
			if dist < 1.3 and dist > 0.05:
				var push = (global_position - other.global_position).normalized()
				push.y = 0
				move_direction += push * ((1.3 - dist) / 1.3) * 0.5

	# 2. Striktní klouzání podél zdí a objektů – zabrání protlačení do collideru
	if is_on_wall():
		var wall_norm: Vector3 = get_wall_normal()
		wall_norm.y = 0
		if wall_norm.length_squared() > 0.01:
			wall_norm = wall_norm.normalized()
			var dot = move_direction.dot(wall_norm)
			if dot < 0.0:
				move_direction -= wall_norm * dot

	move_direction = move_direction.normalized()

	if move_direction.length() > 0.1:
		velocity.x = move_direction.x * speed
		velocity.z = move_direction.z * speed
		
		# Plynulé natočení čelem ve směru chůze
		var target_look: Vector3 = global_position + Vector3(move_direction.x, 0, move_direction.z)
		look_at(target_look, Vector3.UP)
		
		# Přehrávání smyčky chůze
		if anim_player and not anim_player.is_playing():
			anim_player.play("Walking_A")
		elif anim_player and anim_player.current_animation != "Walking_A" and anim_player.current_animation != "Hit_A":
			anim_player.play("Walking_A")

func _handle_attack(_delta: float) -> void:
	if _can_attack and is_instance_valid(player):
		_can_attack = false
		_attack_timer = attack_cooldown
		
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)

enum EnemyType { WARRIOR, SPRINTER, BRUTE }
var enemy_type: EnemyType = EnemyType.WARRIOR

func setup_archetype(type: EnemyType) -> void:
	enemy_type = type
	match type:
		EnemyType.SPRINTER:
			speed = 4.6
			max_hp = 45
			current_hp = 45
			score_value = 150
			scale = Vector3(0.85, 0.85, 0.85)
		EnemyType.BRUTE:
			speed = 2.2
			max_hp = 140
			current_hp = 140
			attack_damage = 25
			score_value = 250
			scale = Vector3(1.28, 1.28, 1.28)
		EnemyType.WARRIOR:
			speed = 3.2
			max_hp = 70
			current_hp = 70
			score_value = 100

func take_damage(amount: int, is_crit: bool = false, is_fire: bool = false, is_frost: bool = false) -> void:
	if _is_dying:
		return
		
	current_hp -= amount
	
	# 1. Zobrazení 3D létajícího čísla poškození
	_spawn_damage_number(amount, is_crit, is_fire, is_frost)
	
	# 2. Oznámení pro HUD (Hitmarker na zaměřovači)
	if is_inside_tree() and get_tree():
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("on_enemy_hit"):
			hud.on_enemy_hit(is_crit)
			
	# 3. Přehrání animace zásahu
	if anim_player and anim_player.has_animation("Hit_A") and current_hp > 0:
		anim_player.play("Hit_A")
		anim_player.queue("Walking_A")
		
	_play_hit_flash()

	if current_hp <= 0:
		die()

func _spawn_damage_number(amount: int, is_crit: bool, is_fire: bool, is_frost: bool) -> void:
	var dmg_scene = load("res://scenes/damage_number.tscn")
	if dmg_scene and is_inside_tree():
		var dmg_inst = dmg_scene.instantiate()
		get_tree().root.add_child(dmg_inst)
		dmg_inst.global_position = global_position + Vector3(randf_range(-0.3, 0.3), 1.6, randf_range(-0.3, 0.3))
		dmg_inst.setup(amount, is_crit, is_fire, is_frost)

func apply_slow(factor: float, duration: float) -> void:
	var orig_speed = speed
	speed = orig_speed * factor
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self):
		speed = orig_speed

func _play_hit_flash() -> void:
	if model_holder:
		var hit_tween: Tween = create_tween()
		hit_tween.tween_property(model_holder, "scale", Vector3(1.2, 0.85, 1.2), 0.04)
		hit_tween.tween_property(model_holder, "scale", Vector3.ONE, 0.09)

func die() -> void:
	if _is_dying:
		return
	_is_dying = true
	emit_signal("enemy_defeated", score_value)
	
	if is_inside_tree() and get_tree():
		# Oznámení pro HUD (Kill hitmarker a inkrementace komba)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("on_enemy_killed"):
			hud.on_enemy_killed()
		elif hud and hud.has_method("add_score"):
			hud.add_score(score_value)
			
		# Otřes kamery hráče při zásahu / eliminaci
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node and player_node.has_method("add_screenshake"):
			player_node.add_screenshake(0.04)

		# Vytvoření zářivého krystalu (Soul Orb)
		var orb_scene = load("res://scenes/soul_orb.tscn")
		if orb_scene:
			var orb = orb_scene.instantiate()
			get_tree().root.add_child(orb)
			orb.global_position = global_position + Vector3(0, 0.4, 0)
			orb.score_value = score_value

	var col = get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", true)

	# Bleskový rozpad na kosti a jiskry
	if death_particles:
		death_particles.emitting = true
		
	if model_holder:
		var fade_tween = create_tween()
		fade_tween.tween_property(model_holder, "scale", Vector3(1.3, 0.15, 1.3), 0.08)
		fade_tween.tween_callback(func(): model_holder.visible = false)

	await get_tree().create_timer(0.75).timeout
	queue_free()
