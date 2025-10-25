extends Node

## True if a cable has been connected to a born, but not to a second
## one. It is therefor "in the hand", and waiting for a second born
## to be clicked
var is_ploting := false :
	set(val):
		is_ploting = val
		layout_changed.emit()

## When is_ploting is true, this variable points to the cable pending
## to be connected 
var cable_being_ploted : Cable

## The born object connected to the first end of the cable being plot
var from : Born
## The born object to which the cable being plot will be connected
var to : Born

var cables : Array[Cable] ## The list of cables created by this manager
var cables_container: Node3D ## The parent node of the cables

var color_id : int ## The index of the color when using a color manager [b](Deprecated)[/b]
var color : Color :
	set(new_color):
		color = new_color
		if cable_being_ploted and is_ploting :
			cable_being_ploted.color = color
## La distancia frente a la camara a cual se mantiene el cable
## mientras se connecta
const ARM_LENGTH = 400

## Sent whenever a cable is being started or ended.
signal layout_changed


func _enter_tree() -> void:
	var s_cancel_cable := "cancel cable"
	if not InputMap.has_action(s_cancel_cable):
		InputMap.add_action(s_cancel_cable)
	var mouse_right = InputEventMouseButton.new()
	mouse_right.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event(s_cancel_cable, mouse_right)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and is_ploting:
		add_mouse_point()
	if event.is_action_pressed("cancel cable") and is_ploting :
		cable_being_ploted.queue_free()
		is_ploting = false


func add_mouse_point():
	var mouse_pos := get_viewport().get_mouse_position()
	var cam : Camera3D = get_viewport().get_camera_3d()
	var Origine := cam.project_ray_origin(mouse_pos)
	var End := Origine + cam.project_ray_normal(mouse_pos)*ARM_LENGTH
	
	if cable_being_ploted.path.curve.point_count > 1:
		cable_being_ploted.path.curve.remove_point(cable_being_ploted.path.curve.point_count-1)
	cable_being_ploted.path.curve.add_point(cable_being_ploted.path.to_local(End))


func start_cable():
	is_ploting = true
	cable_being_ploted = Cable.new_cable()
	get_tree().root.add_child(cable_being_ploted)
	color = Color.from_hsv(randf(), 0.5, 0.5)
	cable_being_ploted.color = color
	cable_being_ploted.plug_banana(from)
	cable_being_ploted.create_cable_begining()
	cables.append(cable_being_ploted)
	add_mouse_point()


func save_cable():
	cable_being_ploted.color_id = color_id
	cable_being_ploted.plug_banana(to,false)
	cable_being_ploted.create_cable_ending()
	cable_being_ploted = null
	is_ploting = false
