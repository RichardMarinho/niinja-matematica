extends SceneTree
## Rebuild the native loading image from the approved logo in this repository.
## Run: godot --headless --path . --script res://tools/build_boot_splash.gd

const LOGO_PATH = "res://assets/ui/esmague-os-documeros-logo.png"
const SPLASH_PATH = "res://assets/ui/esmague-os-documeros-splash.png"
const CANVAS_SIZE = Vector2i(1920, 1080)
const LOGO_LIMIT = Vector2i(1000, 500)
const BACKGROUND = Color8(8, 16, 28)


func _initialize() -> void:
	var logo := Image.load_from_file(LOGO_PATH)
	if logo == null or logo.is_empty():
		push_error("Não foi possível abrir a logo aprovada: " + LOGO_PATH)
		quit(1)
		return
	logo.convert(Image.FORMAT_RGBA8)
	# Ignore almost invisible pixels around the artwork when sizing the logo.
	# The original PNG is never changed. A small margin retains edge smoothing.
	var top_left := Vector2i(logo.get_width(), logo.get_height())
	var bottom_right := Vector2i(-1, -1)
	for y in range(logo.get_height()):
		for x in range(logo.get_width()):
			if logo.get_pixel(x, y).a >= 0.05:
				top_left = top_left.min(Vector2i(x, y))
				bottom_right = bottom_right.max(Vector2i(x, y))
	if bottom_right.x < 0:
		push_error("A logo não contém arte visível.")
		quit(1)
		return
	var bounds := Rect2i(top_left, bottom_right - top_left + Vector2i.ONE)
	bounds = bounds.grow(4).intersection(Rect2i(Vector2i.ZERO, logo.get_size()))
	var artwork := logo.get_region(bounds)
	var ratio := minf(1.0, minf(float(LOGO_LIMIT.x) / bounds.size.x, float(LOGO_LIMIT.y) / bounds.size.y))
	var size := Vector2i(maxi(1, roundi(bounds.size.x * ratio)), maxi(1, roundi(bounds.size.y * ratio)))
	artwork.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	var splash := Image.create(CANVAS_SIZE.x, CANVAS_SIZE.y, false, Image.FORMAT_RGBA8)
	splash.fill(BACKGROUND)
	splash.blend_rect(artwork, Rect2i(Vector2i.ZERO, size), (CANVAS_SIZE - size) / 2)
	var result := splash.save_png(SPLASH_PATH)
	if result != OK:
		push_error("Não foi possível salvar a abertura: " + error_string(result))
		quit(1)
		return
	print("Abertura nativa gerada: ", SPLASH_PATH, " | logo ", size, " | fundo #08101c")
	quit()
