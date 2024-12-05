//Storyteller Cache.
GLOBAL_LIST_EMPTY(storyteller_cache)

// Event defines.
#define EVENT_LEVEL_MUNDANE  		"mundane"
#define EVENT_LEVEL_MINOR			"minor"
#define EVENT_LEVEL_MODERATE 		"moderate"
#define EVENT_LEVEL_CATASTROPHIC	"catastrophic"
#define EVENT_LEVEL_ROLESET 		"roleset"
#define EVENT_LEVEL_ECONOMY  		"economy"


//The threshold of points that we need before attempting to purchase things.
#define POOL_THRESHOLD_MUNDANE		25
#define POOL_THRESHOLD_MINOR		50
#define POOL_THRESHOLD_MODERATE		75
#define POOL_THRESHOLD_CATASTROPHIC	100
#define POOL_THRESHOLD_ROLESET		150


//Event tags. These loosely describe what the event will do.
//Storytellers can vary the weighting and cost of events based on these tags.

//The event generates monsters or antags to battle.
//Example: Skeletons, Goblins, Beespiders.
//Most antags are tagged combat too.
//Combat events usually create work for the Garrison and Mercenaries.
#define TAG_COMBAT "combat"



//The event involves one or very few people. The people who are unaffected often won't care, for the most part.
//Examples: N/A at time of porting/refactoring.
#define TAG_TARGETED "targeted"



//The event involves most or all of the town/keep, everyone has something to do, everyone is involved.
//Examples: N/A at time of porting/refactoring.
#define TAG_COMMUNAL "communal"



//The event has the potential to deal damage to the town and/or keep.
//Examples: N/A at time of porting/refactoring.
//Destructive events usually create work for Stone Masons, Carpenters, Blacksmiths, Artificers.
#define TAG_DESTRUCTIVE "destructive"



//The event is negative. It harms people, breaks things, and generally creates problems.
//This is pretty much every event and antag. Almost everything will be tagged with negative.
#define TAG_NEGATIVE "negative"



//The event helps people, gives them stuff, heals them.
//Often tied to the Mundane events.
#define TAG_POSITIVE "positive"


//The event helps to invoke a horror vibe. Plunges players into darkness, makes terrifying creatures, etc.
#define TAG_SCARY "scary"


//The event comes from outside of the town/keep, making Guards or Mercenaries go and handle them.
//Examples: N/A at time of porting/refactoring.
#define TAG_EXTERNAL "external"




//Defines from other folders going here to keep things... relatively clean and modular?
// Storyteller names macro
#define STORYTELLER_BASE "guide"
