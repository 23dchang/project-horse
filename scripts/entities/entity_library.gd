class_name EntityLibrary
extends RefCounted

var game_data: Data

# Take game data
func _init(data: Data) -> void:
	game_data = data

# Load the specific entity's data
## Updates [code]entity[/code]'s attributes with the 
## custom defined resource core game data.
func load_data(entity:Entity) -> void:
	var entity_data:EntitySchema = null
	
	if entity is Player:
		entity_data = game_data.player_list.pop_front()
	elif entity is Boss:
		entity_data = game_data.boss_list.pop_front()
	
	if not entity_data:
		Logging.log("What is going on. Couldn't find entity_data")
		return
	
	for member in entity_data.get_property_list():
		if member.usage & PROPERTY_USAGE_STORAGE != 0 \
		and member.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0:
			var member_name:String = member.name
			
			# tmp work around
			if member_name == "icon":
				pass
			else:
				entity[member_name] = entity_data[member_name]
