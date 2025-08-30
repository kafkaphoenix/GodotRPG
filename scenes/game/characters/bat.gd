extends CharacterBody2D

@export var death_effect: PackedScene
@export var stats: Stats
@export var max_attack_range := 100
@export var min_attack_range := 10
@export var air_friction := 100
@export var acceleration := 300
@export var speed := 50
@export var tolerance := 5

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get(&"parameters/StateMachine/playback")
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var blink_animation_player: AnimationPlayer = $BlinkAnimationPlayer
@onready var wander_controller: WanderController = $WanderController
@onready var player: Player = get_tree().get_first_node_in_group(&"player")

func _ready() -> void:
    # for top downs games: all collisions are considered walls
    # grounded is for platform games
    motion_mode = MOTION_MODE_FLOATING
    set_collision_layer_value(CollisionsLayers.Layers.ENEMY, true)
    set_collision_mask_value(CollisionsLayers.Layers.ENEMY, true)
    set_collision_mask_value(CollisionsLayers.Layers.WORLD, true)
    ray_cast_2d.set_collision_mask_value(CollisionsLayers.Layers.WORLD, true)
    hitbox.set_collision_layer_value(CollisionsLayers.Layers.ENEMY, true)
    hitbox.set_collision_mask_value(CollisionsLayers.Layers.PLAYER_HURTBOX, true)
    hurtbox.set_collision_layer_value(CollisionsLayers.Layers.ENEMY_HURTBOX, true)
    hurtbox.set_collision_mask_value(CollisionsLayers.Layers.PLAYER, true)
    # called after everything has been processed on the current frame
    hurtbox.hurt.connect(_on_hurt.call_deferred)
    stats = stats.duplicate()
    stats.max_health = 3
    stats.health = 3
    stats.no_health.connect(_on_no_health)

func _physics_process(delta: float) -> void:
    var state := playback.get_current_node()
    match state:
        &"IdleState":
            velocity = velocity.move_toward(Vector2.ZERO, air_friction * delta)
            #seek_player()

            if wander_controller.get_time_left() == 0:
                restart_state()
        &"ChaseState":
            if player is Player:
                # velocity assignment doesn't need delta
                velocity = global_position.direction_to(player.global_position) * speed
                sprite.scale.x = sign(velocity.x)
            else:
                velocity = Vector2.ZERO
            move_and_slide()
        &"HitState":
            #seek_player()
            #
            #if wanderController.get_time_left() == 0:
                #restart_state()
            #
            # change in velocity over time which is acceleration (negative in this case)
            # that's why we apply delta to friction so it's time dependent insteaf
            # of frame dependent
            velocity = velocity.move_toward(Vector2.ZERO, air_friction * delta)
            #
            #if global_position.distance_to(wanderController.target_position) <= tolerance:
                #restart_state()         
            move_and_slide()
    
func is_player_in_range() -> bool:
    if player == null: return false
    var distance := global_position.distance_to(player.global_position)
    return distance < max_attack_range and distance > min_attack_range

func can_see_player() -> bool:
    if not is_player_in_range(): return false
    ray_cast_2d.target_position = player.global_position - global_position
    var see_player := not ray_cast_2d.is_colliding()
    return see_player
    
func restart_state() -> void:
    #state = pick_random_state(randomStates)
    wander_controller.start_wander_timer(randi_range(1, 3))

func _on_hurt(other_hitbox: Hitbox) -> void:
    stats.health -= other_hitbox.damage
    #stats.print_debug()
    velocity = other_hitbox.knockback_direction * other_hitbox.knockback_amount
    blink_animation_player.play(&"blink")
    playback.start(&"HitState")
    
func _on_no_health() -> void:
    create_death_effect()
    queue_free()

func create_death_effect() -> void:
    var death_effect_instance: Node2D = death_effect.instantiate()
    death_effect_instance.global_position = self.global_position
    get_parent().add_child(death_effect_instance)
