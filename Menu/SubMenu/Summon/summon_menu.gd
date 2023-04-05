extends Control

func _ready():
	pass
	
func _on_back_pressed():
	get_parent().load_scene("res://Menu/SubMenu/Home/home.tscn")
