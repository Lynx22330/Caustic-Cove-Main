//Sets the storyteller to a new one, and does any heavy lifting for a handover.
/proc/set_storyteller(var/datum/storyteller/newST, var/announce = TRUE)
	if (!newST)
		//You can call this without passing anything, we'll go fetch it ourselves
		newST = pick_storyteller(STORYTELLER_BASE)

	if (!istype(newST))
		if(!istext(newST))
			return

		if(!GLOB.storyteller_cache[newST])
			return
		else
			newST = GLOB.storyteller_cache[newST]
	
	//Nothing happens if we try to set to the storyteller we already have
	if (get_storyteller() == newST)
		return

	//If there's an existing storyteller, we'll make it do cleanup procedures before the handover
	//we cache it now so we can do that soon
	var/datum/storyteller/oldST = get_storyteller()

	//Finally, we set the new one, and it's set globally.
	GLOB.storyteller = newST

	//Transfer over points
	if (oldST != null)
		GLOB.storyteller.points = oldST.points.Copy()

	//Configure the new storyteller
	GLOB.storyteller.set_up()

	if (announce)
		GLOB.storyteller.announce()

/proc/get_storyteller()
	RETURN_TYPE(/datum/storyteller)
	return GLOB.storyteller

//Counts the roles of every 'job'.
/datum/storyteller/proc/update_role_count()
	if(debug_mode)
		return
		
	players = 0
	nobles = 0
	garrison = 0
	yeomen = 0
	churchies = 0
	courtiers = 0
	adventurers = 0

	for(var/mob/M in GLOB.player_list)
		if(M.client && (M.mind && !M.mind.antag_datums.len) && M.stat != DEAD && (ishuman(M)))
			var/datum/job/job = SSjob.GetJob(M.mind.assigned_role)
			if(job)
				players++
				if(job.title in GLOB.noble_positions)
					nobles++
				if(job.title in GLOB.yeoman_positions)
					yeomen++
				if(job.title in GLOB.garrison_positions)
					garrison++
				if(job.title in GLOB.church_positions)
					churchies++
				if(job.title in GLOB.courtier_positions)
					courtiers++
				if(job.title in GLOB.roguewar_positions)
					adventurers++

/datum/storyteller/proc/calculate_event_weight(var/datum/storyevent/R)
	var/new_weight = R.weight

	new_weight *= weight_mult(players,R.req_players)
	new_weight *= weight_mult(nobles,R.req_nobles)
	new_weight *= weight_mult(garrison,R.req_garrison)
	new_weight *= weight_mult(yeomen,R.req_yeomen)
	new_weight *= weight_mult(churchies,R.req_churchies)
	new_weight *= weight_mult(courtiers,R.req_courtiers)

	new_weight = R.get_special_weight(new_weight)

	//Factoring in tag-based weight modifiers
	//Each storyteller has different tag weights
	for (var/etag in tag_weight_mults)
		if (etag in R.tags)
			new_weight *= tag_weight_mults[etag]

	return new_weight


/datum/storyteller/proc/calculate_event_cost(var/datum/storyevent/R, var/severity)
	var/new_cost = R.get_cost(severity)

	//Factoring in tag-based cost modifiers
	//Each storyteller has different tag weights
	for (var/etag in tag_cost_mults)
		if (etag in R.tags)
			new_cost *= tag_cost_mults[etag]

	return new_cost

/datum/storyteller/proc/weight_mult(var/val, var/req)
	if(req <= 0)
		return 1
	if(val <= 0)	//We need to spawn anything
		return 0.75/req
	return 1-((max(0,req-val)**3)/(req**3))


//Since severity are no longer numbers, we need a proc for incrementing it
/proc/get_next_severity(var/input)
	switch (input)
		if (EVENT_LEVEL_MUNDANE)
			return EVENT_LEVEL_MODERATE
		if (EVENT_LEVEL_MODERATE)
			return EVENT_LEVEL_CATASTROPHIC
		if (EVENT_LEVEL_CATASTROPHIC)
			return EVENT_LEVEL_ROLESET
	return input



var/list/event_last_fired = list()


//Storyteller related procs.

/proc/pick_storyteller(story_name)
	// I wish I didn't have to instance the game modes in order to look up
	// their information, but it is the only way (at least that I know of).
	if(story_name in GLOB.storyteller_cache)
		return GLOB.storyteller_cache[story_name]

	return GLOB.storyteller_cache[STORYTELLER_BASE]

/proc/get_storytellers()
	var/list/runnable_storytellers = list()
	for(var/storyteller in GLOB.storyteller_cache)
		var/datum/storyteller/S = GLOB.storyteller_cache[storyteller]
		if(S)
			runnable_storytellers |= S
	return runnable_storytellers
