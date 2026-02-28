extends Node2D
class_name ResourcePoint

@export var resource_type:ResourcePointType=ResourcePointType.WOOD

enum ResourcePointType {
	WOOD,
	ROCK,
	HOUSE
}

const place_name = {
	ResourcePointType.WOOD:"wood",
	ResourcePointType.ROCK:"rock",
	ResourcePointType.HOUSE:"house"
}

func _ready() -> void:
	

	ResourceManager.register_resource(self)
	
