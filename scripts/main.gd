extends Node3D

## Automatické sestavení středověkého nádvoří z Kenneyho Castle Kitu
func _ready() -> void:
	_setup_castle_environment()

func _setup_castle_environment() -> void:
	var wall_path = "res://assets/castle/Models/GLB format/wall.glb"
	var tower_path = "res://assets/castle/Models/GLB format/tower-square.glb"
	var gate_path = "res://assets/castle/Models/GLB format/gate.glb"
	
	if not ResourceLoader.exists(wall_path):
		return
		
	var wall_res = load(wall_path)
	var tower_res = load(tower_path) if ResourceLoader.exists(tower_path) else null
	var gate_res = load(gate_path) if ResourceLoader.exists(gate_path) else null
	
	var castle_node = get_node_or_null("Environment/CastleWalls")
	if not castle_node or not wall_res:
		return
		
	# Odstraníme jednoduché zástupné kostky
	for child in castle_node.get_children():
		child.queue_free()
		
	var wall_length: float = 4.0 # Modulární velikost zdi
	var half_size: float = 12.0
	
	# Rohové věže
	if tower_res:
		var corners = [
			Vector3(-half_size, 0, -half_size),
			Vector3(half_size, 0, -half_size),
			Vector3(-half_size, 0, half_size),
			Vector3(half_size, 0, half_size)
		]
		for c_pos in corners:
			var tower = tower_res.instantiate()
			castle_node.add_child(tower)
			tower.position = c_pos
			tower.scale = Vector3(2.0, 2.0, 2.0)
			
	# Severní zeď
	for x in range(-2, 3):
		var wall = wall_res.instantiate()
		castle_node.add_child(wall)
		wall.position = Vector3(x * wall_length, 0, -half_size)
		wall.scale = Vector3(2.0, 2.0, 2.0)
		
	# Východní zeď
	for z in range(-2, 3):
		var wall = wall_res.instantiate()
		castle_node.add_child(wall)
		wall.position = Vector3(half_size, 0, z * wall_length)
		wall.rotation_degrees = Vector3(0, 90, 0)
		wall.scale = Vector3(2.0, 2.0, 2.0)
		
	# Západní zeď
	for z in range(-2, 3):
		var wall = wall_res.instantiate()
		castle_node.add_child(wall)
		wall.position = Vector3(-half_size, 0, z * wall_length)
		wall.rotation_degrees = Vector3(0, -90, 0)
		wall.scale = Vector3(2.0, 2.0, 2.0)
		
	# Jižní strana s branou
	for x in [-2, -1, 1, 2]:
		var wall = wall_res.instantiate()
		castle_node.add_child(wall)
		wall.position = Vector3(x * wall_length, 0, half_size)
		wall.rotation_degrees = Vector3(0, 180, 0)
		wall.scale = Vector3(2.0, 2.0, 2.0)
		
	if gate_res:
		var gate = gate_res.instantiate()
		castle_node.add_child(gate)
		gate.position = Vector3(0, 0, half_size)
		gate.rotation_degrees = Vector3(0, 180, 0)
		gate.scale = Vector3(2.0, 2.0, 2.0)
