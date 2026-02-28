extends Node
class_name Order

enum OrderType {
	BUILD,
	GATHER,
	STOP_FIGHTING,
	REST,
	COMPLIMENTED,
	DANCE,
	RENAME
}

@abstract class SingleOrder:
	var order_type: OrderType

class OrderBuild extends SingleOrder:
	var building: String
	
	func _init(p_building: String) -> void:
		order_type = OrderType.BUILD
		building = p_building

class OrderGather extends SingleOrder:
	var resource: String
	
	func _init(p_resource: String) -> void:
		order_type = OrderType.GATHER
		resource = p_resource

class OrderStopFighting extends SingleOrder:
	func _init() -> void:
		order_type = OrderType.STOP_FIGHTING

class OrderRest extends SingleOrder:
	func _init() -> void:
		order_type = OrderType.REST

class OrderComplimented extends SingleOrder:
	func _init() -> void:
		order_type = OrderType.COMPLIMENTED

class OrderDance extends SingleOrder:
	func _init() -> void:
		order_type = OrderType.DANCE

class OrderRename extends SingleOrder:
	var new_name: String
	
	func _init(p_new_name: String) -> void:
		order_type = OrderType.RENAME
		new_name = p_new_name

enum OrderSentiment { POSITIVE, NEUTRAL, NEGATIVE }

var aims: Array[String]
var order: Array[SingleOrder]
var order_sentiment: OrderSentiment

func _init(p_aims: Array, p_orders: Array, p_sentiment: String) -> void:
	
	aims = []
	
	for aim in p_aims:
		aims.append(str(aim))
	
	order_sentiment = _parse_sentiment(p_sentiment)
	order=[]
	for s_order in p_orders:
		
		var parsed_order = _parse_order(s_order)
		
		if parsed_order!=null:
			order.append(parsed_order) 

static func _parse_sentiment(s: String) -> OrderSentiment:
	match s.to_lower():
		"positive": return OrderSentiment.POSITIVE
		"negative": return OrderSentiment.NEGATIVE
		_: return OrderSentiment.NEUTRAL

static func _parse_order(s_order: String) -> SingleOrder:
	var args := s_order.split(":")
	if args.size() == 0: return null
	
	match args[0].to_lower():
		"build": return OrderBuild.new(args[1]) if args.size() > 1 else null
		"gather": return OrderGather.new(args[1]) if args.size() > 1 else null
		"stop_fighting": return OrderStopFighting.new()
		"rest": return OrderRest.new()
		"complimented": return OrderComplimented.new()
		"dance": return OrderDance.new()
		"rename": return OrderRename.new(args[1] if args.size() > 1 else "")
		_: return null
	
