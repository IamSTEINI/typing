extends Camera3D
@export var look_r := 10.0
@export var speed := 5.0
var goal_rotation := Vector2.ZERO
var current_rot := Vector2.ZERO
var startrotation := Vector3.ZERO

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	startrotation = rotation_degrees

func _process(delta: float) -> void:
	var viewport_s = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	
	var offset = (mouse_pos / viewport_s) * 2.0 - Vector2.ONE
	offset = offset.clamp(Vector2(-1, -1), Vector2(1, 1))
	goal_rotation = offset * look_r
	
	current_rot.x = lerp(current_rot.x, goal_rotation.x, delta * speed)
	current_rot.y = lerp(current_rot.y, goal_rotation.y, delta * speed)
	
	rotation_degrees.y = startrotation.y - current_rot.x
	rotation_degrees.x = startrotation.x - current_rot.y
