extends Node3D

@export var TerrainNoise: FastNoiseLite
@export var BuildingsNoise: FastNoiseLite
@export var playerTransform: Node3D
@export var ChunkSize: int = 32
@export var MaxHeight: int = 64
@export var RenderDistance: int = 16
@export var Ranges: Array[LOD_Range]

@export var Buildings: Array[PackedScene]

@export var PL_Scene: PackedScene
var is_player_created = false
var is_world_created = false
var PL: Player

@export var CAM: Camera3D

var chunks: Dictionary
var unready_chunks: Dictionary
var thread: Thread


func _ready() -> void:
  var my_seed = randi()
  TerrainNoise.seed = my_seed
  BuildingsNoise.seed = my_seed
  thread = Thread.new()
  SIGNALBUS.finished_world_creation.connect(_on_finished_world_creation)
  GLOBALS.BuildingArray = Buildings


func _process(_delta: float) -> void:
  update_chunks()
  delete_old_chunks()
  reset_chunks()

  if unready_chunks.size() == 0 && !is_world_created:
    is_world_created = true
    SIGNALBUS.finished_world_creation.emit()


func update_chunks():
  var px = playerTransform.position.x
  var pz = playerTransform.position.z
  var c_pos = world_to_chunk_coord(px, pz)
  var cx = c_pos.x
  var cz = c_pos.y

  for lod_range in Ranges:
    for x in range(cx - lod_range.End, cx - lod_range.Start + 1):
      for z in range(cz - lod_range.End, cz + lod_range.End):
        add_chunk(x, z, lod_range.LOD)
        var c = get_chunk(x, z)
        if c != null && c.LOD == lod_range.LOD:
          c.should_remove = false
    for x in range(cx - lod_range.Start, cx + lod_range.Start):
      for z in range(cz - lod_range.End, cz - lod_range.Start + 1):
        add_chunk(x, z, lod_range.LOD)
        var c = get_chunk(x, z)
        if c != null && c.LOD == lod_range.LOD:
          c.should_remove = false
      for z in range(cz + lod_range.Start - 1, cz + lod_range.End):
        add_chunk(x, z, lod_range.LOD)
        var c = get_chunk(x, z)
        if c != null && c.LOD == lod_range.LOD:
          c.should_remove = false
    for x in range(cx + lod_range.Start - 1, cx + lod_range.End):
      for z in range(cz - lod_range.End, cz + lod_range.End):
        add_chunk(x, z, lod_range.LOD)
        var c = get_chunk(x, z)
        if c != null && c.LOD == lod_range.LOD:
          c.should_remove = false


func delete_old_chunks():
  for key in chunks:
    var c: Chunk = chunks.get(key)
    if c.should_remove:
      c.queue_free()
      chunks.erase(key)

func reset_chunks():
  for key in chunks:
    var c: Chunk = chunks.get(key)
    c.should_remove = true


func world_to_chunk_coord(x: int, z: int) -> Vector2i:
  var cz = (z + ChunkSize * .5) / ChunkSize
  var cx = (x + ChunkSize * .5) / ChunkSize

  if x < 0: cx -= 1
  if z < 0: cz -= 1

  return Vector2(cx, cz)

func get_key(x: int, z: int) -> String:
  return str(x) + ',' + str(z)

func get_chunk(x: int, z: int):
  var key = get_key(x, z)
  if chunks.has(key): return chunks.get(key)

  return null

func add_chunk(x: int, z: int, lod: float):
  var key = get_key(x, z)
  if chunks.has(key) || unready_chunks.has(key):
    return
  if chunks.has(key):
    if chunks[key].LOD != lod:
      chunks[key].should_remove = true
    return
  if unready_chunks.has(key):
    return

    
  if not thread.is_started():
    thread.start(_load_chunk.bind(thread, x, z, lod))
    unready_chunks[key] = lod


func _load_chunk(thr: Thread, x: int, z: int, lod: float):
  var building_value: float = BuildingsNoise.get_noise_2d(x, z)
  var building = Chunk.BuildingType.Empty

  if building_value > .75: building = Chunk.BuildingType.Ruin

  var c = Chunk.new(TerrainNoise, ChunkSize, MaxHeight, lod, Vector2i(x, z), building)
  c.position = Vector3(x * ChunkSize, 0, z * ChunkSize)
  call_deferred("_on_load_finished", c, thr)

func _on_load_finished(c: Chunk, thr: Thread):
  $ChunkContainer.add_child(c)
  var key = get_key(c.chunk_position.x, c.chunk_position.y)
  chunks[key] = c
  unready_chunks.erase(key)
  thr.wait_to_finish()

func _on_finished_world_creation():
  if !is_player_created:
    PL = PL_Scene.instantiate() as Player
    var h = TerrainNoise.get_noise_2d(0, 0) * MaxHeight + .5 # SO it isn stuck
    PL.position.y = h
    playerTransform = PL
    add_child(PL)
    # CAM.current = false