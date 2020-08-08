extends Node2D

class_name GameMaterial

var resource_handler: ResourceHandler = ResourceHandler.new()

func _ready():
	$Sprite.modulate = Color(0.3,0.15,0.0,1.0)

func set_color(color: String) -> void:
	if color == 'red':
		$Sprite.modulate(Color(255,0,0, 255))
	if color == 'green':
		$Sprite.modulate(Color(0,255,0, 255))
	if color == 'blue':
		$Sprite.modulate(Color(0,0,255, 255))


