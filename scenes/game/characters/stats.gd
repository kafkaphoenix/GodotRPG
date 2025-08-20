extends Node

class_name Stats

signal no_health
signal health_changed(value: int)
signal max_health_changed(value: int)

@export var _max_health := 5
var max_health: int:
    get:
        return _max_health
    set(value):
        _max_health = max(1, value)
        self.health = min(health, _max_health)
        max_health_changed.emit(_max_health)

@export var _health := 5
var health: int:
    get:
        return _health
    set(value):
        _health = clamp(value, 0, self.max_health)
        health_changed.emit(_health)
        if _health <= 0:
            no_health.emit()

func print_debug() -> void:
    print("Health: %d / %d" % [health, max_health])
