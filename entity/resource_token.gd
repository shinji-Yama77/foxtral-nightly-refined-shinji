extends Node2D
class_name ResourceToken

@onready var wood_sprite = $Wood
@onready var rock_sprite = $Rock


var resource_type:ResourcePoint.ResourcePointType

func set_token_type(p_resource_type:ResourcePoint.ResourcePointType):
	
	resource_type = p_resource_type
	
	match resource_type:
		ResourcePoint.ResourcePointType.ROCK:
			rock_sprite.visible = true
		ResourcePoint.ResourcePointType.WOOD:
			wood_sprite.visible = true
	
