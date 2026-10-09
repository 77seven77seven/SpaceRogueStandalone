#define GOAL_RARITY_BASIC 500
#define GOAL_RARITY_RARE 200
#define GOAL_RARITY_VERY_RARE 100

/datum/goal
	var/name = "Something"
	var/desc = "Everyone has some kind of goal in life, sooner or later. Maybe it's a short-term ambition, or a long-term goal."
	var/award = 1 // XP
	var/rarity = GOAL_RARITY_BASIC // Lower the number, the higher the rarity.

	var/antag = FALSE // Able to be rolled for antagonists.
	var/special = FALSE // Can only be assigned manually.

/datum/goal/proc/IsCompleted()
	return FALSE

/datum/goal/leisure
	name = "Leisure"
	desc = "Smart planning and diligent work have lead you to be free of any outside obligations. Your goal is complete."
	award = 1

/datum/goal/leisure/IsCompleted()
	return TRUE

/datum/goal/anne_gree_cola
	name = "Anne-Gree Cola"
	desc = "You can't get enough of Anne-Gree. Consume five cans of soda. Drink five cans of Anne-Gree."
	award = 3

/datum/goal/lime_wire
	name = "Lime-Wire"
	desc = "You cannot believe a beverage such as Lime-Lite exists. Drink five cans of it."
	award = 4

/datum/goal/shock
	name = "Shock"
	desc = "You're in for a shock. Witness something horrible happen. Witness someone's death."
	award = 2

/datum/goal/stuntman
	name = "Stuntman"
	desc = "You've always wanted to become a stuntman. Have at least three people witness you break a bone."
	award = 5

/datum/goal/action_star
	name = "Action Star"
	desc = "You've watched far too many action movies recently. You need the real deal. Get shot, and live to tell the tale."
	award = 3

/datum/goal/shopping_spree
	name = "Shopping Spree"
	desc = "It's time for a shopping spree! Purchase 15 things from vending machines."
	award = 2

/datum/goal/fashion
	name = "Fashion"
	desc = "Try on some new clothes! Get the \"fresh threads\" mood buff 5 or more times."
	award = 3

/datum/goal/freshen_up
	name = "Freshen Up"
	desc = "You need to give your scalp some much needed attention. Take some Prism-EX or use a Style Irradiator at least once."
	award = 3

/datum/goal/cleanup
	name = "Cleanup"
	desc = "You care about the environment. Clean up 20 pieces of trash. Throw away at least 20 pieces of trash into bins."
	award = 3

/datum/goal/hoarder
	name = "Hoarder"
	desc = "Roguestation Endera has so many wonderful things. Leave the station with at least 9 items in your inventory. Have 9 items in your inventory when you leave the station. Remember that your bus ticket won't count towards this, since it'll be in your hand when you leave!"
	award = 3

/datum/goal/antique
	name = "Antique"
	desc = "You know of a pawn shop that'll give you a nice sum of cash for anything that's old enough. Leave Roguestation Endera with an antique in your inventory. Leave the station with an Old Bill, Old Coin, Horse Figurine, or old revolver."
	award = 3

/datum/goal/bookworm
	name = "Bookworm"
	desc = "Get your hands on an e-book and read it."
	award = 4

/datum/goal/sickness
	name = "Sickness"
	desc = "Get that nasty cough of yours cured."
	award = 2

/datum/goal/healthy
	name = "Healthy"
	desc = "You MUST remain healthy. Avoid catching a cough at any point in time during your stay in Roguestation Endera. This goal starts complete, and fails if you become ill."
	award = 5

/datum/goal/mental_health_day
	name = "Mental Health Day"
	desc = "It's about time you took care of your mental health. Keep your sorrow at or under 20% for three or more minutes."
	award = 3

/datum/goal/diagnosis
	name = "Diagnosis"
	desc = "A famous medicaloid has promised to diagnose you, but he requires your blood sample first. Leave the station with a sample of your own blood."
	award = 3

/datum/goal/first_aid
	name = "First Aid"
	desc = "A mysterious voice inside your head insists for you to perform good deeds. Perform first aid procedures on people who need them five or more times."
	award = 5

/datum/goal/biometrics
	name = "Biometrics"
	desc = "You have a side-gig of collecting biometric data for shady data brokers. Leave the station with three blood samplers containing someone elses blood."
	award = 5

/datum/goal/mortuary
	name = "Mortuary"
	desc = "Friends, this is clean-up time. Bag up five or more bodies."
	award = 3

/datum/goal/two_tickets
	name = "Two Tickets"
	desc = "You have someone back home that you need to bring a ticket to. Leave the station with a spare ticket."
	award = 3

/datum/goal/socialist
	name = "Socialist"
	desc = "You love spending time with friends. Spend three minutes around two or more people."
	award = 2

/datum/goal/restock
	name = "Restock"
	desc = "You've always wondered how the vending machines work. Install a restock package."
	award = 2

/datum/goal/spend
	name = "Spend"
	desc = "Generous, or just a reckless spender? Send a total of 200§ to other people."
	award = 3

/datum/goal/big_earner
	name = "Big Earner"
	desc = "You're an honest worker. Receive a singular paycheck worth 150§ or more."
	award = 3

/datum/goal/wealth
	name = "Wealth"
	desc = "You want to be wealthy. Leave Endera with at least 400§ in your account."
	award = 3

/datum/goal/guns
	name = "Guns"
	desc = "Guns are cool. Shoot a gun."
	award = 3

/datum/goal/protection
	name = "Protection"
	desc = "You're obsessed with your own security. Obtain a firearm, and leave the station with it."
	award = 3

/datum/goal/murder
	name = "Murder"
	desc = "You've got dark intentions. Take someone's life."
	award = 5

/datum/goal/vigilante
	name = "Vigilante"
	desc = "You're a vigilante. You can't stand seeing the injustice in this world. Get rid of a criminal."
	award = 5

/datum/goal/troublestarter
	name = "Troublestarter"
	desc = "You're a troublestarter - a punkin' instigator. Land 10 melee hits in total on living individuals."
	award = 3

/datum/goal/i_fought_the_law
	name = "I Fought the Law"
	desc = "You have a rebellious streak brewing inside of you. Punch an Enforcer and get away with it."
	award = 4

/datum/goal/true_crime
	name = "True Crime"
	desc = "You're obsessed with true crime. Witness 5 crimes in person."
	award = 3

/datum/goal/clean_record
	name = "Clean Record"
	desc = "You don't want any trouble. Avoid being wanted."
	award = 4

/datum/goal/thrill
	name = "Thrill"
	desc = "You're in it for the thrill. Become wanted thrice."
	award = 3

/datum/goal/do_not_commit_wire_fraud
	name = "Do Not Commit Wire Fraud Under Any Circumstances"
	desc = "Whatever you do, do NOT, under ANY circumstances WHATSOEVER, commit wire fraud."
	award = 1

/datum/goal/falling_down
	name = "Falling Down"
	desc = "You have a briefcase with you. Whatever may be in there, is extremely important to you. Do not lose it under any circumstances. If you have a ticket in the inventory, you can use it through the briefcase."
	award = 6

/datum/goal/amateur_dentistry
	name = "Amateur Dentistry"
	desc = "Long ago, in the very distant past, you tried to obtain a medical license, and failed. Despite it being so long ago, your rage still lingers. Set things right and knock out someone's teeth."
	award = 6

/datum/goal/antag
	antag = TRUE

/datum/goal/antag/debug_goal
	name = "SABOTAGE"
	desc = "Leave them hanging! Kill the reactor, kill them all! MAKE THEIR TUMORS GROW!"
	award = 7 // 7seven
	antag = TRUE

/datum/goal/debug_goal
	name = "Debug Goal"
	desc = "This goal is only available for the Director! This goal was used to test if special goals work. If you're reading this, you're either a coder or they do!"
	award = 77 // 7seven
	special = TRUE

#undef GOAL_RARITY_BASIC
#undef GOAL_RARITY_RARE
#undef GOAL_RARITY_VERY_RARE