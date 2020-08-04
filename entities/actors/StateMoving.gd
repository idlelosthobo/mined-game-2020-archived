extends State

class_name StateMoving

func _ready():
	self.path = entity.path

func _process(delta):
	var move_distance = self.speed * delta
	move_along_path(move_distance)

func move_along_path(distance):
	if path.size() > 0:
		var starting_point = position
		self.looking_point = path[0]
		for i in range(path.size()):
			var distance_to_next_point = starting_point.distance_to(path[0])

			if distance <= distance_to_next_point and distance >= 0.0:
				if distance_to_next_point != 0:
					position = starting_point.linear_interpolate(path[0], distance / distance_to_next_point)
				break
			elif distance < 0.0:
				position = path[0]
				break

			if distance_to_next_point > distance:
				distance -= distance_to_next_point
			else:
				distance = 0.0

			starting_point = path[0]
			path.remove(0)
	else:
		self.new_state = 'idle'
