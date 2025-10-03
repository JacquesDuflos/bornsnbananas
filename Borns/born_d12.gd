@tool
extends Born
class_name BornD12


func _init() -> void:
	pass


func _ready() -> void:
	cylinder = preload("res://addons/bornsnbananas/Borns/born.blend").instantiate().get_child(0)
	cylinder.owner = null
	cylinder.reparent(self)
	cylinder.position = Vector3.ZERO
	cylinder.rotation = Vector3.ZERO
	cylinder.scale = Vector3.ONE
	plug_next = Marker3D.new()
	add_child(plug_next)
	var clic_mask := Area3D.new()
	add_child(clic_mask)
	clic_mask.name = "ClicMask"
	var collision_clic_mask := CollisionShape3D.new()
	collision_clic_mask.shape = CylinderShape3D.new()
	(collision_clic_mask.shape as CylinderShape3D).height = 0.009
	(collision_clic_mask.shape as CylinderShape3D).radius = 0.007
	clic_mask.add_child(collision_clic_mask)
	clic_mask.input_event.connect(_on_click_mask_input_event)
	super()
