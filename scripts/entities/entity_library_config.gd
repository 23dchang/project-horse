## Enables modifying [code]EntityLibrary[/code] parameter values
## without modifying its source code. Make this a sibling node to the
## node that initializes [code]EntityLibrary[/code].
class_name EntityLibraryConfig
extends Node

# For now all entities generate the same number of skills

## [code]key[/code] is skill tier level and [code]value[/code]
## is the number of skill cards to be generated for that tier.
## As of now higher tier level means more powerful skill.
@export var entity_skillset_specs: Dictionary = {
	1: 3,
	2: 2,
	3: 1,
}
