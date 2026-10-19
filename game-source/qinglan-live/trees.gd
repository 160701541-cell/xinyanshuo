extends RefCounted
# 树木生成器：每棵树都要有可辨识的剪影

var vb

func pine(h: int, leaf: Color, trunk_col := Color(0.26, 0.18, 0.12)) -> void:
	# 塔松：主干 + 4 层锥形枝盘，层间留缝
	vb.box(-1, 0, -1, 1, h * 0.42, 1, trunk_col)
	# 锥形树冠：一层层收缩并互相叠压，避免出现台阶感
	var layers := int(h * 0.62)
	for i in layers:
		var t := float(i) / float(layers)
		var y := int(h * 0.36) + i
		var r := int(round(lerp(6.5, 0.9, pow(t, 0.85))))
		if r < 1:
			r = 1
		var c := leaf.lerp(Color(0.09, 0.16, 0.09), t * 0.45)
		vb.box(-r, y, -r, r + 1, y + 1, r + 1, c, 0.05)

func cypress(h: int, leaf: Color) -> void:
	# 侧柏：细高柱状，几乎不分枝
	vb.box(-1, 0, -1, 1, h * 0.25, 1, Color(0.24, 0.17, 0.11))
	vb.box(-2, h * 0.2, -2, 3, h, 3, leaf, 0.07)
	vb.box(-1, h, -1, 2, h + 2, 2, leaf.lightened(0.10), 0.05)

func broadleaf(h: int, leaf: Color) -> void:
	# 阔叶：粗干 → 三根分叉 → 六团树冠
	vb.box(-2, 0, -2, 2, h * 0.45, 2, Color(0.28, 0.20, 0.13))
	var top := int(h * 0.45)
	vb.box(-1, top, -3, 1, top + 5, -1, Color(0.28, 0.20, 0.13))
	vb.box(-1, top, 3, 1, top + 4, 5, Color(0.28, 0.20, 0.13))
	vb.box(3, top, -1, 5, top + 4, 1, Color(0.28, 0.20, 0.13))
	var cy := top + 7
	var blobs := [
		[0, 0, 0, 5.2], [-6, -2, 1, 3.6], [6, -1, -1, 3.8],
		[1, 3, 4, 3.2], [-2, 2, -5, 3.4], [3, 5, 1, 2.8],
	]
	for b in blobs:
		vb.sphere(int(b[0]), cy + int(b[1]), int(b[2]), float(b[3]), leaf, 0.09)

func willow(h: int, leaf: Color) -> void:
	# 垂柳：圆冠 + 下垂枝条
	vb.box(-1, 0, -1, 1, h * 0.55, 1, Color(0.30, 0.22, 0.14))
	vb.sphere(0, int(h * 0.62), 0, h * 0.26, leaf, 0.08)
	var r := int(h * 0.30)
	var cy2 := int(h * 0.72)
	for a in 18:
		var ang := TAU * float(a) / 18.0
		var rr := float(r) * (1.0 + 0.18 * float(a % 3))
		var x := int(round(cos(ang) * rr))
		var z := int(round(sin(ang) * rr))
		var drop := 9 + (a % 4) * 3
		for k in drop:
			vb.put(x, cy2 - k, z, leaf.lightened(0.10 - 0.015 * float(k)))

func bamboo(h: int, leaf: Color) -> void:
	# 竹丛：几根细杆 + 节 + 顶部叶簇
	for i in 7:
		var ox := -4 + (i % 4) * 3
		var oz := -3 + int(i / 4) * 4
		var hh := h - (i % 3) * 2
		vb.box(ox, 0, oz, ox + 1, hh, oz + 1, Color(0.56, 0.66, 0.32), 0.03)
		for y in range(3, hh, 5):
			vb.box(ox, y, oz, ox + 1, y + 1, oz + 1, Color(0.40, 0.50, 0.24))
		vb.sphere(ox, hh, oz, 2.2, leaf, 0.12)
		vb.sphere(ox - 1, hh - 3, oz + 1, 1.4, leaf.darkened(0.05), 0.12)

func peach(h: int, leaf: Color) -> void:
	# 桃/樱：低矮、冠幅宽、粉色
	vb.box(-1, 0, -1, 1, h * 0.35, 1, Color(0.33, 0.22, 0.16))
	var cy := int(h * 0.42)
	vb.sphere(0, cy + 2, 0, h * 0.30, leaf, 0.10)
	vb.sphere(-4, cy, 2, h * 0.18, leaf.lightened(0.05), 0.10)
	vb.sphere(4, cy + 1, -2, h * 0.18, leaf.darkened(0.05), 0.10)

func dead(h: int) -> void:
	# 枯木：无叶，分叉明显
	var trunk := Color(0.34, 0.27, 0.21)
	var top := int(h * 0.55)
	vb.box(-1, 0, -1, 1, top, 1, trunk)
	# 四根主枝，末端再分叉
	vb.box(-5, top - 2, 0, -1, top, 1, trunk)
	vb.box(-7, top + 1, 0, -5, top + 3, 1, trunk)
	vb.box(1, top - 3, 0, 5, top - 1, 1, trunk)
	vb.box(5, top, 0, 7, top + 2, 1, trunk)
	vb.box(0, top - 1, 1, 1, top + 1, 5, trunk)
	vb.box(0, top + 2, 5, 1, top + 4, 7, trunk)
	vb.box(0, top, -1, 1, top + 5, 1, trunk)

# 四阶段生长：0 苗 1 幼 2 成 3 参天（形态不同，不只是放大）
func broadleaf_stage(stage: int, leaf: Color) -> void:
	match stage:
		0:  # 幼苗：一根细茎 + 两片子叶
			vb.box(0, 0, 0, 1, 3, 1, Color(0.34, 0.26, 0.16))
			vb.box(-2, 3, 0, 0, 4, 1, leaf.lightened(0.10))
			vb.box(1, 3, 0, 3, 4, 1, leaf.lightened(0.10))
		1:  # 幼树：单干 + 三枝 + 小冠
			vb.box(0, 0, 0, 2, 7, 2, Color(0.32, 0.24, 0.15))
			vb.box(-3, 6, 0, 0, 7, 1, Color(0.32, 0.24, 0.15))
			vb.box(2, 8, 0, 5, 9, 1, Color(0.32, 0.24, 0.15))
			vb.sphere(0, 10, 0, 3.0, leaf, 0.10)
			vb.sphere(3, 9, 1, 2.0, leaf.darkened(0.05), 0.10)
		2:  # 成树：粗干分叉 + 六团冠
			vb.box(-1, 0, -1, 2, 9, 2, Color(0.30, 0.22, 0.14))
			vb.box(-4, 8, 0, 0, 10, 1, Color(0.30, 0.22, 0.14))
			vb.box(2, 9, 0, 6, 11, 1, Color(0.30, 0.22, 0.14))
			vb.box(0, 9, 2, 1, 11, 5, Color(0.30, 0.22, 0.14))
			for b in [[0,14,0,4.6],[-5,13,1,3.2],[5,13,-1,3.4],[1,16,3,2.8],[-2,15,-4,3.0]]:
				vb.sphere(int(b[0]), int(b[1]), int(b[2]), float(b[3]), leaf, 0.09)
		3:  # 参天：主干两人粗、多级分叉、垂枝与花果
			vb.box(-2, 0, -2, 3, 16, 3, Color(0.28, 0.20, 0.13))
			vb.box(-2, 16, -2, 3, 26, 3, Color(0.30, 0.22, 0.14))
			vb.box(-8, 18, -1, -2, 20, 1, Color(0.28, 0.20, 0.13))
			vb.box(3, 20, -1, 9, 22, 1, Color(0.28, 0.20, 0.13))
			vb.box(-1, 19, 3, 2, 21, 8, Color(0.28, 0.20, 0.13))
			vb.box(-1, 21, -8, 2, 23, -3, Color(0.28, 0.20, 0.13))
			for b in [[0,30,0,7.0],[-8,27,2,4.6],[8,28,-2,4.8],[2,32,6,4.0],[-3,31,-7,4.2],[0,24,0,6.2]]:
				vb.sphere(int(b[0]), int(b[1]), int(b[2]), float(b[3]), leaf, 0.08)
			for i in 8:  # 垂下的枝条
				var ang := TAU * float(i) / 8.0
				var x := int(round(cos(ang) * 7.0))
				var z := int(round(sin(ang) * 7.0))
				vb.box(x, 22, z, x + 1, 27, z + 1, leaf.darkened(0.10), 0.06)
			for i in 5:  # 花/果
				vb.box_e(-4 + i * 2, 26 + (i % 3) * 2, 4, -3 + i * 2, 27 + (i % 3) * 2, 5, Color(0.96, 0.72, 0.78))
