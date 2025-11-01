extends Camera3D

@export var look_r := 10.0
@export var speed := 5.0
@export var notification_scene: PackedScene
@export var message_sent: PackedScene
@export var message_received: PackedScene
@onready var notif_container := $UI/Notifications

var goal_rotation := Vector2.ZERO
var current_rot := Vector2.ZERO
var startrotation := Vector3.ZERO
var nqueue: Array = []
var notifications: Array = []
var showing_notification := false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	startrotation = rotation_degrees
	await get_tree().create_timer(5).timeout
	add_notification("Mike", "Hey...")

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

func render_messages() -> void:
	for message in $Phone.get_node("BG").get_node("Messages").get_node("Messages").get_children():
		message.queue_free()
	
	for message in notifications:
		var new_message = null
		if message.sender == "You":
			new_message = message_sent.instantiate()
			new_message.get_node("Message").get_node("Message").text = message.text
			new_message.get_node("Message").get_node("Sender").text = message.sender
		else:
			new_message = message_received.instantiate()
			new_message.get_node("Message").get_node("Message").text = message.text
			new_message.get_node("Message").get_node("Sender").text = message.sender
		$Phone.get_node("BG").get_node("Messages").get_node("Messages").add_child(new_message)
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		$Phone.visible = !$Phone.visible
		render_messages()

func add_notification(sender: String, text: String) -> void:
	nqueue.append({"sender": sender, "text": text})
	notifications.append({"sender": sender, "text": text})
	if not showing_notification:
		_shownotification()

func _shownotification() -> void:
	$notify.play()
	if nqueue.is_empty():
		showing_notification = false
		return
	showing_notification = true
	var data = nqueue.pop_front()
	var notif = notification_scene.instantiate()
	notif_container.add_child(notif)
	notif.get_node("sender").text = data.sender
	notif.get_node("text").text = data.text
	var origpos = notif.position
	notif.position.y += 100
	var t = create_tween()
	t.tween_property(notif, "position:y", origpos.y, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_interval(2.0)
	t.tween_property(notif, "position:y", origpos.y - 100, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.finished.connect(func():
		notif.queue_free()
		showing_notification = false
		_shownotification()
	)
