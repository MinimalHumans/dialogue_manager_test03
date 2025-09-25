# Main.gd - Clean version with fixed syntax
extends Control

# UI References
@onready var new_chat_button: Button = $TopPanel/NewChatButton
@onready var chat_display: RichTextLabel = $MiddlePanel/RightPanel/ChatContainer/ChatDisplay
@onready var options_container: VBoxContainer = $MiddlePanel/RightPanel/OptionsContainer
@onready var chat_scroll: ScrollContainer = $MiddlePanel/RightPanel/ChatContainer

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

# Competence level mappings
var competence_levels = {
	"INCOMPETENT (0-3)": "INCOMPETENT",
	"STRUGGLING (4-6)": "STRUGGLING", 
	"ADEQUATE (7-9)": "ADEQUATE",
	"NATURAL (10-14)": "NATURAL",
	"MASTERFUL (15+)": "MASTERFUL"
}

var factions = ["MERCHANT", "PIRATE", "MILITARY", "RELIGIOUS"]
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
	new_chat_button.pressed.connect(_on_new_chat_pressed)

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
	
	conversation_state.setup(
		player_competence,
		player_faction.get_item_text(player_faction.selected),
		player_threat.get_item_text(player_threat.selected),
		dominant_trait,
		npc_faction.get_item_text(npc_faction.selected),
		npc_threat.get_item_text(npc_threat.selected)
	)

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
	
	# Show initial request options instead of auto-playing
	show_initial_request_options()

func show_initial_request_options():
	for child in options_container.get_children():
		child.queue_free()
	
	# Add the initial fuel request as a clickable option
	var button = Button.new()
	button.text = "I need to refuel my ship."
	button.pressed.connect(_on_initial_request_pressed)
	options_container.add_child(button)

func _on_initial_request_pressed():
	var initial_request = dialogue_system.get_player_dialogue("fuel_request_initial", "", "ADEQUATE")
	add_player_message(initial_request)
	
	# NPC quotes a specific price instead of just agreeing
	var price_quote = dialogue_system.get_npc_response(
		conversation_state.npc_trait,
		"negotiation",  # Use negotiation responses which include prices
		conversation_state.get_threat_context()
	)
	
	var faction_flavor = dialogue_system.get_faction_flavor(conversation_state.npc_faction, "agreement")
	if faction_flavor:
		price_quote = faction_flavor + " " + price_quote
	
	add_npc_message(price_quote)
	show_accept_or_negotiate_options()

func show_accept_or_negotiate_options():
	for child in options_container.get_children():
		child.queue_free()
	
	# Option 1: Accept the quoted price
	var accept_button = Button.new()
	accept_button.text = "Accept: I'll pay the asking price"
	accept_button.pressed.connect(_on_accept_price_pressed)
	options_container.add_child(accept_button)
	
	# Option 2: Try to negotiate
	var negotiate_button = Button.new()
	negotiate_button.text = "Negotiate: That's too high, let me make a counter-offer"
	negotiate_button.pressed.connect(_on_try_negotiate_pressed)
	options_container.add_child(negotiate_button)

func _on_accept_price_pressed():
	# Player accepts the quoted price - immediate success
	add_player_message("I'll take it at that price.")
	
	var success_response = dialogue_system.get_conversation_flow("success_confirm")
	add_npc_message(success_response)
	end_conversation_clean(true)

func _on_try_negotiate_pressed():
	add_player_message("That's more than I was hoping to pay. Let me see if we can work something out...")
	
	var npc_response = "We'll see what you have in mind."
	add_npc_message(npc_response)
	
	# NOW show social approaches as negotiation tactics
	show_negotiation_tactics()

func show_negotiation_tactics():
	for child in options_container.get_children():
		child.queue_free()
	
	var approaches = ["DIPLOMATIC", "DIRECT", "AGGRESSIVE", "CHARMING", "EMPATHETIC"]
	
	for approach in approaches:
		var button = Button.new()
		var competence = conversation_state.get_player_competence(approach)
		# Generate dialogue text ONCE and store it
		var dialogue_text = dialogue_system.get_player_dialogue("fuel_negotiate_" + approach.to_lower(), approach, competence)
		
		button.text = approach.capitalize() + ": " + dialogue_text
		# Pass the stored dialogue text to the callback to avoid regeneration
		button.pressed.connect(_on_negotiation_tactic_pressed.bind(approach, dialogue_text))
		options_container.add_child(button)

func _on_negotiation_tactic_pressed(approach: String, stored_dialogue_text: String):
	# Use the stored dialogue text instead of regenerating it
	add_player_message(stored_dialogue_text)
	
	var success = calculate_dialogue_success(approach)
	
	if success:
		# NPC accepts the counter-offer
		var acceptance_responses = [
			"You drive a hard bargain, but I can work with that.",
			"Fair enough, I can accept that price.",
			"Alright, you've convinced me.",
			"That sounds reasonable."
		]
		var npc_response = acceptance_responses[randi() % acceptance_responses.size()]
		
		var success_confirm = dialogue_system.get_conversation_flow("success_confirm")
		npc_response += " " + success_confirm
		
		add_npc_message(npc_response)
		end_conversation_clean(true)
	else:
		# NPC rejects the counter-offer - offer final choice
		var rejection_response = dialogue_system.get_npc_response(
			conversation_state.npc_trait,
			"rejection",
			conversation_state.get_threat_context()
		)
		add_npc_message(rejection_response)
		show_final_choice()

func show_final_choice():
	for child in options_container.get_children():
		child.queue_free()
	
	# Give player final choice after negotiation fails
	var accept_original_button = Button.new()
	accept_original_button.text = "Fine, I'll pay your original price"
	accept_original_button.pressed.connect(_on_accept_original_price)
	options_container.add_child(accept_original_button)
	
	var walk_away_button = Button.new()
	walk_away_button.text = "No deal, I'll find fuel elsewhere"
	walk_away_button.pressed.connect(_on_walk_away)
	options_container.add_child(walk_away_button)

func _on_accept_original_price():
	add_player_message("Alright, I'll pay your asking price.")
	
	var grudging_responses = [
		"Smart choice.",
		"Good. Let's get this done.",
		"Fine by me."
	]
	var npc_response = grudging_responses[randi() % grudging_responses.size()]
	var success_confirm = dialogue_system.get_conversation_flow("success_confirm")
	npc_response += " " + success_confirm
	
	add_npc_message(npc_response)
	end_conversation_clean(true)

func _on_walk_away():
	add_player_message("I'll find a better deal somewhere else.")
	
	var dismissal = dialogue_system.get_conversation_flow("polite_dismissal")
	add_npc_message(dismissal)
	end_conversation_clean(false)

func show_social_options():
	for child in options_container.get_children():
		child.queue_free()
	
	var approaches = ["DIPLOMATIC", "DIRECT", "AGGRESSIVE", "CHARMING", "EMPATHETIC"]
	
	for approach in approaches:
		var button = Button.new()
		var competence = conversation_state.get_player_competence(approach)
		var dialogue_text = dialogue_system.get_player_dialogue("fuel_social_" + approach.to_lower(), approach, competence)
		
		button.text = approach.capitalize() + ": " + dialogue_text
		button.pressed.connect(_on_social_option_pressed.bind(approach))
		options_container.add_child(button)

func _on_social_option_pressed(approach: String):
	var competence = conversation_state.get_player_competence(approach)
	var dialogue_text = dialogue_system.get_player_dialogue("fuel_social_" + approach.to_lower(), approach, competence)
	
	add_player_message(dialogue_text)
	
	var success = calculate_dialogue_success(approach)
	
	if success:
		var npc_response = dialogue_system.get_npc_response(
			conversation_state.npc_trait,
			"negotiation",
			conversation_state.get_threat_context()
		)
		add_npc_message(npc_response)
		show_negotiation_options()
	else:
		var response_type = "rejection"
		if competence == "INCOMPETENT":
			response_type = "incompetence_reaction"
		
		var npc_response = dialogue_system.get_npc_response(
			conversation_state.npc_trait,
			response_type,
			conversation_state.get_threat_context()
		)
		add_npc_message(npc_response)
		
		if conversation_state.attempt_count < 2:
			show_second_attempt_options()
		else:
			end_conversation_clean(false)

func show_negotiation_options():
	for child in options_container.get_children():
		child.queue_free()
	
	var approaches = ["DIPLOMATIC", "DIRECT", "AGGRESSIVE", "CHARMING", "EMPATHETIC"]
	
	for approach in approaches:
		var button = Button.new()
		var competence = conversation_state.get_player_competence(approach)
		var dialogue_text = dialogue_system.get_player_dialogue("fuel_negotiate_" + approach.to_lower(), approach, competence)
		
		button.text = approach.capitalize() + ": " + dialogue_text
		button.pressed.connect(_on_negotiation_option_pressed.bind(approach))
		options_container.add_child(button)

func _on_negotiation_option_pressed(approach: String):
	var competence = conversation_state.get_player_competence(approach)
	var dialogue_text = dialogue_system.get_player_dialogue("fuel_negotiate_" + approach.to_lower(), approach, competence)
	
	add_player_message(dialogue_text)
	
	var success = calculate_dialogue_success(approach)
	
	if success:
		# NPC accepts the counter-offer - add success confirmation
		var npc_response = dialogue_system.get_npc_response(
			conversation_state.npc_trait,
			"agreement",
			conversation_state.get_threat_context()
		)
		# Add a success confirmation from conversation flow
		var success_confirm = dialogue_system.get_conversation_flow("success_confirm")
		npc_response += " " + success_confirm
		
		add_npc_message(npc_response)
		end_conversation_clean(true)
	else:
		# NPC rejects the counter-offer
		var npc_response = dialogue_system.get_npc_response(
			conversation_state.npc_trait,
			"rejection",
			conversation_state.get_threat_context()
		)
		add_npc_message(npc_response)
		end_conversation_clean(false)

func end_conversation_clean(success: bool):
	# Clear options and add end indicator without additional NPC message
	for child in options_container.get_children():
		child.queue_free()
	
	var end_label = Label.new()
	if success:
		end_label.text = "--- Fuel Transaction Complete ---"
		end_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		end_label.text = "--- Negotiation Failed ---"
		end_label.add_theme_color_override("font_color", Color.RED)
	
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options_container.add_child(end_label)

func show_second_attempt_options():
	conversation_state.attempt_count += 1
	
	for child in options_container.get_children():
		child.queue_free()
	
	var approaches = ["DIPLOMATIC", "DIRECT", "AGGRESSIVE", "CHARMING", "EMPATHETIC"]
	
	for approach in approaches:
		var button = Button.new()
		var competence = conversation_state.get_player_competence(approach)
		var dialogue_text = dialogue_system.get_player_dialogue("fuel_second_" + approach.to_lower(), approach, competence)
		
		button.text = approach.capitalize() + ": " + dialogue_text
		button.pressed.connect(_on_second_attempt_pressed.bind(approach))
		options_container.add_child(button)

func _on_second_attempt_pressed(approach: String):
	var competence = conversation_state.get_player_competence(approach)
	var dialogue_text = dialogue_system.get_player_dialogue("fuel_second_" + approach.to_lower(), approach, competence)
	
	add_player_message(dialogue_text)
	
	var success = calculate_dialogue_success(approach)
	
	if success:
		var npc_response = dialogue_system.get_npc_response(
			conversation_state.npc_trait,
			"agreement",
			conversation_state.get_threat_context()
		)
		add_npc_message(npc_response)
		show_negotiation_options()
	else:
		var npc_response = dialogue_system.get_npc_response(
			conversation_state.npc_trait,
			"rejection",
			conversation_state.get_threat_context()
		)
		add_npc_message(npc_response)
		end_conversation_clean(false)

func calculate_dialogue_success(approach: String) -> bool:
	var competence = conversation_state.get_player_competence(approach)
	var base_chance = get_competence_success_rate(competence)
	
	# =============================================================================
	# NEGOTIATION SUCCESS MODIFIERS - Easily tunable for game balance
	# =============================================================================
	
	# 1. TRAIT COMPATIBILITY (Original System)
	var trait_match = 1.0
	if approach == conversation_state.npc_trait:
		trait_match = 1.3  # TUNING: Perfect match bonus (30% increase)
	elif is_opposing_approach(approach, conversation_state.npc_trait):
		trait_match = 0.7  # TUNING: Opposing approach penalty (30% decrease)
	
	# 2. FACTION RELATIONSHIP (Original System)
	var faction_mod = dialogue_system.get_faction_relationship(
		conversation_state.player_faction, 
		conversation_state.npc_faction
	)
	
	# 3. NPC PERSONALITY PRICE FLEXIBILITY (New System)
	# How willing each personality type is to negotiate on price
	var personality_flexibility = 1.0
	match conversation_state.npc_trait:
		"AGGRESSIVE":
			personality_flexibility = 0.7  # TUNING: Tough negotiators, "take it or leave it"
		"DIRECT":
			personality_flexibility = 0.9  # TUNING: Straightforward, limited flexibility
		"DIPLOMATIC":
			personality_flexibility = 1.1  # TUNING: Reasonable, seeks compromise
		"CHARMING":
			personality_flexibility = 1.2  # TUNING: Flexible, wants to keep everyone happy
		"EMPATHETIC":
			personality_flexibility = 1.3  # TUNING: Most accommodating, considers player needs
	
	# 4. THREAT LEVEL DYNAMICS (New System)
	# Power dynamics affect negotiation success
	var threat_modifier = 1.0
	var player_threat_val = conversation_state.threat_values.get(conversation_state.player_threat_level, 3)
	var npc_threat_val = conversation_state.threat_values.get(conversation_state.npc_threat_level, 3)
	var threat_difference = player_threat_val - npc_threat_val
	
	if threat_difference >= 2:
		threat_modifier = 1.3  # TUNING: Strong intimidation factor
	elif threat_difference == 1:
		threat_modifier = 1.1  # TUNING: Mild intimidation
	elif threat_difference == 0:
		threat_modifier = 1.0  # TUNING: Equal footing
	elif threat_difference == -1:
		threat_modifier = 0.9  # TUNING: Less leverage
	elif threat_difference <= -2:
		threat_modifier = 0.7  # TUNING: Easily dismissed
	
	# SPECIAL CASE: Empathetic NPCs feel sympathy for weak players instead of contempt
	if conversation_state.npc_trait == "EMPATHETIC" and threat_difference < 0:
		threat_modifier = 1.2  # TUNING: Sympathy bonus overrides intimidation penalty
	
	# 5. CALCULATE BASE SUCCESS CHANCE
	var success_chance = base_chance * trait_match * faction_mod * personality_flexibility * threat_modifier
	
	# 6. PITY BONUS (New System) - Applied AFTER multipliers as additive bonus
	# Empathetic and Charming NPCs take pity on struggling players
	var pity_bonus = 0.0
	if (conversation_state.npc_trait == "EMPATHETIC" or conversation_state.npc_trait == "CHARMING"):
		if competence == "INCOMPETENT" or competence == "STRUGGLING":
			pity_bonus = 0.15  # TUNING: 15% additive bonus for incompetent/struggling players
	
	# Final success chance with pity bonus
	var final_chance = success_chance + pity_bonus
	
	# =============================================================================
	# DEBUG INFO (Remove or comment out for production)
	# =============================================================================
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

func end_conversation(success: bool):
	for child in options_container.get_children():
		child.queue_free()
	
	var flow_type = "polite_dismissal" if success else "hostile_ending"
	var ending_text = dialogue_system.get_conversation_flow(flow_type)
	add_npc_message(ending_text)
	
	var end_label = Label.new()
	end_label.text = "--- Conversation Ended ---"
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.add_theme_color_override("font_color", Color.GRAY)
	options_container.add_child(end_label)

func add_player_message(text: String):
	chat_display.text += "[color=lightblue]Player: " + text + "[/color]\n\n"
	scroll_to_bottom()

func add_npc_message(text: String):
	chat_display.text += "[color=lightgreen]NPC: " + text + "[/color]\n\n"
	scroll_to_bottom()

func scroll_to_bottom():
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value
