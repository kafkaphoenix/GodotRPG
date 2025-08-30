class_name WanderController extends Node2D

@export var wander_range: int = 32

@onready var timer: Timer = $Timer
@onready var start_position: Vector2 = global_position
@onready var target_position: Vector2 = global_position

func _ready() -> void:
    timer.one_shot = true
    timer.autostart = true
    timer.timeout.connect(_on_timer_timeout)
    update_target_position()
    
func update_target_position() -> void:
    var target_vector := Vector2(randi_range(-wander_range, wander_range), randi_range(-wander_range, wander_range))
    # we keep it relative to the starting position
    target_position = start_position + target_vector

func get_time_left() -> float:
    return timer.time_left
    
func start_wander_timer(duration: float) -> void:
    timer.start(duration)    
    
func _on_timer_timeout() -> void:
    # every second
    update_target_position()
