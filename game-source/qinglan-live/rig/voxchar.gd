extends RefCounted
# 超高密度体素角色：1cm 一炷，网格采样 → 只保留外露面 → 单 mesh（顶点色烘焙方向光）
# 坐标：脚底 y=0，面朝 -Z

const V := 0.01
const OX := -0.50
const OY := 0.0
const OZ := -0.36
const W := 100
const H := 200
const D := 72

# 高饱和色板
const PAL := [
	Color(0, 0, 0),            # 0 空
	Color("#0B3B4E"),          # 1 深袍
	Color("#14707F"),          # 2 正袍
	Color("#35B7C2"),          # 3 亮袍
	Color("#F4FAF8"),          # 4 白内衫
	Color("#FFC13B"),          # 5 金
	Color("#D12F3C"),          # 6 朱红
	Color("#FFC9A0"),          # 7 肤色
	Color("#100E1A"),          # 8 发
	Color("#D3E6F5"),          # 9 剑钢
	Color("#161B26"),          # 10 靴
	Color("#3FE3B2"),          # 11 玉
	Color("#07080C"),          # 12 瞳
	Color("#8C1F2C"),          # 13 唇
	Color("#0B2A38"),          # 14 暗影袍
]

var grid := PackedInt32Array()

func _init() -> void:
	grid.resize(W * H * D)
	grid.fill(0)
	_build_parts()
	print("voxels: ", filled_count())

func idx(x: int, y: int, z: int) -> int:
	return (y * D + z) * W + x

func put(x: int, y: int, z: int, c: int) -> void:
	if x < 0 or x >= W or y < 0 or y >= H or z < 0 or z >= D:
		return
	grid[idx(x, y, z)] = c

func wx(x: int) -> float: return OX + (float(x) + 0.5) * V
func wy(y: int) -> float: return OY + (float(y) + 0.5) * V
func wz(z: int) -> float: return OZ + (float(z) + 0.5) * V
func gx(p: float) -> int: return int(round((p - OX) / V - 0.5))
func gy(p: float) -> int: return int(round((p - OY) / V - 0.5))
func gz(p: float) -> int: return int(round((p - OZ) / V - 0.5))

func filled_count() -> int:
	var n := 0
	for i in grid.size():
		if grid[i] > 0:
			n += 1
	return n

# ── 基础体块 ─────────────────────────────────────────────
func box(cx: float, cy: float, cz: float, hx: float, hy: float, hz: float, c: int) -> void:
	for y in range(gy(cy - hy), gy(cy + hy) + 1):
		for z in range(gz(cz - hz), gz(cz + hz) + 1):
			for x in range(gx(cx - hx), gx(cx + hx) + 1):
				if absf(wx(x) - cx) <= hx and absf(wy(y) - cy) <= hy and absf(wz(z) - cz) <= hz:
					put(x, y, z, c)

func ellip(cx: float, cy: float, cz: float, rx: float, ry: float, rz: float, c: int) -> void:
	for y in range(gy(cy - ry), gy(cy + ry) + 1):
		var ty := (wy(y) - cy) / ry
		if absf(ty) > 1.0: continue
		for z in range(gz(cz - rz), gz(cz + rz) + 1):
			var tz := (wz(z) - cz) / rz
			if absf(tz) > 1.0: continue
			var s := 1.0 - ty * ty - tz * tz
			if s < 0.0: continue
			var xr := rx * sqrt(s)
			for x in range(gx(cx - xr), gx(cx + xr) + 1):
				if absf(wx(x) - cx) <= xr:
					put(x, y, z, c)

func caps(a: Vector3, b: Vector3, r: float, c: int) -> void:
	var lo := Vector3(minf(a.x, b.x) - r, minf(a.y, b.y) - r, minf(a.z, b.z) - r)
	var hi := Vector3(maxf(a.x, b.x) + r, maxf(a.y, b.y) + r, maxf(a.z, b.z) + r)
	var ab := b - a
	var l2 := ab.length_squared()
	for y in range(gy(lo.y), gy(hi.y) + 1):
		for z in range(gz(lo.z), gz(hi.z) + 1):
			for x in range(gx(lo.x), gx(hi.x) + 1):
				var p := Vector3(wx(x), wy(y), wz(z))
				var t := 0.0
				if l2 > 0.000001:
					t = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
				if p.distance_to(a + ab * t) <= r:
					put(x, y, z, c)

# 圆台（裙摆/腰身）：radius 随 y 线性插值
func cone(y0: float, y1: float, r0: float, r1: float, squash_z: float, c: int) -> void:
	for y in range(gy(y0), gy(y1) + 1):
		var t := clampf((wy(y) - y0) / maxf(y1 - y0, 0.0001), 0.0, 1.0)
		var r := lerpf(r0, r1, t)
		if r <= 0.0: continue
		for z in range(gz(-r * squash_z), gz(r * squash_z) + 1):
			for x in range(gx(-r), gx(r) + 1):
				var dx := wx(x); var dz := wz(z) / maxf(squash_z, 0.0001)
				if dx * dx + dz * dz <= r * r:
					put(x, y, z, c)

func paint_front(x0: float, x1: float, y0: float, y1: float, c: int, only_skin := true) -> void:
	for y in range(gy(y0), gy(y1) + 1):
		for x in range(gx(x0), gx(x1) + 1):
			for z in range(D):
				var i := idx(x, y, z)
				if grid[i] > 0:
					if (not only_skin) or grid[i] == 7:
						grid[i] = c
					break

func paint_vox(x: int, y: int, c: int, only_skin := true) -> void:
	if x < 0 or x >= W or y < 0 or y >= H: return
	for z in range(D):
		var i := idx(x, y, z)
		if grid[i] > 0:
			if (not only_skin) or grid[i] == 7:
				grid[i] = c
			return

func ring(y0: float, y1: float, r_in: float, r_out: float, squash_z: float, c: int) -> void:
	for y in range(gy(y0), gy(y1) + 1):
		for z in range(gz(-r_out * squash_z), gz(r_out * squash_z) + 1):
			for x in range(gx(-r_out), gx(r_out) + 1):
				var dx := wx(x); var dz := wz(z) / maxf(squash_z, 0.0001)
				var d := dx * dx + dz * dz
				if d <= r_out * r_out and d >= r_in * r_in:
					put(x, y, z, c)

# ── 角色 ─────────────────────────────────────────────────
func _build_parts() -> void:
	# 靴
	for s in [-1.0, 1.0]:
		var bx: float = 0.085 * s
		box(bx, 0.045, -0.03, 0.056, 0.045, 0.105, 10)
		box(bx, 0.075, -0.10, 0.050, 0.030, 0.035, 14)
		box(bx, 0.105, 0.0, 0.058, 0.020, 0.075, 5)      # 靴口金边
	# 小腿 / 大腿
	for s in [-1.0, 1.0]:
		var bx2: float = 0.085 * s
		caps(Vector3(bx2, 0.10, 0.0), Vector3(bx2, 0.50, 0.0), 0.050, 1)
		caps(Vector3(bx2, 0.48, 0.0), Vector3(bx2, 0.90, 0.0), 0.068, 14)
	# 裙摆（三层）
	cone(0.50, 0.72, 0.305, 0.255, 0.80, 4)     # 白裙
	cone(0.50, 0.525, 0.310, 0.306, 0.80, 5)    # 金边
	cone(0.72, 1.00, 0.255, 0.170, 0.80, 2)     # 青袍
	cone(0.715, 0.735, 0.258, 0.252, 0.80, 3)   # 过渡亮边
	# 前襟金色竖条
	for y in range(gy(0.575), gy(0.99)):
		var t := clampf((wy(y) - 0.50) / 0.50, 0.0, 1.0)
		var r := lerpf(0.305, 0.170, t)
		for x in range(gx(-0.011), gx(0.011) + 1):
			for d in 2:
				var z := gz(-r * 0.80) - d
				put(x, y, z, 5)
	# 躯干
	cone(1.00, 1.30, 0.175, 0.200, 0.78, 3)
	cone(1.30, 1.44, 0.200, 0.185, 0.78, 3)
	# 白色内衫 V（前胸）
	for y in range(gy(1.02), gy(1.40)):
		var t := clampf((wy(y) - 1.02) / 0.38, 0.0, 1.0)
		var half := lerpf(0.015, 0.075, t)
		for x in range(gx(-half), gx(half) + 1):
			var z := gz(-0.158) - 1
			put(x, y, z, 4)
	# 领口金边
	ring(1.402, 1.440, 0.112, 0.158, 0.80, 5)
	# 腰带
	ring(0.955, 1.015, 0.150, 0.190, 0.80, 6)
	ellip(0.0, 0.985, -0.155, 0.035, 0.035, 0.030, 11)
	# 宽袖
	for s in [-1.0, 1.0]:
		caps(Vector3(0.185 * s, 1.395, 0.0), Vector3(0.265 * s, 1.02, -0.01), 0.088, 3)
		ring(1.00, 1.035, 0.0, 0.10, 1.0, 5)
	# 袖口处的手
	for s in [-1.0, 1.0]:
		ellip(0.268 * s, 0.975, -0.015, 0.050, 0.055, 0.048, 7)
	# 颈 / 头
	caps(Vector3(0, 1.420, 0), Vector3(0, 1.478, 0), 0.052, 7)
	ellip(0.0, 1.605, 0.0, 0.108, 0.126, 0.108, 7)
	# 头发：从额头以上整个包住，脸露出来
	for y in range(gy(1.44), gy(1.80)):
		for z in range(gz(-0.16), gz(0.16)):
			for x in range(gx(-0.135), gx(0.135)):
				var dx := wx(x) / 0.121
				var dy := (wy(y) - 1.625) / 0.142
				var dz := (wz(z) - 0.014) / 0.124
				if dx * dx + dy * dy + dz * dz <= 1.0:
					var is_face := wz(z) < -0.042 and wy(y) < 1.706
					if not is_face:
						put(x, y, z, 8)
	# 两鬓
	for s0 in [-1.0, 1.0]:
		caps(Vector3(0.100 * s0, 1.700, -0.020), Vector3(0.094 * s0, 1.545, 0.005), 0.024, 8)
	# 马尾
	caps(Vector3(0, 1.735, 0.100), Vector3(0.02, 1.30, 0.155), 0.042, 8)
	# 抹额（额头位置）
	ring(1.694, 1.716, 0.0, 0.112, 1.0, 5)
	ellip(0.0, 1.705, -0.106, 0.019, 0.012, 0.012, 11)
	# 五官：体素坐标贴面绘制（眼 4x3，含眼睑/瞳/高光）
	var fx := gx(0.0)
	var ey: int = gy(1.628)
	for s2 in [-1, 1]:
		var ex: int = fx + s2 * 4
		for dx in range(-2, 2):
			paint_vox(ex + dx, ey + 1, 8, false)            # 上眼睑
			for dy in range(0, -2, -1):
				paint_vox(ex + dx, ey + dy, 4, false)       # 眼白
		for dx in range(-1, 1):
			for dy in range(0, -2, -1):
				paint_vox(ex + dx, ey + dy, 12, false)      # 瞳
		paint_vox(ex - 1, ey, 4, false)                     # 高光
		for dx in range(-2, 2):
			paint_vox(ex + dx, ey + 3, 8, true)             # 眉
	paint_vox(fx - 1, gy(1.548), 13, true)
	paint_vox(fx, gy(1.548), 13, true)
	paint_vox(fx + 1, gy(1.548), 13, true)
	paint_vox(fx, gy(1.672), 6, true)                       # 朱砂
	box(0.0, 1.588, -0.104, 0.008, 0.011, 0.007, 7)         # 鼻
	# 背后剑鞘
	caps(Vector3(0.115, 1.02, 0.135), Vector3(-0.075, 0.56, 0.175), 0.028, 10)
	caps(Vector3(0.115, 1.02, 0.135), Vector3(0.128, 1.10, 0.130), 0.030, 5)

# ── 网格化：只生成外露面 ─────────────────────────────────
func build_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var inds := PackedInt32Array()
	var shade := [0.72, 0.97, 0.93, 0.99, 0.90, 0.91]  # -y +y -z +z -x +x

	var dirs := [Vector3i(0, -1, 0), Vector3i(0, 1, 0), Vector3i(0, 0, -1), Vector3i(0, 0, 1), Vector3i(-1, 0, 0), Vector3i(1, 0, 0)]
	for y in H:
		for z in D:
			var base := (y * D + z) * W
			for x in W:
				var c: int = grid[base + x]
				if c <= 0: continue
				var col: Color = PAL[c]
				var p := Vector3(OX + x * V, OY + y * V, OZ + z * V)
				for d in 6:
					var n: Vector3i = dirs[d]
					var nx := x + n.x
					var ny := y + n.y
					var nz := z + n.z
					if nx >= 0 and nx < W and ny >= 0 and ny < H and nz >= 0 and nz < D:
						if grid[(ny * D + nz) * W + nx] > 0: continue
					var f: Color = col * float(shade[d])
					f.a = 1.0
					var q := _quad(p, n, V)
					var i0 := verts.size()
					for v in 4:
						verts.append(q[v])
						norms.append(Vector3(n))
						cols.append(f)
					inds.append(i0); inds.append(i0 + 1); inds.append(i0 + 2)
					inds.append(i0); inds.append(i0 + 2); inds.append(i0 + 3)

	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = inds
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	print("faces: ", inds.size() / 6)
	return m

func _quad(p: Vector3, n: Vector3i, s: float) -> Array:
	# 以体素角 p 为原点，按法线方向列出 4 个角
	if n == Vector3i(0, 0, -1):
		return [p, p + Vector3(s, 0, 0), p + Vector3(s, s, 0), p + Vector3(0, s, 0)]
	elif n == Vector3i(0, 0, 1):
		return [p + Vector3(0, 0, s), p + Vector3(0, s, s), p + Vector3(s, s, s), p + Vector3(s, 0, s)]
	elif n == Vector3i(-1, 0, 0):
		return [p, p + Vector3(0, s, 0), p + Vector3(0, s, s), p + Vector3(0, 0, s)]
	elif n == Vector3i(1, 0, 0):
		return [p + Vector3(s, 0, 0), p + Vector3(s, 0, s), p + Vector3(s, s, s), p + Vector3(s, s, 0)]
	elif n == Vector3i(0, 1, 0):
		return [p + Vector3(0, s, 0), p + Vector3(s, s, 0), p + Vector3(s, s, s), p + Vector3(0, s, s)]
	else:
		return [p, p + Vector3(0, 0, s), p + Vector3(s, 0, s), p + Vector3(s, 0, 0)]

static func make_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
