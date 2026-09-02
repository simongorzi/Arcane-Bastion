class_name Player
extends CharacterBody3D

## Signály pro komunikaci s HUDem
signal health_changed(current_hp: int, max_hp: int)
signal player_died()

@export_group("Pohyb hráče")
@export var speed: float = 6.0
@export var jump_velocity: float = 5.2
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 12.0

@export_group("Magická hůl & Střelba")
@export var spell_scene: PackedScene = preload("res://scenes/spell.tscn")
@export var fire_rate: float = 0.25 # Prodleva mezi výstřely v sekundách
@export var sway_amount: float = 0.02 # Intenzita pohybu zbraně při otáčení myší
@export var sway_smooth: float = 10.0 # Rychlost vyhlazení návratu hole
@export var bob_frequency: float = 8.0 # Rychlost pohupování při chůzi
@export var bob_amplitude: float = 0.02 # Výška pohupování při chůzi

@export_group("Životy hráče")
@export var max_health: int = 100
var current_health: int = 100

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapon_holder: Node3D = $Head/Camera3D/WeaponHolder
@onready var cast_point: Marker3D = $Head/Camera3D/WeaponHolder/CastPoint
@onready var staff_light: OmniLight3D = get_node_or_null("Head/Camera3D/WeaponHolder/StaffModel/StaffLight")
@onready var cast_flash: GPUParticles3D = get_node_or_null("Head/Camera3D/WeaponHolder/CastFlash")

# Interní proměnné pro animaci hole a střelbu
var _default_weapon_pos: Vector3
var _mouse_input: Vector2 = Vector2.ZERO
var _bob_timer: float = 0.0
var _pulse_timer: float = 0.0
var _can_shoot: bool = true
var _shoot_timer: float = 0.0
var _is_dead: bool = false

# Roguelite upgrady
var has_fireball: bool = false
var has_chain_lightning: bool = false
var has_frost: bool = false
var multishot_level: int = 0
var crit_chance: float = 0.0
var has_blink: bool = false
var _blink_cooldown: float = 0.0

func _ready() -> void:
	# Zamknutí a skrytí kurzoru myši pro FPS režim
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
	
	if weapon_holder:
		_default_weapon_pos = weapon_holder.position

	# Plynulá chůze po svazích a schodech nahoru i dolů bez poskakování
	floor_snap_length = 0.5
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(48.0)


func _unhandled_input(event: InputEvent) -> void:
	if _is_dead:
		return
		
	# Ovládání kamery myší
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_input = event.relative
		# Horizontální rotace (otáčí celé tělo hráče)
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Vertikální rotace (naklápí pouze hlavu/kameru s limitem 89 stupňů)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta: float) -> void:
	# 1. Gravitace
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Skok
	if is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# 3. Směr pohybu (WASD s fallbackem na UI šipky pro okamžité fungování)
	var input_dir: Vector2 = get_movement_vector()
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Bleskový úskok (Blink) na klávesu Shift
	if has_blink:
		_blink_cooldown -= delta
		if Input.is_key_pressed(KEY_SHIFT) and _blink_cooldown <= 0.0:
			_blink_cooldown = 1.4
			var dash_dir = direction if direction != Vector3.ZERO else -transform.basis.z
			velocity += dash_dir * 24.0

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# 4. Časovač střelby
	if not _can_shoot:
		_shoot_timer -= delta
		if _shoot_timer <= 0.0:
			_can_shoot = true

	# 5. Zpracování střelby kliknutím myši
	if is_action_pressed("attack") and _can_shoot:
		cast_spell()

	# 6. Procedurální animace hole (Weapon Sway a Bobbing)
	process_weapon_effects(delta, input_dir)

## Zpracování vstupních směrů pro chůzi (W, A, S, D)
func get_movement_vector() -> Vector2:
	var x: float = 0.0
	var y: float = 0.0
	
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"):
		x += 1.0
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"):
		x -= 1.0
	if Input.is_action_pressed("move_back") or Input.is_action_pressed("ui_down"):
		y += 1.0
	if Input.is_action_pressed("move_forward") or Input.is_action_pressed("ui_up"):
		y -= 1.0
		
	return Vector2(x, y).normalized()

## Pomocná funkce pro podporu akcí i běžných myších eventů
func is_action_just_pressed(action_name: String) -> bool:
	return Input.is_action_just_pressed(action_name)

func is_action_pressed(action_name: String) -> bool:
	if action_name == "attack":
		return Input.is_action_pressed("attack") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	return Input.is_action_pressed(action_name)

## Vystřelení kouzla ze špičky hole + multishot a elementární perky
func cast_spell() -> void:
	if spell_scene == null:
		push_error("Spell scene není přiřazena v Player.gd!")
		return
		
	_can_shoot = false
	_shoot_timer = fire_rate

	var spawn_pos: Vector3 = cast_point.global_position if cast_point else camera.global_position
	var base_dir: Vector3 = -camera.global_transform.basis.z.normalized()
	
	# Multishot výpočty (úhly střel)
	var angles: Array[float] = [0.0]
	if multishot_level >= 1:
		angles.append(-0.08)
		angles.append(0.08)
	if multishot_level >= 2:
		angles.append(-0.16)
		angles.append(0.16)

	for angle in angles:
		var spell_instance = spell_scene.instantiate()
		get_tree().root.add_child(spell_instance)
		spell_instance.global_position = spawn_pos
		
		# Vychýlení směru pro multishot
		var rotated_dir: Vector3 = base_dir.rotated(camera.global_transform.basis.y, angle)
		if spell_instance.has_method("setup_direction"):
			spell_instance.setup_direction(rotated_dir)
		else:
			spell_instance.look_at(spawn_pos + rotated_dir, Vector3.UP)
			
		# Předání perku do kouzla
		spell_instance.is_fireball = has_fireball
		spell_instance.is_chain_lightning = has_chain_lightning
		spell_instance.is_frost = has_frost
		if crit_chance > 0.0 and randf() < crit_chance:
			spell_instance.is_crit = true

	# Zpětný ráz hole (Recoil efekt pomocí Tween)
	play_weapon_recoil()

## Aplikace zvoleného Roguelite vylepšení
func apply_upgrade(id: String) -> void:
	match id:
		"fireball":
			has_fireball = true
		"chain_lightning":
			has_chain_lightning = true
		"frost":
			has_frost = true
		"multishot":
			multishot_level += 1
		"haste":
			fire_rate = maxf(0.12, fire_rate * 0.72)
		"crit":
			crit_chance += 0.25
		"blink":
			has_blink = true
		"vitality":
			max_health += 30
			current_health = max_health
			emit_signal("health_changed", current_health, max_health)

## Procedurální zpětný ráz hole při kouzlení
func play_weapon_recoil() -> void:
	if not weapon_holder:
		return
		
	# Částicový záblesk při výstřelu
	if cast_flash:
		cast_flash.restart()
		cast_flash.emitting = true
		
	# Záblesk magického světla na holi
	if staff_light:
		var flash_tween = create_tween()
		flash_tween.tween_property(staff_light, "light_energy", 6.5, 0.04)
		flash_tween.tween_property(staff_light, "light_energy", 2.8, 0.2)

	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Hůl cukne dozadu a mírně nahoru
	var recoil_pos: Vector3 = _default_weapon_pos + Vector3(0.02, 0.06, 0.18)
	var recoil_rot: Vector3 = Vector3(deg_to_rad(-14), deg_to_rad(6), deg_to_rad(-10))
	
	tween.tween_property(weapon_holder, "position", recoil_pos, 0.05)
	tween.parallel().tween_property(weapon_holder, "rotation", recoil_rot, 0.05)
	
	# Plynulý návrat do výchozí pozice
	tween.chain().tween_property(weapon_holder, "position", _default_weapon_pos, 0.18)
	tween.parallel().tween_property(weapon_holder, "rotation", Vector3.ZERO, 0.18)

## Procedurální sway (reakce na myš) a pohupování při chůzi
func process_weapon_effects(delta: float, input_dir: Vector2) -> void:
	if not weapon_holder:
		return
		
	# 1. Sway (hůl se mírně opožďuje za pohybem myši)
	var target_sway_pos = _default_weapon_pos
	target_sway_pos.x += clamp(-_mouse_input.x * sway_amount, -0.05, 0.05)
	target_sway_pos.y += clamp(_mouse_input.y * sway_amount, -0.05, 0.05)
	
	# Reset vstupu myši po zpracování
	_mouse_input = _mouse_input.lerp(Vector2.ZERO, delta * sway_smooth)

	# 2. Bobbing (pohupování nahoru a do stran při pohybu)
	if is_on_floor() and input_dir.length() > 0.1:
		_bob_timer += delta * bob_frequency
		target_sway_pos.y += sin(_bob_timer) * bob_amplitude
		target_sway_pos.x += cos(_bob_timer * 0.5) * bob_amplitude * 0.7
	else:
		_bob_timer = 0.0

	weapon_holder.position = weapon_holder.position.lerp(target_sway_pos, delta * sway_smooth)

	# 3. Mystická pulsace magického světla na holi
	_pulse_timer += delta * 3.5
	if staff_light and not (_shoot_timer > 0.0):
		staff_light.light_energy = 2.8 + sin(_pulse_timer) * 0.7

## Udělení poškození hráči
func take_damage(amount: int) -> void:
	current_health -= amount
	current_health = clampi(current_health, 0, max_health)
	emit_signal("health_changed", current_health, max_health)
	
	# Drobný otřes kamery při zásahu
	var cam_tween: Tween = create_tween()
	cam_tween.tween_property(camera, "rotation:z", deg_to_rad(randf_range(-3, 3)), 0.05)
	cam_tween.tween_property(camera, "rotation:z", 0.0, 0.1)

	if current_health <= 0 and not _is_dead:
		_is_dead = true
		emit_signal("player_died")
		
		# Pád na zem a zpomalení času do úplného zastavení
		var death_tween = create_tween().set_parallel(true).set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		death_tween.tween_property(head, "position:y", 0.4, 1.2)
		death_tween.tween_property(camera, "rotation:z", deg_to_rad(-40), 1.2)
		
		# Plynulé zpomalení Engine.time_scale až do zastavení
		var time_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		time_tween.tween_method(func(val: float): Engine.time_scale = val, 1.0, 0.05, 1.4)
		time_tween.tween_callback(func(): Engine.time_scale = 0.0)
