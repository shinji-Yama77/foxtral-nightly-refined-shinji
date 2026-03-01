extends Control
class_name MainGUI

@onready var caption = $CanvasLayer/Caption
@onready var talk_button = $CanvasLayer/TalkButton
@onready var wood_value = $CanvasLayer/Inventory/WoodRow/WoodValue
@onready var rock_value = $CanvasLayer/Inventory/RocksRow/RockValue
@onready var eggs_value = $CanvasLayer/Inventory/EggsRow/EggsValue

signal talk_pressed
signal talk_released

func _ready() -> void:
	talk_button.button_down.connect(_on_talk_pressed)
	talk_button.button_up.connect(_on_talk_released)
	
	caption.text = "Say something !"

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
	if wood_value and is_instance_valid(TokenManager):
		wood_value.text = str(TokenManager.get_resource_count(ResourcePoint.ResourcePointType.WOOD))
		rock_value.text = str(TokenManager.get_resource_count(ResourcePoint.ResourcePointType.ROCK))
		eggs_value.text = str(TokenManager.get_resource_count(ResourcePoint.ResourcePointType.FOOD))
