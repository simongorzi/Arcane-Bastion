extends Node3D

## Kompletní procedurální stavba Varianty B: Hradní Příkop, Most a Obrana Hradní Brány
func _ready() -> void:
	_build_variant_b_citadel()
	_setup_build_manager()

func _setup_build_manager() -> void:
	var existing = get_node_or_null("BuildManager")
	if not existing:
		var bm_script = load("res://scripts/build_manager.gd")
		if bm_script:
			var bm = bm_script.new()
			bm.name = "BuildManager"
			add_child(bm)

func _build_variant_b_citadel() -> void:
	var citadel_node = get_node_or_null("Environment/Citadel")
	if not citadel_node:
		citadel_node = Node3D.new()
		citadel_node.name = "Citadel"
		var env = get_node_or_null("Environment")
		if env:
			env.add_child(citadel_node)
		else:
			add_child(citadel_node)

	for child in citadel_node.get_children():
		child.queue_free()

	_build_fortress_gate_and_walls(citadel_node)
	_build_moat_and_stone_bridge(citadel_node)
	_build_winding_approach_road(citadel_node)
	_build_spawn_portal(citadel_node)
	_build_flanking_watchtowers_and_cliffs(citadel_node)
	_build_atmospheric_torches(citadel_node)

## 1. Hlavní Hradní Brána a Hradby (Z = -16)
func _build_fortress_gate_and_walls(parent: Node3D) -> void:
	var gate_scene = load("res://scenes/gate.tscn")
	if gate_scene:
		var gate = gate_scene.instantiate()
		parent.add_child(gate)
		gate.position = Vector3(0, 0, -16.0)

	var wall_path = "res://assets/castle/Models/GLB format/wall.glb"
	var tower_path = "res://assets/castle/Models/GLB format/tower-square.glb"
	var roof_path = "res://assets/castle/Models/GLB format/tower-square-roof.glb"

	# Západní křídlo hradeb
	var west_walls = [
		Vector3(-9.5, 0, -16.0),
		Vector3(-14.0, 0, -16.0),
		Vector3(-18.5, 0, -16.0),
		Vector3(-23.0, 0, -16.0)
	]
	for p in west_walls:
		_place_prop(parent, wall_path, p, 0.0, Vector3(2.2, 2.2, 2.2), Vector3(4.5, 5.5, 1.8))
	_place_tower_with_roof(parent, tower_path, roof_path, Vector3(-27.5, 0, -16.0), 45.0)

	# Východní křídlo hradeb
	var east_walls = [
		Vector3(9.5, 0, -16.0),
		Vector3(14.0, 0, -16.0),
		Vector3(18.5, 0, -16.0),
		Vector3(23.0, 0, -16.0)
	]
	for p in east_walls:
		_place_prop(parent, wall_path, p, 0.0, Vector3(2.2, 2.2, 2.2), Vector3(4.5, 5.5, 1.8))
	_place_tower_with_roof(parent, tower_path, roof_path, Vector3(27.5, 0, -16.0), -45.0)

## 2. Hradní Příkop a Kamenný Most (Z = 2 až Z = -10)
func _build_moat_and_stone_bridge(parent: Node3D) -> void:
	var bridge_path = "res://assets/castle/Models/GLB format/bridge-straight.glb"
	
	# Kamenný klenutý most přes příkop
	_place_prop(parent, bridge_path, Vector3(0, 0, 0.0), 0.0, Vector3(2.2, 2.2, 2.2), Vector3(5.5, 2.0, 6.0))
	_place_prop(parent, bridge_path, Vector3(0, 0, -6.0), 0.0, Vector3(2.2, 2.2, 2.2), Vector3(5.5, 2.0, 6.0))

	# Voda v hradním příkopu (temná azurová vodní plocha)
	var water = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(70, 16)
	water.mesh = plane
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.04, 0.15, 0.22, 0.85)
	mat.roughness = 0.1
	mat.metallic = 0.8
	water.material_override = mat
	parent.add_child(water)
	water.position = Vector3(0, -2.4, -3.0)

## 3. Klikatá S-Cesta pro monstra a dláždění
func _build_winding_approach_road(parent: Node3D) -> void:
	var waypoints = [
		Vector3(0, 0, 48),    # Spawn Portal
		Vector3(-4, 0, 44),
		Vector3(-10, 0, 40),
		Vector3(-14, 0, 36),  # West apex
		Vector3(-10, 0, 31),
		Vector3(0, 0, 26),
		Vector3(8, 0, 23),
		Vector3(12, 0, 19),   # East apex
		Vector3(8, 0, 14),
		Vector3(2, 0, 10),
		Vector3(0, 0, 6),     # Bridge entrance
		Vector3(0, 0, -2),    # Bridge center
		Vector3(0, 0, -10),   # Gate approach
		Vector3(0, 0, -15)    # Gate hitzone
	]

	# Vytvoření dlážděné silnice podél bodů
	var rock_path = "res://assets/castle/Models/GLB format/rocks-small.glb"
	for i in range(waypoints.size() - 1):
		var p1 = waypoints[i]
		var p2 = waypoints[i+1]
		var mid = (p1 + p2) * 0.5
		var dir = (p2 - p1).normalized()
		var len_segment = p1.distance_to(p2)
		
		# Kamenné desky silnice
		var road_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(5.0, 0.1, len_segment + 0.5)
		road_mesh.mesh = box
		var road_mat = StandardMaterial3D.new()
		road_mat.albedo_color = Color(0.28, 0.3, 0.32)
		road_mat.roughness = 0.85
		road_mesh.material_override = road_mat
		parent.add_child(road_mesh)
		road_mesh.position = mid + Vector3(0, 0.05, 0)
		var yaw = atan2(dir.x, dir.z)
		road_mesh.rotation.y = yaw

		# Postranní kameny lemující silnici
		var side_perp = Vector3(-dir.z, 0, dir.x) * 3.0
		_place_prop(parent, rock_path, mid + side_perp, 0.0, Vector3(1.2, 1.2, 1.2), Vector3.ZERO)
		_place_prop(parent, rock_path, mid - side_perp, 180.0, Vector3(1.2, 1.2, 1.2), Vector3.ZERO)

## 4. Temný Magický Portál Spawnů (Z = 48)
func _build_spawn_portal(parent: Node3D) -> void:
	var arch_path = "res://assets/fantasy-town/Models/GLB format/wall-arch.glb"
	_place_prop(parent, arch_path, Vector3(0, 0, 49), 0.0, Vector3(3.0, 3.2, 3.0), Vector3(5.0, 5.0, 1.5))
	
	# Zářící portálová plocha
	var portal_core = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(3.5, 4.5)
	portal_core.mesh = quad
	var pmat = StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.albedo_color = Color(0.6, 0.15, 0.9, 0.9)
	portal_core.material_override = pmat
	parent.add_child(portal_core)
	portal_core.position = Vector3(0, 2.2, 49.0)

	var portal_light = OmniLight3D.new()
	parent.add_child(portal_light)
	portal_light.position = Vector3(0, 2.5, 47.5)
	portal_light.light_color = Color(0.7, 0.2, 1.0)
	portal_light.light_energy = 4.0
	portal_light.omni_range = 10.0

## 5. Strážní Bašty a Skály podél cesty pro stavbu věží
func _build_flanking_watchtowers_and_cliffs(parent: Node3D) -> void:
	var rock_large = "res://assets/castle/Models/GLB format/rocks-large.glb"
	var tower_path = "res://assets/castle/Models/GLB format/tower-square.glb"
	var roof_path = "res://assets/castle/Models/GLB format/tower-square-roof.glb"
	var tree_path = "res://assets/castle/Models/GLB format/tree-large.glb"

	# Skalní masiv u západní zatáčky (Z = 36)
	_place_prop(parent, rock_large, Vector3(-22.0, 0, 36.0), 30.0, Vector3(2.5, 2.5, 2.5), Vector3(6, 6, 6))
	_place_prop(parent, tree_path, Vector3(-20.0, 0, 42.0), 0.0, Vector3(2.0, 2.0, 2.0), Vector3.ZERO)

	# Skalní masiv a vyvýšená bašta u východní zatáčky (Z = 20)
	_place_prop(parent, rock_large, Vector3(20.0, 0, 20.0), -45.0, Vector3(2.5, 2.5, 2.5), Vector3(6, 6, 6))
	_place_tower_with_roof(parent, tower_path, roof_path, Vector3(18.0, 0, 25.0), -30.0)
	_place_prop(parent, tree_path, Vector3(22.0, 0, 14.0), 0.0, Vector3(2.0, 2.0, 2.0), Vector3.ZERO)

	# Předsunutá strážní věž u vstupu na most
	_place_tower_with_roof(parent, tower_path, roof_path, Vector3(-6.5, 0, 6.0), 45.0)
	_place_tower_with_roof(parent, tower_path, roof_path, Vector3(6.5, 0, 6.0), -45.0)

## 6. Louče podél trasy
func _build_atmospheric_torches(parent: Node3D) -> void:
	_create_torch(parent, Vector3(-4.8, 3.8, -14.5), Color(1.0, 0.7, 0.3), 3.5, 8.0)
	_create_torch(parent, Vector3(4.8, 3.8, -14.5), Color(1.0, 0.7, 0.3), 3.5, 8.0)
	_create_torch(parent, Vector3(-6.5, 3.5, 6.0), Color(1.0, 0.65, 0.25), 3.0, 7.0)
	_create_torch(parent, Vector3(6.5, 3.5, 6.0), Color(1.0, 0.65, 0.25), 3.0, 7.0)
	_create_torch(parent, Vector3(0, 3.5, 47.0), Color(0.7, 0.3, 1.0), 3.2, 8.0)

# --- Pomocné funkce ---

func _place_tower_with_roof(parent: Node3D, tower_path: String, roof_path: String, pos: Vector3, rot_y_deg: float) -> void:
	_place_prop(parent, tower_path, pos, rot_y_deg, Vector3(2.2, 2.2, 2.2), Vector3(3.8, 5.0, 3.8))
	if ResourceLoader.exists(roof_path):
		_place_prop(parent, roof_path, pos + Vector3(0, 3.42, 0), rot_y_deg, Vector3(2.25, 2.25, 2.25), Vector3.ZERO)

func _place_prop(parent: Node3D, res_path: String, pos: Vector3, rot_y_deg: float, scale_vec: Vector3, col_box_size: Vector3) -> void:
	if not ResourceLoader.exists(res_path):
		return
	var res = load(res_path)
	if not res:
		return
	var inst = res.instantiate()
	parent.add_child(inst)
	inst.position = pos
	inst.rotation_degrees = Vector3(0, rot_y_deg, 0)
	inst.scale = scale_vec

	if col_box_size != Vector3.ZERO:
		var sb = StaticBody3D.new()
		sb.collision_layer = 1
		sb.collision_mask = 7
		parent.add_child(sb)
		sb.position = pos + Vector3(0, col_box_size.y * 0.5, 0)
		sb.rotation_degrees = Vector3(0, rot_y_deg, 0)

		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = col_box_size
		col.shape = box
		sb.add_child(col)

func _create_torch(parent: Node3D, pos: Vector3, light_color: Color, energy: float, light_range: float) -> void:
	var light = OmniLight3D.new()
	parent.add_child(light)
	light.position = pos
	light.light_color = light_color
	light.light_energy = energy
	light.omni_range = light_range
	light.shadow_enabled = true
	
	var tween = create_tween().set_loops()
	tween.tween_property(light, "light_energy", energy * 0.85, 0.12 + randf() * 0.08)
	tween.tween_property(light, "light_energy", energy * 1.15, 0.14 + randf() * 0.08)
	tween.tween_property(light, "light_energy", energy, 0.1 + randf() * 0.08)
