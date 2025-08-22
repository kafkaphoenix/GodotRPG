extends CharacterBody2D

const PLAYER_HURT_SOUND := preload("res://scenes/game/characters/player_hurt_sound.tscn")

enum State {
    MOVE,
    ROLL,
    ATTACK
}

@export var SPEED := 80
@export var ACCELERATION := 500
@export var ROLL_SPEED := 125
@export var FRICTION := 500
@export var INVINCIBILITY := 0.6

var stats: Stats = PlayerStats
var input_vector := Vector2.ZERO
var last_input_vector := Vector2.ZERO

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get(&"parameters/StateMachine/playback")
@onready var swordHitbox: Hitbox = $HitboxPivot/SwordHitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var blink_animation_player: AnimationPlayer = $BlinkAnimationPlayer

func _ready() -> void:
    # for top downs games: all collisions are considered walls
    # grounded is for platform games
    motion_mode = MOTION_MODE_FLOATING
    set_collision_layer_value(CollisionsLayers.Layers.PLAYER, true)
    set_collision_mask_value(CollisionsLayers.Layers.WORLD, true)
    hurtbox.set_collision_layer_value(CollisionsLayers.Layers.PLAYER, true)
    hurtbox.set_collision_mask_value(CollisionsLayers.Layers.ENEMIES, true)
    swordHitbox.set_collision_layer_value(CollisionsLayers.Layers.PLAYERSWORD, true)
    
    stats.no_health.connect(_on_stats_no_health)
    hurtbox.area_entered.connect(_on_hurtbox_area_entered)
    hurtbox.invincibility_started.connect(_on_hurtbox_invincibility_started)
    hurtbox.invincibility_ended.connect(_on_hurtbox_invincibility_ended)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed(&"ui_cancel"):
        get_tree().quit()   

func move_state(delta: float) -> void:
    input_vector = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
    
    # move toward is better than lerp for movement
    if input_vector != Vector2.ZERO:
        # we update blend position with the input vector only when we are moving
        last_input_vector = input_vector
        var direction_vector := Vector2(input_vector.x, -input_vector.y)
        update_blend_position(direction_vector)
    
    if Input.is_action_just_pressed(&"attack"):
        playback.travel(&"AttackState")
        
    if Input.is_action_just_pressed(&"roll"):
        playback.travel(&"RollState")

    velocity = velocity.move_toward(input_vector * SPEED, ACCELERATION * delta)
    move_and_slide()

func update_blend_position(direction_vector: Vector2) -> void:
    animation_tree.set(&"parameters/StateMachine/MoveState/IdleState/blend_position", direction_vector)
    animation_tree.set(&"parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
    animation_tree.set(&"parameters/StateMachine/AttackState/blend_position", direction_vector)
    animation_tree.set(&"parameters/StateMachine/RollState/blend_position", direction_vector)

func attack_state() -> void:
    velocity = Vector2.ZERO
    playback.travel(&"AttackState")
    
func roll_state(delta: float) -> void:
    # we need to normalize here to avoid issues with joysticks
    velocity = velocity.move_toward(last_input_vector.normalized() * ROLL_SPEED, ACCELERATION * delta)
    playback.travel(&"RollState")
    move_and_slide()  

func _physics_process(delta: float) -> void:
    # you shouldn't move outside physics process?
    var current_state := playback.get_current_node()
    if current_state == &"MoveState":
        move_state(delta)
    if current_state == &"RollState":
        roll_state(delta)
    if current_state == &"AttackState":
        attack_state()

func _on_stats_no_health() -> void:
    queue_free()

func _on_hurtbox_area_entered(area: Area2D) -> void:
    if area is Hitbox:
        var direction := -global_position.direction_to(area.global_position)
        velocity = direction * 100
        var batHitbox := area as Hitbox
        stats.health -= batHitbox.damage
        hurtbox.start_invincibility(INVINCIBILITY)
        var offset := Vector2(0, 8)
        hurtbox.create_hit_effect(offset)
        var hurt_sound := PLAYER_HURT_SOUND.instantiate()
        get_tree().current_scene.add_child(hurt_sound)

func _on_hurtbox_invincibility_started() -> void:
    blink_animation_player.play(&"Start")
    
func _on_hurtbox_invincibility_ended() -> void:
    blink_animation_player.play(&"Stop")
