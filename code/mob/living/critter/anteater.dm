/mob/critter/living/small_animal/anteater
	name = "anteater"
	desc = "A highly specialized mercenary, capable of tearing apart colonies with only its claws and killing hundreds with a single swish of its tongue. Ants, that is. Not people. Probably."
	icon_state = "capybara" // boris change this when you do sprites for it
	icon_state_dead = "capybara-dead"
	is_npc = TRUE
	ai_type = datum/aiHolder/anteater
	speechverb_say = pick("snuffles", "snorts", "sniffs")
	speechverb_stammer = "sniffles"
	speechverb_exclaim = pick("snorts", "hisses", "huffs")
	speechverb_ask = pick("sniffs", "sniffles")
