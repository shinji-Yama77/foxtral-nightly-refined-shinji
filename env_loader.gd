extends Node
class_name EnvLoader

static func load_env(path: String = "res://.env") -> Dictionary:
	var env_vars: Dictionary = {}
	var file = FileAccess.open(path, FileAccess.READ)
	
	if file == null:
		print("No .env file found at: ", path)
		return env_vars
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		
		# Skip empty lines and comments
		if line.is_empty() or line.begins_with("#"):
			continue
		
		# Parse KEY=VALUE format
		var parts = line.split("=", true, 1)
		if parts.size() == 2:
			var key = parts[0].strip_edges()
			var value = parts[1].strip_edges()
			
			# Remove quotes if present
			if value.begins_with('"') and value.ends_with('"'):
				value = value.substr(1, value.length() - 2)
			elif value.begins_with("'") and value.ends_with("'"):
				value = value.substr(1, value.length() - 2)
			
			env_vars[key] = value
	
	file.close()
	print("Loaded ", env_vars.size(), " environment variables")
	return env_vars

static func get_var(key: String, default_value: String = "", path: String = "res://.env") -> String:
	var env = load_env(path)
	return env.get(key, default_value)
