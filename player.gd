extends Camera3D

@export var look_r := 10.0
@export var speed := 5.0
@export var notification_scene: PackedScene
@export var message_sent: PackedScene
@export var message_received: PackedScene
@export var light: OmniLight3D
@export var knock: AudioStreamPlayer3D
@export var door_squeak: AudioStreamPlayer3D
@export var shelf_door: Node3D

@onready var notif_container := $UI/Notifications
@onready var type_field := $UI/TypeWriter

var goal_rotation := Vector2.ZERO
var current_rot := Vector2.ZERO
var startrotation := Vector3.ZERO
var nqueue: Array = []
var notifications: Array = []
var showing_notification := false
var state = 8
var can_reply = true

func fade_light(duration: float = 2.0, max_energy: float = 1.0) -> void:
	var steps = 50
	var wait_time = duration / steps
	for i in range(steps + 1):
		var t = float(i) / steps
		light.light_energy = lerp(0.0, max_energy, t)
		await get_tree().create_timer(wait_time).timeout

func _ready() -> void:
	light.light_energy = 0
	can_reply = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	startrotation = rotation_degrees
	type_field.hide()
	$UI/GridContainer/Send.visible = false
	$Phone.visible = false
	await fade_light(2, 1)
	await type_write("It was Sunday. My parents left this evening for a business trip.")
	await get_tree().create_timer(0.5).timeout
	await type_write("I woke up due to storms outside. I felt my phone buzzing. It's 2:49 AM")
	flicker(1,0.4, 1)
	await get_tree().create_timer(1).timeout
	await get_tree().create_timer(1.5).timeout
	add_notification("Mike", "Hey...")
	await type_write("Someone texted me, I openend my phone [PRESS M] and replied [PRESS SPACE]")
	can_reply = true

func flicker(duration: float = 2.0, min_energy: float = 0.5, max_energy: float = 2.0) -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var end_time := Time.get_ticks_msec() + int(duration * 1000)
	while Time.get_ticks_msec() < end_time:
		light.light_energy = rng.randf_range(min_energy, max_energy)
		await get_tree().create_timer(rng.randf_range(0.05, 0.2)).timeout
	light.light_energy = max_energy	

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
	
	if notifications.size() > 0:
		for message in notifications:
			var new_message = null
			if message.sender == "You":
				new_message = message_sent.instantiate()
				new_message.get_node("OwnMessage").get_node("Message").text = message.text
				new_message.get_node("OwnMessage").get_node("Sender").text = message.sender
			else:
				new_message = message_received.instantiate()
				new_message.get_node("Message").get_node("Message").text = message.text
				new_message.get_node("Message").get_node("Sender").text = message.sender
			$Phone.get_node("BG").get_node("Messages").get_node("Messages").add_child(new_message)

func fire_reply():
	can_reply = false
	if state == 1:
		await get_tree().create_timer(1.35).timeout
		add_notification("Mike", "What do you mean? I was your classmate!")
		await type_write("I had met many people that evening; it was Halloween.")
		await type_write("Perhaps he was one of them. I replied [PRESS SPACE]")
		state += 1
		can_reply = true
	elif state == 3:
		add_notification("Mike", "Anyway... How are you?")
		await type_write("We chatted a bit [PRESS SPACE]")
		state += 1
		can_reply = true
	elif state == 5:
		await get_tree().create_timer(1.35).timeout
		add_notification("Mike", "Good to hear.")
		await get_tree().create_timer(1).timeout
		add_notification("Mike", "Do you still live with your parents?")
		await get_tree().create_timer(2).timeout
		add_notification("Mike", "Okay, just don't answer.")
		await type_write("He seemed strange, but I was still too tired to respond. I told him that I want to sleep")
		state += 1
		can_reply = true
	elif state == 7:
		await get_tree().create_timer(1.35).timeout
		add_notification("Mike", "What?")
		state += 1
		can_reply = true
	elif state == 9:
		await get_tree().create_timer(1.35).timeout
		add_notification("Mike", "Your parents?")
		state += 1
		can_reply = true
	elif state == 11:
		await get_tree().create_timer(1.35).timeout
		add_notification("Mike", "Propably it's just the wind...")
		await type_write("Maybe it was really just the wind. At least, that's what I thought.")
		await get_tree().create_timer(0.8).timeout
		add_notification("Mike", "Or the guest you invited, who stayed. Watching.")
		state += 1
		can_reply = true
	
func type_write(text: String) -> void:
	$typewriter.play()
	type_field.text = ""
	type_field.show()
	var total = text.length()
	for i in range(total):
		type_field.text += text[i]
		await get_tree().create_timer(0.05).timeout
	$typewriter.stop()
	await get_tree().create_timer(1).timeout
	type_field.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		$Phone.visible = !$Phone.visible
		$UI/GridContainer/Send.visible = $Phone.visible
		render_messages()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE && $Phone.visible == true and can_reply == true:
		can_reply = false
		if state == 0:
			add_notification("You", "Who are you??")
			state+=1
		elif state == 2:
			add_notification("You", "I can't remember any Mike...")
			state+=1
		elif state == 4:
			add_notification("You", "I'm good")
			state+=1
		elif state == 6:
			add_notification("You", "Look, I want to sleep.")
			await get_tree().create_timer(1).timeout
			add_notification("You", "We can talk tomorrow")
			flicker(1,0.4, 1)
			await get_tree().create_timer(2).timeout
			$Phone.visible = false
			$UI/GridContainer/Send.visible = false
			knock.play()
			await type_write("There had been a knock at the door. I was scared")
			await get_tree().create_timer(1).timeout
			add_notification("You", "Someone just knocked...")
			$Phone.visible = true
			$UI/GridContainer/Send.visible = true
			state+=1
		elif state == 8:
			add_notification("You", "Yeah, a loud bang at my door")
			state+=1
		elif state == 10:
			add_notification("You", "Impossible, they're outside the city")
			await get_tree().create_timer(1).timeout
			add_notification("You", "God, this is creepy!")
			state+=1
		elif state == 12:
			add_notification("You", "Mike, what do you mean?")
			await type_write("I was frightened. I didn't know what was happening.")
			await flicker(3, 0, 5)
			light.light_energy = 0
			$Phone.visible = false
			$UI/GridContainer/Send.visible = false
			await type_write("Suddenly, the lights turned off. Propably a power outage caused by the storms")
			door_squeak.play()
			type_write("I've heard some door squaking...")
			await get_tree().create_timer(2.9).timeout
			for i in range(80):
				shelf_door.rotation_degrees += Vector3(0,1,0)
				await get_tree().create_timer(0.02).timeout
			state+=1
		fire_reply()
		render_messages()
		await get_tree().process_frame
		var scroll = $Phone/BG/Messages
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func add_notification(sender: String, text: String) -> void:
	if sender != "You":
		nqueue.append({"sender": sender, "text": text})
	else:
		$send.play()
		fire_reply()
	notifications.append({"sender": sender, "text": text})
	render_messages()
	if not showing_notification:
		_shownotification()
		render_messages()
	await get_tree().process_frame
	var scroll = $Phone/BG/Messages
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _shownotification() -> void:
	if nqueue.is_empty():
		showing_notification = false
		return
	$notify.play()
	showing_notification = true
	var data = nqueue.pop_front()
	var notif = notification_scene.instantiate()
	notif_container.add_child(notif)
	notif.get_node("sender").text = data.sender
	notif.get_node("text").text = data.text
	var origpos = notif.position
	notif.position.y -= 100
	var t = create_tween()
	t.tween_property(notif, "position:y", origpos.y, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_interval(2.0)
	t.tween_property(notif, "position:y", origpos.y - 100, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.finished.connect(func():
		$notify.stop()
		notif.queue_free()
		showing_notification = false
		_shownotification()
	)
