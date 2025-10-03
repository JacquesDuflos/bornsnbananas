@tool
extends EditorPlugin


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_autoload_singleton("CableManager", "res://addons/bornsnbananas/Autoloads/cable_manager.gd")
	add_custom_type(
			"Born",
			"Node3D",
			preload("res://addons/bornsnbananas/Borns/born.gd"),
			preload("res://addons/bornsnbananas/Borns/born_logo.svg")
	)
	add_custom_type(
			"BornD12",
			"Born",
			preload("res://addons/bornsnbananas/Borns/born_d12.gd"),
			preload("res://addons/bornsnbananas/Borns/born_logo.svg")
	)
	add_custom_type(
			"Banana",
			"Born",
			preload("res://addons/bornsnbananas/Banana/banana.gd"),
			preload("res://addons/bornsnbananas/Borns/born_logo.svg")
	)
	add_custom_type(
			"Cable",
			"Node3D",
			preload("res://addons/bornsnbananas/Cable/cable.gd"),
			preload("res://addons/bornsnbananas/Borns/born_logo.svg")
	)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_autoload_singleton("CableManager")
	remove_custom_type("Born")
	remove_custom_type("Born12D")
	remove_custom_type("Banana")
	pass
