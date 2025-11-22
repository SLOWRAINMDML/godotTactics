extends Node

# Global Game State Manager

enum GameState {
	MENU,
	BATTLE,
	RESULT,
	WORLD_MAP
}

var current_state: GameState = GameState.MENU
var current_battle_scene: Node = null

# Battle State
var turn_queue: Array = []
var current_turn_index: int = 0
var current_active_character: Node = null # Character

# Signals
signal battle_started
signal battle_ended(victory)
signal turn_advanced(character)

func _ready():
	print("[GameManager] Initialized")
	# TODO: Load initial data or settings

func change_state(new_state: GameState):
	current_state = new_state
	print("[GameManager] State changed to: ", GameState.keys()[new_state])
	
	match new_state:
		GameState.MENU:
			_handle_menu_state()
		GameState.BATTLE:
			_handle_battle_state()
		GameState.RESULT:
			_handle_result_state()
		GameState.WORLD_MAP:
			_handle_world_map_state()

func _handle_menu_state():
	pass

func _handle_battle_state():
	pass

func _handle_result_state():
	pass

func _handle_world_map_state():
	pass

# Battle Logic
func start_battle(units: Array):
	print("[GameManager] Starting battle with ", units.size(), " units.")
	change_state(GameState.BATTLE)
	
	# Initialize turn queue based on AGI (descending)
	turn_queue = units.duplicate()
	turn_queue.sort_custom(func(a, b): return a.current_stats["AGI"] > b.current_stats["AGI"])
	
	current_turn_index = -1
	emit_signal("battle_started")
	advance_turn()

func advance_turn():
	if turn_queue.size() == 0:
		return

	current_turn_index = (current_turn_index + 1) % turn_queue.size()
	current_active_character = turn_queue[current_turn_index]
	
	# Check if character is dead
	if current_active_character == null or not is_instance_valid(current_active_character) or current_active_character.current_health <= 0:
		advance_turn() # Skip dead units
		return
		
	# Reset character turn state
	if current_active_character.has_method("start_turn"):
		current_active_character.start_turn()
	
	print("[GameManager] Turn: ", current_active_character.character_name)
	emit_signal("turn_advanced", current_active_character)

func calculate_damage(attacker, defender, skill_name, terrain_name) -> Dictionary:
	# Basic damage calculation based on readme
	# Physical Damage = (Attacker STR + Skill Power) - (Defender DEF * 0.7)
	
	var str_val = attacker.current_stats["STR"]
	var def_val = defender.current_stats["DEF"]
	var dex_val = attacker.current_stats["DEX"]
	
	var skill_power = 10 # Default
	if GameData.SKILLS.has(skill_name):
		skill_power = GameData.SKILLS[skill_name].get("power", 10)
	
	# Growth bonus (simplified)
	var growth_bonus = 1.0 
	
	var base_damage = (str_val * 1.5 + dex_val * 0.5 + skill_power) * growth_bonus - (def_val * 0.7)
	base_damage = max(1, base_damage)
	
	# Critical
	var crit_chance = 0.05 + (dex_val * 0.002)
	var is_critical = randf() < crit_chance
	
	if is_critical:
		base_damage *= 2.0
		
	# Terrain bonus (Height)
	# Assuming we can get height difference, for now ignore or assume flat
	
	return {
		"damage": int(base_damage),
		"is_critical": is_critical
	}
