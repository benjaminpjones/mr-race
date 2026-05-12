extends Node3D

const CHUNK_SCRIPT := preload("res://scripts/falling_chunk.gd")

signal blocks_removed_changed(count: int)

@export var grid_size: int = 160
@export var tile_size: float = 1.0
@export var tile_thickness: float = 0.5
@export var top_y: float = 0.0
@export var safe_radius_tiles: float = 4.0
@export var fuse: float = 0.4
@export var tiles_fall: bool = true

const STATE_GONE := 0
const STATE_SAFE := 1
const STATE_FALLABLE := 2

var _state: PackedByteArray
var _last_touched: PackedInt32Array
var _fuse_started: PackedByteArray
var _falling_idx: PackedInt32Array
var _shapes: Array
var _primed_cells: Dictionary = {}

var _vehicle: VehicleBody3D
var _floor_body: StaticBody3D
var _falling_mm: MultiMesh
var _shape: BoxShape3D
var _chunk_mesh: BoxMesh
var _chunk_material: StandardMaterial3D
var _epoch: int = 0
var _blocks_removed: int = 0
var _resetting: bool = false
var _hidden_xform: Transform3D = Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO)

func set_vehicle(v: VehicleBody3D) -> void:
	_vehicle = v

func reset() -> void:
	if _resetting:
		return
	_resetting = true
	_epoch += 1
	_primed_cells.clear()
	_fuse_started.fill(0)
	var n := grid_size * grid_size
	for cell in range(n):
		if _state[cell] == STATE_GONE:
			_restore_cell(cell)
	for child in get_children():
		if child is RigidBody3D:
			child.queue_free()
	_blocks_removed = 0
	blocks_removed_changed.emit(_blocks_removed)
	_resetting = false

func _restore_cell(cell: int) -> void:
	_state[cell] = STATE_FALLABLE
	var pos := _cell_local_pos(cell)
	var col := CollisionShape3D.new()
	col.shape = _shape
	col.position = pos
	_floor_body.add_child(col)
	_shapes[cell] = col
	var idx := _falling_idx[cell]
	if idx >= 0:
		_falling_mm.set_instance_transform(idx, Transform3D(Basis(), pos))

func _ready() -> void:
	_build()

func _build() -> void:
	var n := grid_size * grid_size
	_state = PackedByteArray()
	_state.resize(n)
	_last_touched = PackedInt32Array()
	_last_touched.resize(n)
	_fuse_started = PackedByteArray()
	_fuse_started.resize(n)
	_falling_idx = PackedInt32Array()
	_falling_idx.resize(n)
	_shapes = []
	_shapes.resize(n)

	_shape = BoxShape3D.new()
	_shape.size = Vector3(tile_size, tile_thickness, tile_size)

	var falling_mat := StandardMaterial3D.new()
	falling_mat.albedo_color = Color(0.72, 0.38, 0.22)
	_chunk_material = falling_mat

	var safe_mat := StandardMaterial3D.new()
	safe_mat.albedo_color = Color(0.32, 0.38, 0.48)

	var falling_box := BoxMesh.new()
	falling_box.size = Vector3(tile_size, tile_thickness, tile_size)
	falling_box.material = falling_mat
	_chunk_mesh = falling_box

	var safe_box := BoxMesh.new()
	safe_box.size = Vector3(tile_size, tile_thickness, tile_size)
	safe_box.material = safe_mat

	var half := grid_size / 2
	var center_y := top_y - tile_thickness * 0.5
	var safe_sq := safe_radius_tiles * safe_radius_tiles

	var fall_count := 0
	var safe_count := 0
	for i in range(grid_size):
		for j in range(grid_size):
			var ox := (i - half) + 0.5
			var oz := (j - half) + 0.5
			if ox * ox + oz * oz <= safe_sq:
				safe_count += 1
			else:
				fall_count += 1

	_falling_mm = MultiMesh.new()
	_falling_mm.transform_format = MultiMesh.TRANSFORM_3D
	_falling_mm.mesh = falling_box
	_falling_mm.instance_count = fall_count

	var safe_mm := MultiMesh.new()
	safe_mm.transform_format = MultiMesh.TRANSFORM_3D
	safe_mm.mesh = safe_box
	safe_mm.instance_count = safe_count

	var falling_mmi := MultiMeshInstance3D.new()
	falling_mmi.multimesh = _falling_mm
	add_child(falling_mmi)

	var safe_mmi := MultiMeshInstance3D.new()
	safe_mmi.multimesh = safe_mm
	add_child(safe_mmi)

	_floor_body = StaticBody3D.new()
	add_child(_floor_body)

	var fall_idx := 0
	var safe_idx := 0
	for i in range(grid_size):
		for j in range(grid_size):
			var ox := (i - half) + 0.5
			var oz := (j - half) + 0.5
			var pos := Vector3(ox * tile_size, center_y, oz * tile_size)
			var t := Transform3D(Basis(), pos)
			var cell := i * grid_size + j

			var col := CollisionShape3D.new()
			col.shape = _shape
			col.position = pos
			_floor_body.add_child(col)
			_shapes[cell] = col

			if ox * ox + oz * oz <= safe_sq:
				_state[cell] = STATE_SAFE
				safe_mm.set_instance_transform(safe_idx, t)
				_falling_idx[cell] = -1
				safe_idx += 1
			else:
				_state[cell] = STATE_FALLABLE
				_falling_mm.set_instance_transform(fall_idx, t)
				_falling_idx[cell] = fall_idx
				fall_idx += 1

func _physics_process(_delta: float) -> void:
	if not tiles_fall:
		return
	if not _vehicle or not is_instance_valid(_vehicle):
		_check_fuses(Engine.get_physics_frames())
		return
	var frame := Engine.get_physics_frames()
	for child in _vehicle.get_children():
		if child is VehicleWheel3D and child.is_in_contact():
			var body: Node = child.get_contact_body()
			if body == _floor_body:
				_touch_at(child.global_position, frame)
	_check_fuses(frame)

func _touch_at(world_pos: Vector3, frame: int) -> void:
	var cell := _cell_at(world_pos)
	if cell < 0:
		return
	if _state[cell] != STATE_FALLABLE:
		return
	if _fuse_started[cell] != 0:
		return
	_last_touched[cell] = frame
	_primed_cells[cell] = true

func _check_fuses(frame: int) -> void:
	if _primed_cells.is_empty():
		return
	var keep := {}
	for cell in _primed_cells:
		if _fuse_started[cell] != 0:
			continue
		if frame - _last_touched[cell] > 1:
			_fuse_started[cell] = 1
			var epoch: int = _epoch
			var c: int = cell
			get_tree().create_timer(fuse).timeout.connect(func(): _drop(c, epoch))
		else:
			keep[cell] = true
	_primed_cells = keep

func _drop(cell: int, epoch: int) -> void:
	if epoch != _epoch:
		return
	if _state[cell] != STATE_FALLABLE:
		return
	_state[cell] = STATE_GONE

	var idx := _falling_idx[cell]
	if idx >= 0:
		_falling_mm.set_instance_transform(idx, _hidden_xform)

	var col = _shapes[cell]
	if col and is_instance_valid(col):
		col.queue_free()
	_shapes[cell] = null

	var pos := _cell_local_pos(cell)
	var chunk := RigidBody3D.new()
	chunk.set_script(CHUNK_SCRIPT)
	var col2 := CollisionShape3D.new()
	col2.shape = _shape
	chunk.add_child(col2)
	var mi := MeshInstance3D.new()
	mi.mesh = _chunk_mesh
	chunk.add_child(mi)
	chunk.position = pos
	add_child(chunk)

	_blocks_removed += 1
	blocks_removed_changed.emit(_blocks_removed)

func _cell_at(world_pos: Vector3) -> int:
	var local := to_local(world_pos)
	var half := grid_size / 2
	var ix := int(floor(local.x / tile_size)) + half
	var iz := int(floor(local.z / tile_size)) + half
	if ix < 0 or ix >= grid_size or iz < 0 or iz >= grid_size:
		return -1
	return ix * grid_size + iz

func _cell_local_pos(cell: int) -> Vector3:
	var i := cell / grid_size
	var j := cell % grid_size
	var half := grid_size / 2
	var ox := (i - half) + 0.5
	var oz := (j - half) + 0.5
	return Vector3(ox * tile_size, top_y - tile_thickness * 0.5, oz * tile_size)
