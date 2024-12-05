/*
 * WARRANTY VOID IF CODE USED
 */


/datum/events
	var/list/events

/datum/events/New()
	..()
	events = new

/datum/events/Destroy()
	for(var/elist in events)
		for(var/e in events[elist])
			qdel(e)
	events = null
	return ..()

/datum/events/proc/addEventType(event_type as text)
	if(!(event_type in events) || !islist(events[event_type]))
		events[event_type] = list()
		return TRUE
	return FALSE

//	Arguments: event_type as text, proc_holder as datum, proc_name as text
//	Returns: New event, null on error.
/datum/events/proc/addEvent(event_type as text, datum/callback/cb)
	if(!event_type || !cb)
		return
	addEventType(event_type)
	var/list/event = events[event_type]
	event += cb
	return cb

//  Arguments: event_type as text, any number of additional arguments to pass to event handler
//  Returns: null
/datum/events/proc/fireEvent(eventName, ...)
	var/list/event = listgetindex(events,eventName)
	if(istype(event))
		for(var/E in event)
			var/datum/callback/cb = E
			cb.InvokeAsync(arglist(args.Copy(2)))

// Arguments: event_type as text, E as /datum/event
// Returns: TRUE if event cleared, FALSE on error

/datum/events/proc/clearEvent(event_type as text, datum/callback/cb)
	if(!event_type || !cb)
		return FALSE
	var/list/event = listgetindex(events,event_type)
	event -= cb
	qdel(cb)
	return TRUE

/////////////////////////////
//STORYTELLER RELATED PROCS//
/////////////////////////////

//Called when the tick is equal to the startWhen variable.
//Allows you to start before announcing or vice versa.
//Only called once.
/datum/events/proc/start()//Called when the tick is equal to the startWhen variable.

//Checks if the event can fire now.
//This should always be called before paying for the event
/datum/events/proc/can_trigger()
	return TRUE

//Called first before processing.
//Allows you to setup your event, such as randomly
//setting the startWhen and or announceWhen variables.
//Only called once.
/datum/events/proc/setup()
	return

/datum/events/proc/Initialize()
	// event needs to be responsible for this, as stuff like APLUs currently make their own events for curious reasons
	SSevents.running += src
	setup()
