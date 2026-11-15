@tool
extends Node3D

## 0° = ISS between Earth and Sun (in sunlight) · 180° = behind Earth (in shadow)
@export_range(0, 360, 1) var angle_degrees: float = 0:
	set(value):
		angle_degrees = value
		update_iss()

## Distance from Earth's center to the ISS
@export var orbit_radius: float = 5

## The node the angle is measured from (the Sun or the light)
@export var sun_reference: NodePath = NodePath("sol")


func _ready():
	update_iss()


func _process(_delta):
	update_iss()


func update_iss():
	if not is_node_ready():
		return

	var iss := get_node_or_null("ISS con nave N1 Crew-11 Dragon") as Node3D
	var earth := get_node_or_null("Tierra wtf") as Node3D
	var sun := get_node_or_null(sun_reference) as Node3D
	if iss == null or earth == null or sun == null:
		return

	# Sun direction on the XZ plane only (Y ignored)
	var to_sun := Vector2(sun.global_position.x - earth.global_position.x,
						  sun.global_position.z - earth.global_position.z)
	if to_sun.length() < 0.001:
		return

	# Add the angle to the Sun's angle → position on the circle
	var a := to_sun.angle() + deg_to_rad(angle_degrees)

	iss.global_position = Vector3(
		earth.global_position.x + cos(a) * orbit_radius,
		earth.global_position.y,                      # same height as Earth, never changes
		earth.global_position.z + sin(a) * orbit_radius
	)
