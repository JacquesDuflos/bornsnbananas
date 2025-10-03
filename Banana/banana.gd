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
