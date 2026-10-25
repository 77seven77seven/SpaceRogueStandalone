/obj/item/consumable
	name = "consumable"
	buy_rollable = FALSE

	var/nutrition = 0
	var/hydration = 0
	var/mood = 0

	var/destroy_on_eat = FALSE

	var/flavor_profile
	var/flavor_profile_style = "good"

/obj/item/consumable/use(mob/human/H)
	if(nutrition)
		H.AdjustHunger(-nutrition)
	if(hydration)
		H.AdjustThirst(-hydration)
	if(mood)
		var/moodrand = mood - rand(-4,4)
		H.AdjustSorrow(-moodrand)
	
	if(flavor_profile)
		H.chat_info(flavor_profile, flavor_profile_style)

	if(destroy_on_eat)
		destroyself(H)

/obj/item/consumable/food/nutrition
	name = "nutrition bar"
	icon_state = "nutritionbar"
	desc = "Imported from some backwater (compared to where <u>you</u> are though, it is quite close to human civilization at large) waterworld. Not very good, and the amount of time it took to transport here probably didn't do it any favors."
	desc_expansive = "Fish offal and kelp, squeezed into a tightly packed nutritional brick through sheer tyranny of will."
	nutrition = 20
	mood = -12

	vendor_name = "NBAR"
	vendor_price = 20

/obj/item/consumable/drink/annegree
	name = "Anne-Gree Cola"
	icon_state = "annegree"

	desc = "A refreshing can of soda, mixed with chemicals to trick your taste buds into percepting it is colder than it is, even if stored at room temperature. Refreshing."
	desc_expansive = "This product's name was censored after the UN Performative Display of Emotion Prohibition act was enacted, and prohibited brands from naming themselves or their products after emotions or feelings. Pronounced Anney-Gree. Supposedly."
	hydration = 15
	mood = 25

	vendor_name = "ANNE"
	vendor_price = 15

/obj/item/consumable/drink/limelite
	name = "Lime-Lite"
	icon_state = "limelite"

	desc = "Lime-Lite™, a lithiated lemon-lime soda coming to space stations near you! Be refreshed, even in space. \"Be Lime-Wired!\""
	desc_expansive = "Rumors are that the company behind Lime-Lite™ is owned by the same company that makes Anne-Gree®, using the fierce competition public angle as a mere marketing stunt between corporations."
	hydration = 25
	mood = 15

	vendor_name = "LIME"
	vendor_price = 15

/obj/item/consumable/food/meallice
	name = "meal lice"
	desc = "A flavorless grain that almost never wiggles on its own."
	icon_state = "meallice"

	nutrition = 12
	hydration = -6
	mood = -20

	destroy_on_eat = TRUE
	flavor_profile = "Eugh, bleugh BLEUGH! For it being flavorless, it sure has a tendency to NOT have a good texture!"
	flavor_profile_style = "bad"

/obj/item/consumable/food/cooked_meal
	name = "cooked meal lice"
	desc = "Meal lice, finally given a purpose."
	icon_state = "meallice"
	destroy_on_eat = TRUE

/obj/item/consumable/food/cooked_meal/hearty
	name = "hearty meallice mash"
	desc = "A dense mash that is unusually filling."
	nutrition = 35
	hydration = -5
	mood = 8
	flavor_profile = "A surprisingly filling bowl of meal lice."

/obj/item/consumable/food/cooked_meal/fritters
	name = "crispy meallice fritters"
	desc = "A crunchy snack with enough texture to lift the spirit."
	nutrition = 20
	mood = 25
	flavor_profile = "Crispy, warm, and almost pleasant."

/obj/item/consumable/food/cooked_meal/broth
	name = "meallice broth"
	desc = "A thin broth that is much easier to swallow than plain meal lice."
	nutrition = 10
	hydration = 35
	mood = 5
	flavor_profile = "The warm broth takes the edge off your thirst."

/obj/item/consumable/food/cooked_meal/ration
	name = "compact meallice ration"
	desc = "A compressed, calorie-heavy ration; dry and deeply unappetizing."
	nutrition = 50
	hydration = -12
	mood = -5
	flavor_profile = "Dense calories, at the cost of every other pleasure."
	flavor_profile_style = "bad"