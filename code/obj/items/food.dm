/obj/item/consumable
	name = "consumable"
	buy_rollable = FALSE

	var/nutrition = 0
	var/hydration = 0
	var/mood = 0
	var/lactose_intolerant_mood = 0

	var/destroy_on_eat = FALSE
	var/eat_sound

	var/flavor_profile
	var/flavor_profile_style = "good"

/obj/item/consumable/use(mob/human/H)
	if(nutrition)
		H.AdjustHunger(-nutrition)
	if(hydration)
		H.AdjustThirst(-hydration)
	var/effective_mood = mood
	if(lactose_intolerant_mood && H.mind?.HasQuirk(/datum/quirk/lactose_intolerant))
		effective_mood += lactose_intolerant_mood
	if(effective_mood)
		var/moodrand = effective_mood - rand(-4,4)
		H.AdjustSorrow(-moodrand)
	
	if(flavor_profile)
		H.chat_info(flavor_profile, flavor_profile_style)
	if(eat_sound)
		playsound(get_turf(H), eat_sound, 75, FALSE, -2)

	if(destroy_on_eat)
		destroyself(H)

/obj/item/consumable/food
	eat_sound = 'sound/effects/human/eatfood.ogg'

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

/obj/item/consumable/food/burger
	name = "borgaire"
	desc = "A common snack on roguestations, easy to make, and very filling. A clean and proper borgaire."
	icon = 'icons/obj/burger.dmi'
	icon_state = "burger_small"
	destroy_on_eat = TRUE
	droprot = FALSE

/obj/item/consumable/food/burger/bread
	name = "breadbun"
	desc = "The start and finish of a proper roguestation borgaire. Add a patty and any toppings, then close it with another bun."
	icon_state = "bun"
	destroy_on_eat = TRUE
	
	vendor_name = "BUNS"
	icon_state = "bun"
	vendor_price = 3

	var/burger_nutrition = 0
	var/burger_hydration = 0
	var/burger_mood = 0
	var/burger_lactose_intolerant_mood = 0
	var/burger_has_patty = FALSE

/obj/item/consumable/food/burger/bread/interact(mob/human/user, obj/item/held_item, params)
	if(!held_item)
		return ..()

	if(istype(held_item, /obj/item/consumable/food/burger/bread))
		if(!burger_has_patty)
			user.chat_info("[pick("What kind of chef would I be if I didn't add a patty into it?","Without a delicious slice of lice? I don't think so.","But... where are the lice?!")]", "bad")
			return

		var/obj/item/consumable/food/burger/bread/closing_bun = held_item
		var/obj/item/consumable/food/burger/finished = new(get_turf(src))
		finished.nutrition = max(0, burger_nutrition + closing_bun.burger_nutrition)
		finished.hydration = max(0, burger_hydration + closing_bun.burger_hydration)
		finished.mood = burger_mood + closing_bun.burger_mood
		finished.lactose_intolerant_mood = burger_lactose_intolerant_mood + closing_bun.burger_lactose_intolerant_mood

		playsound(get_turf(user), 'sound/effects/pickup.ogg', falloff_exponent = 4, vol = 20, vary = TRUE, extrarange = -3)

		finished.update_transform()
		finished.pixel_y = src.pixel_y
		finished.pixel_x = src.pixel_x
		user.chat_info("[pick("Dinner is served.","Ah, what a great thing I have just made.","Hmm... yes, I am going places tonight.","Ah, feels good.","Here we are!")]")

		closing_bun.destroyself(user)
		qdel(src)
		return

	var/obj/item/consumable/food/burger/part/ingredient = held_item
	if(istype(ingredient, /obj/item/consumable/food/burger/part/patty))
		if(burger_has_patty)
			user.chat_info("The cardinal sin of having more than one patty per borgaire can not and WILL not be done here.", "bad")
			return
		burger_has_patty = TRUE
	
	playsound(get_turf(user), 'sound/effects/pickup.ogg', falloff_exponent = 4, vol = 20, vary = TRUE, extrarange = -3)

	burger_nutrition += ingredient.burger_nutrition
	burger_hydration += ingredient.burger_hydration
	burger_mood += ingredient.burger_mood
	burger_lactose_intolerant_mood += ingredient.burger_lactose_intolerant_mood
	var/ingredient_name = ingredient.name
	ingredient.destroyself(user)
	user.chat_info("You add [ingredient_name] to the borgaire.")

/obj/item/consumable/food/burger/part
	destroy_on_eat = TRUE
	icon_state = "meallice"

	var/burger_nutrition = 0
	var/burger_hydration = 0
	var/burger_mood = 0
	var/burger_lactose_intolerant_mood = 0

/obj/item/consumable/food/burger/part/patty
	name = "meal-lice patty"
	icon_state = "patty"
	desc = "Pressed, hopefully not depressed, and ready to be the main source of nutrition for the would-be spaceman."
	nutrition = 24
	burger_nutrition = 24
	vendor_name = "PATT"
	vendor_price = 12

/obj/item/consumable/food/burger/part/bacon
	name = "meal-lice strips"
	icon_state = "bacon"
	desc = "Thin slices of meal lice, fit for a child. Are you a child? I thought not."
	nutrition = 8
	burger_nutrition = 8
	vendor_name = "MBAC"
	vendor_price = 8

/obj/item/consumable/food/burger/part/lettuce
	name = "lettuce"
	icon_state = "lettuce"
	desc = "A crisp, hydrating topping."
	hydration = 8
	burger_nutrition = -3
	burger_hydration = 8
	vendor_name = "LETT"
	vendor_price = 5

/obj/item/consumable/food/burger/part/tomato
	name = "tomato"
	icon_state = "tomato"
	desc = "A juicy slice of genetically modified fruit that's ought to put that long lost spark back into your cold, cosmos-filled life."
	desc_expansive = "The juiciness and taste of a tomato, with the temperament of a potato. What a beautiful thing and a testament to human ingenuity!"
	mood = 10
	burger_nutrition = -3
	burger_mood = 10
	vendor_name = "TOMA"
	vendor_price = 5

/obj/item/consumable/food/burger/part/cheese
	name = "cheese"
	icon_state = "cheese"
	desc = "A rich, savoury topping. Not so pleasant if you drew the short straw in the genetic lottery."
	desc_expansive = "A pasteurized prepared cheese product, contains just enough lactose to be tolerated yet disliked."
	mood = 10
	lactose_intolerant_mood = -20
	burger_nutrition = -3
	burger_hydration = -5
	burger_mood = 10
	burger_lactose_intolerant_mood = -20
	vendor_name = "CHEE"
	vendor_price = 7