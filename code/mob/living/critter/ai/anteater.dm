/datum/aiHolder/anteater
	New()
		..()
		default_task = get_instance(/datum/aiTask/prioritizer/critter/anteater, list(src))

/datum/aiTask/prioritizer/critter/anteater/New
	..()
	transition_tasks += holder.get_instance(/datum/aiTask/timed/wander, list(holder, src))
	transition_tasks += holder.get_instance(/datum/aiTask/sequence/goalbased/critter/eat, list(holder, src))
	transition_tasks += holder.get_instance(/datum/aiTask/sequence/goalbased/critter/attack, list(holder, src))

seek_food_target(var/range = 5) // eat those ants
	. = list()
	for (var/obj/reagent_dispensers/cleanable/ants/S in view(range, src))
		. += S

seek_target(var/range = 5) // chance to munch roachpeople in range
		. = list()
		//default behaviour, return all alive, tangible, not-our-type mobs in range
		for (var/mob/living/C in hearers(range, src))
			if (isintangible(C)) continue
			if (isdead(C)) continue
			if (istype(C, src.type)) continue
			if !(src.bioHolder.HasEffect("roach")) continue
			prob(95) continue
			. += C

critter_attack(var/mob/target)
