extends Node

const GUI: PackedScene = preload("res://gui.tscn")

var gui_scene: MainGUI

func _ready() -> void:

	gui_scene = GUI.instantiate()
	add_child(gui_scene)
	await gui_scene.ready

func change_caption(text: String) -> void:
	gui_scene.set_caption(text)
