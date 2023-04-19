extends Node3D

@export var pin_speed: float = 10.0
@export var data_source: Node = null


func _physics_process(delta : float):
	# Move pin around the grid
	if Input.is_action_pressed("pin_move_north"):
		position.z -= delta * pin_speed
	if Input.is_action_pressed("pin_move_south"):
		position.z += delta * pin_speed
	if Input.is_action_pressed("pin_move_west"):
		position.x -= delta * pin_speed
	if Input.is_action_pressed("pin_move_east"):
		position.x += delta * pin_speed
	
	_update_pin_cursor_display()

func _update_pin_cursor_display() -> void:
	if not data_source:
		return
	
	if data_source.has_method("get_height_at_xz"):
		position.y = data_source.get_height_at_xz(
			Vector2(position.x, position.z)
		)
