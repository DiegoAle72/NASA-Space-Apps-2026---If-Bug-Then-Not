extends VBoxContainer
var EnabledButton: Button = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Ready")
	for i in $TabSelector/Buttons.get_children():
		print(i)
		if i is Button:
			i.pressed.connect(ButtonPressed.bind(i))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func ButtonPressed(node: Control) -> void:
	print("Just initialized " + node.name)
	EnabledButton = node
	$TabContainer/TabContainer.current_tab = int(node.name)
	pass # Replace with function body.
