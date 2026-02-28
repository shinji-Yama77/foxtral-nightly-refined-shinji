extends Node

var resource_array:Array[ResourcePoint] = []

func register_resource(resource:ResourcePoint):
	
	resource_array.append(resource)

func select_resource_by_name(name:String)-> ResourcePoint:
	
	for resource in resource_array:
		
		if ResourcePoint.place_name[resource.resource_type] == name:
			return resource
		
	return null
