extends KinematicBody2D

class_name Actor


onready var entity = $Entity
onready var research_manager: ResearchManager = get_node('/root/Game/ResearchManager')


var working = false

var speed: float
var base_speed: float

var job_node_path = null
var job_position = null
var job_map_key: int = 0

var destination: Destination = Destination.new()

var being_repaired: bool = false

var power_usage_percentage = 0.0
var coolant_usage_percentage = 0.0

var resource_handler: ResourceHandler = ResourceHandler.new()
var base_resource_handler: ResourceHandler = ResourceHandler.new()

var drone: bool = false
var drone_distance_to_distributor: float = 0.0

onready var layer = get_parent()
onready var equipment_manager: EquipmentManager = get_node('/root/Game/World/EquipmentManager')
onready var job_manager: JobManager = get_node('/root/Game/World/JobManager')
onready var resource_manager: ResourceManager = get_node('/root/Game/ResourceManager')

var state: State
var state_manager: StateManager

var path = PoolVector2Array() setget set_path


func _ready():
	add_to_group('Persist')
	state_manager = StateManager.new()
	change_state("idle")


func _physics_process(delta):
	if state.new_state == 'idle':
		change_state('idle')

	if state.new_state == 'moving':
		change_state('moving')

	if state_manager.current_state == 'moving':
		$AnimatedSprite.look_at(state.looking_point)


func _process(delta):
	self.position = self.state.position



func check_map_key() -> bool:
	if layer.tile_manager.map_key != job_map_key:
		job_map_key = layer.tile_manager.map_key
		return true
	else:
		job_map_key = layer.tile_manager.map_key
		return false


func set_path(value):
	path = value
	if value.size() == 0:
		return
	change_state("moving")


func change_state(new_state_name):
	if state:
		state.queue_free()
	state = state_manager.get_state(new_state_name).new()
	state.setup(funcref(self, "change_state"), self)
	state.name = "current_state"
	add_child(state)


func go_to_destination(end_position: Vector2, end_layer_number: int):
	if $Destination.has_step():
		var step = $Destination.get_step()
		if step['action'] == 'path':
			set_path(step['data'])
		if step['action'] == 'elevator':
			use_elevator(step['data'])
	else:
		$Destination.generate_steps(self.position, self.layer.number, end_position, end_layer_number)


func use_elevator(elevator_node_path):
	var elevator = get_node(elevator_node_path)
	if elevator.type == 'elevator_down':
		var new_layer = get_node(elevator.linked_elevator_up_node_path).get_parent()
		get_parent().move_node_to_layer(self.get_path(), new_layer)
		elevator_node_path = null
	if elevator.type == 'elevator_up':
		var new_layer = get_node(elevator.linked_elevator_down_node_path).get_parent()
		get_parent().move_node_to_layer(self.get_path(), new_layer)
		elevator_node_path = null


func repair():
	self.entity.durability = 100.0
	self.being_repaired = false


func _on_Timer_timeout():
	if drone:
		self.drone_distance_to_distributor = equipment_manager.get_distance_to_closest_equipment(self.position, layer, 'distributor')
#		print('Updating Distance to Distributor %s' % drone_distance_to_distributor)
		var multiplier: float = 1.0
		var free_distance: float = 200.0 +  research_manager.research_affect_list['distributor_range_increase']
		if drone_distance_to_distributor > free_distance:
			multiplier = 1.0 + ((drone_distance_to_distributor - free_distance) / free_distance)
		resource_handler.power_usage = base_resource_handler.power_usage * multiplier
		resource_handler.coolant_usage = base_resource_handler.coolant_usage * multiplier

		var durability_color: float = (self.entity.get_durability_percentage() * 0.8) + 0.2
		$AnimatedSprite.modulate = Color(durability_color, durability_color, durability_color, 1.0)
		if self.entity.need_repair() and not being_repaired:
			job_manager.create_job(self.position, self.layer, 'service', self.get_path())
			being_repaired = true
#		print('Power Usage: %s' % resource_handler.power_usage)

