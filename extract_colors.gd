extends SceneTree

func _init():
	var img = Image.new()
	var err = img.load("res://sprite/ForestAnimals/FoxSoftColors.png")
	if err == OK:
		var colors = {}
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var c = img.get_pixel(x, y)
				if c.a > 0:
					var hex = c.to_html(false)
					if not colors.has(hex):
						colors[hex] = 0
					colors[hex] += 1
		var arr = []
		for hex in colors:
			arr.append({"color": hex, "count": colors[hex]})
		arr.sort_custom(func(a,b): return a.count > b.count)
		for i in range(min(10, arr.size())):
			print(arr[i].color, " : ", arr[i].count)
	else:
		print("Failed to load image")
	quit()
