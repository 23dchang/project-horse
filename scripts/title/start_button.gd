extends Button

# To whomever it may concern, this is just placeholder code to test transitioning
# between scenes (e.g. Title screen -> Boss fight). Obviously, you are allowed to change
# the name of variables/scripts as I assume "start_button.gd" may clash with future buttons
# of a similar name. As such, feel free to change/rewrite the code here. THX!


func _on_pressed() -> void:
	get_tree().root.get_node("World").load_scene("res://scenes/boss_fight.tscn")
