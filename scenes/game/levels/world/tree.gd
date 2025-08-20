extends StaticBody2D

func _ready() -> void:
    set_collision_layer_value(CollisionsLayers.Layers.WORLD, true)
