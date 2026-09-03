class_name Spawner
extends Node3D

@export_group("Nastavení Spawneru")
@export var monster_scene: PackedScene = preload("res://scenes/monster.tscn")
@export var spawn_interval: float = 5.0 # Každých 5 sekund
@export var max_active_monsters: int = 25
@export var auto_start: bool = true

# Odkazy na poduzly
@onready var timer: Timer = $Timer
@onready var spawn_points_container: Node3D = get_node_or_null("SpawnPoints")

var _spawn_points: Array[Node3D] = []

func _ready() -> void:
	# Shromáždění všech Marker3D bodů určených pro spawn
	_gather_spawn_points()
	
	# Příprava časovače
	if not timer:
		timer = Timer.new()
		add_child(timer)
		
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	
	if auto_start:
		timer.start()

	_connect_wave_manager()

func _connect_wave_manager() -> void:
	await get_tree().process_frame
	var wave_mgr = get_tree().get_first_node_in_group("wave_manager")
	if not wave_mgr:
		wave_mgr = get_node_or_null("../WaveManager")
	if wave_mgr:
		wave_mgr.zone_unlocked.connect(_on_zone_unlocked)

func _on_zone_unlocked(zone_id: int) -> void:
	# Severní spawn se odemkne až po otevření mříže Zóny 2 (Vlna 4+)
	if zone_id == 2 and spawn_points_container:
		var north_pt = spawn_points_container.get_node_or_null("SpawnPoint_North")
		if north_pt and not _spawn_points.has(north_pt):
			_spawn_points.append(north_pt)

func _gather_spawn_points() -> void:
	_spawn_points.clear()
	if spawn_points_container:
		for child in spawn_points_container.get_children():
			if child is Node3D:
				# SpawnPoint_North je za mříží – neaktivní pro Vlny 1–3
				if child.name == "SpawnPoint_North":
					continue
				_spawn_points.append(child)
				
	# Pokud nejsou definovány explicitní body v poduzlu, použijeme pozici samotného Spawneru
	if _spawn_points.is_empty():
		_spawn_points.append(self)

@export var pack_size_min: int = 3
@export var pack_size_max: int = 5

func _on_timer_timeout() -> void:
	spawn_wave()

## Vygeneruje útočnou smečku monster ve formaci
func spawn_wave() -> void:
	if monster_scene == null or _spawn_points.is_empty():
		return

	var wave_mgr = get_tree().get_first_node_in_group("wave_manager")
	var remaining_in_wave = 999
	if wave_mgr:
		if not wave_mgr.is_wave_active:
			return
		remaining_in_wave = wave_mgr.enemies_to_spawn_this_wave - wave_mgr.enemies_spawned_so_far
		if remaining_in_wave <= 0:
			return

	var current_enemies = get_tree().get_nodes_in_group("enemies")
	var capacity = max_active_monsters - current_enemies.size()
	if capacity <= 0:
		return

	# Určení velikosti smečky pro tento útok
	var count_to_spawn = clampi(randi_range(pack_size_min, pack_size_max), 1, min(remaining_in_wave, capacity))
	var chosen_point: Node3D = _spawn_points.pick_random()
	var spawn_pos: Vector3 = chosen_point.global_position

	for i in range(count_to_spawn):
		var monster_instance: Monster = monster_scene.instantiate()
		get_tree().root.add_child(monster_instance)
		
		# Rozmístění ve formaci okolo brány
		var formation_offset = Vector3(
			randf_range(-2.4, 2.4),
			0,
			randf_range(-2.4, 2.4)
		)
		monster_instance.global_position = spawn_pos + formation_offset
		
		# Výběr archetypu nepřítele (Sprinter, Brute, Warrior)
		var roll = randf()
		if roll < 0.22:
			monster_instance.setup_archetype(Monster.EnemyType.SPRINTER)
		elif roll < 0.40:
			monster_instance.setup_archetype(Monster.EnemyType.BRUTE)
		else:
			monster_instance.setup_archetype(Monster.EnemyType.WARRIOR)

		if wave_mgr:
			wave_mgr.notify_enemy_spawned(monster_instance)
