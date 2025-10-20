@tool
extends Node3D
class_name Born
## A 3D object to which can be connected bananas and cables produced by the 
## CableManager.

## Un texto que define el punto de connexion. Cualquier banana que se connecta
## a este borneo le copiará su designation.
@export var designation : String
## The color that will be applyed to the mesh.
@export var color : Color:
	set(new_col):
		color = new_col
		if not is_node_ready(): return
		set_color(color)

## El punto que conincide con el banano que se enchufe en este borneo
@export var plug_next : Marker3D
## El mesh visible
@export var cylinder : MeshInstance3D

## El potensial electrico relativo a la tierra del sistema
var u : float = 0.0

## La intensidad electrica que va del banano conectado a la 
## connexion fija
var i : float = 0.0


func _ready() -> void:
	set_color(color)


## Changes the solor of the cylinder mesh
func set_color(col : Color):
	if not cylinder : return
	#if not cylinder.get_surface_override_material(0):
	cylinder.set_surface_override_material(0,StandardMaterial3D.new())
	var mat := cylinder.get_surface_override_material(0)
	mat.albedo_color = col


## Return the cable (if any) of which this banana is the banana_from
## or the banana_to. Else returns null value.
## should be moved to banana as it doesn't apply to borns
func get_cable() -> Cable:
	for cable:Cable in CableManager.cables:
		if self in [cable.banana_from, cable.banana_to]:
			return cable
	return null


## Returns the cable object connected to this born
func get_cable_connected() -> Cable:
	for cable:Cable in CableManager.cables:
		if self in [cable.born_from, cable.born_to]:
			return cable
	return null


## If a banana is connected to this born, returns it, else returns null
func get_banana_connected() -> Banana:
	for cable :Cable in CableManager.cables:
		if cable.born_from == self:
			return cable.banana_from
		if cable.born_to == self:
			return cable.banana_to
	return null


## Recursively looks for the banana connected to this one. Else returns self
func get_top_banana_connected() -> Born:
	var next_bana := get_banana_connected()
	if next_bana :
		return next_bana.get_top_banana_connected()
	else :
		return self


## Either creates a new cable and connect its from born to this one, or
## or connect the to born of the cable presently in creation and saves it
## in the CableManager
func start_or_finish_cable():
	var actual_born : Born = get_top_banana_connected()
	#print("borne cliquee")
	if CableManager.is_ploting:
		# terminer de connecter
		CableManager.to = actual_born
		CableManager.save_cable()
	else :
		CableManager.from = actual_born
		CableManager.start_cable()


## Frees the cable connected to this banana if any. This will trigger the
## reconnect methode of the cables connected to this one
func delete_cable():
	var cable := get_cable()
	if not cable : return
	cable.queue_free()


func _on_click_mask_input_event(
		_camera: Node, event: InputEvent, _event_position: Vector3,
		_normal: Vector3, _shape_idx: int
) -> void:
	if Engine.is_editor_hint() : return
	if not event is InputEventMouseButton: return
	
	# on left clic
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		start_or_finish_cable()
	# on right clic
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		delete_cable()
