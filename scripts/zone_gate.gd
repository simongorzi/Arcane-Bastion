class_name ZoneGate
extends Node3D

@export var zone_id: int = 2
@export var open_height: float = 5.2
@export var open_duration: float = 2.8

@onready var gate_mesh: Node3D = $GateMesh
@onready var col_shape: CollisionShape3D = $StaticBody3D/CollisionShape3D
@onready var open_sound: AudioStreamPlayer3D = get_node_or_null("OpenSound")
@onready var dust_particles: GPUParticles3D = get_node_or_null("DustParticles")

var _is_open: bool = false

func _ready() -> void:
	# Napojení na WaveManager
	var wave_mgr = get_tree().get_first_node_in_group("wave_manager")
	if wave_mgr:
		wave_mgr.zone_unlocked.connect(_on_zone_unlocked)

func _on_zone_unlocked(unlocked_zone_id: int) -> void:
	if unlocked_zone_id == zone_id and not _is_open:
		open_gate()

## Plynulé otevření padací mříže
func open_gate() -> void:
	_is_open = true
	
	# Aktivace prachových částic
	if dust_particles:
		dust_particles.emitting = true
		
	# Zvuk otevírání
	if open_sound:
		open_sound.play()
		
	# Otřes kamery hráče
	var player = get_tree().get_first_node_in_group("player")
	if player and player.camera:
		var cam_tween = create_tween()
		for i in range(12):
			var shake_offset = Vector3(randf_range(-0.08, 0.08), randf_range(-0.08, 0.08), 0)
			cam_tween.tween_property(player.camera, "position", player.camera.position + shake_offset, 0.05)
		cam_tween.tween_property(player.camera, "position", Vector3.ZERO, 0.1)

	# Zvednutí brány nahoru
	var tween = create_tween()
	tween.tween_property(gate_mesh, "position:y", gate_mesh.position.y + open_height, open_duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		
	# Deaktivace kolize po zvednutí
	tween.finished.connect(func():
		if col_shape:
			col_shape.disabled = true
	)
