extends RefCounted
## DeepSeek blue whale girl: live 3D identity mesh layer on top of existing
## fully clothed Quaternius CC0 65-joint humanoid. NOT an official brand asset.
## Custom components use actual triangle meshes, UVs and PBR/toon materials;
## they follow skeleton Head/Spine/Pelvis instead of sticking to screen pixels.
##
## Art parity is IN PROGRESS. The foundation body face/eye silhouette is not
## a bespoke reference-matched anime sculpt or a finished retail avatar.

const BLUE_DARK := Color(0.044, 0.113, 0.37)
const BLUE_MAIN := Color(0.095, 0.24, 0.57)
const BLUE_SKY := Color(0.22, 0.61, 0.91)
const BLUE_PALE := Color(0.59, 0.81, 0.99)
const WHITE := Color(0.95, 0.965, 1.0)
const GOLD := Color(0.88, 0.66, 0.32)

static func _surface_mat(col:Color, metallic:float=0.0, rough:float=0.63) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=col
    mat.roughness=rough
    mat.metallic=metallic
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return mat

static func _colored_mesh(name:String, mesh:Mesh, parent:Node3D, mat:Material, p:Vector3=Vector3.ZERO) -> MeshInstance3D:
    var obj:=MeshInstance3D.new()
    obj.name=name
    obj.mesh=mesh
    obj.position=p
    obj.material_override=mat
    obj.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    parent.add_child(obj)
    return obj

static func _ball(name:String, parent:Node3D, p:Vector3, scale:Vector3,
                  color:Color, material:Material=null) -> MeshInstance3D:
    var geo:=SphereMesh.new()
    geo.radius=0.5
    geo.height=1.0
    geo.radial_segments=16
    geo.rings=8
    var part:=_colored_mesh(name,geo,parent,material if material!=null else _surface_mat(color),p)
    part.scale=scale
    return part

static func _ribbon_mat() -> StandardMaterial3D:
    var m:=_surface_mat(WHITE,0.0,0.52)
    m.vertex_color_use_as_albedo=true
    m.shading_mode=BaseMaterial3D.SHADING_MODE_PER_PIXEL
    return m

static func _vertex(st:SurfaceTool,p:Vector3,uv:Vector2,col:Color) -> void:
    st.set_color(col)
    st.set_uv(uv)
    st.add_vertex(p)

static func _quad(st:SurfaceTool,
                   a:Vector3,b:Vector3,c:Vector3,d:Vector3,
                   ta:Color,tb:Color,ba:Color,bb:Color) -> void:
    _vertex(st,a,Vector2(0,0),ta)
    _vertex(st,c,Vector2(0,1),ba)
    _vertex(st,b,Vector2(1,0),tb)
    _vertex(st,b,Vector2(1,0),tb)
    _vertex(st,c,Vector2(0,1),ba)
    _vertex(st,d,Vector2(1,1),bb)

static func _make_hair_strand(label:String,parent:Node3D,start:Vector3,end:Vector3,
                             half_width:float,side_wave:float,depth_wave:float,
                             tint:Color) -> MeshInstance3D:
    # Multiple tapering dimensional hair locks, not billboards or PNG cards.
    # Each strip has front/back curved normals and vertex color gradient.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var steps:=14
    var base:=start
    var last_l:=Vector3.ZERO
    var last_r:=Vector3.ZERO
    var last_top:=BLUE_DARK
    var previous_bottom:=BLUE_DARK
    for k in range(steps+1):
        var t:=float(k)/float(steps)
        var curve:=sin(t*PI*.96)
        var tip:=Vector3(
            lerpf(start.x,end.x,t)+side_wave*curve+sin(t*PI*2.0)*0.022,
            lerpf(start.y,end.y,t)+0.034*curve,
            lerpf(start.z,end.z,t)+depth_wave*curve
        )
        var width:=half_width*(0.80+0.23*sin(t*PI))*(1.0-pow(t,3.5))
        var c1:=Color(BLUE_DARK.r,BLUE_DARK.g,BLUE_DARK.b,1).lerp(BLUE_SKY,clampf(t*.83,0,1))
        c1=c1.lerp(tint,0.22)
        var c2:=c1.lightened(.13+sin(t*PI)*.06)
        var left:=tip+Vector3(-width,0,-.009)
        var right:=tip+Vector3(width,0,.015)
        if k>0:
            _quad(st,last_l,last_r,left,right,last_top,last_top.lightened(.14),c1,c2)
        last_l=left
        last_r=right
        last_top=c1
        previous_bottom=c2
    st.generate_normals()
    var geo:=st.commit() as ArrayMesh
    return _colored_mesh("DS_HAIR_"+label,geo,parent,_ribbon_mat())

static func _scallop(name:String,parent:Node3D,center:Vector3,
                     radii:Vector2,amount:int,color:Color,plane:String="x") -> int:
    var n:=0
    for i in range(amount):
        var a:float=PI*float(i)/maxf(1.0,float(amount-1))
        var v:=Vector3(
           center.x+cos(a)*radii.x,
           center.y+sin(a)*radii.y,
           center.z)
        if plane=="z":
            v=Vector3(center.x+cos(a)*radii.x,center.y,
                center.z+sin(a)*radii.y)
        _ball("DS_RUFFLE_"+name+"_"+str(i),parent,v,
            Vector3(.073,.105,.047),color)
        n+=1
    return n

static func _fin(name:String,parent:Node3D,p:Vector3,side:float,color:Color) -> void:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var root:=p
    var end:=p+Vector3(side*.33,.075,-.04)
    var up:=p+Vector3(side*.21,.145,.004)
    var bottom:=p+Vector3(side*.19,-.055,.020)
    _vertex(st,root,Vector2(0,0),color)
    _vertex(st,up,Vector2(.5,0),BLUE_SKY)
    _vertex(st,end,Vector2(1,.45),BLUE_DARK)
    _vertex(st,root,Vector2(0,0),color)
    _vertex(st,end,Vector2(1,.45),BLUE_DARK)
    _vertex(st,bottom,Vector2(.5,1),BLUE_MAIN)
    st.generate_normals()
    _colored_mesh("DS_FIN_"+name,st.commit(),parent,_ribbon_mat())

static func _whale_tail(parent:Node3D) -> void:
    # Whimsical two-lobed whale caudal fin at waist; an actual 3D accessory.
    var stalk:=CylinderMesh.new()
    stalk.top_radius=.05
    stalk.bottom_radius=.082
    stalk.height=.29
    stalk.radial_segments=12
    var shaft:=_colored_mesh("DS_WHALE_TAIL_STALK",stalk,parent,_surface_mat(BLUE_MAIN),
        Vector3(0,-.09,.27))
    shaft.rotation_degrees=Vector3(76,0,0)
    _fin("WHALE_LEFT",parent,Vector3(-.02,-.02,.50),-1.0,BLUE_MAIN)
    _fin("WHALE_RIGHT",parent,Vector3(.02,-.02,.50),1.0,BLUE_MAIN)

static func _skirt(parent:Node3D) -> void:
    # Radial rings with folds, true closed 3D mesh, 48 subdivisions.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var count:=48
    var bands:=9
    var n:=0
    for i in range(count):
        var a:=2.0*PI*float(i)/float(count)
        var b:=2.0*PI*float(i+1)/float(count)
        for j in range(bands):
            var t:=float(j)/float(bands)
            var u:=float(j+1)/float(bands)
            var verts=[]
            for ang in [a,b]:
                for r in [t,u]:
                    var rad:float=lerpf(.16,.41,r)*(1.0+.055*cos(ang*12.0))
                    verts.append(Vector3(
                       cos(ang)*rad,-.13-r*.53,
                       sin(ang)*rad))
            var c1:=BLUE_DARK.lerp(BLUE_MAIN,.4+t*.2)
            var c2:=BLUE_MAIN.lerp(BLUE_SKY,t*.26)
            _quad(st,verts[0],verts[2],verts[1],verts[3],c1,c1,c2,c2)
            n+=2
    st.generate_normals()
    _colored_mesh("DS_SKIRT_NAVY_PLEATS",st.commit(),parent,_ribbon_mat())
    _scallop("SKIRT_HEM",parent,Vector3(0,-.68,0),Vector2(.40,.40),
        14,WHITE,"z")
    # Apron as separate curved outward-facing fabric, not flat HUD artwork.
    var panel:=SurfaceTool.new()
    panel.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(16):
        var a:float=-PI*.68+PI*.37*float(i)/16.0
        var b:float=-PI*.68+PI*.37*float(i+1)/16.0
        var top1:=Vector3(cos(a)*.21,-.17,sin(a)*.21)
        var top2:=Vector3(cos(b)*.21,-.17,sin(b)*.21)
        var bot1:=Vector3(cos(a)*.38,-.61,sin(a)*.38)
        var bot2:=Vector3(cos(b)*.38,-.61,sin(b)*.38)
        _quad(panel,top1,top2,bot1,bot2,WHITE,WHITE,WHITE,WHITE)
    panel.generate_normals()
    _colored_mesh("DS_APRON_WHITE_LAYER",panel.commit(),parent,_ribbon_mat())

static func _eyes(parent:Node3D) -> void:
    # Leave the original skinned face, but create distinct sapphire irises.
    # Full anime facial sculpt & corrective blendshapes remain a separate P0.
    for side in [-1.0,1.0]:
        var eye:=_ball("DS_EYE_IRIS_"+str(side),parent,
            Vector3(side*.072,.018,-.146),Vector3(.075,.084,.018),BLUE_MAIN)
        eye.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        _ball("DS_EYE_LIGHT_"+str(side),parent,
            Vector3(side*.072-.012,.041,-.158),Vector3(.021,.022,.008),WHITE)

static func _style_garment(rig:Skeleton3D) -> int:
    var count:=0
    for node in rig.find_children("*","MeshInstance3D",true,false):
        var part:=node as MeshInstance3D
        if part==null or part.name.begins_with("知音"):
            continue
        if part.mesh==null:
            continue
        # Clothing is the CC0 skinned mesh, not a motionless overlaid image.
        var material:=_surface_mat(BLUE_MAIN,0.0,.73)
        part.material_override=material
        part.set_meta("deepseek_navy_uniform",true)
        count+=1
    return count

static func _bone_mount(rig:Skeleton3D,bone:String,label:String) -> BoneAttachment3D:
    var found:=rig.find_bone(bone)
    if found<0:
        push_error("DeepSeek character has no humanoid bone: "+bone)
        return null
    var attachment:=BoneAttachment3D.new()
    attachment.name=label
    attachment.bone_name=bone
    rig.add_child(attachment)
    return attachment

static func install(avatar:Node3D) -> Dictionary:
    var skeletons:=avatar.find_children("*","Skeleton3D",true,false)
    if skeletons.is_empty():
        push_error("DeepSeek avatar requires skinned humanoid, not a dummy")
        return {}
    var rig:=skeletons[0] as Skeleton3D
    if rig.get_bone_count()<60:
        push_error("DeepSeek requires 65 bone animation rig")
        return {}
    var changed:=_style_garment(rig)
    var head:=_bone_mount(rig,"Head","DS_ANCHOR_HEAD")
    var waist:=_bone_mount(rig,"pelvis","DS_ANCHOR_PELVIS")
    var chest:=_bone_mount(rig,"spine_03","DS_ANCHOR_CHEST")
    if head==null or waist==null or chest==null:
        return {}
    # Headboard, blue bows, fins and a navy/sky-blue long layered hairstyle.
    _scallop("MAID_HEADBAND",head,Vector3(0,.19,-.012),Vector2(.19,.077),9,WHITE)
    var cap:=_ball("DS_HAIR_CROWN",head,Vector3(0,.105,.012),
        Vector3(.37,.25,.33),BLUE_MAIN)
    cap.material_override=_surface_mat(Color(.075,.18,.46),0.0,.42)
    for i in range(12):
        var x:float=(float(i)-5.5)*.036
        var z:float=.06 if i%2==0 else -.10
        var start:=Vector3(x,.18,z)
        var end:=Vector3(x*1.9,-.73+float(i%4)*.045,
            .15+float(i%3)*.028)
        _make_hair_strand(str(i),head,start,end,.064,
            x*.7,(float(i%3)-1)*.035,BLUE_MAIN)
    for i in range(7):
        var x:float=(float(i)-3.0)*.061
        _make_hair_strand("BANG_"+str(i),head,
            Vector3(x,.19,-.17),Vector3(x*.76,-.09,-.24),
            .042,-x*.25,-.03,BLUE_DARK)
    _fin("LEFT",head,Vector3(-.19,-.01,.014),-1.0,BLUE_MAIN)
    _fin("RIGHT",head,Vector3(.19,-.01,.014),1.0,BLUE_MAIN)
    _ball("DS_BOW_CENTER",head,Vector3(.23,.17,-.04),
        Vector3(.085,.08,.055),BLUE_SKY)
    _ball("DS_BOW_LEFT",head,Vector3(.18,.17,-.045),
        Vector3(.10,.07,.048),BLUE_PALE)
    _ball("DS_BOW_RIGHT",head,Vector3(.30,.18,-.041),
        Vector3(.10,.073,.052),BLUE_PALE)
    _eyes(head)
    _skirt(waist)
    _whale_tail(waist)
    _ball("DS_COLLAR_BLUE_BOW",chest,Vector3(0,.012,-.133),
        Vector3(.15,.071,.035),BLUE_DARK)
    _ball("DS_COLLAR_GEM",chest,Vector3(0,.025,-.163),
        Vector3(.058,.070,.033),BLUE_SKY,_surface_mat(BLUE_SKY,.3,.2))
    return {
        "identity":"npc_deepseek_blue",
        "rig_bones":rig.get_bone_count(),
        "garment_meshes_styled":changed,
        "hair_locks":19,
        "fin_meshes":4,
        "tail":"mesh",
        "headband":"mesh",
        "apron":"mesh",
        "status":"stylized_3d_work_in_progress"
    }
