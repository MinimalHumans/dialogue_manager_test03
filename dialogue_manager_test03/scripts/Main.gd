# Main.gd - With counter-offer system
extends Control

# UI References
@onready var new_chat_button: Button = $TopPanel/NewChatButton
@onready var randomize_player_button: Button = $TopPanel/RandomizePlayerButton
@onready var randomize_npc_button: Button = $TopPanel/RandomizeNPCButton
@onready var chat_display: RichTextLabel = $MiddlePanel/RightPanel/ChatContainer/ChatDisplay
@onready var options_container: VBoxContainer = $MiddlePanel/RightPanel/OptionsContainer
@onready var chat_scroll: ScrollContainer = $MiddlePanel/RightPanel/ChatContainer
@onready var system_selector: OptionButton = $TopPanel/SystemSelector

# Player Stats UI
@onready var player_diplomatic: OptionButton = $MiddlePanel/LeftPanel/PlayerStatsPanel/PlayerStatsContainer/PlayerGrid/DiplomaticOption
@onready var player_direct: OptionButton = $MiddlePanel/LeftPanel/PlayerStatsPanel/PlayerStatsContainer/PlayerGrid/DirectOption
@onready var player_aggressive: OptionButton = $MiddlePanel/LeftPanel/PlayerStatsPanel/PlayerStatsContainer/PlayerGrid/AggressiveOption
@onready var player_charming: OptionButton = $MiddlePanel/LeftPanel/PlayerStatsPanel/PlayerStatsContainer/PlayerGrid/CharmingOption
@onready var player_empathetic: OptionButton = $MiddlePanel/LeftPanel/PlayerStatsPanel/PlayerStatsContainer/PlayerGrid/EmpatheticOption
@onready var player_faction: OptionButton = $MiddlePanel/LeftPanel/PlayerStatsPanel/PlayerStatsContainer/PlayerGrid/PlayerFactionOption
@onready var player_threat: OptionButton = $MiddlePanel/LeftPanel/PlayerStatsPanel/PlayerStatsContainer/PlayerGrid/PlayerThreatOption

# NPC Stats UI
@onready var npc_diplomatic: OptionButton = $MiddlePanel/LeftPanel/NPCStatsPanel/NPCStatsContainer/NPCGrid/NPCDiplomaticOption
@onready var npc_direct: OptionButton = $MiddlePanel/LeftPanel/NPCStatsPanel/NPCStatsContainer/NPCGrid/NPCDirectOption
@onready var npc_aggressive: OptionButton = $MiddlePanel/LeftPanel/NPCStatsPanel/NPCStatsContainer/NPCGrid/NPCAggressiveOption
@onready var npc_charming: OptionButton = $MiddlePanel/LeftPanel/NPCStatsPanel/NPCStatsContainer/NPCGrid/NPCCharmingOption
@onready var npc_empathetic: OptionButton = $MiddlePanel/LeftPanel/NPCStatsPanel/NPCStatsContainer/NPCGrid/NPCEmpatheticOption
@onready var npc_faction: OptionButton = $MiddlePanel/LeftPanel/NPCStatsPanel/NPCStatsContainer/NPCGrid/NPCFactionOption
@onready var npc_threat: OptionButton = $MiddlePanel/LeftPanel/NPCStatsPanel/NPCStatsContainer/NPCGrid/NPCThreatOption

# System References
var dialogue_system: DialogueSystem
var conversation_state: ConversationState
var selected_system_id: int = 1  # Default to first system

# Competence level mappings
var competence_levels = {
	"INCOMPETENT (0-3)": "INCOMPETENT",
	"STRUGGLING (4-6)": "STRUGGLING", 
	"ADEQUATE (7-9)": "ADEQUATE",
	"NATURAL (10-14)": "NATURAL",
	"MASTERFUL (15+)": "MASTERFUL"
}

var factions = ["FPU", "PIRATE", "MILITARY", "HEXARCHY", "COS", "NEUTRAL"]
var traits = ["DIPLOMATIC", "DIRECT", "AGGRESSIVE", "CHARMING", "EMPATHETIC"]
var threat_levels = ["NEGLIGIBLE", "LOW", "MODERATE", "FORMIDABLE", "OVERWHELMING"]

func _ready():
	dialogue_system = DialogueSystem.new()
	conversation_state = ConversationState.new()
	
	# Fix ChatDisplay sizing issues
	chat_display.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
	chat_display.size_flags_vertical = Control.SIZE_FILL | Control.SIZE_EXPAND
	chat_display.fit_content = false
	chat_display.custom_minimum_size = Vector2(400, 300)
	
	setup_ui()
	populate_system_selector()
	new_chat_button.pressed.connect(_on_new_chat_pressed)
	randomize_player_button.pressed.connect(_on_randomize_player_pressed)
	randomize_npc_button.pressed.connect(_on_randomize_npc_pressed)

func setup_ui():
	# Setup competence level dropdowns for player
	var player_dropdowns = [player_diplomatic, player_direct, player_aggressive, player_charming, player_empathetic]
	for dropdown in player_dropdowns:
		dropdown.clear()
		for level_text in competence_levels.keys():
			dropdown.add_item(level_text)
		dropdown.selected = 2

	# Setup NPC trait dropdowns
	var npc_dropdowns = [npc_diplomatic, npc_direct, npc_aggressive, npc_charming, npc_empathetic]
	for dropdown in npc_dropdowns:
		dropdown.clear()
		for level_text in competence_levels.keys():
			dropdown.add_item(level_text)
		dropdown.selected = 2
	
	# Setup faction dropdowns
	var faction_dropdowns = [player_faction, npc_faction]
	for dropdown in faction_dropdowns:
		dropdown.clear()
		for faction in factions:
			dropdown.add_item(faction)
		dropdown.selected = 0
	
	# Setup threat level dropdowns
	var threat_dropdowns = [player_threat, npc_threat]
	for dropdown in threat_dropdowns:
		dropdown.clear()
		for threat in threat_levels:
			dropdown.add_item(threat)
		dropdown.selected = 2
		
func populate_system_selector():
	system_selector.clear()
	
	# Query all systems from database
	dialogue_system.db.query("SELECT system_id, system_name FROM system_data ORDER BY system_name")
	
	var i = 0
	while i < dialogue_system.db.query_result.size():
		var row = dialogue_system.db.query_result[i]
		var sys_id = row["system_id"]
		var sys_name = str(row["system_name"])
		
		# Add to dropdown (text shows name, but we track ID separately)
		system_selector.add_item(sys_name, sys_id)
		i += 1
	
	# Select the first system by default
	if system_selector.get_item_count() > 0:
		system_selector.selected = 0
		selected_system_id = system_selector.get_item_id(0)
	
	# Connect the selection change signal
	system_selector.item_selected.connect(_on_system_selected)

func _on_system_selected(index: int):
	selected_system_id = system_selector.get_item_id(index)
	print("Selected system ID: ", selected_system_id)

func _on_new_chat_pressed():
	chat_display.text = ""
	
	for child in options_container.get_children():
		child.queue_free()
	
	setup_conversation_state()
	start_conversation()

func setup_conversation_state():
	var player_competence = {
		"DIPLOMATIC": get_competence_from_dropdown(player_diplomatic),
		"DIRECT": get_competence_from_dropdown(player_direct),
		"AGGRESSIVE": get_competence_from_dropdown(player_aggressive),
		"CHARMING": get_competence_from_dropdown(player_charming),
		"EMPATHETIC": get_competence_from_dropdown(player_empathetic)
	}
	
	var npc_competence = {
		"DIPLOMATIC": get_competence_from_dropdown(npc_diplomatic),
		"DIRECT": get_competence_from_dropdown(npc_direct),
		"AGGRESSIVE": get_competence_from_dropdown(npc_aggressive),
		"CHARMING": get_competence_from_dropdown(npc_charming),
		"EMPATHETIC": get_competence_from_dropdown(npc_empathetic)
	}
	
	var dominant_trait = get_dominant_npc_trait(npc_competence)
	
	# Generate random NPC name
	var random_name = dialogue_system.get_random_npc_name()
	
	conversation_state.setup(
		player_competence,
		player_faction.get_item_text(player_faction.selected),
		player_threat.get_item_text(player_threat.selected),
		dominant_trait,
		npc_faction.get_item_text(npc_faction.selected),
		npc_threat.get_item_text(npc_threat.selected),
		random_name  # ADD THIS PARAMETER
	)
	
	print("NPC Name: ", conversation_state.npc_name)  # Debug output

func get_competence_from_dropdown(dropdown: OptionButton) -> String:
	var selected_text = dropdown.get_item_text(dropdown.selected)
	return competence_levels[selected_text]
	


func get_dominant_npc_trait(npc_competence: Dictionary) -> String:
	var diplomatic_val = get_competence_value(npc_competence["DIPLOMATIC"])
	var direct_val = get_competence_value(npc_competence["DIRECT"])
	var aggressive_val = get_competence_value(npc_competence["AGGRESSIVE"])
	var charming_val = get_competence_value(npc_competence["CHARMING"])
	var empathetic_val = get_competence_value(npc_competence["EMPATHETIC"])
	
	var highest_trait = "DIPLOMATIC"
	var highest_value = diplomatic_val
	
	if direct_val > highest_value:
		highest_value = direct_val
		highest_trait = "DIRECT"
	
	if aggressive_val > highest_value:
		highest_value = aggressive_val
		highest_trait = "AGGRESSIVE"
	
	if charming_val > highest_value:
		highest_value = charming_val
		highest_trait = "CHARMING"
	
	if empathetic_val > highest_value:
		highest_value = empathetic_val
		highest_trait = "EMPATHETIC"
	
	return highest_trait

func get_competence_value(competence: String) -> int:
	match competence:
		"INCOMPETENT":
			return 1
		"STRUGGLING":
			return 2
		"ADEQUATE":
			return 3
		"NATURAL":
			return 4
		"MASTERFUL":
			return 5
		_:
			return 3

func start_conversation():
	var greeting = dialogue_system.get_faction_flavor(conversation_state.npc_faction, "greeting")
	add_npc_message(greeting)
	show_initial_request_options()
	
# Add to your Main.gd script

# Call this after initial greeting to show info request option
func show_info_request_option():
	var button = Button.new()
	var info_request = dialogue_system.get_player_dialogue("info_request_initial", "", "ADEQUATE")
	button.text = info_request
	button.pressed.connect(_on_info_request_pressed.bind(info_request))
	options_container.add_child(button)

func _on_info_request_pressed(stored_text: String):
	add_player_message(stored_text)
	
	# Determine if NPC charges for info
	if should_npc_charge_for_info():
		# NPC wants payment
		var paid_response = dialogue_system.get_npc_response(
			conversation_state.npc_trait,
			"information_paid",
			""
		)
		add_npc_message(paid_response)
		show_info_accept_or_negotiate_options()
	else:
		# NPC shares freely
		var free_response_with_description = dialogue_system.get_info_response_with_description(
			conversation_state.npc_trait,
			conversation_state.npc_faction,
			selected_system_id,  # System ID - hardcoded to Helios for now
			true
		)
		add_npc_message(free_response_with_description)
		
		# End with farewell
		var farewell = dialogue_system.get_faction_flavor(conversation_state.npc_faction, "farewell")
		add_npc_message(farewell)
		end_conversation_clean(true)

func should_npc_charge_for_info() -> bool:
	var base_charge_chance = 0.5
	
	# Personality affects willingness to share freely
	match conversation_state.npc_trait:
		"EMPATHETIC":
			base_charge_chance = 0.2  # Usually shares
		"CHARMING":
			base_charge_chance = 0.3
		"DIPLOMATIC":
			base_charge_chance = 0.5
		"DIRECT":
			base_charge_chance = 0.6
		"AGGRESSIVE":
			base_charge_chance = 0.8  # Usually charges
	
	# Good faction relationships reduce charge chance
	var faction_mod = dialogue_system.get_faction_relationship(
		conversation_state.player_faction,
		conversation_state.npc_faction
	)
	
	# Adjust based on faction relationship
	# Allied (1.2) = 0.83x charge chance, Opposing (0.8) = 1.25x charge chance
	var relationship_modifier = 2.0 - faction_mod  # Inverted: better relations = lower chance
	
	# Threat dynamics - higher threat players get charged more often
	var threat_modifier = 1.0
	var player_threat_val = conversation_state.threat_values.get(conversation_state.player_threat_level, 3)
	var npc_threat_val = conversation_state.threat_values.get(conversation_state.npc_threat_level, 3)
	var threat_difference = player_threat_val - npc_threat_val
	
	if threat_difference >= 2:
		threat_modifier = 0.7  # Intimidated, less likely to charge
	elif threat_difference == 1:
		threat_modifier = 0.9
	elif threat_difference == 0:
		threat_modifier = 1.0
	elif threat_difference == -1:
		threat_modifier = 1.1
	elif threat_difference <= -2:
		threat_modifier = 1.3  # Player seems weak, more likely to charge
	
	var final_chance = base_charge_chance * relationship_modifier * threat_modifier
	
	print("=== INFO CHARGE CALCULATION ===")
	print("Base chance (", conversation_state.npc_trait, "): ", base_charge_chance)
	print("Relationship modifier: ", relationship_modifier)
	print("Threat modifier: ", threat_modifier)
	print("Final chance to charge: ", final_chance)
	print("==============================")
	
	return randf() < final_chance

func show_info_accept_or_negotiate_options():
	for child in options_container.get_children():
		child.queue_free()
	
	var faction_key_accept = "price_accept_" + conversation_state.player_faction.to_lower()
	var faction_key_negotiate = "price_negotiate_" + conversation_state.player_faction.to_lower()
	
	var accept_text = dialogue_system.get_player_dialogue(faction_key_accept, "", "ADEQUATE")
	var negotiate_text = dialogue_system.get_player_dialogue(faction_key_negotiate, "", "ADEQUATE")
	
	var accept_button = Button.new()
	accept_button.text = accept_text
	accept_button.pressed.connect(_on_accept_info_price.bind(accept_text))
	options_container.add_child(accept_button)
	
	var negotiate_button = Button.new()
	negotiate_button.text = negotiate_text
	negotiate_button.pressed.connect(_on_negotiate_info_price.bind(negotiate_text))
	options_container.add_child(negotiate_button)

func _on_accept_info_price(stored_text: String):
	add_player_message(stored_text)
	
	# NPC provides the information
	var description = dialogue_system.build_system_description(
		selected_system_id,  # System ID - Helios for now
		conversation_state.npc_faction
	)
	add_npc_message(description)
	
	# End with farewell only (REMOVED success_confirm)
	var farewell = dialogue_system.get_faction_flavor(conversation_state.npc_faction, "farewell")
	add_npc_message(farewell)
	end_conversation_clean(true)

func _on_negotiate_info_price(stored_text: String):
	add_player_message(stored_text)
	
	var npc_response = dialogue_system.get_npc_response(
		conversation_state.npc_trait,
		"negotiate_acknowledge",
		""
	)
	add_npc_message(npc_response)
	
	show_info_negotiation_tactics()

func show_info_negotiation_tactics():
	for child in options_container.get_children():
		child.queue_free()
	
	var approaches = ["DIPLOMATIC", "DIRECT", "AGGRESSIVE", "CHARMING", "EMPATHETIC"]
	
	for approach in approaches:
		var button = Button.new()
		var competence = conversation_state.get_player_competence(approach)
		var dialogue_text = dialogue_system.get_player_dialogue("fuel_negotiate_" + approach.to_lower(), approach, competence)
		
		button.text = approach.capitalize() + ": " + dialogue_text
		button.pressed.connect(_on_info_negotiation_tactic.bind(approach, dialogue_text))
		options_container.add_child(button)

func _on_info_negotiation_tactic(approach: String, stored_dialogue_text: String):
	add_player_message(stored_dialogue_text)
	
	var success = calculate_dialogue_success(approach)
	
	if success:
		# NPC accepts and provides info
		var npc_response = dialogue_system.get_npc_response(
			conversation_state.npc_trait,
			"counter_accept",
			""
		)
		add_npc_message(npc_response)
		
		# Provide the system description
		var description = dialogue_system.build_system_description(
			selected_system_id,  # System ID - Helios
			conversation_state.npc_faction
		)
		add_npc_message(description)
		
		var farewell = dialogue_system.get_faction_flavor(conversation_state.npc_faction, "farewell")
		add_npc_message(farewell)
		end_conversation_clean(true)
	else:
		# Determine if NPC makes counter-offer
		if should_npc_counter_offer(approach):
			# NPC makes counter-offer
			var counter_offer = dialogue_system.get_npc_response(
				conversation_state.npc_trait,
				"counter_offer",
				""
			)
			add_npc_message(counter_offer)
			show_info_counter_offer_choice()
		else:
			# NPC rejects outright
			var rejection_response = dialogue_system.get_npc_response(
				conversation_state.npc_trait,
				"rejection",
				conversation_state.get_threat_context()
			)
			add_npc_message(rejection_response)
			show_info_grudging_choice()

func show_info_counter_offer_choice():
	for child in options_container.get_children():
		child.queue_free()
	
	var faction_key_accept = "enthusiastic_accept_" + conversation_state.player_faction.to_lower()
	var faction_key_reject = "final_reject_" + conversation_state.player_faction.to_lower()
	
	var accept_text = dialogue_system.get_player_dialogue(faction_key_accept, "", "ADEQUATE")
	var reject_text = dialogue_system.get_player_dialogue(faction_key_reject, "", "ADEQUATE")
	
	var accept_button = Button.new()
	accept_button.text = accept_text
	accept_button.pressed.connect(_on_accept_info_counter_offer.bind(accept_text))
	options_container.add_child(accept_button)
	
	var reject_button = Button.new()
	reject_button.text = reject_text
	reject_button.pressed.connect(_on_walk_away_from_info.bind(reject_text))
	options_container.add_child(reject_button)

func show_info_grudging_choice():
	for child in options_container.get_children():
		child.queue_free()
	
	var faction_key_accept = "grudging_accept_" + conversation_state.player_faction.to_lower()
	var faction_key_reject = "final_reject_" + conversation_state.player_faction.to_lower()
	
	var accept_text = dialogue_system.get_player_dialogue(faction_key_accept, "", "ADEQUATE")
	var reject_text = dialogue_system.get_player_dialogue(faction_key_reject, "", "ADEQUATE")
	
	var accept_button = Button.new()
	accept_button.text = accept_text
	accept_button.pressed.connect(_on_grudging_accept_info_price.bind(accept_text))
	options_container.add_child(accept_button)
	
	var reject_button = Button.new()
	reject_button.text = reject_text
	reject_button.pressed.connect(_on_walk_away_from_info.bind(reject_text))
	options_container.add_child(reject_button)

func _on_accept_info_counter_offer(stored_text: String):
	add_player_message(stored_text)
	
	# Provide system description
	var description = dialogue_system.build_system_description(
		selected_system_id,  # System ID
		conversation_state.npc_faction
	)
	add_npc_message(description)
	
	var farewell = dialogue_system.get_faction_flavor(conversation_state.npc_faction, "farewell")
	add_npc_message(farewell)
	end_conversation_clean(true)

func _on_grudging_accept_info_price(stored_text: String):
	add_player_message(stored_text)
	
	var npc_response = dialogue_system.get_npc_response(
		conversation_state.npc_trait,
		"grudging_accept",
		""
	)
	add_npc_message(npc_response)
	
	# Provide system description
	var description = dialogue_system.build_system_description(
		selected_system_id,  # System ID
		conversation_state.npc_faction
	)
	add_npc_message(description)
	
	var farewell = dialogue_system.get_faction_flavor(conversation_state.npc_faction, "farewell")
	add_npc_message(farewell)
	end_conversation_clean(true)

func _on_walk_away_from_info(stored_text: String):
	add_player_message(stored_text)
	
	var dismissal = dialogue_system.get_conversation_flow("polite_dismissal")
	var farewell = dialogue_system.get_faction_flavor(conversation_state.npc_faction, "farewell")
	add_npc_message(dismissal + " " + farewell)
	end_conversation_clean(false)

func show_initial_request_options():
	for child in options_container.get_children():
		child.queue_free()
	
	# Fuel request button
	var fuel_button = Button.new()
	fuel_button.text = "I need to refuel my ship."
	fuel_button.pressed.connect(_on_initial_request_pressed)
	options_container.add_child(fuel_button)
	
	# Info request button
	var info_button = Button.new()
	var info_request = dialogue_system.get_player_dialogue("info_request_initial", "", "ADEQUATE")
	info_button.text = info_request
	info_button.pressed.connect(_on_info_request_pressed.bind(info_request))
	options_container.add_child(info_button)

func _on_initial_request_pressed():
	var initial_request = dialogue_system.get_player_dialogue("fuel_request_initial", "", "ADEQUATE")
	add_player_message(initial_request)
	
	var price_quote = dialogue_system.get_npc_response(
		conversation_state.npc_trait,
		"negotiation",
		conversation_state.get_threat_context()
	)
	
	add_npc_message(price_quote)
	show_accept_or_negotiate_options()

func show_accept_or_negotiate_options():
	for child in options_container.get_children():
		child.queue_free()
	
	var faction_key_accept = "price_accept_" + conversation_state.player_faction.to_lower()
	var faction_key_negotiate = "price_negotiate_" + conversation_state.player_faction.to_lower()
	
	var accept_text = dialogue_system.get_player_dialogue(faction_key_accept, "", "ADEQUATE")
	var negotiate_text = dialogue_system.get_player_dialogue(faction_key_negotiate, "", "ADEQUATE")
	
	var accept_button = Button.new()
	accept_button.text = accept_text
	accept_button.pressed.connect(_on_accept_price_pressed.bind(accept_text))
	options_container.add_child(accept_button)
	
	var negotiate_button = Button.new()
	negotiate_button.text = negotiate_text
	negotiate_button.pressed.connect(_on_try_negotiate_pressed.bind(negotiate_text))
	options_container.add_child(negotiate_button)

func _on_accept_price_pressed(stored_text: String):
	add_player_message(stored_text)
	
	var success_response = dialogue_system.get_conversation_flow("success_confirm")
	var farewell = dialogue_system.get_faction_flavor(conversation_state.npc_faction, "farewell")
	add_npc_message(success_response + " " + farewell)
	end_conversation_clean(true)

func _on_try_negotiate_pressed(stored_text: String):
	add_player_message(stored_text)
	
	var npc_response = dialogue_system.get_npc_response(
		conversation_state.npc_trait,
		"negotiate_acknowledge",
		""
	)
	add_npc_message(npc_response)
	
	show_negotiation_tactics()

func show_negotiation_tactics():
	for child in options_container.get_children():
		child.queue_free()
	
	var approaches = ["DIPLOMATIC", "DIRECT", "AGGRESSIVE", "CHARMING", "EMPATHETIC"]
	
	for approach in approaches:
		var button = Button.new()
		var competence = conversation_state.get_player_competence(approach)
		var dialogue_text = dialogue_system.get_player_dialogue("fuel_negotiate_" + approach.to_lower(), approach, competence)
		
		button.text = approach.capitalize() + ": " + dialogue_text
		button.pressed.connect(_on_negotiation_tactic_pressed.bind(approach, dialogue_text))
		options_container.add_child(button)

func _on_negotiation_tactic_pressed(approach: String, stored_dialogue_text: String):
	add_player_message(stored_dialogue_text)
	
	var success = calculate_dialogue_success(approach)
	
	if success:
		# NPC accepts the counter-offer
		var npc_response = dialogue_system.get_npc_response(
			conversation_state.npc_trait,
			"counter_accept",
			""
		)
		
		var success_confirm = dialogue_system.get_conversation_flow("success_confirm")
		var farewell = dialogue_system.get_faction_flavor(conversation_state.npc_faction, "farewell")
		npc_response += " " + success_confirm + " " + farewell
		
		add_npc_message(npc_response)
		end_conversation_clean(true)
	else:
		# Determine if NPC makes counter-offer
		if should_npc_counter_offer(approach):
			# NPC makes counter-offer
			var counter_offer = dialogue_system.get_npc_response(
				conversation_state.npc_trait,
				"counter_offer",
				""
			)
			add_npc_message(counter_offer)
			show_counter_offer_choice()
		else:
			# NPC rejects outright
			var rejection_response = dialogue_system.get_npc_response(
				conversation_state.npc_trait,
				"rejection",
				conversation_state.get_threat_context()
			)
			add_npc_message(rejection_response)
			show_grudging_choice()

func should_npc_counter_offer(approach: String) -> bool:
	var base_chance = 0.0
	
	# Personality affects willingness to negotiate
	match conversation_state.npc_trait:
		"EMPATHETIC":
			base_chance = 0.7  # Very willing to find middle ground
		"CHARMING":
			base_chance = 0.6  # Likes to keep things friendly
		"DIPLOMATIC":
			base_chance = 0.5  # Professional negotiator
		"DIRECT":
			base_chance = 0.3  # Prefers clear decisions
		"AGGRESSIVE":
			base_chance = 0.2  # Take it or leave it attitude
	
	# Higher player competence increases counter-offer chance
	var competence = conversation_state.get_player_competence(approach)
	var competence_bonus = 0.0
	match competence:
		"MASTERFUL":
			competence_bonus = 0.2
		"NATURAL":
			competence_bonus = 0.1
		"ADEQUATE":
			competence_bonus = 0.0
		"STRUGGLING":
			competence_bonus = -0.1
		"INCOMPETENT":
			competence_bonus = -0.2
	
	var final_chance = base_chance + competence_bonus
	
	print("=== COUNTER-OFFER CHANCE ===")
	print("Base chance (", conversation_state.npc_trait, "): ", base_chance)
	print("Competence bonus: ", competence_bonus)
	print("Final chance: ", final_chance)
	print("===========================")
	
	return randf() < final_chance

func show_counter_offer_choice():
	for child in options_container.get_children():
		child.queue_free()
	
	var faction_key_accept = "enthusiastic_accept_" + conversation_state.player_faction.to_lower()
	var faction_key_reject = "final_reject_" + conversation_state.player_faction.to_lower()
	
	var accept_text = dialogue_system.get_player_dialogue(faction_key_accept, "", "ADEQUATE")
	var reject_text = dialogue_system.get_player_dialogue(faction_key_reject, "", "ADEQUATE")
	
	var accept_button = Button.new()
	accept_button.text = accept_text
	accept_button.pressed.connect(_on_accept_counter_offer.bind(accept_text))
	options_container.add_child(accept_button)
	
	var reject_button = Button.new()
	reject_button.text = reject_text
	reject_button.pressed.connect(_on_walk_away.bind(reject_text))
	options_container.add_child(reject_button)

func show_grudging_choice():
	for child in options_container.get_children():
		child.queue_free()
	
	var faction_key_accept = "grudging_accept_" + conversation_state.player_faction.to_lower()
	var faction_key_reject = "final_reject_" + conversation_state.player_faction.to_lower()
	
	var accept_text = dialogue_system.get_player_dialogue(faction_key_accept, "", "ADEQUATE")
	var reject_text = dialogue_system.get_player_dialogue(faction_key_reject, "", "ADEQUATE")
	
	var accept_button = Button.new()
	accept_button.text = accept_text
	accept_button.pressed.connect(_on_grudging_accept_original.bind(accept_text))
	options_container.add_child(accept_button)
	
	var reject_button = Button.new()
	reject_button.text = reject_text
	reject_button.pressed.connect(_on_walk_away.bind(reject_text))
	options_container.add_child(reject_button)

func _on_accept_counter_offer(stored_text: String):
	add_player_message(stored_text)
	
	var success_confirm = dialogue_system.get_conversation_flow("success_confirm")
	var farewell = dialogue_system.get_faction_flavor(conversation_state.npc_faction, "farewell")
	add_npc_message(success_confirm + " " + farewell)
	end_conversation_clean(true)

func _on_grudging_accept_original(stored_text: String):
	add_player_message(stored_text)
	
	var npc_response = dialogue_system.get_npc_response(
		conversation_state.npc_trait,
		"grudging_accept",
		""
	)
	var success_confirm = dialogue_system.get_conversation_flow("success_confirm")
	var farewell = dialogue_system.get_faction_flavor(conversation_state.npc_faction, "farewell")
	npc_response += " " + success_confirm + " " + farewell
	
	add_npc_message(npc_response)
	end_conversation_clean(true)

func _on_walk_away(stored_text: String):
	add_player_message(stored_text)
	
	var dismissal = dialogue_system.get_conversation_flow("polite_dismissal")
	var farewell = dialogue_system.get_faction_flavor(conversation_state.npc_faction, "farewell")
	add_npc_message(dismissal + " " + farewell)
	end_conversation_clean(false)

func end_conversation_clean(success: bool):
	for child in options_container.get_children():
		child.queue_free()
	
	var end_label = Label.new()
	if success:
		end_label.text = "--- Conversation Complete ---"
		end_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		end_label.text = "--- Negotiation Failed ---"
		end_label.add_theme_color_override("font_color", Color.RED)
	
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options_container.add_child(end_label)

func calculate_dialogue_success(approach: String) -> bool:
	var competence = conversation_state.get_player_competence(approach)
	var base_chance = get_competence_success_rate(competence)
	
	# Trait compatibility
	var trait_match = 1.0
	if approach == conversation_state.npc_trait:
		trait_match = 1.3
	elif is_opposing_approach(approach, conversation_state.npc_trait):
		trait_match = 0.7
	
	# Faction relationship
	var faction_mod = dialogue_system.get_faction_relationship(
		conversation_state.player_faction, 
		conversation_state.npc_faction
	)
	
	# NPC personality price flexibility
	var personality_flexibility = 1.0
	match conversation_state.npc_trait:
		"AGGRESSIVE":
			personality_flexibility = 0.7
		"DIRECT":
			personality_flexibility = 0.9
		"DIPLOMATIC":
			personality_flexibility = 1.1
		"CHARMING":
			personality_flexibility = 1.2
		"EMPATHETIC":
			personality_flexibility = 1.3
	
	# Threat level dynamics
	var threat_modifier = 1.0
	var player_threat_val = conversation_state.threat_values.get(conversation_state.player_threat_level, 3)
	var npc_threat_val = conversation_state.threat_values.get(conversation_state.npc_threat_level, 3)
	var threat_difference = player_threat_val - npc_threat_val
	
	if threat_difference >= 2:
		threat_modifier = 1.3
	elif threat_difference == 1:
		threat_modifier = 1.1
	elif threat_difference == 0:
		threat_modifier = 1.0
	elif threat_difference == -1:
		threat_modifier = 0.9
	elif threat_difference <= -2:
		threat_modifier = 0.7
	
	# Empathetic NPCs sympathize with weak players
	if conversation_state.npc_trait == "EMPATHETIC" and threat_difference < 0:
		threat_modifier = 1.2
	
	# Calculate base success chance
	var success_chance = base_chance * trait_match * faction_mod * personality_flexibility * threat_modifier
	
	# Pity bonus
	var pity_bonus = 0.0
	if (conversation_state.npc_trait == "EMPATHETIC" or conversation_state.npc_trait == "CHARMING"):
		if competence == "INCOMPETENT" or competence == "STRUGGLING":
			pity_bonus = 0.15
	
	var final_chance = success_chance + pity_bonus
	
	print("=== NEGOTIATION SUCCESS CALCULATION ===")
	print("Base Chance (", competence, "): ", base_chance)
	print("Trait Match: ", trait_match)
	print("Faction Modifier: ", faction_mod)
	print("Personality Flexibility (", conversation_state.npc_trait, "): ", personality_flexibility)
	print("Threat Modifier (", threat_difference, " difference): ", threat_modifier)
	print("Pity Bonus: ", pity_bonus)
	print("Final Chance: ", final_chance)
	print("========================================")
	
	return randf() < final_chance

func get_competence_success_rate(competence: String) -> float:
	match competence:
		"INCOMPETENT":
			return 0.2
		"STRUGGLING":
			return 0.4
		"ADEQUATE":
			return 0.6
		"NATURAL":
			return 0.8
		"MASTERFUL":
			return 0.9
		_:
			return 0.6

func is_opposing_approach(approach1: String, approach2: String) -> bool:
	var opposites = {
		"DIPLOMATIC": "AGGRESSIVE",
		"AGGRESSIVE": "DIPLOMATIC",
		"DIRECT": "CHARMING",
		"CHARMING": "DIRECT"
	}
	return opposites.get(approach1, "") == approach2

func add_player_message(text: String):
	chat_display.text += "[color=lightblue]Player: " + text + "[/color]\n\n"
	scroll_to_bottom()

func add_npc_message(text: String):
	chat_display.text += "[color=lightgreen]" + conversation_state.npc_name + ": " + text + "[/color]\n\n"
	scroll_to_bottom()

func scroll_to_bottom():
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value

func _on_randomize_player_pressed():
	player_diplomatic.selected = randi() % competence_levels.size()
	player_direct.selected = randi() % competence_levels.size()
	player_aggressive.selected = randi() % competence_levels.size()
	player_charming.selected = randi() % competence_levels.size()
	player_empathetic.selected = randi() % competence_levels.size()
	player_faction.selected = randi() % factions.size()
	player_threat.selected = randi() % threat_levels.size()

func _on_randomize_npc_pressed():
	npc_diplomatic.selected = randi() % competence_levels.size()
	npc_direct.selected = randi() % competence_levels.size()
	npc_aggressive.selected = randi() % competence_levels.size()
	npc_charming.selected = randi() % competence_levels.size()
	npc_empathetic.selected = randi() % competence_levels.size()
	npc_faction.selected = randi() % factions.size()
	npc_threat.selected = randi() % threat_levels.size()
