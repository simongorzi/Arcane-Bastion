class_name WaveManager
extends Node

signal wave_started(wave_number: int, total_enemies: int)
signal wave_completed(wave_number: int)
signal enemy_count_changed(remaining: int, total_wave_enemies: int)
signal intermission_tick(seconds_left: int)
signal zone_unlocked(zone_id: int)

@export_group("Nastavení Vln")
@export var total_waves: int = 10
@export var intermission_duration: float = 6.0

var current_wave: int = 0
var enemies_to_spawn_this_wave: int = 0
var enemies_spawned_so_far: int = 0
var active_enemies_count: int = 0
var is_wave_active: bool = false
var is_intermission: bool = false
var intermission_timer: float = 0.0

@onready var spawner: Node = get_node_or_null("../Spawner")

func _enter_tree() -> void:
	add_to_group("wave_manager")

func _ready() -> void:
	add_to_group("wave_manager")
	await get_tree().process_frame
	await get_tree().create_timer(1.2).timeout
	start_next_wave()

func _process(delta: float) -> void:
	if is_intermission:
		intermission_timer -= delta
		emit_signal("intermission_tick", int(ceil(intermission_timer)))
		if intermission_timer <= 0.0:
			is_intermission = false
			start_next_wave()

## Zahájení nové vlny
func start_next_wave() -> void:
	current_wave += 1
	is_wave_active = true
	is_intermission = false
	
	# Výpočet počtu nepřátel pro vlnu (Vlna 1 = 18, Vlna 2 = 24, Vlna 3 = 30, Vlna 4 = 36...)
	enemies_to_spawn_this_wave = 12 + current_wave * 6
	enemies_spawned_so_far = 0
	active_enemies_count = 0
	
	emit_signal("wave_started", current_wave, enemies_to_spawn_this_wave)
	emit_signal("enemy_count_changed", enemies_to_spawn_this_wave, enemies_to_spawn_this_wave)
	
	# Konfigurace spawneru
	if spawner:
		spawner.spawn_interval = maxf(2.0, 3.8 - current_wave * 0.2)
		if spawner.get("timer"):
			spawner.timer.wait_time = spawner.spawn_interval
			spawner.timer.start()
		if spawner.has_method("spawn_wave"):
			spawner.spawn_wave()

## Volá Spawner při každém vytvoření nepřítele
func notify_enemy_spawned(enemy: Monster) -> void:
	enemies_spawned_so_far += 1
	active_enemies_count += 1
	
	# Zvýšení obtížnosti podle čísla vlny
	if current_wave >= 4:
		enemy.speed = 3.2 + (current_wave - 3) * 0.15
		enemy.max_hp = int(70 * (1.0 + (current_wave - 3) * 0.2))
		enemy.current_hp = enemy.max_hp
		
	# Propojení signálu porážky nepřítele
	enemy.enemy_defeated.connect(_on_enemy_defeated)
	
	# Zastavení spawneru, jakmile jsou vygenerováni všichni nepřátelé dané vlny
	if enemies_spawned_so_far >= enemies_to_spawn_this_wave:
		if spawner and spawner.timer:
			spawner.timer.stop()

## Volá se při zabití nepřítele
func _on_enemy_defeated(_score_value: int) -> void:
	active_enemies_count = max(0, active_enemies_count - 1)
	var remaining_total = (enemies_to_spawn_this_wave - enemies_spawned_so_far) + active_enemies_count
	emit_signal("enemy_count_changed", remaining_total, enemies_to_spawn_this_wave)
	
	# Kontrola dokončení vlny
	if enemies_spawned_so_far >= enemies_to_spawn_this_wave and active_enemies_count == 0:
		_complete_current_wave()

## Vlna úspěšně dokončena
func _complete_current_wave() -> void:
	is_wave_active = false
	emit_signal("wave_completed", current_wave)
	
	# Odemknutí Zóny 2 (Vnitřní svatyně) po poražení Vlny 3!
	if current_wave == 3:
		emit_signal("zone_unlocked", 2)
	# Odemknutí Zóny 3 po poražení Vlny 7!
	elif current_wave == 7:
		emit_signal("zone_unlocked", 3)
		
	# Zahájení odpočinku a výběru karet
	is_intermission = true
	intermission_timer = intermission_duration
