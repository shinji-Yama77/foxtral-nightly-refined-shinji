extends Control
class_name MainGUI

@onready var caption = $CanvasLayer/Caption
@onready var talk_button = $CanvasLayer/TalkButton
@onready var resources_values = $CanvasLayer/ResourcesValues

signal talk_pressed
signal talk_released

func _ready() -> void:
	talk_button.button_down.connect(_on_talk_pressed)
	talk_button.button_up.connect(_on_talk_released)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_talk_pressed()
		talk_button.button_pressed = true
	elif event.is_action_released("ui_accept"):
		_on_talk_released()
		talk_button.button_pressed = false

func _on_talk_pressed() -> void:
	talk_pressed.emit()

func _on_talk_released() -> void:
	talk_released.emit()

func set_caption(text: String) -> void:
	caption.text = text

func _process(_delta: float) -> void:
	if resources_values and is_instance_valid(TokenManager):
		var wood = TokenManager.get_resource_count(ResourcePoint.ResourcePointType.WOOD)
		var rock = TokenManager.get_resource_count(ResourcePoint.ResourcePointType.ROCK)
		var eggs = TokenManager.get_resource_count(ResourcePoint.ResourcePointType.FOOD)
		resources_values.text = str(wood) + "\n" + str(rock) + "\n" + str(eggs)
