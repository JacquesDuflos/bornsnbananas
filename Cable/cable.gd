extends Node3D
class_name Cable
## An object that can connect to a born or an other banana,
## and has a wire connected to it. 

var born_from : Born ## Born to which is connected the first end
var born_to : Born ## Born to which is connected the second end
var banana_from : Banana ## First banana of the cable
var banana_to : Banana ## Second banana of the cable

var path : Path3D ## The path describing the cable
var path_mesh : CSGPolygon3D ## The mesh following the path
var mat : StandardMaterial3D ## The material applyed to the path mesh
var color_id : int ## [b] Deprecated : use color instead [/b] the color id of the color manager
var color : Color : ## the color of the cable and bananas
	set(c):
		color = c
		update_color(color)

const BANANA = preload("res://addons/bornsnbananas/Banana/banana.tscn")


func _init() -> void:
	path = Path3D.new()
	add_child(path)
	path.curve = Curve3D.new()
	path.curve.bake_interval = 0.001
	path_mesh = CSGPolygon3D.new()
	add_child(path_mesh)
	mat = StandardMaterial3D.new()
	path_mesh.material = mat
	path_mesh.polygon = draw_circle(6,0.005)
	path_mesh.mode = CSGPolygon3D.MODE_PATH
	banana_from = BANANA.instantiate()
	banana_from.moved.connect(recnx_cable)
	banana_from.visible = false
	add_child(banana_from)
	banana_to = BANANA.instantiate()
	banana_to.moved.connect(recnx_cable)
	banana_to.visible = false
	add_child(banana_to)
	update_color(color)


func _ready() -> void:
	path_mesh.path_node = path.get_path()


func _exit_tree() -> void:
	CableManager.cables.erase(self)
	CableManager.layout_changed.emit()
	replug_after_del()


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
## moving the cable
func plug_banana(born : Born, is_from := true, smooth := false):
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
	path_mesh.polygon = draw_circle(6, 0.005 * born_scale.x)
	path_mesh.path_interval = 0.02 * born_scale.x
	path.curve.bake_interval = 0.02 * born_scale.x
	banana.scale = born_scale
	var pos := -banana.plug_position.global_position + banana.global_position
	pos += born.plug_next.global_position
	if smooth :
		var _t = create_tween().tween_property(banana,"position",pos,0.4)
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


## Creates the second and last point of the paht
func create_cable_ending(invert := false):
	var banana := banana_to if not invert else banana_from
	path.curve.remove_point(path.curve.point_count - 1)
	path.curve.add_point(
			banana.cable_origine.global_position,
			banana.offset_for_cable.global_position - banana.cable_origine.global_position,
			Vector3.ZERO,
	)


## Updates the color of the bananas meshes and cable mesh
func update_color(new_color:Color):
	banana_from.color = new_color
	banana_to.color = new_color
	mat.albedo_color = new_color
