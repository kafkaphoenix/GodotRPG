extends Node2D

const GRASS_EFFECT: PackedScene  = preload("res://assets/Effects/grass_effect.tscn") 
@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
    hurtbox.set_collision_layer_value(CollisionsLayers.Layers.GRASS, true)
    hurtbox.set_collision_mask_value(CollisionsLayers.Layers.PLAYERSWORD, true)
    hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func create_grass_effect() -> void:
    var grass_effect: Node2D = GRASS_EFFECT.instantiate()
    grass_effect.position = self.position
    get_parent().add_child(grass_effect)

func _on_hurtbox_area_entered(_area: Area2D) -> void:
    create_grass_effect()
    queue_free()
