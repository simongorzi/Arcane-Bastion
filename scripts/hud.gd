class_name HUD
extends CanvasLayer

@export_group("Odkazy na prvky rozhraní")
@onready var health_bar: ProgressBar = get_node_or_null("Control/MarginContainer/VBoxContainer/HealthBar")
@onready var health_label: Label = get_node_or_null("Control/MarginContainer/VBoxContainer/HealthLabel")
@onready var score_label: Label = get_node_or_null("Control/TopBar/ScorePanel/ScoreLabel")
@onready var kill_count_label: Label = get_node_or_null("Control/TopBar/KillPanel/KillCountLabel")
@onready var wave_label: Label = get_node_or_null("Control/TopBar/WavePanel/WaveLabel")
@onready var enemy_label: Label = get_node_or_null("Control/TopBar/EnemyPanel/EnemyLabel")
@onready var banner_panel: PanelContainer = get_node_or_null("Control/BannerPanel")
@onready var banner_title: Label = get_node_or_null("Control/BannerPanel/VBox/BannerTitle")
@onready var banner_subtitle: Label = get_node_or_null("Control/BannerPanel/VBox/BannerSubtitle")

# Pause Menu
@onready var pause_panel: Control = get_node_or_null("Control/PausePanel")
@onready var resume_btn: Button = get_node_or_null("Control/PausePanel/VBox/ResumeBtn")
@onready var reset_btn: Button = get_node_or_null("Control/PausePanel/VBox/ResetBtn")
@onready var settings_btn: Button = get_node_or_null("Control/PausePanel/VBox/SettingsBtn")
@onready var quit_btn: Button = get_node_or_null("Control/PausePanel/VBox/QuitBtn")

# Settings Menu
@onready var settings_panel: Control = get_node_or_null("Control/SettingsPanel")
@onready var sens_slider: HSlider = get_node_or_null("Control/SettingsPanel/VBox/SensSlider")
@onready var sens_label: Label = get_node_or_null("Control/SettingsPanel/VBox/SensLabel")
@onready var fullscreen_check: CheckBox = get_node_or_null("Control/SettingsPanel/VBox/FullscreenCheck")
@onready var volume_slider: HSlider = get_node_or_null("Control/SettingsPanel/VBox/VolumeSlider")
@onready var back_from_settings_btn: Button = get_node_or_null("Control/SettingsPanel/VBox/BackFromSettingsBtn")

# Game Over Screen
@onready var game_over_panel: Control = get_node_or_null("Control/GameOverPanel")
@onready var final_score_label: Label = get_node_or_null("Control/GameOverPanel/VBoxContainer/FinalScoreLabel")
@onready var final_kills_label: Label = get_node_or_null("Control/GameOverPanel/VBoxContainer/FinalKillsLabel")
@onready var game_over_restart_button: Button = get_node_or_null("Control/GameOverPanel/VBoxContainer/GameOverRestartButton")
@onready var game_over_quit_button: Button = get_node_or_null("Control/GameOverPanel/VBoxContainer/GameOverQuitButton")

var score: int = 0
var kills: int = 0
var is_game_over: bool = false
var _player: Player = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud")
	
	if pause_panel:
		pause_panel.visible = false
	if settings_panel:
		settings_panel.visible = false
	if game_over_panel:
		game_over_panel.visible = false
	if banner_panel:
		banner_panel.visible = false
		
	# Zapojení tlačítek pauzy
	if resume_btn:
		resume_btn.pressed.connect(resume_game)
	if reset_btn:
		reset_btn.pressed.connect(restart_game)
	if settings_btn:
		settings_btn.pressed.connect(open_settings)
	if quit_btn:
		quit_btn.pressed.connect(quit_game)
		
	# Zapojení tlačítek nastavení
	if back_from_settings_btn:
		back_from_settings_btn.pressed.connect(back_to_pause)
	if sens_slider:
		sens_slider.value_changed.connect(_on_sens_changed)
	if fullscreen_check:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
		fullscreen_check.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_changed)

	# Zapojení tlačítek prohry
	if game_over_restart_button:
		game_over_restart_button.pressed.connect(restart_game)
	if game_over_quit_button:
		game_over_quit_button.pressed.connect(quit_game)

	# Napojení na signály hráče
	_player = get_tree().get_first_node_in_group("player") as Player
	if _player:
		connect_player(_player)
		if sens_slider:
			sens_slider.value = _player.mouse_sensitivity
		
	update_ui(100, 100)

	# Asynchronní propojení s WaveManagerem (zaručuje platnost bez ohledu na pořadí stromu)
	_connect_wave_manager()

func _connect_wave_manager() -> void:
	await get_tree().process_frame
	var wave_mgr = get_tree().get_first_node_in_group("wave_manager")
	if not wave_mgr:
		wave_mgr = get_node_or_null("../WaveManager")
	if wave_mgr:
		wave_mgr.wave_started.connect(_on_wave_started)
		wave_mgr.wave_completed.connect(_on_wave_completed)
		wave_mgr.enemy_count_changed.connect(_on_enemy_count_changed)
		wave_mgr.intermission_tick.connect(_on_intermission_tick)
		wave_mgr.zone_unlocked.connect(_on_zone_unlocked)

func _on_wave_started(wave_num: int, total_enemies: int) -> void:
	if wave_label:
		wave_label.text = "Wave: " + str(wave_num)
	if enemy_label:
		enemy_label.text = "Enemies: " + str(total_enemies)
	show_banner("✦ WAVE " + str(wave_num) + " ✦", "The undead horde approaches!")

func _on_wave_completed(wave_num: int) -> void:
	show_banner("✓ WAVE " + str(wave_num) + " COMPLETED!", "Prepare for the next onslaught...")

func _on_enemy_count_changed(remaining: int, _total: int) -> void:
	if enemy_label:
		enemy_label.text = "Enemies: " + str(remaining)

func _on_intermission_tick(seconds_left: int) -> void:
	if seconds_left > 0:
		if enemy_label:
			enemy_label.text = "Next: " + str(seconds_left) + "s"

func _on_zone_unlocked(zone_id: int) -> void:
	if zone_id == 2:
		show_banner("🏰 ZONE 2 UNLOCKED!", "The Inner Sanctum gate has opened!")

func show_banner(title: String, subtitle: String = "") -> void:
	if not banner_panel:
		return
	if banner_title:
		banner_title.text = title
	if banner_subtitle:
		banner_subtitle.text = subtitle
		
	banner_panel.visible = true
	banner_panel.modulate.a = 0.0
	banner_panel.scale = Vector2(0.85, 0.85)
	banner_panel.pivot_offset = Vector2(230, 55)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(banner_panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(banner_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.chain().tween_interval(2.6)
	tween.chain().tween_property(banner_panel, "modulate:a", 0.0, 0.45)
	tween.finished.connect(func():
		if banner_panel and banner_panel.modulate.a <= 0.05:
			banner_panel.visible = false
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_game_over:
			return
		if settings_panel and settings_panel.visible:
			back_to_pause()
			get_viewport().set_input_as_handled()
		elif pause_panel and pause_panel.visible:
			resume_game()
			get_viewport().set_input_as_handled()
		else:
			pause_game()
			get_viewport().set_input_as_handled()

func pause_game() -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if pause_panel:
		pause_panel.visible = true
	if settings_panel:
		settings_panel.visible = false

func resume_game() -> void:
	if pause_panel:
		pause_panel.visible = false
	if settings_panel:
		settings_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false

func restart_game() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func quit_game() -> void:
	get_tree().quit()

func open_settings() -> void:
	if pause_panel:
		pause_panel.visible = false
	if settings_panel:
		settings_panel.visible = true

func back_to_pause() -> void:
	if settings_panel:
		settings_panel.visible = false
	if pause_panel:
		pause_panel.visible = true

func _on_sens_changed(val: float) -> void:
	if _player:
		_player.mouse_sensitivity = val
	if sens_label:
		sens_label.text = "Mouse Sensitivity: %.4f" % val

func _on_fullscreen_toggled(button_pressed: bool) -> void:
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_volume_changed(val: float) -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus != -1:
		var db = linear_to_db(val / 100.0)
		AudioServer.set_bus_volume_db(master_bus, db)

func connect_player(player_node: Node) -> void:
	if player_node.has_signal("health_changed"):
		player_node.health_changed.connect(on_health_changed)
	if player_node.has_signal("player_died"):
		player_node.player_died.connect(on_player_died)

func on_health_changed(current_hp: int, max_hp: int) -> void:
	update_ui(current_hp, max_hp)

func add_score(amount: int) -> void:
	score += amount
	kills += 1
	if score_label:
		score_label.text = "Score: %d" % score
	if kill_count_label:
		kill_count_label.text = "Kills: %d" % kills

func update_ui(hp: int, max_hp: int) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp
	if health_label:
		health_label.text = "HP: %d / %d" % [hp, max_hp]

## Zobrazení Game Over obrazovky po zpomalení času
func on_player_died() -> void:
	is_game_over = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if final_score_label:
		final_score_label.text = "Final Score: %d" % score
	if final_kills_label:
		final_kills_label.text = "Total Kills: %d" % kills
		
	# Počkáme, až se hra zpomalí (cca 1.4 sekundy reálného času)
	await get_tree().create_timer(1.4, true, false, true).timeout
	
	if game_over_panel:
		game_over_panel.visible = true
