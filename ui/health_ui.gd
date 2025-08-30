extends Control

const HEARTH_WIDTH := 15

@onready var heartUIFull:TextureRect = $HeartUIFull
@onready var heartUIEmpty:TextureRect = $HeartUIEmpty
@onready var player: Player = get_tree().get_first_node_in_group(&"player")

var max_hearts: int:
    get:
        return max_hearts
    set(value):
        max_hearts = value
        if heartUIEmpty != null:
            heartUIEmpty.size.x = max_hearts * HEARTH_WIDTH

var hearts: int:
    get:
        return hearts
    set(value):
        hearts = value
        if heartUIFull != null:
            heartUIFull.size.x = hearts * HEARTH_WIDTH

func _ready() -> void:
    self.max_hearts = player.stats.max_health
    self.hearts = player.stats.health
    player.stats.connect("health_changed", _on_health_changed)
    player.stats.connect("max_health_changed", _on_max_health_changed)
    
func _on_health_changed(value: int) -> void:
    self.hearts = value

func _on_max_health_changed(value: int) -> void:
    self.max_hearts = value
