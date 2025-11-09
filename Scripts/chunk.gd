extends Node3D
class_name Chunk

@export var noise: FastNoiseLite
@export var size: int
@export var max_height: int
@export var LOD: float
@export var chunk_position: Vector2i
@export var pos: Vector2i
# @export var LowColor: Color
# @export var HighColor: Color
# @export var GroundGradient: Gradient
# @export var FarGradient: Gradient

var should_remove = true


func _init(global_noise: FastNoiseLite, chunk_size: int, height: int, lod: float, c_pos: Vector2i) -> void:
  self.noise = global_noise
  self.size = chunk_size
  self.chunk_position = c_pos
  self.pos = c_pos * size
  self.max_height = height
  self.LOD = lod


func _ready():
  generate_chunk()


func generate_chunk():

  var plane_mesh = PlaneMesh.new()
  plane_mesh.size = Vector2(size, size)
  plane_mesh.subdivide_width = size * LOD # consider using (2 ** LOD)
  plane_mesh.subdivide_depth = size * LOD
  plane_mesh.material = preload("res://Materials/WhiteMaterial.tres")
  var GroundGradient = preload("res://Materials/near_gradient.tres")
  var FarGradient = preload("res://Materials/far_gradient.tres")

  var st = SurfaceTool.new()
  var mdt = MeshDataTool.new()

  st.begin(Mesh.PRIMITIVE_TRIANGLES)
  st.create_from(plane_mesh, 0)
  var array_mesh = st.commit()

  mdt.create_from_surface(array_mesh, 0)
  for i in range(mdt.get_vertex_count()):
    var v = mdt.get_vertex(i)
    var px = v.x + pos.x
    var pz = v.z + pos.y
    var noise_val = noise.get_noise_2d(px, pz)
    v.y = noise_val * max_height
    mdt.set_vertex(i, v)

    var c: Color = GroundGradient.sample((noise_val + 1) / 2)
    # if LOD > .6:
    #   c = FarGradient.sample(float(noise_val + 1) / 2)
    # else: c = FarGradient.sample(float(noise_val + 1) / 2)
    # if LOD < 1: c = Color.GREEN
    # if LOD < .4: c = Color.RED
    
    mdt.set_vertex_color(i, c)


  array_mesh.clear_surfaces()
  mdt.commit_to_surface(array_mesh, 0)


  var mesh_inst = MeshInstance3D.new()
  mesh_inst.mesh = array_mesh
  mesh_inst.lod_bias = LOD
  # mesh_inst.create_debug_tangents()
  if LOD >= 1: mesh_inst.create_trimesh_collision()
  add_child(mesh_inst)


# returns the height of the vertex at pos (x, z) in the range [-1, 1]
func GenerateHeightData(x: int, z: int) -> float:
  var h: float = 0
  h += noise.get_noise_2d(x, z)
  return h