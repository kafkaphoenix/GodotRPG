class_name Stats extends Resource

signal no_health
signal health_changed(value: int)
signal max_health_changed(value: int)

@export var max_health := 1:
    get:
        return max_health
    set(value):
        max_health = max(1, value)
        max_health_changed.emit(max_health)

@export var health := 1:
    get:
        return health
    set(value):
        health = clamp(value, 0, self.max_health)
        health_changed.emit(health)
        if health <= 0:
            no_health.emit()

func print_debug() -> void:
    print("Health: %d / %d" % [health, max_health])
