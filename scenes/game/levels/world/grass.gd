extends Node2D

@export var grass_effect: PackedScene

@onready var hurtbox: Hurtbox = $Hurtbox

func _ready() -> void:
    hurtbox.set_collision_layer_value(CollisionsLayers.Layers.ENEMY_HURTBOX, true)
    hurtbox.set_collision_mask_value(CollisionsLayers.Layers.PLAYER, true)
    hurtbox.hurt.connect(_on_hurt)

func _on_hurt(_other_hitbox: Hitbox) -> void:
    var grass_effect_instance: Node2D = grass_effect.instantiate()
    grass_effect_instance.global_position = self.global_position
    get_tree().current_scene.add_child(grass_effect_instance)
    queue_free()
