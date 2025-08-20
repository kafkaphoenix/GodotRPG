extends CharacterBody2D

@export var MAX_SPEED := 80
@export var ACCELERATION := 500
@export var ROLL_SPEED := 125
@export var FRICTION := 500
@export var INVINCIBILITY := 0.6

enum State {
    MOVE,
    ROLL,
    ATTACK
}

var state := State.MOVE
var roll_vector := Vector2.DOWN
var stats: Stats = PlayerStats

@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var animationTree: AnimationTree = $AnimationTree
@onready var swordHitbox: Hitbox = $HitboxPivot/SwordHitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var animationCurrentState: AnimationNodeStateMachinePlayback = animationTree.get(&"parameters/playback")
@onready var blinkAnimationPlayer: AnimationPlayer = $BlinkAnimationPlayer
const playerHurtSound := preload("res://scenes/game/characters/player_hurt_sound.tscn")

func _ready() -> void:
    # for top downs games: all collisions are considered walls
    motion_mode = MOTION_MODE_FLOATING
    set_collision_layer_value(CollisionsLayers.Layers.PLAYER, true)
    set_collision_mask_value(CollisionsLayers.Layers.WORLD, true)
    hurtbox.set_collision_layer_value(CollisionsLayers.Layers.PLAYER, true)
    hurtbox.set_collision_mask_value(CollisionsLayers.Layers.ENEMIES, true)
    swordHitbox.set_collision_layer_value(CollisionsLayers.Layers.PLAYERSWORD, true)
    
    animationTree.active = true
    animationTree.animation_finished.connect(_on_animation_tree_animation_finished)
    stats.no_health.connect(_on_stats_no_health)
    hurtbox.area_entered.connect(_on_hurtbox_area_entered)
    hurtbox.invincibility_started.connect(_on_hurtbox_invincibility_started)
    hurtbox.invincibility_ended.connect(_on_hurtbox_invincibility_ended)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed(&"ui_cancel"):
        get_tree().quit()   

func move_state(delta: float) -> void:
    var input_vector := Vector2(Input.get_axis(&"ui_left", &"ui_right"), Input.get_axis(&"ui_up", &"ui_down"))
    # to avoid diagonal increased speed
    input_vector = input_vector.limit_length(1.0)
    
    # move toward is better than lerp for movement
    if input_vector != Vector2.ZERO:
        # we update blend position with the input vector only when we are moving
        roll_vector = input_vector
        animationTree.set(&"parameters/Idle/blend_position", input_vector)
        animationTree.set(&"parameters/Run/blend_position", input_vector)
        animationTree.set(&"parameters/Attack/blend_position", input_vector)
        animationTree.set(&"parameters/Roll/blend_position", input_vector)
        animationCurrentState.travel(&"Run")
        # velocity defined in CharacterBody2D already
        velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
    else:
        animationCurrentState.travel(&"Idle")
        velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

    move()
    
    if Input.is_action_just_pressed(&"attack"):
        state = State.ATTACK
        
    if Input.is_action_just_pressed(&"roll"):
        state = State.ROLL

func attack_state() -> void:
    velocity = Vector2.ZERO
    animationCurrentState.travel(&"Attack")
    
func roll_state(delta: float) -> void:
    velocity = velocity.move_toward(roll_vector * ROLL_SPEED, ACCELERATION * delta)
    animationCurrentState.travel(&"Roll")
    move()  

func move() -> void:
    # applies delta under the hood to velocity
    move_and_slide()

func _physics_process(delta: float) -> void:
    # you shouldn't move outside physics process?
    match state:
        State.MOVE:
            move_state(delta)
        State.ROLL:
            roll_state(delta)
        State.ATTACK:
            attack_state()

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
    if (anim_name == &"AttackDown"
    or anim_name == &"AttackUp"
    or anim_name == &"AttackLeft"
    or anim_name == &"AttackRight"
    or anim_name == &"RollDown"
    or anim_name == &"RollUp"
    or anim_name == &"RollLeft"
    or anim_name == &"RollRight"
    ):
        velocity = Vector2.ZERO
        state = State.MOVE

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
        var hurtSound := playerHurtSound.instantiate()
        get_tree().current_scene.add_child(hurtSound)

func _on_hurtbox_invincibility_started() -> void:
    blinkAnimationPlayer.play("Start")
    
func _on_hurtbox_invincibility_ended() -> void:
    blinkAnimationPlayer.play("Stop")
