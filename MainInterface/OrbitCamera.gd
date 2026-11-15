extends Camera3D

@export var target: Node3D
@export var drag_sensitivity := 0.008
@export_range(0.1, 5.0, 0.05) var zoom := 1.4

var _dragging := false
var _yaw := 0.0
var _pitch := 0.0
var _center_offset := Vector3.ZERO
var _radius := 0.5


func _ready() -> void:
	var bounds := AABB()
	for child in target.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var mesh_bounds := mesh.global_transform * mesh.get_aabb()
		bounds = bounds.merge(mesh_bounds) if bounds.has_volume() else mesh_bounds
	if bounds.has_volume():
		_center_offset = target.to_local(bounds.get_center())
		_radius = bounds.size.length() * 0.5

	get_viewport().size_changed.connect(_update_orbit)
	_update_orbit()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_dragging = false
			return
		_yaw = wrapf(_yaw - event.relative.x * drag_sensitivity, -PI, PI)
		_pitch = clampf(_pitch - event.relative.y * drag_sensitivity, -1.48, 1.48)
		_update_orbit()
		get_viewport().set_input_as_handled()


func _update_orbit() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var half_fov := deg_to_rad(fov) * 0.5
	var limiting_half_fov := atan(tan(half_fov) * clampf(aspect, 0.01, 1.0))
	var distance := _radius * 1.1 / (sin(limiting_half_fov) * zoom)
	var center := target.to_global(_center_offset)
	var direction := Vector3.BACK.rotated(Vector3.RIGHT, _pitch).rotated(Vector3.UP, _yaw)
	look_at_from_position(center + direction * distance, center)
