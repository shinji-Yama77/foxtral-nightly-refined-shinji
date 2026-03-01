extends CharacterBody2D
class_name Fox

@onready var animation_player = $AnimationPlayer
@onready var animation_sprite = $Sprite2D
@onready var nametag = $Nametag

@export var primary_name:String =""
@export var speed = 30
@export var body_color: Color = Color(1, 1, 1, 1)

const random_moving_time = 3

const Token: PackedScene = preload("res://entity/resource_token.tscn")

const gather_area = 30
const drop_scatter_radius = 10

var secondary_name:String = ""

var happyness:float = 0.75
var tiredness:float = 0.0
var obediance:float = 0.25
@onready var hungryness:float = randf_range(0,0.25)

const HUNGER_RATE = 0.0025
const HUNGER_THRESHOLD = 1.0
const HUNGER_SHOW_THRESHOLD = 0.5
const FRUIT_SIZE = 32
const FRUIT_COLS = 4
const FRUIT_ROWS = 3

var hunger_sprite: Sprite2D

var mouse_pos:Vector2

var _is_mic_enabled: bool = false
var _alive_timer: float = 0.0

enum TaskType{
	GATHER,
	BUILD,
	REST,
	EAT
}

@abstract class Task:
	var type:TaskType
	
	@abstract func process(fox:Fox)->bool

class TaskRest:
	extends Task
	
	var moving:bool = false
	var moving_timer:Timer = null
	var moving_direction:Vector2=Vector2()
	
	func _init():
		type = TaskType.REST
		
	func process(fox:Fox):
		
		if moving==false:
			
			if randf()>0.98:
				moving=true
				moving_timer = Timer.new()
				moving_timer.wait_time = random_moving_time
				
				fox.add_child(moving_timer)
				
				moving_timer.start()
				
				moving_timer.timeout.connect(func():moving=false;moving_timer.queue_free())
				moving_direction= Vector2(randf_range(-1,1),randf_range(-1,1))
				moving_direction = moving_direction/moving_direction.length()
			
		else:

			fox.velocity+=moving_direction*fox.speed/3
			
		return false

class TaskBuild:
	extends Task
	
	var building_id: String
	var house: ResourcePoint
	var house_position: Vector2
	const build_distance: float = 10.0
	
	func _init(p_building_id: String):
		type = TaskType.BUILD
		building_id = p_building_id
		house = ResourceManager.select_resource_by_name("house")
		if house != null:
			house_position = house.get_position() + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * drop_scatter_radius
		else:
			house_position = Vector2.ZERO
	
	func process(fox: Fox) -> bool:
		if house == null:
			return true
		var dist := (fox.get_position() - house_position).length()
		if dist < build_distance:
			BuildingManager.try_build(building_id)
			return true
		fox.velocity = fox.get_position().direction_to(house_position) * fox.speed
		return false
		
class TaskGather:
	extends Task
	
	var resource:ResourcePoint
	var resource_token:ResourceToken
	var amount:int
	
	var resource_gathered:bool=false
	
	var house = ResourceManager.select_resource_by_name("house")
	
	var target_position:Vector2
	var house_position:Vector2
	
	func _init(a_resource:String,a_amount:int=1):
		type = TaskType.GATHER
		resource=ResourceManager.select_resource_by_name(a_resource)
		amount=a_amount
		house_position = house.get_position()+ Vector2(randf_range(-1, 1), randf_range(-1, 1)) * drop_scatter_radius
		
		target_position = resource.get_position()+Vector2(randf_range(-1,1),randf_range(-1,1))*gather_area
		
	func process(fox:Fox)->bool:
		
		if resource_gathered ==false:
			
			fox.velocity= fox.get_position().direction_to(target_position)*fox.speed
			
			if (fox.get_position()-target_position).length()<5:
				
				resource_gathered=true
								
				resource_token = Token.instantiate()
				fox.add_child(resource_token)
				resource_token.set_token_type(resource.resource_type)
				
				resource_token.position = fox.mouse_pos
		else:
			resource_token.position = fox.mouse_pos
			fox.velocity= fox.get_position().direction_to(house_position)*fox.speed
			
			if (fox.get_position()-house_position).length()<5:

				resource_token.reparent(fox.get_parent())
				TokenManager.register_token(resource_token)
				return true
		
		return false

class TaskEat:
	extends Task

	var food_token: ResourceToken
	var target_position: Vector2

	func _init():
		type = TaskType.EAT
		food_token = TokenManager.get_token(ResourcePoint.ResourcePointType.FOOD)

	func process(fox: Fox) -> bool:
		if not food_token or not is_instance_valid(food_token):
			return true
		
		target_position = food_token.global_position
		fox.velocity = fox.get_position().direction_to(target_position) * fox.speed

		if (fox.get_position() - target_position).length() < 5:
			if TokenManager.try_consume(ResourcePoint.ResourcePointType.FOOD, 1):
				fox.hungryness = 0.0
			return true

		return false

var schedule:Array[Task] = [TaskRest.new()]

func rename(new_name:String):
	
	secondary_name = new_name
	nametag.text = new_name

func compute_order(orders:Array[Order.SingleOrder]):
	
	for order in orders:
		match order.order_type:
			Order.OrderType.REST:
				self.rest()
			Order.OrderType.RENAME:
				rename(order.new_name)
				
			Order.OrderType.GATHER:
				schedule.insert(0, TaskGather.new(order.resource, 1))
			Order.OrderType.BUILD:
				var build_order := order as Order.OrderBuild
				if build_order != null:
					schedule.insert(0, TaskBuild.new(build_order.building))
			Order.OrderType.EAT:
				schedule.insert(0, TaskEat.new())

func flip(flip:bool):
	
	animation_sprite.flip_h = flip
	if flip:
		mouse_pos=Vector2(-7,-7)
	else:
		mouse_pos=Vector2(7,-7)
	
func rest():
	
	schedule = [TaskRest.new()]
	
func _ready() -> void:

	animation_player.play("idle")
	EntityManager.register_fox(self)
	nametag.text = primary_name
	
	var mat = ShaderMaterial.new()
	mat.shader = load("res://entity/fox_color.gdshader")
	mat.set_shader_parameter("body_color", body_color)
	animation_sprite.material = mat



	hunger_sprite = Sprite2D.new()
	hunger_sprite.texture = load("res://sprite/FruitsVegetables/Fruits.png")
	hunger_sprite.region_enabled = true
	hunger_sprite.position = Vector2(16, -8)
	hunger_sprite.scale = Vector2(0.5, 0.5)
	hunger_sprite.visible = false
	add_child(hunger_sprite)
	
	if GuiManager != null:
		if not GuiManager.is_node_ready():
			await GuiManager.ready
		if GuiManager.gui_scene != null:
			GuiManager.gui_scene.talk_pressed.connect(_on_talk_start)
			GuiManager.gui_scene.talk_released.connect(_on_talk_stop)

func _on_talk_start() -> void:
	_is_mic_enabled = true

func _on_talk_stop() -> void:
	_is_mic_enabled = false

func _process(delta: float) -> void:
	_alive_timer += delta
	var target_alpha: float = 0.0
	if _alive_timer < 5.0 or _is_mic_enabled:
		target_alpha = 1.0
	
	var current_alpha = nametag.modulate.a
	if current_alpha != target_alpha:
		nametag.modulate.a = move_toward(current_alpha, target_alpha, delta)

func _pick_random_fruit() -> void:
	var col = randi() % FRUIT_COLS
	var row = randi() % FRUIT_ROWS
	hunger_sprite.region_rect = Rect2(col * FRUIT_SIZE, row * FRUIT_SIZE, FRUIT_SIZE, FRUIT_SIZE)

func _physics_process(delta: float) -> void:

	hungryness = minf(hungryness + HUNGER_RATE * delta, HUNGER_THRESHOLD)

	var should_show = hungryness >= HUNGER_SHOW_THRESHOLD
	if should_show and not hunger_sprite.visible:
		_pick_random_fruit()
	hunger_sprite.visible = should_show

	velocity=Vector2()

	var actual_task = schedule[0]

	if actual_task.process(self):
		schedule.pop_front()

	velocity *= 1.0 - (hungryness * 0.7)
		
		
	if velocity.length() >0 :
		animation_player.play("running")
		
		if velocity.x >0:
			flip(false)
		else:
			flip(true)
	else:
		
			animation_player.play("idle")
		
		
	move_and_slide()
	
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		velocity += collision.get_normal() * speed * 0.5
		
	position.x = clamp(position.x, 16, 304)
	position.y = clamp(position.y, 32, 164)
		
