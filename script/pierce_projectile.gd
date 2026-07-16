
extends Area2D
signal first_hit_enemy_reached(enemy: Node)
@export var background_top_z: int = 30
var first_hit_enemy: Node = null

@export var speed: float = 3500.0
@export var speed_max: float = 3500.0
@export var max_distance: float = 1200.0
var max_scale_proyektil := 0.4
var max_distance_default := 1200.0
var scale_proyektil := 1.0
@export var hit_radius: float = 26.0
@export var hit_radius_max: float = 26.0
@export var damage: int = 1
@export var max_depth_difference: float = 0.3
@export var projectile_scale: Vector2 = Vector2(0.25,0.25)
@export var projectile_color: Color = Color(1.0, 0.48, 0.55, 0.92)

var locked_z_index: int = 1100
var locked_scale_value: float = 0.0

@onready var visual: AnimatedSprite2D = $Visual

var direction: Vector2 = Vector2.ZERO
var traveled_distance: float = 0.0
var ignored_enemy: Node = null
var hit_enemies: Array[Node] = []
var source_depth_plane: float = 0.5
var _first_hit_signal_emitted: bool = false



func _ready() -> void:
	monitoring = false
	monitorable = false
	z_index = locked_z_index
	setup_visual()
	if visual != null:
		visual.animation = "launch"
		visual.play()
		visual.connect("animation_finished", Callable(self, "_on_visual_animation_finished"))
	_sync_motion_with_visual_scale()
func _on_visual_animation_finished() -> void:
	if visual.animation == "launch":
		visual.animation = "travel"
		visual.play()


func _physics_process(delta: float) -> void:
	if direction == Vector2.ZERO:
		queue_free()
		return

	var move_step: float = speed * delta
	global_position += direction * move_step
	traveled_distance += move_step
	rotation = direction.angle()

	# Setelah terkena musuh, z_index proyektil tetap seperti saat pertama kena

	deal_damage_on_overlap()

	if traveled_distance >= max_distance:
		queue_free()


func setup(start_pos: Vector2, move_direction: Vector2, source_enemy: Node = null, source_depth: float = 0.5) -> void:
	global_position = start_pos
	direction = move_direction.normalized()
	ignored_enemy = source_enemy
	source_depth_plane = source_depth
	traveled_distance = 0.0
	hit_enemies.clear()
	_lock_scale_from_source(source_enemy)
	_apply_locked_visual_scale()
	_sync_motion_with_visual_scale()


func _extract_enemy_depth(enemy: Node) -> Variant:
	if enemy == null or not is_instance_valid(enemy):
		return null

	for prop in enemy.get_property_list():
		if String(prop.get("name", "")) == "depth":
			return enemy.get("depth")

	return null


func setup_visual() -> void:
	if visual == null:
		return

	_apply_locked_visual_scale()
	visual.modulate = projectile_color
	# AnimatedSprite2D tidak punya property 'texture', jadi tidak perlu create_placeholder_texture
	_sync_motion_with_visual_scale()


func create_placeholder_texture() -> ImageTexture:
	var image := Image.create(56, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)


func deal_damage_on_overlap() -> void:
	_sync_motion_with_visual_scale()
	var circle := CircleShape2D.new()
	circle.radius = hit_radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, global_position)
	query.collide_with_areas = true
	query.collision_mask = 1 << 1

	var results := get_world_2d().direct_space_state.intersect_shape(query)
	# Kumpulkan semua musuh valid
	var enemy_hits := []
	for result in results:
		var hit_area: Variant = result.get("collider")
		if not (hit_area is Area2D):
			continue
		var enemy: Node = hit_area.get_parent()
		if enemy == null or enemy == ignored_enemy:
			continue
		if hit_enemies.has(enemy):
			continue
		if not enemy.has_method("apply_damage"):
			continue
		var enemy_depth: Variant = _extract_enemy_depth(enemy)
		if enemy_depth != null:
			if absf(float(enemy_depth) - source_depth_plane) > max_depth_difference:
				continue
		var enemy_z := 0
		if "z_index" in enemy:
			enemy_z = enemy.z_index
		enemy_hits.append({"enemy": enemy, "z": enemy_z})

	# Urutkan musuh berdasarkan z_index menurun (paling depan dulu)
	enemy_hits.sort_custom(func(a, b): return b["z"] - a["z"])

	for hit in enemy_hits:
		var enemy = hit["enemy"]
		# Simpan reference ke musuh pertama yang kena
		if first_hit_enemy == null:
			first_hit_enemy = enemy
			if not _first_hit_signal_emitted:
				_first_hit_signal_emitted = true
				first_hit_enemy_reached.emit(enemy)

		hit_enemies.append(enemy)
		var total_damage := damage + EnhancementManager.get_pierce_damage_bonus_for(enemy)
		if enemy.is_in_group("orb_nodes") and enemy.has_method("apply_damage"):
			enemy.apply_damage(total_damage, true)
		else:
			enemy.apply_damage(total_damage)

func set_projectile_visual_sync(_scale_val: float) -> void:
	pass

func _lock_scale_from_source(source_enemy: Node) -> void:
	locked_scale_value = _calculate_locked_scale_value(source_enemy)
	if locked_scale_value > 0.0:
		scale_proyektil = locked_scale_value
		max_distance = max_distance_default * (scale_proyektil / max_scale_proyektil)

func _apply_locked_visual_scale() -> void:
	if visual == null:
		return

	if locked_scale_value > 0.0:
		visual.scale = Vector2.ONE * locked_scale_value
	else:
		visual.scale = projectile_scale

func _calculate_locked_scale_value(source_enemy: Node) -> float:
	if source_enemy == null or not is_instance_valid(source_enemy):
		return 0.0

	var source_scale_x := 0.0
	if "scale" in source_enemy:
		source_scale_x = float((source_enemy as Node2D).scale.x)
	elif source_enemy.has_method("get_scale"):
		source_scale_x = float((source_enemy.get_scale() as Vector2).x)

	if source_scale_x <= 0.0:
		return 0.0

	var scale_val := max_scale_proyektil * (source_scale_x / 0.3)
	return min(scale_val, max_scale_proyektil)

func _sync_motion_with_visual_scale() -> void:
	if visual == null:
		return

	var scale_ratio := 0.0
	if max_scale_proyektil > 0.0:
		scale_ratio = clampf(visual.scale.x / max_scale_proyektil, 0.0, 1.0)

	speed = speed_max * scale_ratio
	hit_radius = hit_radius_max * scale_ratio
