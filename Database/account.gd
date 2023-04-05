extends Node

class_name Account

@export var id: int
@export var player_name: String
@export var level: int
@export var exp: float
@export var max_exp: float
@export var energy: int
@export var gems: int
@export var zel: int
@export var karma: int
@export var arena_orbs: int
# For this data, we can use the %s of a date 
# ==> allow us to look the number since 01-01-1970 
#		between today and last free-gems collected
@export var last_daily_gems: int


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_account_info(id: int, player_name: String, level: int, exp: float, max_exp: float,
energy: int, gems: int, zel: int, karma: int, arena_orbs: int, last_daily_gems: int):
	self.id = id
	self.player_name = player_name
	self.level = level
	self.exp = exp
	self.max_exp = max_exp
	self.energy = energy
	self.gems = gems
	self.zel = zel
	self.karma = karma
	self.arena_orbs = arena_orbs
	self.last_daily_gems = last_daily_gems
	
func get_account_info() -> Array:
	return [id, player_name, level, exp, max_exp, energy, gems, zel, karma, arena_orbs]

func account_is_active() -> bool:
	return player_name != ""
