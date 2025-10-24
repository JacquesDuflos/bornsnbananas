@tool
extends Born
class_name Banana

## El punto que conincide con el borneo en el que se enchufa este banano
@export var plug_position : Marker3D
## El punto de donde arranca el cable de este banano
@export var cable_origine : Marker3D
## El punto a donde se dirige el cable de este banano al arrancar
@export var offset_for_cable: Marker3D

# TODO : stop using clicable and use get_connected_banana()!=null instead
var clicable : bool ## used to prevent clicing when exist a repluged. 
var previous_pos : Vector3  ## to send the moved signal

## Signal emmited every time the local position of this banana changes.
## It is used to update the cable mesh
signal moved


func _ready() -> void:
	super()
	previous_pos = position


func _process(_delta: float) -> void:
	if position != previous_pos :
		moved.emit(position, self)
	previous_pos = position


func _on_click_mask_input_event(
		_camera: Node, event: InputEvent, _event_position: Vector3,
		_normal: Vector3, _shape_idx: int
) -> Variant:
	if not super(_camera, event, _event_position, _normal, _shape_idx) :
		return false
	
	# on right clic
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		delete_cable()
		return "cable deleted"
	return true


## Return the first born to which is connected the banana.
func get_original_borne() -> Born:
	var born : Born
	if self == (get_parent() as Cable).banana_from:
		born = (get_parent() as Cable).born_from
	else :
		born = (get_parent() as Cable).born_to
	
	if born is Banana :
		return born.get_original_borne()
	else :
		return born


## Return the cable (if any) of which this banana is the banana_from
## or the banana_to. Else returns null value.
## should be moved to banana as it doesn't apply to borns
func get_cable() -> Cable:
	for cable:Cable in CableManager.cables:
		if self in [cable.banana_from, cable.banana_to]:
			return cable
	return null


## Frees the cable connected to this banana if any. This will trigger the
## reconnect methode of the cables connected to this one
func delete_cable():
	var cable := get_cable()
	if not cable : return
	cable.queue_free()
