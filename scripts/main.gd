extends Node3D

## Kompletní procedurální stavba Velké Organické Pevnosti (The Grand Organic Citadel)
func _ready() -> void:
	_build_organic_citadel()

func _build_organic_citadel() -> void:
	var citadel_node = get_node_or_null("Environment/Citadel")
	if not citadel_node:
		citadel_node = Node3D.new()
		citadel_node.name = "Citadel"
		var env = get_node_or_null("Environment")
		if env:
			env.add_child(citadel_node)
		else:
			add_child(citadel_node)

	# Vyčištění případných předchozích dynamických prvků
	for child in citadel_node.get_children():
		child.queue_free()

	_build_perimeter_walls(citadel_node)
	_build_market_quarter(citadel_node)
	_build_military_armory(citadel_node)
	_build_central_plaza(citadel_node)
	_build_high_sanctum(citadel_node)
	_build_torch_network(citadel_node)

## 1. Asymetrické vnější hradby a brány (obvod cca 60m x 60m)
func _build_perimeter_walls(parent: Node3D) -> void:
	var wall_path = "res://assets/castle/Models/GLB format/wall.glb"
	var tower_path = "res://assets/castle/Models/GLB format/tower-square.glb"
	var roof_path = "res://assets/castle/Models/GLB format/tower-square-roof.glb"
	var gate_path = "res://assets/castle/Models/GLB format/gate.glb"
	var banner_path = "res://assets/castle/Models/GLB format/flag-banner-long.glb"

	# A. JIŽNÍ PŘEDBRANÍ & BRÁNA (Z = 26)
	_place_prop(parent, gate_path, Vector3(0, 0, 26), 180.0, Vector3(2.2, 2.2, 2.2), Vector3.ZERO)
	# Dvě strážní věže brány
	_place_tower_with_roof(parent, tower_path, roof_path, banner_path, Vector3(-5.2, 0, 26), 180.0)
	_place_tower_with_roof(parent, tower_path, roof_path, banner_path, Vector3(5.2, 0, 26), 180.0)

	# Jihozápadní hradba (mírný náklon směrem k baště)
	var sw_positions = [
		Vector3(-9.2, 0, 25.8),
		Vector3(-13.2, 0, 25.4),
		Vector3(-17.2, 0, 24.6),
		Vector3(-21.0, 0, 23.5)
	]
	for p in sw_positions:
		_place_wall_segment(parent, wall_path, p, 185.0)

	# Jihozápadní rohová bašta
	_place_tower_with_roof(parent, tower_path, roof_path, banner_path, Vector3(-25.0, 0, 22.0), 135.0)

	# Jihovýchodní hradba
	var se_positions = [
		Vector3(9.2, 0, 25.8),
		Vector3(13.2, 0, 25.4),
		Vector3(17.2, 0, 24.6),
		Vector3(21.2, 0, 23.2),
		Vector3(25.0, 0, 21.5)
	]
	for p in se_positions:
		_place_wall_segment(parent, wall_path, p, 175.0)

	# Jihovýchodní rohová věž
	_place_tower_with_roof(parent, tower_path, roof_path, banner_path, Vector3(28.5, 0, 19.5), -135.0)

	# B. VÝCHODNÍ HRADBA & OBCHODNÍ BRÁNA (X = 30)
	var e_south_positions = [
		Vector3(29.2, 0, 15.5),
		Vector3(29.8, 0, 11.5),
		Vector3(30.2, 0, 7.5)
	]
	for p in e_south_positions:
		_place_wall_segment(parent, wall_path, p, 90.0)

	# Východní brána s předsunutou věží
	_place_prop(parent, gate_path, Vector3(30.5, 0, 3.5), 90.0, Vector3(2.0, 2.0, 2.0), Vector3.ZERO)
	_place_tower_with_roof(parent, tower_path, roof_path, banner_path, Vector3(32.5, 0, 7.5), 90.0)

	var e_north_positions = [
		Vector3(30.2, 0, -0.5),
		Vector3(29.8, 0, -4.5),
		Vector3(29.2, 0, -8.5),
		Vector3(28.5, 0, -12.5),
		Vector3(27.8, 0, -16.5)
	]
	for p in e_north_positions:
		_place_wall_segment(parent, wall_path, p, 90.0)

	# Severovýchodní bašta
	_place_tower_with_roof(parent, tower_path, roof_path, banner_path, Vector3(26.5, 0, -21.0), -45.0)

	# C. ZÁPADNÍ HRADBA & VOJENSKÁ BRANKA (X = -28)
	var w_south_positions = [
		Vector3(-25.8, 0, 18.0),
		Vector3(-26.8, 0, 14.0),
		Vector3(-27.8, 0, 10.0),
		Vector3(-28.5, 0, 6.0),
		Vector3(-29.0, 0, 2.0)
	]
	for p in w_south_positions:
		_place_wall_segment(parent, wall_path, p, -90.0)

	# Západní výpadová branka (Sally Port)
	_place_prop(parent, gate_path, Vector3(-29.2, 0, -2.5), -90.0, Vector3(2.0, 2.0, 2.0), Vector3.ZERO)
	_place_tower_with_roof(parent, tower_path, roof_path, banner_path, Vector3(-31.0, 0, 1.5), -90.0)

	var w_north_positions = [
		Vector3(-29.0, 0, -6.5),
		Vector3(-28.5, 0, -10.5),
		Vector3(-28.0, 0, -14.5),
		Vector3(-27.5, 0, -18.5)
	]
	for p in w_north_positions:
		_place_wall_segment(parent, wall_path, p, -90.0)

	# Severozápadní rohová bašta
	_place_tower_with_roof(parent, tower_path, roof_path, banner_path, Vector3(-26.5, 0, -22.5), 45.0)

	# D. SEVERNÍ HRADBY SPOJUJÍCÍ CHRÁMOVÉ NÁDVORÍ
	var n_west_walls = [
		Vector3(-22.5, 0, -22.5),
		Vector3(-18.5, 0, -22.5),
		Vector3(-14.5, 0, -22.5)
	]
	for p in n_west_walls:
		_place_wall_segment(parent, wall_path, p, 0.0)

	var n_east_walls = [
		Vector3(14.5, 0, -21.8),
		Vector3(18.5, 0, -21.8),
		Vector3(22.5, 0, -21.8)
	]
	for p in n_east_walls:
		_place_wall_segment(parent, wall_path, p, 0.0)

## 2. Východní Tržnice (The Lower Bazaar)
func _build_market_quarter(parent: Node3D) -> void:
	var stall_red = "res://assets/fantasy-town/Models/GLB format/stall-red.glb"
	var stall_green = "res://assets/fantasy-town/Models/GLB format/stall-green.glb"
	var stall_plain = "res://assets/fantasy-town/Models/GLB format/stall.glb"
	var cart_path = "res://assets/fantasy-town/Models/GLB format/cart.glb"
	var cart_high = "res://assets/fantasy-town/Models/GLB format/cart-high.glb"
	var barrel_path = "res://assets/pirate-kit/Models/GLB format/barrel.glb"
	var crate_path = "res://assets/pirate-kit/Models/GLB format/crate.glb"

	# Stánky rozestavěné podél oblouku cesty
	_place_prop(parent, stall_red, Vector3(12.0, 0, 12.0), -20.0, Vector3(1.8, 1.8, 1.8), Vector3(2.2, 2.0, 2.0))
	_place_prop(parent, stall_green, Vector3(17.5, 0, 9.5), -45.0, Vector3(1.8, 1.8, 1.8), Vector3(2.2, 2.0, 2.0))
	_place_prop(parent, stall_plain, Vector3(15.0, 0, 16.0), 30.0, Vector3(1.8, 1.8, 1.8), Vector3(2.2, 2.0, 2.0))
	_place_prop(parent, stall_red, Vector3(21.0, 0, 13.0), -60.0, Vector3(1.8, 1.8, 1.8), Vector3(2.2, 2.0, 2.0))

	# Obchodnické povozy
	_place_prop(parent, cart_path, Vector3(9.5, 0, 17.5), 65.0, Vector3(1.6, 1.6, 1.6), Vector3(2.4, 1.4, 1.6))
	_place_prop(parent, cart_high, Vector3(21.5, 0, 5.5), 10.0, Vector3(1.6, 1.6, 1.6), Vector3(2.2, 1.8, 1.6))

	# Hromady sudů a beden tvořící přirozené krytí a uličky
	_place_barrel_stack(parent, barrel_path, crate_path, Vector3(15.0, 0, 4.0))
	_place_barrel_stack(parent, barrel_path, crate_path, Vector3(23.5, 0, 17.5))
	_place_barrel_stack(parent, barrel_path, crate_path, Vector3(11.0, 0, 21.0))

## 3. Západní Vojenská Zbrojnice & Cvičiště (Military Armory)
func _build_military_armory(parent: Node3D) -> void:
	var catapult_path = "res://assets/castle/Models/GLB format/siege-catapult.glb"
	var ballista_path = "res://assets/castle/Models/GLB format/siege-ballista.glb"
	var fence_path = "res://assets/fantasy-town/Models/GLB format/fence.glb"
	var fence_broken = "res://assets/fantasy-town/Models/GLB format/fence-broken.glb"
	var chest_path = "res://assets/pirate-kit/Models/GLB format/chest.glb"
	var crate_path = "res://assets/pirate-kit/Models/GLB format/crate.glb"
	var barrel_path = "res://assets/pirate-kit/Models/GLB format/barrel.glb"

	# Velký obléhací katapult připravený u zdi
	_place_prop(parent, catapult_path, Vector3(-16.5, 0, 11.5), -140.0, Vector3(1.8, 1.8, 1.8), Vector3(3.5, 2.5, 3.5))
	# Těžká balista chránící západní branku
	_place_prop(parent, ballista_path, Vector3(-19.5, 0, 1.5), -80.0, Vector3(1.8, 1.8, 1.8), Vector3(3.0, 2.0, 3.0))

	# Dřevěné cvičné palisády a zátarasy
	_place_prop(parent, fence_path, Vector3(-12.5, 0, 7.5), 15.0, Vector3(1.8, 1.8, 1.8), Vector3(2.5, 1.2, 0.5))
	_place_prop(parent, fence_broken, Vector3(-15.0, 0, 16.5), 45.0, Vector3(1.8, 1.8, 1.8), Vector3(2.5, 1.2, 0.5))
	_place_prop(parent, fence_path, Vector3(-21.5, 0, 8.5), -75.0, Vector3(1.8, 1.8, 1.8), Vector3(2.5, 1.2, 0.5))

	# Truhly s municí a výzbrojí
	_place_prop(parent, chest_path, Vector3(-13.0, 0, 3.5), 25.0, Vector3(1.6, 1.6, 1.6), Vector3(1.0, 0.8, 0.8))
	_place_prop(parent, chest_path, Vector3(-13.8, 0, 2.8), -15.0, Vector3(1.6, 1.6, 1.6), Vector3(1.0, 0.8, 0.8))
	_place_barrel_stack(parent, barrel_path, crate_path, Vector3(-22.0, 0, 14.0))

## 4. Centrální Náměstí & Kašna (The Citadel Plaza)
func _build_central_plaza(parent: Node3D) -> void:
	var fountain_path = "res://assets/fantasy-town/Models/GLB format/fountain-round.glb"
	var bench_path = "res://assets/fantasy-town/Models/GLB format/bench.glb"

	# Monumentální kruhová kašna uprostřed křižovatky
	_place_prop(parent, fountain_path, Vector3(0, 0, 10.5), 0.0, Vector3(1.8, 1.8, 1.8), Vector3(3.2, 1.5, 3.2))

	# Kamenné lavičky u kašny
	_place_prop(parent, bench_path, Vector3(-3.2, 0, 10.5), 90.0, Vector3(1.5, 1.5, 1.5), Vector3(1.5, 0.8, 0.6))
	_place_prop(parent, bench_path, Vector3(3.2, 0, 10.5), -90.0, Vector3(1.5, 1.5, 1.5), Vector3(1.5, 0.8, 0.6))

## 5. Horní Chrámová Svatyně (The High Sanctum)
func _build_high_sanctum(parent: Node3D) -> void:
	var arch_path = "res://assets/fantasy-town/Models/GLB format/wall-arch.glb"
	var pillar_path = "res://assets/fantasy-town/Models/GLB format/pillar-stone.glb"

	# Monumentální kamenná kolonáda rámující chrám
	var pillars = [
		Vector3(-7.5, 0, -23.0),
		Vector3(7.5, 0, -23.0),
		Vector3(-7.5, 0, -28.0),
		Vector3(7.5, 0, -28.0),
		Vector3(-4.0, 0, -32.0),
		Vector3(4.0, 0, -32.0)
	]
	for pil_pos in pillars:
		_place_prop(parent, pillar_path, pil_pos, 0.0, Vector3(2.2, 2.5, 2.2), Vector3(1.2, 5.0, 1.2))

	# Klenuté gotické oblouky na bocích svatyně
	_place_prop(parent, arch_path, Vector3(-7.5, 0, -25.5), 90.0, Vector3(2.2, 2.2, 2.2), Vector3(0.8, 4.0, 3.5))
	_place_prop(parent, arch_path, Vector3(7.5, 0, -25.5), -90.0, Vector3(2.2, 2.2, 2.2), Vector3(0.8, 4.0, 3.5))
	_place_prop(parent, arch_path, Vector3(0.0, 0, -32.0), 0.0, Vector3(2.2, 2.2, 2.2), Vector3(3.5, 4.0, 0.8))

## 6. Síť atmosférického osvětlení (plápolající louče a lucerny)
func _build_torch_network(parent: Node3D) -> void:
	var lantern_path = "res://assets/fantasy-town/Models/GLB format/lantern.glb"

	# Jižní brána – 2 teplé louče na věžích
	_create_torch(parent, Vector3(-3.5, 3.8, 25.5), Color(1.0, 0.65, 0.25), 3.5, 8.0)
	_create_torch(parent, Vector3(3.5, 3.8, 25.5), Color(1.0, 0.65, 0.25), 3.5, 8.0)

	# Východní brána – 1 lucerna a louč
	_place_prop(parent, lantern_path, Vector3(29.0, 0, 4.5), -90.0, Vector3(1.8, 1.8, 1.8), Vector3.ZERO)
	_create_torch(parent, Vector3(29.0, 2.6, 4.5), Color(1.0, 0.7, 0.3), 3.2, 7.5)

	# Západní brána
	_place_prop(parent, lantern_path, Vector3(-27.5, 0, -1.5), 90.0, Vector3(1.8, 1.8, 1.8), Vector3.ZERO)
	_create_torch(parent, Vector3(-27.5, 2.6, -1.5), Color(1.0, 0.65, 0.25), 3.2, 7.5)

	# Tržnice – 2 závěsné lucerny
	_place_prop(parent, lantern_path, Vector3(13.5, 0, 10.5), 45.0, Vector3(1.8, 1.8, 1.8), Vector3.ZERO)
	_create_torch(parent, Vector3(13.5, 2.6, 10.5), Color(1.0, 0.72, 0.35), 3.0, 7.0)

	_place_prop(parent, lantern_path, Vector3(19.0, 0, 14.5), -30.0, Vector3(1.8, 1.8, 1.8), Vector3.ZERO)
	_create_torch(parent, Vector3(19.0, 2.6, 14.5), Color(1.0, 0.72, 0.35), 3.0, 7.0)

	# Zbrojnice – táborový oheň / koš
	_create_torch(parent, Vector3(-17.0, 1.2, 6.5), Color(1.0, 0.55, 0.2), 3.8, 8.5)

	# Kašna na náměstí
	_create_torch(parent, Vector3(0.0, 2.2, 10.5), Color(1.0, 0.75, 0.4), 2.8, 7.0)

	# Svatyně – 2 mystické azurové louče
	_create_torch(parent, Vector3(-5.5, 2.5, -23.0), Color(0.2, 0.85, 1.0), 3.6, 8.0)
	_create_torch(parent, Vector3(5.5, 2.5, -23.0), Color(0.2, 0.85, 1.0), 3.6, 8.0)

# --- Pomocné funkce pro rozmisťování ---

func _place_wall_segment(parent: Node3D, wall_path: String, pos: Vector3, rot_y_deg: float) -> void:
	_place_prop(parent, wall_path, pos, rot_y_deg, Vector3(2.0, 2.0, 2.0), Vector3(4.0, 5.5, 1.8))

func _place_tower_with_roof(parent: Node3D, tower_path: String, roof_path: String, banner_path: String, pos: Vector3, rot_y_deg: float) -> void:
	_place_prop(parent, tower_path, pos, rot_y_deg, Vector3(2.2, 2.2, 2.2), Vector3(3.8, 7.0, 3.8))
	if ResourceLoader.exists(roof_path):
		_place_prop(parent, roof_path, pos + Vector3(0, 5.8, 0), rot_y_deg, Vector3(2.3, 2.3, 2.3), Vector3.ZERO)
	if ResourceLoader.exists(banner_path):
		var banner_offset = Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(rot_y_deg)) * 1.8 + Vector3(0, 3.2, 0)
		_place_prop(parent, banner_path, pos + banner_offset, rot_y_deg, Vector3(1.8, 1.8, 1.8), Vector3.ZERO)

func _place_barrel_stack(parent: Node3D, barrel_path: String, crate_path: String, pos: Vector3) -> void:
	_place_prop(parent, barrel_path, pos + Vector3(-0.4, 0, -0.4), 0.0, Vector3(1.5, 1.5, 1.5), Vector3(1.6, 1.2, 1.6))
	_place_prop(parent, barrel_path, pos + Vector3(0.4, 0, -0.3), 15.0, Vector3(1.5, 1.5, 1.5), Vector3.ZERO)
	_place_prop(parent, barrel_path, pos + Vector3(0.0, 0, 0.5), -20.0, Vector3(1.5, 1.5, 1.5), Vector3.ZERO)
	_place_prop(parent, crate_path, pos + Vector3(0.7, 0, 0.7), 40.0, Vector3(1.5, 1.5, 1.5), Vector3(1.2, 1.2, 1.2))

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

	# Přidání kolize, pokud je zadána velikost boxu
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
	light.shadow_bias = 0.05
	
	# Jemné plápolání ohně
	var tween = create_tween().set_loops()
	tween.tween_property(light, "light_energy", energy * 0.82, 0.12 + randf() * 0.08)
	tween.tween_property(light, "light_energy", energy * 1.15, 0.14 + randf() * 0.08)
	tween.tween_property(light, "light_energy", energy, 0.1 + randf() * 0.08)
