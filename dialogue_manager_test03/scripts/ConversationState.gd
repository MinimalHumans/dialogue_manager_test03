# ConversationState.gd
class_name ConversationState
extends RefCounted

# Player state
var player_competence = {
	"DIPLOMATIC": "ADEQUATE",
	"DIRECT": "ADEQUATE", 
	"AGGRESSIVE": "ADEQUATE",
	"CHARMING": "ADEQUATE",
	"EMPATHETIC": "ADEQUATE"
}
var player_faction: String = "MERCHANT"
var player_threat_level: String = "MODERATE"

# NPC state
var npc_trait: String = "DIPLOMATIC"
var npc_faction: String = "MERCHANT" 
var npc_threat_level: String = "MODERATE"

# Conversation tracking
var attempt_count: int = 0
var conversation_phase: String = "initial"
var successful_approaches: Array[String] = []
var failed_approaches: Array[String] = []

# Threat level mappings for calculations
var threat_values = {
	"NEGLIGIBLE": 1,
	"LOW": 2,
	"MODERATE": 3,
	"FORMIDABLE": 4,
	"OVERWHELMING": 5
}

func setup(p_competence: Dictionary, p_faction: String, p_threat: String, n_trait: String, n_faction: String, n_threat: String):
	player_competence = p_competence.duplicate()
	player_faction = p_faction
	player_threat_level = p_threat
	npc_trait = n_trait
	npc_faction = n_faction
	npc_threat_level = n_threat
	
	# Reset conversation state
	attempt_count = 0
	conversation_phase = "initial"
	successful_approaches.clear()
	failed_approaches.clear()

func get_player_competence(approach: String) -> String:
	return player_competence.get(approach, "ADEQUATE")

func get_threat_context() -> String:
	var player_threat_value = threat_values.get(player_threat_level, 3)
	var npc_threat_value = threat_values.get(npc_threat_level, 3)
	var difference = player_threat_value - npc_threat_value
	
	if difference >= 2:
		return "player_higher"
	elif difference <= -2:
		return "player_lower"
	elif abs(difference) >= 3:
		return "extreme_mismatch"
	else:
		return ""  # Equal or close, no special context

func get_threat_difference() -> String:
	var player_threat_value = threat_values.get(player_threat_level, 3)
	var npc_threat_value = threat_values.get(npc_threat_level, 3)
	var difference = player_threat_value - npc_threat_value
	
	if difference >= 2:
		return "much_higher"
	elif difference == 1:
		return "higher"
	elif difference == 0:
		return "equal"
	elif difference == -1:
		return "lower"
	else:  # difference <= -2
		return "much_lower"

func record_approach_result(approach: String, success: bool):
	if success and approach not in successful_approaches:
		successful_approaches.append(approach)
	elif not success and approach not in failed_approaches:
		failed_approaches.append(approach)

func has_tried_approach(approach: String) -> bool:
	return approach in successful_approaches or approach in failed_approaches

func get_available_approaches() -> Array[String]:
	var all_approaches = ["DIPLOMATIC", "DIRECT", "AGGRESSIVE", "CHARMING", "EMPATHETIC"]
	var available = []
	
	for approach in all_approaches:
		# Always allow all approaches - competence affects delivery, not availability
		available.append(approach)
	
	return available

func is_conversation_over() -> bool:
	return attempt_count >= 3 or conversation_phase == "ended"

func end_conversation(success: bool):
	conversation_phase = "ended"
	if success:
		conversation_phase = "successful_end"

func get_conversation_summary() -> Dictionary:
	return {
		"attempts": attempt_count,
		"phase": conversation_phase,
		"successful_approaches": successful_approaches.duplicate(),
		"failed_approaches": failed_approaches.duplicate(),
		"player_config": {
			"competence": player_competence.duplicate(),
			"faction": player_faction,
			"threat": player_threat_level
		},
		"npc_config": {
			"trait": npc_trait,
			"faction": npc_faction,
			"threat": npc_threat_level
		}
	}
