extends Area2D

class_name SoftCollision

# we could also use voids here for better performance
func get_push_vector() -> Vector2:
    var push_vector := Vector2.ZERO
    var areas := get_overlapping_areas()
    var is_colliding := areas.size() > 0

    if is_colliding:
        var area := areas[0]
        push_vector = area.global_position.direction_to(global_position)
    
    return push_vector

func _ready() -> void:
    set_collision_layer_value(CollisionsLayers.Layers.SOFT_COLLISION, true)
    set_collision_mask_value(CollisionsLayers.Layers.SOFT_COLLISION, true)
