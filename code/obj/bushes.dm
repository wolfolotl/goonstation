/obj/shrub //copy-pasted from decorations.dm
	name = "shrub"
	desc = "A bush. Despite your best efforts, you can't tell if it's real or not."
	icon = 'icons/misc/bushes.dmi'
	icon_state = "bush-scruffy"
	anchored = ANCHORED
	density = 0
	layer = EFFECTS_LAYER_UNDER_1
	flags = FLUID_SUBMERGE
	text = "<font color=#5c5>s"
	var/health = 50
	var/destroyed = 0 // Broken shrubs are unable to vend prizes, this is also used to track a objective.
	var/max_uses = 0 // The maximum amount of time one can try to shake this shrub for something.
	var/spawn_chance = 0 // How likely is this shrub to spawn something?
	var/last_use = 0 // To prevent spam.
	var/time_between_uses = 400 // The default time between uses.
	var/override_default_behaviour = 0 // When this is set to 1, the additional_items list will be used to dispense items.
	var/list/additional_items = list() // See above.
	/// How many bites can cow people take out of it?
	var/bites = 5
	/// The mask used to show bite marks
	var/current_mask = 5
	/// Is the bush actually made out of plastic?
	var/is_plastic = FALSE

	New()
		..()
		max_uses = rand(0, 5)
		spawn_chance = rand(1, 40)
		if (prob(5))
			is_plastic = TRUE
		#ifdef XMAS
		if(src.z == Z_LEVEL_STATION)
			src.UpdateOverlays(image(src.icon, "[icon_state]-xmas"), "xmas")
		#endif

	ex_act(var/severity)
		switch(severity)
			if(1,2)
				qdel(src)
			else
				src.take_damage(45)

	attack_hand(mob/user)
		if (!user) return
		if (destroyed && iscow(user) && user.a_intent == INTENT_HELP)
			boutput(user, "<span class='notice'>You pick at the ruined bush, looking for any leaves to graze on, but cannot find any.</span>")
			return ..()
		else if (destroyed)
			return ..()

		user.lastattacked = src
		if (iscow(user) && user.a_intent == INTENT_HELP)	//Cow people may want to eat some of the bush's leaves
			graze(user)
			return 0

		playsound(src, 'sound/impact_sounds/Bush_Hit.ogg', 50, 1, -1)

		var/original_x = pixel_x
		var/original_y = pixel_y
		var/wiggle = 6

		SPAWN(0) //need spawn, why would we sleep in attack_hand that's disgusting
			while (wiggle > 0)
				wiggle--
				animate(src, pixel_x = rand(-3,3), pixel_y = rand(-3,3), time = 2, easing = EASE_IN)
				sleep(0.1 SECONDS)

		animate(src, pixel_x = original_x, pixel_y = original_y, time = 2, easing = EASE_OUT)

		if (max_uses > 0 && ((last_use + time_between_uses) < world.time) && prob(spawn_chance))
			var/something = null

			if (override_default_behaviour && islist(additional_items) && length(additional_items))
				something = pick(additional_items)
			else
				something = pick(trinket_safelist)

			if (ispath(something))
				#ifdef XMAS
				var/obj/item/gift/thing = new/obj/item/gift(src.loc)
				thing.gift = new something(thing)
				#else
				var/thing = new something(src.loc)
				#endif
				visible_message("<b><span class='alert'>[user] violently shakes [src] around! \An [thing] falls out!</span></b>", 1)
				last_use = world.time
				max_uses--
		else
			visible_message("<b><span class='alert'>[user] violently shakes [src] around![prob(20) ? " A few leaves fall out!" : null]</span></b>", 1)

		//no more BUSH SHIELDS
		for(var/mob/living/L in get_turf(src))
			if (!L.getStatusDuration("weakened") && !L.hasStatus("resting"))
				boutput(L, "<span class='alert'><b>A branch from [src] smacks you right in the face!</b></span>")
				L.TakeDamageAccountArmor("head", rand(1,6), 0, 0, DAMAGE_BLUNT)
				logTheThing(LOG_COMBAT, user, "shakes a bush and smacks [L] with a branch [log_loc(user)].")
				var/r = rand(1,2)
				switch(r)
					if (1)
						L.changeStatus("weakened", 4 SECONDS)
					if (2)
						L.changeStatus("stunned", 2 SECONDS)

		interact_particle(user,src)

	Crossed(atom/movable/AM)
		. = ..()
		if(isliving(AM))
			APPLY_ATOM_PROPERTY(AM, PROP_MOB_HIDE_ICONS, src)

	Uncrossed(atom/movable/AM)
		. = ..()
		if(isliving(AM))
			REMOVE_ATOM_PROPERTY(AM, PROP_MOB_HIDE_ICONS, src)

	attackby(var/obj/item/W, mob/user)
		user.lastattacked = src
		hit_twitch(src)
		attack_particle(user,src)
		playsound(src, 'sound/impact_sounds/Bush_Hit.ogg', 50, 1, 0)
		src.take_damage(W.force)
		user.visible_message("<span class='alert'><b>[user] hacks at [src] with [W]!</b></span>")

	proc/graze(mob/living/carbon/human/user)
		src.bites -= 1
		var/desired_mask = (src.bites / initial(src.bites)) * 5
		desired_mask = round(desired_mask)
		desired_mask = clamp(desired_mask, 1, 5)

		if (desired_mask != current_mask)
			current_mask = desired_mask
			src.add_filter("bite", 0, alpha_mask_filter(icon=icon('icons/obj/foodNdrink/food.dmi', "eating[desired_mask]")))

		eat_twitch(user)
		playsound(user, 'sound/items/eatfood.ogg', rand(10,50), 1)

		if (is_plastic)
			user.setStatus("weakened", 3 SECONDS)
			user.visible_message("<span class='notice'>[user] takes a bite out of [src] and chokes on the plastic leaves.</span>", "<span class='alert'>You munch on some of [src]'s leaves, but realise too late it's made of plastic. You start choking!</span>")
			user.take_oxygen_deprivation(20)
			user.losebreath += 2
		else
			user.changeStatus("food_hp_up", 20 SECONDS)
			user.visible_message("<span class='notice'>[user] takes a bite out of [src].</span>", "<span class='notice'>You munch on some of [src]'s leaves, like any normal human would.</span>")
			user.sims?.affectMotive("Hunger", 10)

		if(src.bites <= 0)
			destroy()
		return 0

	proc/take_damage(var/damage_amount = 5)
		src.health -= damage_amount
		if (src.health <= 0)
			destroy()
			return

	proc/destroy()
		src.visible_message("<span class='alert'><b>The [src.name] falls apart!</b></span>")
		new /obj/decal/cleanable/leaves(get_turf(src))
		playsound(src.loc, 'sound/impact_sounds/Wood_Snap.ogg', 90, 1)
		qdel(src)

	scruffy //dir s
		New()
			. = ..()
			icon_state = "bush-scruffy"
			desc = "A scruffy bush. Despite your best efforts, you can't tell if it's real or not."

	feathered //dir n
		New()
			. = ..()
			icon_state = "bush-feathered"
			desc = "A bush with feathery leaves. Despite your best efforts, you can't tell if it's real or not."

	leafy //dir e
		New()
			. = ..()
			icon_state = "bush-leafy"
			desc = "A shorter bush with large, lettuce-like leaves. Despite your best efforts, you can't tell if it's real or not."

	ferny //dir w
		New()
			. = ..()
			icon_state = "bush-ferny"
			desc = "A fernlike bush. Despite your best efforts, you can't tell if it's real or not."

	longleaf //dir se
		New()
			. = ..()
			icon_state = "bush-longleaf"
			desc = "A bush with long, tapering leaves. Despite your best efforts, you can't tell if it's real or not."

	shaggy
		New()
			. = ..()
			icon_state = "bush-shaggy"
			desc = "A bush with particularly shaggy foliage. Despite your best efforts, you can't tell if it's real or not."

	scrappy
		New()
			. = ..()
			icon_state = "bush-scrappy"
			desc = "A small, scrubby bush. Despite your best efforts, you can't tell if it's real or not."

	wideleaf
		New()
			. = ..()
			icon_state = "bush-wideleaf"
			desc = "A bush with wide, tapering leaves. Despite your best efforts, you can't tell if it's real or not."

	random
		New()
			. = ..()
			src.dir = pick(alldirs)

	snow
		icon = 'icons/turf/snow.dmi'
		icon_state = "snowshrub"

		random
			New()
				. = ..()
				src = pick(cardinal)


//It'll show up on multitools
/obj/shrub/syndicateplant
	var/net_id
	New()
		. = ..()
		var/turf/T = get_turf(src.loc)
		var/obj/machinery/power/data_terminal/link = locate() in T
		link?.master = src

/obj/shrub/captainshrub
	name = "\improper Captain's bonsai tree"
	icon = 'icons/misc/worlds.dmi'
	icon_state = "bonsai"
	desc = "The Captain's most prized possession. Don't touch it. Don't even look at it."
	anchored = ANCHORED
	density = 1
	layer = EFFECTS_LAYER_UNDER_1
	dir = EAST

	destroy()
		src.set_dir(NORTHEAST)
		src.destroyed = 1
		src.set_density(0)
		icon_state = "bonsai-destroyed"
		src.desc = "The scattered remains of a once-beautiful bonsai tree."
		playsound(src.loc, 'sound/impact_sounds/Slimy_Hit_3.ogg', 100, 0)
		// The bonsai tree goes to the deadbar because of course it does, except when there is no deadbar of course
		var/list/afterlife_turfs = get_area_turfs(/area/afterlife/bar)
		if(length(afterlife_turfs))
			var/obj/shrub/captainshrub/C = new /obj/shrub/captainshrub
			C.overlays += image('icons/misc/32x64.dmi',"halo")
			C.set_loc(pick(afterlife_turfs))
			C.anchored = UNANCHORED
			C.set_density(0)
		for (var/mob/living/M in mobs)
			if (M.mind && M.mind.assigned_role == "Captain")
				boutput(M, "<span class='alert'>You suddenly feel hollow. Something very dear to you has been lost.</span>")

	graze(mob/user)
		user.lastattacked = src
		if (user.mind && user.mind.assigned_role == "Captain")
			boutput(user, "<span class='notice'>You catch yourself almost taking a bite out of your precious bonzai but stop just in time!</span>")
			return
		else
			boutput(user, "<span class='alert'>I don't think the Captain is going to be too happy about this...</span>")
			user.visible_message("<b><span class='alert'>[user] violently grazes on [src]!</span></b>", "<span class='notice'>You voraciously devour the bonzai, what a feast!</span>")
			src.interesting = "Inexplicably, the genetic code of the bonsai tree has the words 'fuck [user.real_name]' encoded in it over and over again."
			src.destroy()
			user.changeStatus("food_deep_burp", 2 MINUTES)
			user.changeStatus("food_hp_up", 2 MINUTES)
			user.changeStatus("food_energized", 2 MINUTES)
			return

	attackby(obj/item/W, mob/user)
		if (!W) return
		if (!user) return
		if (inafterlife(user))
			boutput(user, "You can't bring yourself to hurt such a beautiful thing!")
			return
		if (src.destroyed) return
		if (user.mind && user.mind.assigned_role == "Captain")
			if (issnippingtool(W))
				boutput(user, "<span class='notice'>You carefully and lovingly sculpt your bonsai tree.</span>")
			else
				boutput(user, "<span class='alert'>Why would you ever destroy your precious bonsai tree?</span>")
		else if(isitem(W) && (user.mind && user.mind.assigned_role != "Captain"))
			src.destroy()
			boutput(user, "<span class='alert'>I don't think the Captain is going to be too happy about this...</span>")
			src.visible_message("<b><span class='alert'>[user] ravages [src] with [W].</span></b>", 1)
			src.interesting = "Inexplicably, the genetic code of the bonsai tree has the words 'fuck [user.real_name]' encoded in it over and over again."
		return

	meteorhit(obj/O as obj)
		src.visible_message("<b><span class='alert'>The meteor smashes right through [src]!</span></b>")
		src.destroy()
		src.interesting = "Looks like it was crushed by a giant fuck-off meteor."
		return

	ex_act(severity)
		src.visible_message("<b><span class='alert'>[src] is ripped to pieces by the blast!</span></b>")
		src.destroy()
		src.interesting = "Looks like it was blown to pieces by some sort of explosive."
		return

/obj/captain_bottleship //not a bush but it behaves like one. rip manta
	name = "\improper Captain's ship in a bottle"
	desc = "The Captain's most prized possession. Don't touch it. Don't even look at it."
	icon = 'icons/obj/decoration.dmi'
	icon_state = "bottleship"
	anchored = ANCHORED
	density = 0
	layer = EFFECTS_LAYER_1
	var/destroyed = 0

	// stole all of this from the captain's shrub lol
	update_icon()
		if (!src) return
		src.destroyed = 1
		src.desc = "The scattered remains of a once-beautiful ship in a bottle."
		playsound(src.loc, 'sound/impact_sounds/Glass_Shards_Hit_1.ogg', 100, 0)
		// The bonsai goes to the deadbar so I guess the ship in a bottle does too lol
		var/obj/captain_bottleship/C = new /obj/captain_bottleship
		C.overlays += image('icons/misc/32x64.dmi',"halo")
		C.set_loc(pick(get_area_turfs(/area/afterlife/bar)))
		C.anchored = UNANCHORED
		for (var/mob/living/M in mobs)
			if (M.mind && M.mind.assigned_role == "Captain")
				boutput(M, "<span class='alert'>You suddenly feel hollow. Something very dear to you has been lost.</span>")
		return

	attackby(obj/item/W, mob/user)
		if (!W) return
		if (!user) return
		if (inafterlife(user))
			boutput(user, "You can't bring yourself to hurt such a beautiful thing!")
			return
		if (src.destroyed) return
		if (user.mind && user.mind.assigned_role == "Captain")
			boutput(user, "<span class='alert'>Why would you ever destroy your precious ship in a bottle?</span>")
		else if(isitem(W) && (user.mind && user.mind.assigned_role != "Captain"))
			src.UpdateIcon()
			boutput(user, "<span class='alert'>I don't think the Captain is going to be too happy about this...</span>")
			src.visible_message("<b><span class='alert'>[user] ravages the [src] with [W].</span></b>", 1)
			src.interesting = "Inexplicably, the signal flags on the shattered mast just say 'fuck [user.real_name]'."
		return

	meteorhit(obj/O as obj)
		src.visible_message("<b><span class='alert'>The meteor smashes right through [src]!</span></b>")
		src.UpdateIcon()
		src.interesting = "Looks like it was crushed by a giant fuck-off meteor."
		return

	ex_act(severity)
		src.visible_message("<b><span class='alert'>[src] is shattered and pulverized by the blast!</span></b>")
		src.UpdateIcon()
		src.interesting = "Looks like it was blown to pieces by some sort of explosive."
		return

/obj/potted_plant //not changing this yet but it makes sense to move it out here
	name = "potted plant"
	desc = "Considering the fact that plants communicate through their roots, you wonder if this one ever feels lonely."
	icon = 'icons/obj/decoration.dmi'
	icon_state = "ppot0"
	anchored = ANCHORED
	density = 0
	deconstruct_flags = DECON_SCREWDRIVER

	New()
		..()
		if (src.icon_state == "ppot0") // only randomize a plant if it's not set to something specific
			src.icon_state = "ppot[rand(1,5)]"

	potted_plant1
		icon_state = "ppot1"

	potted_plant2
		icon_state = "ppot2"

	potted_plant3
		icon_state = "ppot3"

	potted_plant4
		icon_state = "ppot4"

	potted_plant5
		icon_state = "ppot5"
