# DialogueSystem.gd - Clean version with fixed syntax
class_name DialogueSystem
extends RefCounted

var db: SQLite
var db_path = "res://data/dialogue_system.db"

# Cached data for performance
var player_dialogue_cache = {}
var competence_modifiers_cache = {}
var npc_responses_cache = {}
var faction_flavor_cache = {}
var faction_relationships_cache = {}
var conversation_flow_cache = {}
var threat_modifiers_cache = {}
var dialogue_variables_cache = {}

func _init():
	db = SQLite.new()
	db.path = db_path
	if not db.open_db():
		push_error("Failed to open database at: " + db_path)
		return
	
	load_all_data()

func load_all_data():
	# Load player dialogue base
	db.query("SELECT * FROM player_dialogue_base")
	var i = 0
	while i < db.query_result.size():
		var row = db.query_result[i]
		var key = str(row["dialogue_key"])
		player_dialogue_cache[key] = {
			"social_type": str(row["social_type"]) if row["social_type"] else null,
			"dialogue_phase": str(row["dialogue_phase"]),
			"base_text": str(row["base_text"]),
			"notes": str(row["notes"]) if row["notes"] else ""
		}
		i += 1
	
	# Load competence modifiers
	db.query("SELECT * FROM competence_modifiers")
	i = 0
	while i < db.query_result.size():
		var row = db.query_result[i]
		var level_name = str(row["competence_level"])
		
		if level_name not in competence_modifiers_cache:
			competence_modifiers_cache[level_name] = {}
		
		var modifier_type_name = str(row["modifier_type"])
		if modifier_type_name not in competence_modifiers_cache[level_name]:
			competence_modifiers_cache[level_name][modifier_type_name] = []
		
		var modifier_data = {}
		modifier_data["text"] = str(row["modifier_text"])
		modifier_data["chance"] = float(row["apply_chance"])
		
		competence_modifiers_cache[level_name][modifier_type_name].append(modifier_data)
		i += 1
	
	# Load NPC responses
	db.query("SELECT * FROM npc_responses")
	i = 0
	while i < db.query_result.size():
		var row = db.query_result[i]
		var trait_name = str(row["dominant_trait"])
		
		# Initialize trait dictionary if it doesn't exist
		if trait_name not in npc_responses_cache:
			npc_responses_cache[trait_name] = {}
		
		var response_type_name = str(row["response_type"])
		
		# Initialize response type array if it doesn't exist
		if response_type_name not in npc_responses_cache[trait_name]:
			npc_responses_cache[trait_name][response_type_name] = []
		
		# Create response data
		var response_data = {}
		response_data["text"] = str(row["response_text"])
		if row["threat_context"]:
			response_data["threat_context"] = str(row["threat_context"])
		else:
			response_data["threat_context"] = null
		response_data["includes_price_var"] = bool(row["includes_price_var"])
		
		# Add to cache
		npc_responses_cache[trait_name][response_type_name].append(response_data)
		i += 1
	
	# Load faction flavor
	db.query("SELECT * FROM faction_flavor")
	i = 0
	while i < db.query_result.size():
		var row = db.query_result[i]
		var faction_name = str(row["faction"])
		
		if faction_name not in faction_flavor_cache:
			faction_flavor_cache[faction_name] = {}
		
		var component_type_name = str(row["component_type"])
		if component_type_name not in faction_flavor_cache[faction_name]:
			faction_flavor_cache[faction_name][component_type_name] = []
		
		faction_flavor_cache[faction_name][component_type_name].append(str(row["flavor_text"]))
		i += 1
	
	# Load faction relationships
	db.query("SELECT * FROM faction_relationships")
	i = 0
	while i < db.query_result.size():
		var row = db.query_result[i]
		var key = str(row["faction1"]) + "_" + str(row["faction2"])
		faction_relationships_cache[key] = {
			"relationship": str(row["relationship"]),
			"modifier": float(row["modifier"])
		}
		i += 1
	
	# Load conversation flow
	db.query("SELECT * FROM conversation_flow")
	i = 0
	while i < db.query_result.size():
		var row = db.query_result[i]
		var flow_type_name = str(row["flow_type"])
		
		if flow_type_name not in conversation_flow_cache:
			conversation_flow_cache[flow_type_name] = []
		
		var flow_data = {}
		flow_data["text"] = str(row["flow_text"])
		if row["attempt_number"]:
			flow_data["attempt_number"] = row["attempt_number"]
		else:
			flow_data["attempt_number"] = null
		flow_data["is_final"] = bool(row["is_final"])
		
		conversation_flow_cache[flow_type_name].append(flow_data)
		i += 1
	
	# Load threat modifiers
	db.query("SELECT * FROM threat_modifiers")
	i = 0
	while i < db.query_result.size():
		var row = db.query_result[i]
		var threat_diff_name = str(row["threat_difference"])
		
		if threat_diff_name not in threat_modifiers_cache:
			threat_modifiers_cache[threat_diff_name] = {}
		
		var reaction_type_name = str(row["reaction_type"])
		if reaction_type_name not in threat_modifiers_cache[threat_diff_name]:
			threat_modifiers_cache[threat_diff_name][reaction_type_name] = {}
		
		var intensity_name = str(row["intensity"])
		threat_modifiers_cache[threat_diff_name][reaction_type_name][intensity_name] = str(row["modifier_text"])
		i += 1
	
	# Load dialogue variables
	db.query("SELECT * FROM dialogue_variables")
	i = 0
	while i < db.query_result.size():
		var row = db.query_result[i]
		var var_name = str(row["variable_name"])
		dialogue_variables_cache[var_name] = {
			"type": str(row["variable_type"]),
			"default_value": str(row["default_value"]) if row["default_value"] else "",
			"min_value": float(row["min_value"]) if row["min_value"] else 0.0,
			"max_value": float(row["max_value"]) if row["max_value"] else 100.0,
			"notes": str(row["notes"]) if row["notes"] else ""
		}
		i += 1

func get_player_dialogue(dialogue_key: String, social_type: String, competence_level: String) -> String:
	if not player_dialogue_cache.has(dialogue_key):
		return "ERROR: Dialogue key not found: " + dialogue_key
	
	var base_data = player_dialogue_cache[dialogue_key]
	var base_text = base_data["base_text"]
	
	var modified_text = apply_competence_modifiers(base_text, competence_level)
	modified_text = substitute_variables(modified_text)
	
	return modified_text

func apply_competence_modifiers(base_text: String, competence_level: String) -> String:
	if not competence_modifiers_cache.has(competence_level):
		return base_text
	
	var modifiers = competence_modifiers_cache[competence_level]
	var modified_text = base_text
	
	# Apply prefix
	if modifiers.has("prefix") and modifiers["prefix"].size() > 0:
		var prefix_options = modifiers["prefix"]
		var selected_prefix = prefix_options[randi() % prefix_options.size()]
		if randf() < selected_prefix["chance"]:
			modified_text = selected_prefix["text"] + modified_text
	
	# Apply interruption
	if modifiers.has("interruption") and modifiers["interruption"].size() > 0:
		var interrupt_options = modifiers["interruption"]
		var selected_interrupt = interrupt_options[randi() % interrupt_options.size()]
		if randf() < selected_interrupt["chance"]:
			var words = modified_text.split(" ")
			if words.size() > 2:
				var insert_pos = words.size() / 2
				words.insert(insert_pos, selected_interrupt["text"])
				modified_text = " ".join(words)
	
	# Apply qualifier
	if modifiers.has("qualifier") and modifiers["qualifier"].size() > 0:
		var qualifier_options = modifiers["qualifier"]
		var selected_qualifier = qualifier_options[randi() % qualifier_options.size()]
		if randf() < selected_qualifier["chance"]:
			modified_text = selected_qualifier["text"] + " " + modified_text
	
	# Apply enhancer
	if modifiers.has("enhancer") and modifiers["enhancer"].size() > 0:
		var enhancer_options = modifiers["enhancer"]
		var selected_enhancer = enhancer_options[randi() % enhancer_options.size()]
		if randf() < selected_enhancer["chance"]:
			modified_text = modified_text + ", " + selected_enhancer["text"]
	
	# Apply suffix
	if modifiers.has("suffix") and modifiers["suffix"].size() > 0:
		var suffix_options = modifiers["suffix"]
		var selected_suffix = suffix_options[randi() % suffix_options.size()]
		if randf() < selected_suffix["chance"]:
			modified_text = modified_text + selected_suffix["text"]
	
	return modified_text

func get_npc_response(dominant_trait: String, response_type: String, threat_context: String = "") -> String:
	if not npc_responses_cache.has(dominant_trait):
		return "ERROR: Trait not found: " + dominant_trait
	
	if not npc_responses_cache[dominant_trait].has(response_type):
		return "ERROR: Response type not found: " + response_type
	
	var responses = npc_responses_cache[dominant_trait][response_type]
	
	var filtered_responses = []
	var j = 0
	while j < responses.size():
		var response = responses[j]
		if threat_context.is_empty() or response["threat_context"] == null or response["threat_context"] == threat_context:
			filtered_responses.append(response)
		j += 1
	
	if filtered_responses.is_empty():
		filtered_responses = responses
	
	var selected_response = filtered_responses[randi() % filtered_responses.size()]
	var response_text = selected_response["text"]
	
	response_text = substitute_variables(response_text)
	
	return response_text

func get_faction_flavor(faction: String, component_type: String) -> String:
	if not faction_flavor_cache.has(faction) or not faction_flavor_cache[faction].has(component_type):
		return ""
	
	var flavor_options = faction_flavor_cache[faction][component_type]
	return flavor_options[randi() % flavor_options.size()]

func get_faction_relationship(faction1: String, faction2: String) -> float:
	var key = faction1 + "_" + faction2
	if faction_relationships_cache.has(key):
		return faction_relationships_cache[key]["modifier"]
	
	key = faction2 + "_" + faction1
	if faction_relationships_cache.has(key):
		return faction_relationships_cache[key]["modifier"]
	
	return 1.0

func get_conversation_flow(flow_type: String, attempt_number: int = -1) -> String:
	if not conversation_flow_cache.has(flow_type):
		return "ERROR: Flow type not found: " + flow_type
	
	var flow_options = conversation_flow_cache[flow_type]
	
	var filtered_options = []
	var k = 0
	while k < flow_options.size():
		var option = flow_options[k]
		if attempt_number == -1 or option["attempt_number"] == null or option["attempt_number"] == attempt_number:
			filtered_options.append(option)
		k += 1
	
	if filtered_options.is_empty():
		filtered_options = flow_options
	
	var selected_option = filtered_options[randi() % filtered_options.size()]
	return selected_option["text"]

func get_threat_modifier(threat_difference: String, reaction_type: String, intensity: String = "subtle") -> String:
	if not threat_modifiers_cache.has(threat_difference):
		return ""
	
	if not threat_modifiers_cache[threat_difference].has(reaction_type):
		return ""
	
	var reactions = threat_modifiers_cache[threat_difference][reaction_type]
	if reactions.has(intensity):
		return reactions[intensity]
	
	var reaction_keys = reactions.keys()
	if reaction_keys.size() > 0:
		return reactions[reaction_keys[0]]
	
	return ""

func substitute_variables(text: String) -> String:
	var result = text
	
	result = result.replace("[PRICE]", "100")
	result = result.replace("[PRICE-20%]", "80")
	result = result.replace("[PRICE-25%]", "75")
	result = result.replace("[PRICE-30%]", "70")
	result = result.replace("[PRICE-40%]", "60")
	result = result.replace("[LAST-PRICE]", "85")
	result = result.replace("[FACTION_INSULT]", "outsider")
	result = result.replace("[THREAT_LEVEL]", "minor")
	
	return result

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if db:
			db.close()
