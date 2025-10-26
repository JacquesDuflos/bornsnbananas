extends Node3D
class_name Cable
## An object that can connect to a born or an other banana,
## and has a wire connected to it. 

var born_from : Born ## Born to which is connected the first end
var born_to : Born ## Born to which is connected the second end
@export var banana_from : Banana ## First banana of the cable
@export var banana_to : Banana ## Second banana of the cable

@export var path : Path3D ## The path describing the cable
@export var dynamic_mesh : CSGPolygon3D ## The mesh following the path
@export var static_mesh : MeshInstance3D ## the mesh object used when the cable stops mooving
@export var click_mask : Area3D ## The area to detect when cable is clicked
@export var collision_shape_3d: CollisionShape3D ## The click_mask collition shape

## true if the cable is curently static
var is_static : bool :
	set(value):
		is_static = value
		#$BananaFrom/Label3D.text = "true" if is_static else "false"
var mat : StandardMaterial3D ## The material applyed to the path mesh
var color_id : int ## [b] Deprecated : use color instead [/b] the color id of the color manager
var color : Color : ## the color of the cable and bananas
	set(c):
		color = c
		update_color(color)
var hovered : bool = false

const CABLE = preload("uid://bvx44koknarr")
const BANANA = preload("res://addons/bornsnbananas/Banana/banana.tscn")


static func new_cable(color : Color = Color.ORANGE_RED) -> Cable:
	var new_cab : Cable = CABLE.instantiate()
	new_cab.path.curve = new_cab.path.curve.duplicate()
	new_cab.dynamic_mesh.material = new_cab.dynamic_mesh.material.duplicate()
	new_cab.mat = new_cab.dynamic_mesh.material
	new_cab.color = color
	new_cab.collision_shape_3d.shape = new_cab.collision_shape_3d.shape.duplicate()
	return new_cab


func _ready() -> void:
	mat = dynamic_mesh.material
	dynamic_mesh.polygon = draw_circle(6,0.005)
	#dynamic_mesh.path_node = path.get_path()
	#color = Color.from_hsv(randf(), 0.5, 0.5)
	update_color(color)


func _exit_tree() -> void:
	CableManager.cables.erase(self)
	CableManager.layout_changed.emit()
	replug_after_del()


func _input(event: InputEvent) -> void:
	if hovered:
		if (event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.is_pressed()
		):
			print ("cable clicked")


func _on_click_mask_mouse_entered() -> void:
	hovered = true


func _on_click_mask_mouse_exited() -> void:
	hovered = false


## A simple helper that creates points along a circl in a 2d plan.
## n : number of points to be drawn (minimum 3)
## dia : diameter
## returns : a PackedVector2Array of the calculated points
func draw_circle(n : int, dia : float) -> PackedVector2Array :
	var cir : PackedVector2Array
	for i in n :
		var alpha := i * 2 * PI / n
		cir.append(Vector2(cos(alpha) * dia, sin(alpha) * dia))
	return cir


## Turns the CSG polygon into a static mesh, and free any existing previous
## static mesh. Usefull to boost performence
## when the cable stops moving
func make_static(recursive : bool = false, is_from : bool = true) -> void :
	if is_static :
		printerr ("cable already static")
		return
	is_static = true
	await get_tree().process_frame
	click_mask.monitorable = true
	collision_shape_3d.shape = dynamic_mesh.bake_collision_shape()
	static_mesh.mesh = dynamic_mesh.bake_static_mesh()
	static_mesh.show()
	dynamic_mesh.free()
	
	if not recursive : return
	var ban : Banana = banana_from if is_from else banana_to
	var next_ban := ban.get_banana_connected()
	if not next_ban : return
	var next_cable := next_ban.get_cable()
	if not next_cable : return
	var next_is_from :bool = next_ban == next_cable.banana_from
	next_cable.make_static(true, next_is_from)


## Creates a CSG polygon and hide the static mesh.
## if recursive parameter set to true, will make any connected cable
## dynamic too.
## is_from only applies if recursive set to true. If is_from true, will look
## for the cables connected to the from banana
func make_dynamic(recursive : bool = false, is_from : bool = true) -> void :
	if is_static :
		is_static = false
		static_mesh.hide()
		if !dynamic_mesh:
			dynamic_mesh = CSGPolygon3D.new()
			add_child(dynamic_mesh)
	else :
		printerr("cable already dynamic")
	click_mask.monitorable = false
	dynamic_mesh.material = mat
	var born_scale = banana_from.global_transform.basis.get_scale()
	dynamic_mesh.polygon = draw_circle(6,0.005 * born_scale.x)
	dynamic_mesh.path_interval = 0.02 * born_scale.x
	path.curve.bake_interval = 0.02 * born_scale.x
	dynamic_mesh.mode = CSGPolygon3D.MODE_PATH
	dynamic_mesh.path_node = path.get_path()
	
	if not recursive : return
	var ban : Banana = banana_from if is_from else banana_to
	var next_ban := ban.get_banana_connected()
	if not next_ban : return
	var next_cable := next_ban.get_cable()
	if not next_cable : return
	var next_is_from :bool = next_ban == next_cable.banana_from
	next_cable.make_dynamic(true, next_is_from)


## Move the connected bananas to the previous banana or born after deleting this
## banana.
func replug_after_del():
	if born_from == banana_to :
		# self-connected cable
		replug_one_banana(banana_from, born_to)
		return
		
	if born_to == banana_from :
		# self-connected cable
		replug_one_banana(banana_to, born_from)
		return

	replug_one_banana(banana_from, born_from)
	replug_one_banana(banana_to, born_to)


## Replug the specified origin banana's connected banana (if any) to the
## specified born.
func replug_one_banana(origin_banana : Banana, to_born : Born):
	var recnx := origin_banana.get_banana_connected()
	if recnx :
		var c: Cable = recnx.get_cable()
		var is_from : bool = c.banana_from == recnx
		c.make_dynamic(true, is_from)
		c.plug_banana(to_born, is_from, true)


## Update the cable mesh when the banana moves. Called by the moved signal
## of the bananas
func recnx_cable(_pos : Vector3, banana : Banana):
	if CableManager.is_ploting : return
	if not path.curve : return
	var n_point := path.curve.point_count 
	if n_point < 2 : return
	path.curve.set_point_position(
			0, banana_from.cable_origine.global_position
	)
	path.curve.set_point_position(
			n_point-1,banana_to.cable_origine.global_position
	)
	update_color(color)
	recursive_replug(banana)


## Positions the banana on the born, rotates and scales it accordingly and
## updates its designation.
## born : the born to which the banana will be connected
## is_from : if true, the banana_from will be connected, else the banana_to
## smooth : the connexion should be instant or with a tween. Usefull for 
## moving the cable. in that case, will make_static recursive after
func plug_banana(born : Born, is_from := true, smooth := false):
	#make_dynamic()
	var banana : Banana
	if is_from :
		banana = banana_from
		born_from = born
	else:
		banana = banana_to
		born_to = born
	banana.visible = true
	banana.designation = born.designation
	banana.rotation = born.global_rotation
	var born_scale := born.global_transform.basis.get_scale()
	if is_static:
		printerr("banana was plugged while cable static")
	else :
		dynamic_mesh.polygon = draw_circle(6, 0.005 * born_scale.x)
		dynamic_mesh.path_interval = 0.02 * born_scale.x
	path.curve.bake_interval = 0.02 * born_scale.x
	banana.scale = born_scale
	var pos := -banana.plug_position.global_position + banana.global_position
	pos += born.plug_next.global_position
	if smooth :
		var _t := create_tween().tween_property(banana,"position",pos,0.4)
		await _t.finished
		make_static(true, is_from)
	else :
		banana.position = pos


## Triggers the plug_banana of the next banana if any when the cable moved
func recursive_replug(banana : Banana):
	var next_banana := banana.get_banana_connected()
	if not next_banana : return
	var c := next_banana.get_cable()
	var is_from : bool
	is_from = next_banana == c.banana_from
	c.plug_banana(banana, is_from, false)


## Creates the first point of the path
func create_cable_begining(invert := false):
	var banana := banana_from if not invert else banana_to
	path.curve.clear_points()
	path.curve.add_point(
			banana.cable_origine.global_position,
			Vector3.ZERO,
			banana.offset_for_cable.global_position - banana.cable_origine.global_position,
	)
	make_dynamic()


## Creates the second and last point of the paht
func create_cable_ending(invert := false):
	var banana := banana_to if not invert else banana_from
	path.curve.remove_point(path.curve.point_count - 1)
	path.curve.add_point(
			banana.cable_origine.global_position,
			banana.offset_for_cable.global_position - banana.cable_origine.global_position,
			Vector3.ZERO,
	)
	make_static()


## Updates the color of the bananas meshes and cable mesh
func update_color(new_color:Color):
	banana_from.color = new_color
	banana_to.color = new_color
	mat.albedo_color = new_color
