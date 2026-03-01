extends CharacterBody2D
class_name Fox

@onready var animation_player = $AnimationPlayer
@onready var animation_sprite = $Sprite2D
@onready var nametag = $Nametag

@export var primary_name:String =""
@export var speed = 30
const random_moving_time = 3

const Token: PackedScene = preload("res://entity/resource_token.tscn")

const gather_area = 30
const drop_scatter_radius = 10

var secondary_name:String = ""

var happyness:float = 0.75
var tiredness:float = 0.0
var obediance:float = 0.25
var hungryness:float = 0.0 

var mouse_pos:Vector2

enum TaskType{
	GATHER,
	BUILD,
	REST
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
				
				moving_timer.timeout.connect(func():moving=false)
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

func _physics_process(delta: float) -> void:
	
	velocity=Vector2()
	
	var actual_task = schedule[0]
	
	if actual_task.process(self):
		schedule.pop_front()
		
		
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
		
