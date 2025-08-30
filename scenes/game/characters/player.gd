class_name Player extends CharacterBody2D

@export var hurt_sound: PackedScene
@export var stats: Stats
@export var speed := 80
@export var acceleration := 500
@export var roll_speed := 125
@export var friction := 500

var input_vector := Vector2.ZERO
# default roll if the sprite is looking down too
# included blend in animation tree state
var last_input_vector := Vector2.DOWN

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get(&"parameters/StateMachine/playback")
@onready var weapon_hitbox: Hitbox = $WeaponHitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var blink_animation_player: AnimationPlayer = $BlinkAnimationPlayer

func _ready() -> void:
    # for top downs games: all collisions are considered walls
    # grounded is for platform games
    motion_mode = MOTION_MODE_FLOATING
    set_collision_layer_value(CollisionsLayers.Layers.PLAYER, true)
    set_collision_mask_value(CollisionsLayers.Layers.WORLD, true)
    weapon_hitbox.set_collision_layer_value(CollisionsLayers.Layers.PLAYER, true)
    weapon_hitbox.set_collision_mask_value(CollisionsLayers.Layers.ENEMY_HURTBOX, true)
    hurtbox.set_collision_layer_value(CollisionsLayers.Layers.PLAYER_HURTBOX, true)
    hurtbox.set_collision_mask_value(CollisionsLayers.Layers.ENEMY, true)
    # called after everything has been processed on the current frame
    hurtbox.hurt.connect(_on_hurt.call_deferred)
    stats = stats.duplicate()
    stats.max_health = 4
    stats.health = 4
    stats.no_health.connect(_on_no_health)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed(&"ui_cancel"):
        get_tree().quit()   

func move_state(delta: float) -> void:
    input_vector = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
    
    # move toward is better than lerp for movement
    if input_vector != Vector2.ZERO:
        last_input_vector = input_vector
        var direction_vector := Vector2(input_vector.x, -input_vector.y)
        # we update blend position with the input vector only when we are moving
        update_blend_position(direction_vector)
    
    if Input.is_action_just_pressed(&"attack"):
        playback.travel(&"AttackState")
        
    if Input.is_action_just_pressed(&"roll"):
        playback.travel(&"RollState")

    velocity = velocity.move_toward(input_vector * speed, acceleration * delta)
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
    velocity = velocity.move_toward(last_input_vector.normalized() * roll_speed, acceleration * delta)
    playback.travel(&"RollState")
    move_and_slide()  

func _physics_process(delta: float) -> void:
    var current_state := playback.get_current_node()
    if current_state == &"MoveState":
        move_state(delta)
    if current_state == &"RollState":
        roll_state(delta)
    if current_state == &"AttackState":
        attack_state()

func _on_no_health() -> void:
    queue_free()
    #hide()
    #remove_from_group(&"player")
    #process_mode = Node.PROCESS_MODE_DISABLED

func _on_hurt(other_hitbox: Hitbox) -> void:
    stats.health -= other_hitbox.damage
    blink_animation_player.play(&"blink")
    var hurt_sound_instance := hurt_sound.instantiate()
    get_tree().current_scene.add_child(hurt_sound_instance)
