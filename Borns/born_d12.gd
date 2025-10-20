@tool
extends Born
class_name BornD12
## a class to instanciate the complete scene for diameter12mm borns
## for now it works by creating everythin by code in the ready
## function, maybe it would be better to do as in this tutorial
## https://www.youtube.com/watch?v=u9aMR50yjCE&lc=Ugwj9E-q3feQ8_PCoWh4AaABAg.AO7SVEkJNqOAO7USLKos5r


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
