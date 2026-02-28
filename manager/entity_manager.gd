extends Node

var fox_list:Array[Fox]

func register_fox(fox:Fox):
	
	fox_list.append(fox)
	
func search_fox_by_name(name:String)->Fox:

	for fox in fox_list:
		
		if fox.primary_name==name or fox.secondary_name==name:
			
			return fox
			
	return null
	
func execute_order(order:Order):
	
	print("execute order")
	for aim in order.aims :
		
		print("aims :",aim)
		
		var fox_target=search_fox_by_name(aim)
		
		if fox_target != null:
			print("give order to ",fox_target.primary_name)
			fox_target.compute_order(order.order)
