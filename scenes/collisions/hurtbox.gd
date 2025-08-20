extends Area2D

class_name Hurtbox

signal invincibility_started
signal invincibility_ended

const HitEffect: PackedScene = preload("res://assets/Effects/hit_effect.tscn")
@onready var timer: Timer = $Timer
@onready var collisionShape: CollisionShape2D = $CollisionShape2D

var invincible: bool:
    get:
        return invincible
    set(value):
        invincible = value
        if invincible:
            invincibility_started.emit()
        else:
            invincibility_ended.emit()

func _ready() -> void:
    timer.timeout.connect(_on_timer_timeout)
    invincibility_started.connect(_on_hurtbox_invincibility_started)
    invincibility_ended.connect(_on_hurtbox_invincibility_ended)

func create_hit_effect(offset: Vector2 = Vector2(0,0)) -> void:
    var hitEffect: Node2D  = HitEffect.instantiate()
    hitEffect.position = self.position - offset
    get_parent().add_child(hitEffect)
    
func start_invincibility(duration: float) -> void:
    self.invincible = true
    timer.start(duration)

func _on_timer_timeout() -> void:
    self.invincible = false

func _on_hurtbox_invincibility_started() -> void:
    # we need to defer setting the variable after the physic process
    collisionShape.set_deferred("disabled", true)
    
func _on_hurtbox_invincibility_ended() -> void:
    # this one happens after timer so it's okey
    collisionShape.disabled = false
    
