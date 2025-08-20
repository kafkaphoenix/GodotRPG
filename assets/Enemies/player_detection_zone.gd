extends Area2D

class_name PlayerDetectionZone

var player: CharacterBody2D = null

func _ready() -> void:
    set_collision_mask_value(CollisionsLayers.Layers.PLAYER, true)
    body_entered.connect(_on_player_detection_zone_body_entered)
    body_exited.connect(_on_player_detection_zone_body_exited)

func _on_player_detection_zone_body_entered(body: Node2D) -> void:
    player = body as CharacterBody2D

func _on_player_detection_zone_body_exited(_body: Node2D) -> void:
    player = null

func can_see_player() -> bool:
    return player != null
