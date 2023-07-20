extends Area2D

signal AttackFinished(id: int)
signal TargetSelected(id: int)
signal DamagingEnemy(actual_unit: int, targeted_unit: int)
signal DeathAnimationFinished(id: int, is_ally: bool)

# Flag to let parent scenes check if a unit is in this slot
@export var is_unit = false
# Corresponds to the unit placement in unit_display
@export var place_ID: int = 0
# Is the unit currently being targeted?
@export var is_targeted: bool = false
# Is this our unit, or an enemy?
@export var is_friendly: bool = true
#Let the game know if the unit is dead or not
@export var is_dead: bool = false
# Remember the place ID of the unit being targeted by it's attack
@export var targeted_place_ID:int = 0
# Remember the number of unit currently attacking this unit
@export var time_being_targeted:int = 0

@export var hit_array:Array[int]
# The sprite for the unit
@onready var sprite = $Sprite
# Store the equipment for the unit
@export var idle_equipment: Array[CharEquipment] = []
@export var attack_equipment: Array[CharEquipment] = []
@export var travel_equipment: Array[CharEquipment] = []
# Used to allow the unit to return to their initial spot
var initial_position = Vector2(0,0)

var speed: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect the target selection
	connect("input_event", _on_input_event)

	# Always find a way back home...
	initial_position = position


func set_properties(unit: Unit, flip: bool, new_idle_equipment, new_attack_equipment, new_travel_equipment):
	# Show the correct unit
	sprite.sprite_frames = unit.sprite_sheet
	# Rest any animations from units that previously had this place_id
	$Sprite/AnimationPlayer.play("RESET")
	hit_array = unit.number_of_hit
	# A unit is here!
	is_unit = true
	is_dead = false
	
	var frames = unit.sprite_sheet
	
	targeted_place_ID = 0
	time_being_targeted = 0
	
	# Face the correct direction
	if flip:
		sprite.flip_h = true
		# Only enemies face this direction
		is_friendly = false
	
	# For each piece of equipment, make a sprite and align it
	for equipment_piece in new_idle_equipment:
		print(equipment_piece)
		idle_equipment.append(equipment_piece)
		var new_sprite = ResourceLoader.load("res://Battle/Field/equipment.tscn").instantiate()
		
		new_sprite.set_properties(frames, equipment_piece, flip)
		new_sprite.play(equipment_piece.name)
		# Add to tree
		$Sprite/EquipmentContainer.add_child(new_sprite)

	for equipment_piece in new_attack_equipment:
		# Store the piece
		attack_equipment.append(equipment_piece)
		# Load the equipment scene and set its properties
		var new_sprite = ResourceLoader.load("res://Battle/Field/equipment.tscn").instantiate()
		new_sprite.set_properties(frames, equipment_piece, flip)
		new_sprite.play("Wait")
		# Add to tree
		$Sprite/AtkEquipmentContainer.add_child(new_sprite)
	
	for equipment_piece in new_travel_equipment:
		# Store the piece
		travel_equipment.append(equipment_piece)
		# Load the equipment scene and set its properties
		var new_sprite = ResourceLoader.load("res://Battle/Field/equipment.tscn").instantiate()
		new_sprite.set_properties(frames, equipment_piece, flip)
		new_sprite.play("Wait")
		# Add to tree
		$Sprite/TravelEquipmentContainer.add_child(new_sprite)

	# Play the idle animation
	sprite.play("Idle")
	
	# Set the target to be in the center of the unit.
	# Check the animVersion to see how to calculate the center
	var center: Vector2
	if unit.animationVersion == 1:
		center = sprite.sprite_frames.get_frame_texture("Idle", 0).region.size / 2
	else:
		center = sprite.sprite_frames.get_frame_texture("Idle", 0).get_size() / 2

	var reverse = -1 if flip == true else 1
	# The target subtracts 24 its diameter is 24 = 12*2
	$Clickable.position = center - Vector2(24,24)
	# Reverse the value if enemy unit
	$Clickable.position.x *= reverse
	# Same as above, but subtracts 33 to mitigate the pivot offset
	$Target.position = $Clickable.position - Vector2(33,33)

func reset_spritesheet():
	sprite.sprite_frames = null
	$Sprite/Shadow.sprite_frames = null

# This method move the attacking unit to the target unit (depending the position)
func attack(enemy_position: Vector2):
	print("Attack animation")
	# Move towards enemy
	var tween = create_tween()
	tween.tween_property(self, "position", enemy_position, 1.0 * speed)
	# Play the travel animation if it exists
	if sprite.sprite_frames.has_animation("Travel"):
		sprite.play("Travel")
		# Play any travel equipment and stop any idle equipment
		var counter = 0
		for equipment in travel_equipment:
			$Sprite/TravelEquipmentContainer.get_child(counter).play(equipment.name)
			counter = counter + 1
		counter = 0
		for equipment in idle_equipment:
			$Sprite/EquipmentContainer.get_child(counter).play("Wait")
			counter = counter + 1
	tween.tween_callback(_on_move_finished.bind(true))

func _on_move_finished(play_atk_animation: bool):
	# Plays an attack animation or returns home
	if play_atk_animation:
		sprite.play("Attack")
		var counter = 0
		for equipment in attack_equipment:
			$Sprite/AtkEquipmentContainer.get_child(counter).play(equipment.name)
			counter = counter + 1
		counter = 0
		for equipment in idle_equipment:
			$Sprite/EquipmentContainer.get_child(counter).play("Wait")
			counter = counter + 1
		counter = 0
		for equipment in travel_equipment:
			$Sprite/TravelEquipmentContainer.get_child(counter).play("Wait")
			counter = counter + 1
		for hit in hit_array:
			emit_signal("DamagingEnemy", place_ID, targeted_place_ID, hit)
	else:
		var tween = create_tween()
		tween.tween_property(self, "position", initial_position, 1.0 * speed)
		tween.tween_callback(_on_attack_finished)

func _on_attack_finished():
	emit_signal("AttackFinished", place_ID)
	var counter = 0
	for equipment in idle_equipment:
		$Sprite/EquipmentContainer.get_child(counter).play(equipment.name)
		counter = counter + 1

func _on_unit_animation_finished(anim_name):
	# Switch to idle if attack is complete
	# This does NOT include the death animations, as they are handled by the animitationPlayer
	print(anim_name, " is the anim name")
	if anim_name == "Attack":
		# Attack finished, switch to idle animation
		sprite.play("Idle")
		# Move away from enemy
		_on_move_finished(false)


# This method remove the target of the unit (because the user select it again or the unit has died) 
func remove_target():
	is_targeted = false
	$Target.visible = false

func play_death_animation():
	$Sprite/AnimationPlayer.play("Death")

# This event is trigger when the user click on a unit.
# If it's an enemy unit (!is_friendly), this will add a target on it, if the unit is not dead
func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx):
	# Listen for clicks or taps
	# to do - allow number pad for unit target (1 targets unit1, 2 targets unit2, etc)
	if ((event is InputEventMouseButton and event.is_pressed()) or event is InputEventScreenTouch) and !is_friendly and !is_dead and is_unit:
		is_targeted = true
		$Target.visible = true
		emit_signal("TargetSelected", place_ID)

func _on_death_animation_finished(_anim_name):
	emit_signal("DeathAnimationFinished", place_ID, is_friendly)
