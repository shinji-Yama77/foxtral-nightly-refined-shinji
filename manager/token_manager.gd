extends Node

var token_list: Array[ResourceToken] = []

func register_token(resource_token: ResourceToken) -> void:
	token_list.append(resource_token)

func get_count(resource_type: ResourcePoint.ResourcePointType) -> int:
	var count := 0
	for t in token_list:
		if t.resource_type == resource_type:
			count += 1
	return count

func try_consume(resource_type: ResourcePoint.ResourcePointType, amount: int) -> bool:
	if get_count(resource_type) < amount:
		return false
	var to_remove: Array[ResourceToken] = []
	for t in token_list:
		if t.resource_type == resource_type and to_remove.size() < amount:
			to_remove.append(t)
	for t in to_remove:
		token_list.erase(t)
		t.queue_free()
	return true

