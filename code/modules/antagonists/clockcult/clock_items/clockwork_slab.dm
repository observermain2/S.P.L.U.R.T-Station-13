/obj/item/clockwork/slab //Clockwork slab: The most important tool in Ratvar's arsenal. Allows scripture recital, tutorials, and generates components.
	name = "clockwork slab"
	desc = "A strange metal tablet. A clock in the center turns around and around."
	clockwork_desc = "A link between you and the Celestial Derelict. It contains information, recites scripture, and is your most vital tool as a Servant.\
	It can be used to link traps and triggers by attacking them with the slab. Keep in mind that traps linked with one another will activate in tandem!"

	icon_state = "dread_ipad"
	lefthand_file = 'icons/mob/inhands/antag/clockwork_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/antag/clockwork_righthand.dmi'
	var/inhand_overlay //If applicable, this overlay will be applied to the slab's inhand

	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL

	var/busy //If the slab is currently being used by something
	var/no_cost = FALSE //If the slab is admin-only and needs no components and has no scripture locks
	var/speed_multiplier = 1 //multiples how fast this slab recites scripture
	// var/selected_scripture = SCRIPTURE_DRIVER //handled UI side
	var/obj/effect/proc_holder/slab/slab_ability //the slab's current bound ability, for certain scripture

	var/recollecting = TRUE //if we're looking at fancy recollection. tutorial enabled by default
	var/recollection_category = "Default"

	var/list/quickbound = list(/datum/clockwork_scripture/spatial_gateway, \
	/datum/clockwork_scripture/ranged_ability/kindle, /datum/clockwork_scripture/ranged_ability/hateful_manacles) //quickbound scripture, accessed by index
	var/maximum_quickbound = 5 //how many quickbound scriptures we can have

	var/ui_x = 800
	var/ui_z = 420

	var/obj/structure/destructible/clockwork/trap/linking //If we're linking traps together, which ones we're doing

/obj/item/clockwork/slab/internal //an internal motor for mobs running scripture
	name = "scripture motor"
	quickbound = list()
	no_cost = TRUE

/obj/item/clockwork/slab/debug
	speed_multiplier = 0
	no_cost = TRUE

/obj/item/clockwork/slab/traitor
	var/spent = FALSE

/obj/item/clockwork/slab/traitor/check_uplink_validity()
	return !spent

/obj/item/clockwork/slab/traitor/attack_self(mob/living/user)
	if(!is_servant_of_ratvar(user) && !spent)
		to_chat(user, "<span class='userdanger'>You press your hand onto [src], golden tendrils of light latching onto you. Was this the best of ideas?</span>")
		if(add_servant_of_ratvar(user, FALSE, FALSE, /datum/antagonist/clockcult/neutered/traitor))
			spent = TRUE
			// Add some (5 KW) power so they don't suffer for 100 ticks
			GLOB.clockwork_power += 5000
			// This intentionally does not use adjust_clockwork_power.
		else
			to_chat(user, "<span class='userdanger'>[src] falls dark. It appears you weren't worthy.</span>")
	return ..()

//ATTACK HAND IGNORING PARENT RETURN VALUE
/obj/item/clockwork/slab/debug/attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(!is_servant_of_ratvar(user))
		add_servant_of_ratvar(user)
	return ..()

/obj/item/clockwork/slab/cyborg //three scriptures, plus a spear and fabricator
	clockwork_desc = "A divine link to the Celestial Derelict, allowing for limited recital of scripture."
	quickbound = list(/datum/clockwork_scripture/ranged_ability/judicial_marker, /datum/clockwork_scripture/ranged_ability/linked_vanguard, \
	/datum/clockwork_scripture/create_object/stargazer)
	maximum_quickbound = 6 //we usually have one or two unique scriptures, so if ratvar is up let us bind one more
	actions_types = list()

/obj/item/clockwork/slab/cyborg/engineer //three scriptures, plus a fabricator
	quickbound = list(/datum/clockwork_scripture/spatial_gateway, /datum/clockwork_scripture/create_object/replicant, /datum/clockwork_scripture/create_object/sigil_of_transmission,  /datum/clockwork_scripture/create_object/stargazer)

/obj/item/clockwork/slab/cyborg/medical //five scriptures, plus a spear
	quickbound = list(/datum/clockwork_scripture/spatial_gateway, /datum/clockwork_scripture/ranged_ability/linked_vanguard, /datum/clockwork_scripture/ranged_ability/sentinels_compromise, \
	/datum/clockwork_scripture/create_object/vitality_matrix)

/obj/item/clockwork/slab/cyborg/security //twoscriptures, plus a spear
	quickbound = list(/datum/clockwork_scripture/spatial_gateway,  /datum/clockwork_scripture/ranged_ability/hateful_manacles, /datum/clockwork_scripture/ranged_ability/judicial_marker)

/obj/item/clockwork/slab/cyborg/peacekeeper //two scriptures, plus a spear
	quickbound = list(/datum/clockwork_scripture/spatial_gateway, /datum/clockwork_scripture/ranged_ability/hateful_manacles, /datum/clockwork_scripture/ranged_ability/judicial_marker)

/obj/item/clockwork/slab/cyborg/janitor //six scriptures, plus a fabricator
	quickbound = list(/datum/clockwork_scripture/spatial_gateway, /datum/clockwork_scripture/create_object/replicant, /datum/clockwork_scripture/create_object/sigil_of_transgression, \
	/datum/clockwork_scripture/create_object/stargazer, /datum/clockwork_scripture/create_object/ocular_warden, /datum/clockwork_scripture/create_object/mania_motor)

/obj/item/clockwork/slab/cyborg/service //six scriptures, plus xray vision
	quickbound = list(/datum/clockwork_scripture/spatial_gateway, /datum/clockwork_scripture/create_object/replicant,/datum/clockwork_scripture/create_object/stargazer, \
	/datum/clockwork_scripture/spatial_gateway, /datum/clockwork_scripture/create_object/clockwork_obelisk)

/obj/item/clockwork/slab/cyborg/miner //two scriptures, plus a spear and xray vision
	quickbound = list(/datum/clockwork_scripture/spatial_gateway, /datum/clockwork_scripture/ranged_ability/linked_vanguard, /datum/clockwork_scripture/spatial_gateway)

/obj/item/clockwork/slab/cyborg/access_display(mob/living/user)
	if(!GLOB.ratvar_awakens)
		to_chat(user, "<span class='warning'>Use the action buttons to recite your limited set of scripture!</span>")
	else
		..()

/obj/item/clockwork/slab/cyborg/ratvar_act()
	..()
	if(!GLOB.ratvar_awakens)
		SStgui.close_uis(src)

/obj/item/clockwork/slab/Initialize()
	. = ..()
	update_slab_info(src)
	START_PROCESSING(SSobj, src)
	if(GLOB.ratvar_approaches)
		name = "supercharged [name]"
		speed_multiplier = max(0.1, speed_multiplier - 0.25)

/obj/item/clockwork/slab/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(slab_ability && slab_ability.ranged_ability_user)
		slab_ability.remove_ranged_ability()
	slab_ability = null
	return ..()

/obj/item/clockwork/slab/dropped(mob/user)
	. = ..()
	addtimer(CALLBACK(src, .proc/check_on_mob, user), 1) //dropped is called before the item is out of the slot, so we need to check slightly later

/obj/item/clockwork/slab/worn_overlays(isinhands = FALSE, icon_file, used_state, style_flags = NONE)
	. = ..()
	if(isinhands && item_state && inhand_overlay)
		var/mutable_appearance/M = mutable_appearance(icon_file, "slab_[inhand_overlay]")
		. += M

/obj/item/clockwork/slab/proc/check_on_mob(mob/user)
	if(user && !(src in user.held_items) && slab_ability && slab_ability.ranged_ability_user) //if we happen to check and we AREN'T in user's hands, remove whatever ability we have
		slab_ability.remove_ranged_ability()

//Power generation
/obj/item/clockwork/slab/process()
	if(GLOB.ratvar_approaches && speed_multiplier == initial(speed_multiplier))
		name = "supercharged [name]"
		speed_multiplier = max(0.1, speed_multiplier - 0.25)
	adjust_clockwork_power(0.1) //Slabs serve as very weak power generators on their own (no, not enough to justify spamming them)

/obj/item/clockwork/slab/examine(mob/user)
	. = ..()
	if(is_servant_of_ratvar(user) || isobserver(user))
		if(LAZYLEN(quickbound))
			for(var/i in 1 to quickbound.len)
				if(!quickbound[i])
					continue
				var/datum/clockwork_scripture/quickbind_slot = quickbound[i]
				. += "Quickbind button: <span class='[get_component_span(initial(quickbind_slot.primary_component))]'>[initial(quickbind_slot.name)]</span>."
		. += "Available power: <span class='bold brass'>[DisplayPower(get_clockwork_power())].</span>"

//Slab actions; Hierophant, Quickbind
/obj/item/clockwork/slab/ui_action_click(mob/user, action)
	if(istype(action, /datum/action/item_action/clock/quickbind))
		var/datum/action/item_action/clock/quickbind/Q = action
		recite_scripture(quickbound[Q.scripture_index], user, FALSE)

//Scripture Recital
/obj/item/clockwork/slab/attack_self(mob/living/user)
	if(iscultist(user))
		to_chat(user, "<span class='heavy_brass'>\"You reek of blood. You've got a lot of nerve to even look at that slab.\"</span>")
		user.visible_message("<span class='warning'>A sizzling sound comes from [user]'s hands!</span>", "<span class='userdanger'>[src] suddenly grows extremely hot in your hands!</span>")
		playsound(get_turf(user), 'sound/weapons/sear.ogg', 50, 1)
		user.dropItemToGround(src)
		user.emote("scream")
		user.apply_damage(5, BURN, BODY_ZONE_L_ARM)
		user.apply_damage(5, BURN, BODY_ZONE_R_ARM)
		return FALSE
	if(!is_servant_of_ratvar(user))
		to_chat(user, "<span class='warning'>The information on [src]'s display shifts rapidly. After a moment, your head begins to pound, and you tear your eyes away.</span>")
		if(user.confused || user.dizziness)
			user.confused += 5
			user.dizziness += 5
		return FALSE
	if(busy)
		to_chat(user, "<span class='warning'>[src] refuses to work, displaying the message: \"[busy]!\"</span>")
		return FALSE
	if(!no_cost && !can_recite_scripture(user))
		to_chat(user, "<span class='nezbere'>[src] hums fitfully in your hands, but doesn't seem to do anything...</span>")
		return FALSE
	access_display(user)

/obj/item/clockwork/slab/AltClick(mob/living/user)
	. = ..()
	if(is_servant_of_ratvar(user) && linking && user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		linking = null
		to_chat(user, "<span class='notice'>Object link canceled.</span>")
		return TRUE

/obj/item/clockwork/slab/proc/access_display(mob/living/user)
	if(!is_servant_of_ratvar(user))
		return FALSE
	ui_interact(user)
	return TRUE

/obj/item/clockwork/slab/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, datum/tgui/master_ui = null, datum/ui_state/state = GLOB.inventory_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "ClockworkSlab", name, ui_x, ui_z, master_ui, state)
		ui.open()

/obj/item/clockwork/slab/proc/recite_scripture(datum/clockwork_scripture/scripture, mob/living/user)
	if(!scripture || !user || !user.canUseTopic(src) || (!no_cost && !can_recite_scripture(user)))
		return FALSE
	if(user.get_active_held_item() != src)
		to_chat(user, "<span class='warning'>You need to hold the slab in your active hand to recite scripture!</span>")
		return FALSE
	var/initial_tier = initial(scripture.tier)
	if(initial_tier == SCRIPTURE_PERIPHERAL)
		to_chat(user, "<span class='warning'>Nice try using href exploits</span>")
		return
	if(!GLOB.ratvar_awakens && !no_cost && !SSticker.scripture_states[initial_tier])
		to_chat(user, "<span class='warning'>That scripture is not unlocked, and cannot be recited!</span>")
		return FALSE
	var/datum/clockwork_scripture/scripture_to_recite = new scripture
	scripture_to_recite.slab = src
	scripture_to_recite.invoker = user
	scripture_to_recite.run_scripture()
	return TRUE


//Gets text for a certain section. "Default" is used for when you first open Recollection.
//Current sections (make sure to update this if you add one:
//- Basics
//- Terminology
//- Components
//- Scripture
//- Power
//- Conversion

/obj/item/clockwork/slab/ui_data(mob/user) //we display a lot of data via TGUI
	. = list()
	.["recollection"] = recollecting
	.["power"] = DisplayPower(get_clockwork_power())
	.["power_unformatted"] = get_clockwork_power()
	// .["rec_text"] = recollection() handled TGUI side
	.["HONOR_RATVAR"] = GLOB.ratvar_awakens
	.["scripture"] = list()
	for(var/s in GLOB.all_scripture)
		var/datum/clockwork_scripture/S = GLOB.all_scripture[s]
		if(S.tier == SCRIPTURE_PERIPHERAL) //yes, tiers are the tabs.
			continue
		
		var/list/data = list()
		data["name"] = S.name
		data["descname"] = S.descname
		data["tip"] = "[S.desc]\n[S.usage_tip]"
		data["required"] = "([DisplayPower(S.power_cost)][S.special_power_text ? "+ [replacetext(S.special_power_text, "POWERCOST", "[DisplayPower(S.special_power_cost)]")]" : ""])"
		data["required_unformatted"] = S.power_cost
		data["type"] = "[S.type]"
		data["quickbind"] = S.quickbind //this is if it cant quickbind
		data["fontcolor"] = get_component_color_bright(S.primary_component)
		data["important"] = S.important //italic!
		
		var/found = quickbound.Find(S.type)
		if(found)
			data["bound"] = found //number (pos) on where is it on the list
		if(S.invokers_required > 1)
			data["invokers"] = "Invokers: [S.invokers_required]"
		
		.["rec_binds"] = list()
		for(var/i in 1 to maximum_quickbound)
			if(GLOB.ratvar_awakens)
				return
			if(LAZYLEN(quickbound) < i || !quickbound[i])
				.["rec_binds"] += list(list())
			else
				var/datum/clockwork_scripture/quickbind_slot = quickbound[i]
				dat += "A <b>Quickbind</b> slot, currently set to <b><font color=[get_component_color_bright(initial(quickbind_slot.primary_component))]>[initial(quickbind_slot.name)]</font></b>.<br>"
	.["power"] = "<b><font color=#B18B25>[DisplayPower(get_clockwork_power())]</b> power is available for scripture and other consumers.</font>"

	switch(selected_scripture) //display info based on selected scripture tier
		if(SCRIPTURE_DRIVER)
			.["tier_info"] = "<font color=#B18B25><b>These scriptures are permanently unlocked.</b></font>"
		if(SCRIPTURE_SCRIPT)
			if(SSticker.scripture_states[SCRIPTURE_SCRIPT])
				.["tier_info"] = "<font color=#B18B25><b>These scriptures are permanently unlocked.</b></font>"
			else
				.["tier_info"] = "<font color=#B18B25><i>These scriptures will automatically unlock when the Ark is halfway ready or if [DisplayPower(SCRIPT_UNLOCK_THRESHOLD)] of power is reached.</i></font>"
		if(SCRIPTURE_APPLICATION)
			if(SSticker.scripture_states[SCRIPTURE_APPLICATION])
				.["tier_info"] = "<font color=#B18B25><b>These scriptures are permanently unlocked.</b></font>"
			else
				.["tier_info"] = "<font color=#B18B25><i>Unlock these optional scriptures by converting another servant or if [DisplayPower(APPLICATION_UNLOCK_THRESHOLD)] of power is reached..</i></font>"
		if(SCRIPTURE_JUDGEMENT)
			if(SSticker.scripture_states[SCRIPTURE_JUDGEMENT])
				.["tier_info"] = "<font color=#B18B25><b>These scriptures are permanently unlocked.</b></font>"
			else
				.["tier_info"] = "<font color=#B18B25><i>Unlock creation of powerful equipment and structures by gaining five members of the cult..</i></font>"


	.["selected"] = selected_scripture
	.["scripturecolors"] = "<font color=#DAAA18>Scriptures in <b>yellow</b> are related to construction and building.</font><br>\
	<font color=#6E001A>Scriptures in <b>red</b> are related to attacking and offense.</font><br>\
	<font color=#1E8CE1>Scriptures in <b>blue</b> are related to healing and defense.</font><br>\
	<font color=#AF0AAF>Scriptures in <b>purple</b> are niche but still important!</font><br>\
	<font color=#DAAA18><i>Scriptures with italicized names are important to success.</i></font>"
	generate_all_scripture()
	.["recollection_categories"] = GLOB.ratvar_awakens ? list() : list(
		list("name" = "Getting Started", "desc" = "First-time servant? Read this first."),
		list("name" = "Basics", "desc" = "A primer on how to play as a servant."),
		list("name" = "Terminology", "desc" = "Common acronyms, words, and terms."),
		list("name" = "Components", "desc" = "Information on components, your primary resource."),
		list("name" = "Scripture", "desc" = "Information on scripture, ancient tools used by the cult."),
		list("name" = "Power", "desc" = "The power system that certain objects use to function."),
		list("name" = "Conversion", "desc" = "Converting the crew, cyborgs, and very walls to your cause.")
	)
	// .["rec_section"]["title"] //this is here if ever we decided to return these back.
	// .["rec_section"]["info"]// wall of info for the thing

/obj/item/clockwork/slab/ui_act(action, params)
	switch(action)
		if("toggle")
			recollecting = !recollecting
		if("recite")
			INVOKE_ASYNC(src, .proc/recite_scripture, text2path(params["script"]), usr, FALSE)
		if("bind")
			var/datum/clockwork_scripture/path = text2path(params["script"]) //we need a path and not a string
			if(!ispath(path, /datum/clockwork_scripture) || !initial(path.quickbind) || initial(path.tier) == SCRIPTURE_PERIPHERAL) //fuck you href bus
				to_chat(usr, "<span class='warning'>Nice try using href exploits</span>")
				return
			var/found_index = quickbound.Find(path)
			if(found_index) //hey, we already HAVE this bound
				if(LAZYLEN(quickbound) == found_index) //if it's the last scripture, remove it instead of leaving a null
					quickbound -= path
				else
					quickbound[found_index] = null //otherwise, leave it as a null so the scripture maintains position
				update_quickbind()
			else
				var/target_index = input("Position of [initial(path.name)], 1 to [maximum_quickbound]?", "Input")  as num|null
				if(isnum(target_index) && target_index > 0 && target_index <= maximum_quickbound && !..())
					var/datum/clockwork_scripture/S
					if(LAZYLEN(quickbound) >= target_index)
						S = quickbound[target_index]
					if(S != path)
						quickbind_to_slot(path, target_index)
		if("rec_category")
			recollection_category = params["category"]
			update_static_data()
	return TRUE

/obj/item/clockwork/slab/proc/quickbind_to_slot(datum/clockwork_scripture/scripture, index) //takes a typepath(typecast for initial()) and binds it to a slot
	if(!ispath(scripture) || !scripture || (scripture in quickbound))
		return
	while(LAZYLEN(quickbound) < index)
		quickbound += null
	var/datum/clockwork_scripture/quickbind_slot = GLOB.all_scripture[quickbound[index]]
	if(quickbind_slot && !quickbind_slot.quickbind)
		return //we can't unbind things we can't normally bind
	quickbound[index] = scripture
	update_quickbind()

/obj/item/clockwork/slab/proc/update_quickbind()
	for(var/datum/action/item_action/clock/quickbind/Q in actions)
		qdel(Q) //regenerate all our quickbound scriptures
	if(LAZYLEN(quickbound))
		for(var/i in 1 to quickbound.len)
			if(!quickbound[i])
				continue
			var/datum/action/item_action/clock/quickbind/Q = new /datum/action/item_action/clock/quickbind(src)
			Q.scripture_index = i
			var/datum/clockwork_scripture/quickbind_slot = GLOB.all_scripture[quickbound[i]]
			Q.name = "[quickbind_slot.name] ([Q.scripture_index])"
			Q.desc = quickbind_slot.quickbind_desc
			Q.button_icon_state = quickbind_slot.name
			Q.UpdateButtonIcon()
			if(isliving(loc))
				Q.Grant(loc)
