extends RefCounted
## Deterministic, seamless, procedural HD2D stone paving for public Godot.
## Native 256px texture; no collage, external CDN or downloaded model required.
const SIZE: int = 256
const BRICK_W: int = 64
const BRICK_H: int = 32
const JOINT: int = 3
const MORTAR := Color8(76, 74, 66)

static func make_image() -> Image:
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in range(SIZE):
		for x in range(SIZE):
			image.set_pixel(x, y, pixel_color(x, y))
	return image

static func make_texture() -> Texture2D:
	return ImageTexture.create_from_image(make_image())

static func pixel_color(x: int, y: int) -> Color:
	# Side edges are mortar, so adjacent instances connect exactly.
	if x < JOINT or x >= SIZE - JOINT or y < JOINT or y >= SIZE - JOINT:
		return MORTAR
	var row: int = y / BRICK_H
	var stagger: int = (row % 2) * (BRICK_W / 2)
	var local_x: int = posmod(x + stagger, BRICK_W)
	var local_y: int = y % BRICK_H
	if local_x < JOINT or BRICK_W - local_x <= JOINT or local_y < JOINT:
		return MORTAR
	var brick_index: int = posmod((x + stagger) / BRICK_W, SIZE / BRICK_W)
	var h: int = posmod(brick_index * 19 + row * 37 + 41, 37)
	var grain: int = posmod(x * 7 + y * 13 + (x * y) / 11, 13) - 6
	var light: int = 127 + h + grain
	if local_y < JOINT + 2:
		light += 13
	elif local_y > BRICK_H - JOINT - 3:
		light -= 10
	return Color8(clampi(light + 16, 0, 255), clampi(light + 9, 0, 255), clampi(light - 6, 0, 255))

static func edges_match(image: Image) -> bool:
	if image.get_width() != SIZE or image.get_height() != SIZE:
		return false
	for x in range(SIZE):
		if image.get_pixel(x, 0) != image.get_pixel(x, SIZE - 1):
			return false
	for y in range(SIZE):
		if image.get_pixel(0, y) != image.get_pixel(SIZE - 1, y):
			return false
	return true
