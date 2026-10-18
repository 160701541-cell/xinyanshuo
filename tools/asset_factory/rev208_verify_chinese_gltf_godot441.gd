extends SceneTree
## Independent native Godot 4.4.1 import check, NOT original Main art approval.
## These are actual author Chinese architecture geometry assets converted from
## immutable CC0 FBX, with provenance retained by the separate intake CI.
func _initialize() -> void:
  call_deferred("_run")

func _run() -> void:
  var folder: String=OS.get_environment("CANGLAN_CHINESE_SOURCE_DIR")
  if folder.is_empty():
    printerr("FAIL_REV208_CHINESE_GLTF_NO_PINNED_SOURCE_DIRECTORY")
    quit(77)
    return
  for filename in [
      "chinese_four_corner_pavilion.glb",
      "chinese_classical_garden_wall.glb"]:
    var path: String=folder.path_join(filename)
    if not FileAccess.file_exists(path):
      printerr("FAIL_REV208_CHINESE_GLTF_NO_REAL_VENDOR_CONVERTED_BINARY "+path)
      quit(78)
      return
    var state:=GLTFState.new()
    var doc:=GLTFDocument.new()
    var err: Error=doc.append_from_file(path,state)
    if err!=OK:
      printerr("FAIL_REV208_CHINESE_CC0_GLB2_GODOT441_IMPORT "+str(err)+" "+path)
      quit(79)
      return
    var scene: Node=doc.generate_scene(state)
    if scene==null:
      printerr("FAIL_REV208_CHINESE_ARCHITECTURE_GODOT_GENERATED_NO_REAL_SCENE")
      quit(80)
      return
    var parts: Array[Node]=scene.find_children("*","MeshInstance3D",true,false)
    var surfaces: int=0
    var triangles: int=0
    var real_materials: int=0
    var uv_parts: int=0
    for node in parts:
      var mesh: MeshInstance3D=node as MeshInstance3D
      if mesh==null or mesh.mesh==null:
        continue
      surfaces+=mesh.mesh.get_surface_count()
      for idx in range(mesh.mesh.get_surface_count()):
        var arrays: Array=mesh.mesh.surface_get_arrays(idx)
        if arrays[Mesh.ARRAY_TEX_UV]!=null and (
            arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array).size()>3:
          uv_parts+=1
        if arrays[Mesh.ARRAY_INDEX]!=null:
          triangles+=(arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()/3
        elif arrays[Mesh.ARRAY_VERTEX]!=null:
          triangles+=(arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()/3
        if mesh.mesh.surface_get_material(idx)!=null:
          real_materials+=1
    if parts.is_empty() or surfaces<1 or uv_parts<1 or triangles<100 or (
        triangles>5000000):
      printerr("FAIL_REV208_CHINESE_CC0_GODOT_IMPORT_NOT_REAL_UV_MESHES "+
        str({"file":filename,"nodes":parts.size(),"surfaces":surfaces,
          "uv_surfaces":uv_parts,"triangles":triangles}))
      scene.free()
      quit(81)
      return
    print("PASS_REV208_CHINESE_AUTHOR_CC0_FBX_CONVERTED_GLTF_NATIVE_GODOT441 "+
      str({"file":filename,"nodes":parts.size(),"surfaces":surfaces,
        "uv_surfaces":uv_parts,"materials":real_materials,
        "triangles":triangles,"pending_original_main_art_p0":true}))
    scene.free()
  print("PASS_REV208_CHINESE_PAVILION_AND_MOONGATE_REAL_3D_GODOT_SOURCE_IMPORT_QUARANTINED_NOT_GAME_ART_ACCEPTED")
  quit(0)
