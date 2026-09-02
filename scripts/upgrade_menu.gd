class_name UpgradeMenu
extends Control

signal upgrade_selected(upgrade_id: String)

@onready var cards_container: HBoxContainer = $VBoxContainer/CardsContainer
@onready var card_1_btn: Button = $VBoxContainer/CardsContainer/Card1
@onready var card_2_btn: Button = $VBoxContainer/CardsContainer/Card2
@onready var card_3_btn: Button = $VBoxContainer/CardsContainer/Card3

var available_upgrades: Array[Dictionary] = [
	{
		"id": "fireball",
		"title": "🔥 FIREBALL",
		"desc": "Projectiles explode on impact, dealing AoE damage to all nearby enemies.",
		"type": "spell"
	},
	{
		"id": "chain_lightning",
		"title": "⚡ CHAIN LIGHTNING",
		"desc": "Striking an enemy unleashes an electric arc chaining up to 3 nearby foes.",
		"type": "spell"
	},
	{
		"id": "frost",
		"title": "❄️ FROST NOVA",
		"desc": "Freezes enemies, slowing their movement by 50% for 4 seconds.",
		"type": "spell"
	},
	{
		"id": "multishot",
		"title": "🏹 MULTISHOT (+1)",
		"desc": "Fires an additional magic bolt in an expanding spread with each cast.",
		"type": "weapon"
	},
	{
		"id": "haste",
		"title": "⏩ ARCANE HASTE",
		"desc": "+30% faster staff attack rate (significantly reduces cooldown).",
		"type": "weapon"
	},
	{
		"id": "crit",
		"title": "💥 CRITICAL SURGE",
		"desc": "+25% chance to land a devastating critical strike dealing 2.5× damage.",
		"type": "weapon"
	},
	{
		"id": "blink",
		"title": "💨 ARCANE BLINK",
		"desc": "Press SHIFT to instantly teleport 6 meters forward in movement direction.",
		"type": "ability"
	},
	{
		"id": "vitality",
		"title": "💖 TITAN'S VITALITY",
		"desc": "+30 Maximum Health and immediately restore HP to full.",
		"type": "health"
	}
]

var _current_choices: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	card_1_btn.pressed.connect(func(): _choose_card(0))
	card_2_btn.pressed.connect(func(): _choose_card(1))
	card_3_btn.pressed.connect(func(): _choose_card(2))
	
	# Napojení na WaveManager
	var wave_mgr = get_tree().get_first_node_in_group("wave_manager")
	if wave_mgr:
		wave_mgr.wave_completed.connect(_on_wave_completed)

func _on_wave_completed(_wave_num: int) -> void:
	# Krátká pauza 0.8s na dokončení exploze posledního monstra
	await get_tree().create_timer(0.8).timeout
	present_upgrades()

func present_upgrades() -> void:
	# Výběr 3 unikátních náhodných karet
	available_upgrades.shuffle()
	_current_choices = available_upgrades.slice(0, 3)
	
	_setup_card_button(card_1_btn, _current_choices[0])
	_setup_card_button(card_2_btn, _current_choices[1])
	_setup_card_button(card_3_btn, _current_choices[2])
	
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _setup_card_button(btn: Button, data: Dictionary) -> void:
	btn.text = data["title"] + "\n\n" + data["desc"]

func _choose_card(index: int) -> void:
	if index >= _current_choices.size():
		return
		
	var chosen = _current_choices[index]
	emit_signal("upgrade_selected", chosen["id"])
	
	# Aplikace vylepšení na hráče
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_upgrade"):
		player.apply_upgrade(chosen["id"])
		
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
