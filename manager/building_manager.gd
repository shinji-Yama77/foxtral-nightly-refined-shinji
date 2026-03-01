extends Node
## Manages recipes and building. Foxes deliver wood/rock to the house (tokens registered in TokenManager on drop).
## When a fox is sent to build, it goes to the house and calls try_build(); consumed tokens (sprites) are removed.
## For "house", a house sprite is shown northwest of the rocks.

signal building_completed(building_id: String)

const RECIPES: Dictionary = {
	"house": {
		ResourcePoint.ResourcePointType.WOOD: 2,
		ResourcePoint.ResourcePointType.ROCK: 2
	}
}

# RockPoint in main.tscn is at (241, 157). House sprite placed northwest of it.
const ROCK_POSITION: Vector2 = Vector2(241, 157)
const HOUSE_OFFSET_NORTHWEST: Vector2 = Vector2(-50, -70)  # left and up; polish as needed

var _house_sprite: Sprite2D = null

func try_build(building_id: String) -> bool:
	if not RECIPES.has(building_id):
		return false
	var recipe: Dictionary = RECIPES[building_id]
	for resource_type in recipe:
		var amount: int = recipe[resource_type]
		if TokenManager.get_count(resource_type) < amount:
			return false
	for resource_type in recipe:
		var amount: int = recipe[resource_type]
		TokenManager.try_consume(resource_type, amount)
	building_completed.emit(building_id)
	print("Built: ", building_id)
	if building_id == "house":
		_spawn_house_sprite()
	return true

func _spawn_house_sprite() -> void:
	if _house_sprite != null and is_instance_valid(_house_sprite):
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var texture: Texture2D = load("res://sprite/house.png") as Texture2D
	if texture == null:
		return
	_house_sprite = Sprite2D.new()
	_house_sprite.texture = texture
	_house_sprite.position = ROCK_POSITION + HOUSE_OFFSET_NORTHWEST
	_house_sprite.scale = Vector2(0.22, 0.22)
	_house_sprite.z_index = -1  # behind other assets, in front of background
	tree.current_scene.add_child(_house_sprite)
