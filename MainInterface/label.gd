extends CanvasLayer

## "What is your angle 0-360 from the ISS"
@export var persons_angle: int = 90

var sun_position = 0 # défini par axe terre-soleil
var cable_distance = 20.0
var astronaut_speed = 0.5
var angle_from_safe_point = 0
var pi = 3.141

var label: Label


func _ready():
	label = Label.new()
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)


func _process(_delta):
	var ISS_angle = int(get_parent().angle_degrees)   # ISS angle from your Node3D script

	if 225 >= ISS_angle and ISS_angle >= 135:
		label.text = "You're at safety point, don't move from there"
	else:
		var persons_angle_from_ISS = persons_angle + 1
		var angle_from_safety_point = abs(180 - persons_angle_from_ISS)
		var angle_from_safety = 2 * pi * cable_distance
		var distance_from_safety = angle_from_safety / (360.0 / (persons_angle_from_ISS))
		var time_to_get_to_safety = distance_from_safety / astronaut_speed
		label.text = "Your distance from safe point of the ISS is: %s meters and you will get there in %s seconds" \
			% [distance_from_safety, time_to_get_to_safety]
	GlobalData.ISSCosoMessage = label.text
