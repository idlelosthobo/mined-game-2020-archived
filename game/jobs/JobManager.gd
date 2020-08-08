extends Node

class_name JobManager

const JOB = preload("res://game/jobs/Job.tscn")

var job_location_list: Dictionary

var job_search_delay: float = 0.05
var job_search_timer: float = 0.0
var job_success_limit: int = 10

func _init():
	self.job_location_list['digging'] = Dictionary()
	self.job_location_list['material'] = Dictionary()
	self.job_location_list['equipment'] = Dictionary()
	self.job_location_list['service'] = Dictionary()

func _ready():
	pass # Replace with function body.

func create_job(world_location: Vector2, layer , job_type: String, job_object_node_path: String = 'null'):
	var job: Job = JOB.instance()
	job.setup(world_location, layer, job_type)
	if job_object_node_path != 'null':
		job.object_node_path = job_object_node_path
	add_child(job)
	job_location_list[job_type][job.get_path()] = job.world_location_offset

func remove_job(world_location: Vector2, layer, job_type: String, job_object_node_path: String = 'null'):
	if job_type == 'digging':
		var tile_location = layer.dig_tile_map.world_to_map(world_location)
		get_node('digging_l%s_x%s_y%s' % [layer.number, tile_location.x, tile_location.y]).queue_free()
	#This naming will create problems later when there is lots of these objects.
	if job_type == 'material':
		get_node(job_object_node_path).queue_free()
	if job_type == 'equipment':
		get_node(job_object_node_path).queue_free()
	if job_type == 'service':
		get_node(job_object_node_path).queue_free()

func clean_up_jobs():
	pass

func get_closest_job_node_paths(world_location: Vector2, job_type: String) -> Dictionary:
	var job_distance_list: Dictionary
	for job in job_location_list[job_type]:
		job_distance_list[world_location.distance_to(job_location_list[job_type][job])] = job
#		print(world_location.distance_to(job_location_list[job]))
	var distance_array: Array = job_distance_list.keys()
	distance_array.sort()
	var job_closest_list: Dictionary
	for distance in distance_array:
		job_closest_list[distance] = job_distance_list[distance]
#		print(job_distance_list[distance])
	return job_closest_list

func job_accessibility(job, drone):
	print('%s Accessibility Check' % drone.name)
	job.accessibility = get_node('/root/Game/World/Layer_%s' % job.layer_number).tile_manager.get_accessibility(job.tile_location)
	if job.accessibility['north'] or job.accessibility['east'] or job.accessibility['south'] or job.accessibility['west']:
		if job_direction(job, drone, 'north'):
			return true
		elif job_direction(job, drone, 'east'):
			return true
		elif job_direction(job, drone, 'south'):
			return true
		elif job_direction(job, drone, 'west'):
			return true

func job_direction(job, drone, direction: String) -> bool:
	if job.accessibility[direction] and not job.assigned_units[direction]:
		drone.job_node_path = job.get_path()
		drone.job_position = direction
		drone.working = true
		job.assigned_units[direction] = drone
		return true
	else:
		return false


func _process(delta):
	job_search_timer += delta
	var job_found: bool = true
	var job_success: int = 0
	var process_jobs = true
	if job_search_timer > job_search_delay and process_jobs:
		job_search_timer = 0.0

		if get_tree().get_nodes_in_group("digging_jobs").size() > 0:
			for mining_drone in get_tree().get_nodes_in_group('mining_drones'):
				if not mining_drone.working:
					job_found = false
					var job_path_list = get_closest_job_node_paths(mining_drone.position, 'digging')
					for job_path in job_path_list:
						var job = get_node(job_path_list[job_path])
						if job_accessibility(job, mining_drone):
							job_found = true
							job_success += 1
							break
				if not job_found or job_success >= job_success_limit:
					print('Mining Success %s' % job_success)
					break

		if get_tree().get_nodes_in_group("material_jobs").size() > 0:
			for logistic_drone in get_tree().get_nodes_in_group('logistic_drones'):
				if not logistic_drone.working:
					job_found = false
					var job_path_list = get_closest_job_node_paths(logistic_drone.position, 'material')
					for job_path in job_path_list:
						var job = get_node(job_path_list[job_path])
						if not job.assigned_units['center']:
							logistic_drone.job_node_path = job.get_path()
							logistic_drone.job_position = 'center'
							logistic_drone.working = true
							job.assigned_units['center'] = logistic_drone
							job_found = true
							job_success += 1
							break
				if not job_found or job_success >= job_success_limit:
					print('Logistic Success %s' % job_success)
					break

		if get_tree().get_nodes_in_group("equipment_jobs").size() > 0:
			for construction_drone in get_tree().get_nodes_in_group('construction_drones'):
				if not construction_drone.working:
					job_found = false
					var job_path_list = get_closest_job_node_paths(construction_drone.position, 'equipment')
					for job_path in job_path_list:
						var job = get_node(job_path_list[job_path])
						if job_accessibility(job, construction_drone):
							job_found = true
							job_success += 1
							break
				if not job_found or job_success >= job_success_limit:
					print('Construction Success %s' % job_success)
					break
