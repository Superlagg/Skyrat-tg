#define VOLUME_LIGHT 1 // Volume 'light' mode extracts per action
#define VOLUME_STRONG 5 // Volume 'strong' mode extracts per action
#define HANDLE_LIGHT 1 // 'light' mode
#define HANDLE_STRONG 2 // 'strong' mode
#define HANDLE_MODE_LOWEST 1 // The lowest numbered setting currently available (so we dont need yet another list)
#define HANDLE_MODE_HIGHEST 2 // The highest numbered setting currently available
#define PLEASURE_LIGHT 1 // How much pleasure is gained through 'light' mode
#define PLEASURE_STRONG 3 // How much pleasure is gained through 'strong' mode
#define AROUSAL_LIGHT 1 // How much arousal is gained through 'light' mode
#define AROUSAL_STRONG 3 // How much arousal is gained through 'strong' mode
#define PAIN_LIGHT 3 // How much pain is gained through 'light' mode
#define PAIN_STRONG 10 // How much pain is gained through 'strong' mode
// Self-(and otherwise) Expression (of mammary organs)

/// The expression device
/obj/item/milker
	name = "milker"
	desc = "You and me, baby, ain't nothin' but mammals."
	icon_state = "latexballon"
	inhand_icon_state = "nothing"
	force = 0
	throwforce = 0
	item_flags = DROPDEL | ABSTRACT | HAND_ITEM
	attack_verb_continuous = list("slaps")
	attack_verb_simple = list("slap")
	hitsound = 'sound/effects/snap.ogg'
	var/pleasure_amt = PLEASURE_LIGHT
	var/arousal_amt = AROUSAL_LIGHT
	var/pain_amt = PAIN_LIGHT // *chomp*
	var/handle_mode = HANDLE_LIGHT // How aggressively we're going to milk someone
	var/squirt_volume = VOLUME_LIGHT // How much we're trying to express per squeeze / suck / CHOMP

/obj/item/milker/Initialize(mapload)
	. = ..()
	toggleMode(null, TRUE)

/obj/item/milker/attack(mob/living/M, mob/living/carbon/human/user)
	if(!in_range(M, user))
		to_chat(user, span_warning("[M] is too far away!"))
		return FALSE
	var/mob/living/carbon/being_milked = M

	var/obj/item/organ/genital/breasts/breasts = being_milked.getorganslot(ORGAN_SLOT_BREASTS)
	if(!breastCheck(being_milked, user, breasts))
		return FALSE

	/// What's in our other hand? If it's a reagent container, we could try bottling it!
	/// Holding a reagent container implies wanting to *use* the container, so if the container doesn't work, don't proceed!
	var/obj/item/reagent_containers/milk_bottle = user.get_inactive_held_item()
	if(istype(milk_bottle))
		bottleMilk(being_milked, user, breasts, milk_bottle)
	else // Or just drink it
		drinkMilk(being_milked, user, breasts)

/// Set how vigorously you want to make the stuff come out
/obj/item/milker/attack_self(mob/user)
	toggleMode(user, FALSE)

/obj/item/milker/proc/toggleMode(mob/user, milker_setup)
	if(!milker_setup)
		if(handle_mode++ > HANDLE_MODE_HIGHEST)
			handle_mode = HANDLE_MODE_LOWEST
	switch(handle_mode)
		if(HANDLE_LIGHT)
			if(user)
				user.visible_message(
				message = span_purple("[user] relaxes [user.p_their()] jaw and softens [user.p_their()] milking hand, appearing to opt for a gentler approach."),
				self_message = span_purple("You relax your jaw and soften your milking hand, opting for a gentler approach."),
				blind_message = span_purple("You hear a relaxed rustle."),
				vision_distance = 1)
			desc = "[initial(desc)]" + "\n[span_purple("It looks somewhat gentle.")]"
			pleasure_amt = PLEASURE_LIGHT
			arousal_amt = AROUSAL_LIGHT
			pain_amt = PAIN_LIGHT
			squirt_volume = VOLUME_LIGHT
		if(HANDLE_STRONG)
			if(user)
				user.visible_message(
				message = span_purple("[user] tightens [user.p_their()] jaw and clenches [user.p_their()] milking hand, appearing to opt for a more aggressive approach."),
				self_message = span_purple("You tighten your jaw and clench your milking hand, opting for a more aggressive approach."),
				blind_message = span_purple("You hear a vigorous rustle."),
				vision_distance = 1)
			desc = "[initial(desc)]" + "\n[span_purple("It looks rather aggressive!")]"
			pleasure_amt = PLEASURE_STRONG
			arousal_amt = AROUSAL_STRONG
			pain_amt = PAIN_STRONG
			squirt_volume = VOLUME_STRONG

/// Checks if the breasts are present, exposed, lactating, in range, and containing some kind of fluid. Returns a message if not!
/obj/item/milker/proc/breastCheck(mob/living/carbon/being_milked, mob/living/carbon/human/milker, obj/item/organ/genital/breasts/breasts)
	var/self_suckle = (being_milked == milker) // Grammarize
	if(!being_milked.client?.prefs?.read_preference(/datum/preference/toggle/master_erp_preferences))
		to_chat(milker, span_warning("[self_suckle ? "You would prefer to leave those alone!" : "[being_milked] would prefer you leave those alone!"]"))
		return FALSE
	if(!being_milked.client?.prefs?.read_preference(/datum/preference/toggle/erp/sex_toy)) // I guess its a sextoy!
		to_chat(milker, span_warning("[self_suckle ? "You would prefer to put your hands somewhere else!" : "[being_milked] would prefer you to keep your hands to yourself!"]"))
		return FALSE
	if(!iscarbon(being_milked)) // Trying to milk a robot? A megarachnid? *IAN*?
		to_chat(milker, span_warning("You can't milk that!"))
		return FALSE
	if(being_milked.stat != CONSCIOUS)
		to_chat(milker, span_warning("[self_suckle ? "You are in no condition to be milked!" : "[being_milked] is in no condition to be milked!"]"))
		return FALSE
	if(!istype(breasts))
		to_chat(milker, span_warning("[self_suckle ? "You don't have any breasts!" : "[being_milked] doesn't seem to have any breasts!"]"))
		return FALSE
	if(!breasts.is_exposed())
		to_chat(milker, span_warning("[self_suckle ? "You can't get to your breasts!" : "[being_milked]'s breasts aren't accessible!"]"))
		return FALSE
	if(!breasts.lactates)
		to_chat(milker, span_warning("[self_suckle ? "You aren't lactating" : "[being_milked] doesn't seem to be lactating!"]"))
		return FALSE
	if(breasts.internal_fluids.total_volume <= 0)
		to_chat(milker, span_warning("[self_suckle ? "You're out of milk!" : "[being_milked] is fresh out of milk!"]"))
		return FALSE
	if(!in_range(being_milked, milker))
		to_chat(milker, span_warning("[self_suckle ? "Your breasts are too far away! ...somehow!" : "[being_milked]'s breasts are too far away!"]"))
		return FALSE
	return TRUE

/// Checks if the drinker can, in fact, get their mouth onto the thing they're drinking
/obj/item/milker/proc/mouthCheck(mob/living/carbon/human/milker)
	if(!ishuman(milker))
		return FALSE
	var/covered
	if(milker.is_mouth_covered(head_only = 1))
		covered = "headgear"
	else if(milker.is_mouth_covered(mask_only = 1))
		covered = "mask"
	if(covered)
		to_chat(milker, span_warning("You have to remove your [covered] first!"))
		return FALSE
	return TRUE

/// Checks if the container is a container, unsealed, and has room. Retyrns a message if not!
/obj/item/milker/proc/bottleCheck(mob/living/carbon/being_milked, mob/living/carbon/human/milker, obj/item/reagent_containers/milk_bottle)
	if(!istype(milk_bottle)) // Not a container?
		return FALSE
	if(!milk_bottle.is_open_container()) // Sealed container?
		to_chat(milker, span_warning("[milk_bottle] is sealed!"))
		return FALSE
	if(milk_bottle.reagents?.holder_full()) // Is full?
		to_chat(milker, span_warning("[milk_bottle] is full!"))
		return FALSE
	return TRUE

/// Attempt to consume the contents of someone's breasts.
/obj/item/milker/proc/drinkMilk(mob/living/carbon/human/being_milked, mob/living/carbon/human/milker, obj/item/organ/genital/breasts/breasts)
	if(!breastCheck(being_milked, milker, breasts) || !mouthCheck(milker))
		return FALSE

	var/self_suckle = (being_milked == milker) // Feeding off your own supply?

	switch(handle_mode)
		if(HANDLE_LIGHT) // Gentle paws...
			if(self_suckle) // Drinking your own milk
				if(milker.combat_mode)
					milker.visible_message(
					message = span_purple("[milker] yanks one of [milker.p_their()] nipples up to their mouth and starts nibbling..."),
					self_message = span_purple("You yank your nipple up to your mouth and start nibbling..."),
					blind_message = span_purple("You hear an awkward nibbling noise."),
					vision_distance = 1) // Subtle distance
				else
					milker.visible_message(
					message = span_purple("[milker] pulls one of [milker.p_their()] nipples up to [milker.p_their()] lips..."),
					self_message = span_purple("You pull your nipple up to your lips and start suckling..."),
					blind_message = span_purple("You hear an awkward kissing noise."),
					vision_distance = 1)
			else // Drinking someone else's milk
				if(milker.combat_mode)
					milker.visible_message(
					message = span_purple("[milker] yanks one of [being_milked]'s nipples into [milker.p_their()] mouth and starts nibbling..."),
					self_message = span_purple("You yank [being_milked]'s nipple up to your mouth and start nibbling..."),
					blind_message = span_purple("You hear a faint nibbling noise."),
					vision_distance = 1)
				else
					milker.visible_message(
					message = span_purple("[milker] wraps [milker.p_their()] lips around [being_milked]'s nipple and starts to suckle..."),
					self_message = span_purple("You wrap your lips around [being_milked]'s nipple and start suckling..."),
					blind_message = span_purple("You hear a faint kissing noise."),
					vision_distance = 1)
		if(HANDLE_STRONG) // SQUISH
			if(self_suckle) // Drinking your own milk
				if(milker.combat_mode) // CHOMP
					milker.visible_message(
					message = span_purple("[milker] grips hard into one of [milker.p_their()] breasts and wrenches it up to [milker.p_their()] mouth, chomping down hard!"),
					self_message = span_purple("You wrench one of your breasts up to your mouth and start to bite down!"),
					blind_message = span_purple("You hear an awkward chomping noise."),
					vision_distance = 1) // Subtle distance
				else
					milker.visible_message(
					message = span_purple("[milker] clasps a hand into one of [milker.p_their()] breasts, then plunges [milker.p_their()] mouth around [milker.p_their()] nipple!"),
					self_message = span_purple("You grab onto one of your breasts and ram that nipple right into your mouth!"),
					blind_message = span_purple("You hear an awkward plapping noise."),
					vision_distance = 1)
			else // Drinking someone else's milk
				if(milker.combat_mode) // CHOMP
					milker.visible_message(
					message = span_purple("[milker] grips hard into one of [being_milked]'s breasts and wrenches it up to [milker.p_their()] mouth, chomping down hard!"),
					self_message = span_purple("You wrench [being_milked]'s breast up to your mouth and start to bite down!"),
					blind_message = span_purple("You hear a chomping noise."),
					vision_distance = 1)
				else
					milker.visible_message(
					message = span_purple("[milker] clasps a hand into one of [being_milked]'s breasts, then plunges [milker.p_their()] mouth around [being_milked.p_their()] nipple!"),
					self_message = span_purple("You grab onto one of [being_milked]'s breasts and ram that nipple right into your mouth!"),
					blind_message = span_purple("You hear a plapping noise."),
					vision_distance = 1)

	if(!do_mob(milker, being_milked, 1 SECONDS))
		milker.visible_message(
		message = span_purple("[milker] was interrupted!"),
		self_message = span_purple("You were interrupted!"),
		blind_message = span_purple("You hear someone's lips slip."),
		vision_distance = 1)
		return FALSE
	if(!breastCheck(being_milked, milker, breasts)) // Their breasts may have changed state (gutted, clothes, drained...)
		return FALSE

	milker.adjustArousal(arousal_amt)

	switch(handle_mode)
		if(HANDLE_LIGHT) // Gentle paws...
			if(milker.combat_mode) // Nibble...
				milker.visible_message(
				message = span_purple("[milker] nibbles on [self_suckle ? "[milker.p_their()] own" : "[being_milked]'s"] nipple, teasing out a stream of milk!"),
				self_message = span_purple("You nibble into [self_suckle ? "your own" : "[being_milked]'s"] nipple and feel a stream of milk spray into your mouth!"),
				blind_message = span_purple("You hear a nibble, and a squirt."),
				vision_distance = 1)
				being_milked.adjustPain(pain_amt)
				playsound(milker.loc,'sound/weapons/bite.ogg', rand(10,50), TRUE)
			else
				milker.visible_message(
				message = span_purple("[milker] suckles out a gentle stream of [self_suckle ? "[milker.p_their()] own" : "[being_milked]'s"] milk!"),
				self_message = span_purple("You suckle down a gentle stream of [self_suckle ? "your own" : "[being_milked]'s"] milk!"),
				blind_message = span_purple("You hear a slurp."),
				vision_distance = 1)
				being_milked.adjustArousal(arousal_amt)
				being_milked.adjustPleasure(pleasure_amt)
				playsound(milker.loc,'sound/items/drink.ogg', rand(10,50), TRUE)
		if(HANDLE_STRONG) // SQUISH
			if(milker.combat_mode) // CHOMP
				milker.visible_message(
				message = span_purple("[milker] bites down into [self_suckle ? "[milker.p_their()] own" : "[being_milked]'s"] nipple, slurping down a mouthful of milk!"),
				self_message = span_purple("You chomp down into [self_suckle ? "your own" : "[being_milked]'s"] breast and feast upon the milk within!"),
				blind_message = span_purple("You hear a hungry nibble."),
				vision_distance = 1)
				being_milked.adjustPain(pain_amt)
				playsound(milker.loc,'sound/weapons/bite.ogg', rand(10,50), TRUE)
			else
				milker.visible_message(
				message = span_purple("[milker] suckles down a mouthful of [self_suckle ? "[milker.p_their()] own" : "[being_milked]'s"] milk!"),
				self_message = span_purple("You suckle down a mouthful of [self_suckle ? "your own" : "[being_milked]'s"] milk!"),
				blind_message = span_purple("You hear a faint slurp."),
				vision_distance = 1)
				being_milked.adjustArousal(arousal_amt)
				being_milked.adjustPleasure(pleasure_amt)
				playsound(milker.loc,'sound/items/drink.ogg', rand(10,50), TRUE)

	log_combat(milker, being_milked, "fed_boob", breasts.internal_fluids.log_list())

	var/gulp_size = squirt_volume
	SEND_SIGNAL(breasts, COMSIG_DRINK_DRANK, being_milked, milker)
	breasts.internal_fluids.trans_to(milker, gulp_size, transfered_by = being_milked, methods = INGEST)
	return TRUE

/// Attempt to bottle the contents of someone's breasts.
/obj/item/milker/proc/bottleMilk(mob/living/carbon/human/being_milked, mob/living/carbon/human/milker, obj/item/organ/genital/breasts/breasts, obj/item/reagent_containers/milk_bottle)
	if(!bottleCheck(being_milked, milker, milk_bottle))
		return FALSE
	if(!breastCheck(being_milked, milker, breasts))
		return FALSE

	var/self_bottle = (being_milked == milker) // Feeding off your own supply?

	milker.visible_message(
	message = span_purple("[milker] places \a [milk_bottle] under one of [self_bottle ? "[milker.p_their()]" : "[being_milked]'s"] nipples and starts to squeeze..."),
	self_message = span_purple("You place \the [milk_bottle] under one of [self_bottle ? "your" : "[being_milked]'s"] nipples and starts to squeeze..."),
	blind_message = span_purple("You hear a faint plap."),
	vision_distance = 1) // Subtle distance

	if(!do_mob(milker, being_milked, 3 SECONDS))
		milker.visible_message(
		message = span_purple("[milker] was interrupted!"),
		self_message = span_purple("You were interrupted!"),
		blind_message = span_purple("You hear someone's fingers slip."),
		vision_distance = 1)
		return FALSE
	if(!breastCheck(being_milked, milker, breasts)) // Their breasts may have changed state (gutted, clothes, drained...)
		return FALSE
	if(!bottleCheck(being_milked, milker, milk_bottle)) // Their container may have changed state (filled, sealed, dropped...)
		return FALSE

	being_milked.adjustArousal(arousal_amt)
	being_milked.adjustPleasure(pleasure_amt)
	milker.adjustArousal(arousal_amt)

	breasts.internal_fluids.trans_to(milk_bottle, squirt_volume, transfered_by = milker)
	milker.visible_message(
	message = span_purple("[milker] takes aim and squirts some of [self_bottle ? "[milker.p_their()]" : "[being_milked]'s"] milk into \a [milk_bottle]!"),
	self_message = span_purple("You take aim and squirt some of [self_bottle ? "your" : "[being_milked]'s"] milk into \the [milk_bottle]!"),
	blind_message = span_purple("You hear a faint trickle."),
	vision_distance = 1)
	log_combat(milker, being_milked, "bottled_boob", breasts.internal_fluids.log_list())
	return TRUE
