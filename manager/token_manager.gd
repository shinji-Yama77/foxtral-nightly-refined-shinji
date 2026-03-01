extends Node



var token_list:Array[ResourceToken]

func register_token(resource_token:ResourceToken):
	token_list.append(resource_token)
	
func get_resource_count(type: ResourcePoint.ResourcePointType) -> int:
	var count = 0
	for token in token_list:
		if is_instance_valid(token) and token.resource_type == type:
			var parent = token.get_parent()
			if is_instance_valid(parent) and not parent is Fox:
				count += 1
	return count
