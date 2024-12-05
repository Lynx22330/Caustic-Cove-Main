//Heavily ported from Eris Storyteller and edited/refactored for Caustic Cove.
GLOBAL_DATUM(storyteller, /datum/storyteller)
GLOBAL_VAR_INIT(mob_count, 0) //In order to calculate how many mobs exist at a given time.

/datum/storyteller
	//Strings
	var/config_tag
	var/name = "Storyteller"
	var/welcome = "Welcome."
	var/description = "You shouldn't be seeing this."

	//Antag related var.
	var/one_role_per_player = TRUE

	//Weight related var.
	var/calculate_weights = TRUE

	//To help with logging.

		//Setting this to TRUE will prevent normal storyteller functioning.
	var/debug_mode = FALSE 

	//Misc vars.
	var/list/processing_events = list()
	var/last_tick = 0
	var/next_tick = 0
	var/tick_interval = 60 SECONDS
	var/multiplier_gain = 1

	//Total playercount of EVERYONE.
	var/player_count_tally = 0

	//Individual Role Count of JOBS.
	var/players = 0
	var/nobles = 0
	var/garrison = 0
	var/adventurers = 0
	var/yeomen = 0
	var/churchies = 0
	var/courtiers = 0

	var/event_spawn_timer
	var/event_spawn_stage

//Default points for storytellers to use for causing events.
/* 		EVENT_LEVEL_MUNDANE 	-> Typically joke events, or nothing at all.
		EVENT_LEVEL_MINOR		-> Small events that are typically job related or nothing at all.
		EVENT_LEVEL_MODERATE	-> Slightly game changing events, enemies spawning or some sort of plant growth appeared.
		EVENT_LEVEL_CATASTROPHIC-> Major event that can occur "world" wide, or at a set locale. Typically bad, can also be good.
		EVENT_LEVEL_ROLESET 	-> Antag points so more antags can appear during the middle of the round when a player spawns.
*/
	var/list/points = list(
	EVENT_LEVEL_MUNDANE,
	EVENT_LEVEL_MINOR,
	EVENT_LEVEL_MODERATE,
	EVENT_LEVEL_CATASTROPHIC,
	EVENT_LEVEL_ROLESET)

	//Lists of every event the storyteller can use. Dynamically built at the start of the game.
	var/list/event_pool_mundane = list()
	var/list/event_pool_minor = list()
	var/list/event_pool_moderate = list()
	var/list/event_pool_catastrophic = list()
	var/list/event_pool_roleset = list()

	//Configuration
	//Things you can set to make new storytellers! Very fun.
	var/gain_multiplier_mundane = 1.0
	var/gain_multiplier_minor = 1.0
	var/gain_multiplier_moderate = 1.0
	var/gain_multiplier_catastrophic = 1.0
	var/gain_multiplier_roleset = 1.0

	//Depending on a given tag, you can increase or decrease the weight and cost of a given event. 
	var/list/tag_weight_mults = list()
	var/list/tag_cost_mults = list()

	//The variance of point gain per tick. Keeps the storyteller unpredictable and more random.
	var/variance = 0.15

	//Weights of events are multiplied by this value after they occur. This prevents back-to-back events from occuring.
	var/repetition_multiplier = 0.85 

	//When an event is selected, it is put on a timed delay between 1 decisecond, to the max given value of this var. (1-27000 ticks)
	//This is to prevent events from overlapping one another.
	var/event_schedule_delay = 45 MINUTES

	//Whether or not a Storyteller can be voted for. Might not be used here but will be here just in case.
	var/votable = TRUE


/////////////////////////
//ROUND-START AND SETUP//
/////////////////////////

/datum/storyteller/proc/can_start(var/announce = FALSE) //If TRUE, output reason why it can't start to world.
	if(debug_mode || SSticker.start_immediately)
		return TRUE

/datum/storyteller/proc/announce()
	to_chat(world, "<b><font size=3>Storyteller is [name].</font> <br>[welcome]</b>")

/datum/storyteller/proc/set_up()
	build_event_pools()
	set_timer()
	set_up_events()

/datum/storyteller/proc/set_up_events()
	return

//////////////////
////MAIN PROCESS//
//////////////////

/datum/storyteller/proc/Process()
	if(can_tick())
			//Update these things so we can accurately select events
		update_role_count()
		update_event_weights()
		/*
			Handle points calls a large stack that increments all the point totals, and then attempts to
			trigger as many events as our totals can afford to
		*/
		handle_points()

		//Set the time for the next tick
		set_timer()

/datum/storyteller/proc/can_tick()
	if (world.time > next_tick)
		return TRUE

/datum/storyteller/proc/set_timer()
	if (!(world.time > next_tick))	//We duplicate this check from can_tick, so that an admin forcing an immediate event won't
		return						//Throw the timing out of sync for the rest of the game
		
	//We won't set the next tick timer unless it's actually time to do so
	last_tick = world.time
	next_tick = last_tick + tick_interval

////////////////////////////////////////////////
///SUB PROCESSING: For individual storyevents///
////////////////////////////////////////////////
/datum/storyteller/proc/add_processing(var/datum/storyevent/S)
	ASSERT(istype(S))
	processing_events.Add(S)

/datum/storyteller/proc/remove_processing(var/datum/storyevent/S)
	processing_events.Remove(S)

/datum/storyteller/proc/process_events()	//Called in ticker
	for(var/datum/storyevent/S in processing_events)
		if(S.processing)
			S.Process()
			if(S.is_ended())
				S.stop_processing(TRUE)

//////////////////
///Event Weight///
//////////////////

/datum/storyteller/proc/update_event_weight(var/datum/storyevent/R)
	ASSERT(istype(R))

	R.weight_cache = calculate_event_weight(R)
	//R.weight_cache *= 1-rand()*weight_randomizer
	return R.weight_cache

//////////////////
///Silly Button///
//////////////////

/proc/storyteller_button()
	if(GLOB.storyteller)
		return "<a href='?src=\ref[GLOB.storyteller];panel=1'>\[STORY\]</a>"
	else
		return "<s>\[STORY\]</s>"

/////////////////////
///Points Handling///
/////////////////////

/datum/storyteller/proc/modify_points(var/delta, var/type = EVENT_LEVEL_ROLESET)
	if (!delta || !isnum(delta))
		return
	//Adds delta points to the specified pool.
	//If type is 0, adds points to all pools
	//Pass a negative delta to subtract points
	if (type)
		points[type] += delta
	else
		for (var/a in points)
			points[a] += delta

//When getting the storyteller system working for us, we don't want regenerating points to prevent late game spams. Essentially the round starts difficult and gets easier
//over time to prevent "always PvE" and allow for some relaxation and RP. Commenting out prior code in case we need it for reference later. -Kaz
/datum/storyteller/proc/handle_points()
	points[EVENT_LEVEL_MUNDANE] += 1 * (gain_multiplier_mundane) * (RAND_DECIMAL(1-variance, 1+variance))
	points[EVENT_LEVEL_MINOR] += 1 * (gain_multiplier_minor) * (RAND_DECIMAL(1-variance, 1+variance))
	points[EVENT_LEVEL_MODERATE] += 1 * (gain_multiplier_moderate) * (RAND_DECIMAL(1-variance, 1+variance))
	points[EVENT_LEVEL_CATASTROPHIC] += 1 * (gain_multiplier_catastrophic) * (RAND_DECIMAL(1-variance, 1+variance))
	points[EVENT_LEVEL_ROLESET] += 1 * (gain_multiplier_roleset) * (RAND_DECIMAL(1-variance, 1+variance))
	check_thresholds()


/datum/storyteller/proc/check_thresholds()
	while (points[EVENT_LEVEL_MUNDANE] >= POOL_THRESHOLD_MUNDANE)
		if (!handle_event(EVENT_LEVEL_MUNDANE))
			break

	while (points[EVENT_LEVEL_MINOR] >= POOL_THRESHOLD_MINOR)
		if (!handle_event(EVENT_LEVEL_MINOR))
			break

	while (points[EVENT_LEVEL_MODERATE] >= POOL_THRESHOLD_MODERATE)
		if (!handle_event(EVENT_LEVEL_MODERATE))
			break

	while (points[EVENT_LEVEL_CATASTROPHIC] >= POOL_THRESHOLD_CATASTROPHIC)
		if (!handle_event(EVENT_LEVEL_CATASTROPHIC))
			break

	//No loop for roleset events to prevent possible wierdness like the same player being picked twice
	if(points[EVENT_LEVEL_ROLESET] >= POOL_THRESHOLD_ROLESET)
		handle_event(EVENT_LEVEL_ROLESET)

////////////////////
///Event Handling///
////////////////////

//First we figure out which pool we're going to take an event from.
/datum/storyteller/proc/handle_event(var/event_type)
	//This is a buffer which will hold a copy of the list we choose.
	//We will be modifying it and don't want those modifications to go back to the source.
	var/list/temp_pool
	switch(event_type)
		if (EVENT_LEVEL_MINOR)
			temp_pool = event_pool_mundane.Copy()
		if (EVENT_LEVEL_MUNDANE)
			temp_pool = event_pool_mundane.Copy()
		if (EVENT_LEVEL_MODERATE)
			temp_pool = event_pool_moderate.Copy()
		if (EVENT_LEVEL_CATASTROPHIC)
			temp_pool = event_pool_catastrophic.Copy()
		if (EVENT_LEVEL_ROLESET)
			temp_pool = event_pool_roleset.Copy()

	if (!temp_pool || !temp_pool.len)
		return FALSE

	var/datum/storyevent/choice = null
	//We pick an event from the pool at random, and check if it's allowed to run.
	while (choice == null)
		choice = pickweight(temp_pool)
		if (!choice.can_trigger(event_type))
			//If its not, we'll remove it from the temp pool and then pick another.
			temp_pool -= choice
			choice = null

		if (!temp_pool.len)
			return FALSE
			//Repeat until we find one which is allowed, or the pool is empty.

	if (!choice)
		return FALSE

	//Once we get here, we've found an event which can run!


	//If it is allowed to run, we'll deduct its cost from our appropriate point score, and schedule it for triggering
	var/cost = calculate_event_cost(choice, event_type)
	points[event_type] -= cost
	schedule_event(choice, event_type)

	return TRUE
	//When its trigger time comes, the event will once again check if it can run,
	//	if it can't it will cancel itself and refund the points it cost to trigger it.



//Sets up an event to be fired in the near future. This keeps things unpredictable
//	the actual fire event proc is located in storyteller_meta
/datum/storyteller/proc/schedule_event(var/datum/storyevent/C, var/event_type)
	var/delay
	if (event_type == EVENT_LEVEL_ROLESET)
		delay = 1 //Basically no delay on these to reduce bugginess
	else
		delay = rand(1, event_schedule_delay)
	var/handle = addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(fire_event), C, event_type), delay, TIMER_STOPPABLE)
	scheduled_events.Add(list(C), type, handle)


//////////////////////////////
///Pool and Weight handling///
//////////////////////////////

//Builds up this storyteller's local event pools.
//This should be called only once for each new storyteller
/datum/storyteller/proc/build_event_pools()
	event_pool_mundane.Cut()
	event_pool_moderate.Cut()
	event_pool_catastrophic.Cut()
	event_pool_roleset.Cut()
	for (var/datum/storyevent/a in storyevents)


		var/new_weight

		if (!a.enabled)
			new_weight = 0
		else
			new_weight = calculate_event_weight(a)
			//Reduce the weight based on number of ocurrences.
			//This is mostly for the sake of midround handovers
			if (a.ocurrences >= 1)
				new_weight *= repetition_multiplier ** a.ocurrences

		//We setup the event pools as an associative list in preparation for a pickweight call
		if (EVENT_LEVEL_MUNDANE in a.event_pools)
			event_pool_mundane[a] = new_weight
		if (EVENT_LEVEL_MINOR in a.event_pools)
			event_pool_minor[a] = new_weight
		if (EVENT_LEVEL_MODERATE in a.event_pools)
			event_pool_moderate[a] = new_weight
		if (EVENT_LEVEL_CATASTROPHIC in a.event_pools)
			event_pool_catastrophic[a] = new_weight
		if (EVENT_LEVEL_ROLESET in a.event_pools)
			event_pool_roleset[a] = new_weight


/datum/storyteller/proc/update_event_weights()
	event_pool_mundane = update_pool_weights(event_pool_mundane)
	event_pool_minor = update_pool_weights(event_pool_minor)
	event_pool_moderate = update_pool_weights(event_pool_moderate)
	event_pool_catastrophic = update_pool_weights(event_pool_catastrophic)
	event_pool_roleset = update_pool_weights(event_pool_roleset)

/datum/storyteller/proc/update_pool_weights(var/list/pool)
	for(var/datum/storyevent/a in pool)
		var/new_weight = calculate_event_weight(a)
		if (a.ocurrences >= 1)
			new_weight *= repetition_multiplier ** a.ocurrences

		pool[a] = new_weight
	return pool
