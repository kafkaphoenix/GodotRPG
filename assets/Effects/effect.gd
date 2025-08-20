extends AnimatedSprite2D

func _ready() -> void:
    animation_finished.connect(_on_animated_sprite_2d_animation_finished)
    play(&"Animate")

func _on_animated_sprite_2d_animation_finished() -> void:
    queue_free()
