/+
	entity content system scribbles

do we care?



https://www.simplilearn.com/entity-component-system-introductory-guide-article

https://austinmorlan.com/posts/entity_component_system/ <---


https://medium.com/mirum-budapest/introduction-to-data-oriented-programming-85b51b99572d

	Using an entity-component system to structure your “objects”. This architecture is like an in-memory database, where entities are identifiers that we can use to look up components. A component represents a particular aspect of an entity (only data, not behavior). A system queries components and performs operations on them.

	For example, let’s say you have 3D entities in your project. These entities can move in the virtual world. There are corresponding components that store data like position, heading, and speed. And there is a system that drives the related calculations.
+/

struct entity
	{
	ulong indentifier;
	}
	
	
struct transform // component, each has a unique id
	{
	pair pos;
	}

struct shape // component, each has a unique id
	{
	color c;
	}


