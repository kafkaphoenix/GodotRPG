extends CharacterBody2D

const BAT_DEATH_EFFECT: PackedScene  = preload("res://assets/Effects/bat_death_effect.tscn") 

enum State {
    IDLE,
    WANDER,
    CHASE
}

const randomStates: Array = [State.IDLE, State.WANDER]

@export var KNOCKBACK_SPEED := 120
@export var AIR_FRICTION := 100
@export var ACCELERATION := 300
@export var SPEED := 50
@export var PUSHBACK := 400
@export var TOLERANCE := 5
@export var INVINCIBILITY := 0.4

@onready var stats: Stats = $Stats
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $BatHitbox
@onready var playerDetectionZone: PlayerDetectionZone = $PlayerDetectionZone
@onready var sprite: AnimatedSprite2D = $AnimatedSprite
@onready var state := State.IDLE
@onready var softCollision: SoftCollision = $SoftCollision
@onready var wanderController: WanderController = $WanderController
@onready var blinkAnimationPlayer: AnimationPlayer = $BlinkAnimationPlayer

func _ready() -> void:
    set_collision_mask_value(CollisionsLayers.Layers.WORLD, true)
    hurtbox.set_collision_layer_value(CollisionsLayers.Layers.ENEMIES, true)
    hurtbox.set_collision_mask_value(CollisionsLayers.Layers.PLAYERSWORD, true)
    hitbox.set_collision_layer_value(CollisionsLayers.Layers.ENEMIES, true)
    stats.max_health = 3
    stats.no_health.connect(_on_stats_no_health)
    randomize()
    sprite.frame = randi_range(0, sprite.sprite_frames.get_frame_count("Fly") - 1)
    state = pick_random_state(randomStates)
    hurtbox.area_entered.connect(_on_hurtbox_area_entered)
    hurtbox.invincibility_started.connect(_on_hurtbox_invincibility_started)
    hurtbox.invincibility_ended.connect(_on_hurtbox_invincibility_ended)

func _physics_process(delta: float) -> void:
    velocity = velocity.move_toward(Vector2.ZERO, AIR_FRICTION * delta) 
    
    match state:
        State.IDLE:
            velocity = velocity.move_toward(Vector2.ZERO, AIR_FRICTION * delta)
            seek_player()

            if wanderController.get_time_left() == 0:
                restart_state()
        State.WANDER:
            seek_player()

            if wanderController.get_time_left() == 0:
                restart_state()
            
            move_toward_point(wanderController.target_position, delta)
            
            if global_position.distance_to(wanderController.target_position) <= TOLERANCE:
                restart_state()
                
        State.CHASE:
            var player := playerDetectionZone.player
            if player != null:
                move_toward_point(player.global_position, delta)
            else:
                state = State.IDLE
    
    velocity += softCollision.get_push_vector() * delta * PUSHBACK
    move_and_slide()    

func move_toward_point(point: Vector2, delta: float) -> void:
    var direction := global_position.direction_to(point)
    velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
    sprite.flip_h = velocity.x < 0
    
func restart_state() -> void:
    state = pick_random_state(randomStates)
    wanderController.start_wander_timer(randi_range(1, 3))

func seek_player() -> void:
    if playerDetectionZone.can_see_player():
        state = State.CHASE
        
func pick_random_state(state_list: Array) -> State:
    return state_list.pick_random()

func _on_hurtbox_area_entered(area: Area2D) -> void:
    var direction := -global_position.direction_to(area.global_position)
    velocity = direction * KNOCKBACK_SPEED
    var swordHitbox := area as Hitbox
    stats.health -= swordHitbox.damage
    # stats.print_debug()
    hurtbox.create_hit_effect()
    hurtbox.start_invincibility(INVINCIBILITY)
    
func _on_stats_no_health() -> void:
    create_bat_death_effect()
    queue_free()

func create_bat_death_effect() -> void:
    var bat_death_effect: Node2D = BAT_DEATH_EFFECT.instantiate()
    bat_death_effect.position = self.position
    get_parent().add_child(bat_death_effect)

func _on_hurtbox_invincibility_started() -> void:
    blinkAnimationPlayer.play("Start")
    
func _on_hurtbox_invincibility_ended() -> void:
    blinkAnimationPlayer.play("Stop")
