extends Node2D

const W := 720.0
const H := 1280.0
const LANES := [210.0, 360.0, 510.0]
const PLAYER_Y := 1000.0
const CYAN := Color("54f4ff")
const PINK := Color("ff4bd8")
const GOLD := Color("ffd45c")

var rng := RandomNumberGenerator.new()
var state := "menu"
var lane := 1
var player_x := 360.0
var obstacles: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var score := 0.0
var best := 0
var shards := 0
var speed := 470.0
var spawn_timer := 0.0
var pickup_timer := 1.0
var hit_flash := 0.0
var shield_time := 0.0
var magnet_time := 0.0
var dash_time := 0.0
var elapsed := 0.0
var touch_start := Vector2.ZERO
var ui_layer: CanvasLayer
var score_label: Label
var best_label: Label
var shard_label: Label
var message_label: Label
var start_button: Button
var left_button: Button
var right_button: Button
var dash_button: Button
var pause_button: Button
var paused := false

func _ready() -> void:
	rng.randomize()
	_load_best()
	_build_ui()
	_show_menu()
	queue_redraw()

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(root)

	score_label = _label("0", 42, Color.WHITE)
	score_label.position = Vector2(28, 28)
	score_label.size = Vector2(250, 58)
	root.add_child(score_label)
	best_label = _label("BEST 0", 20, Color("a8a2d8"))
	best_label.position = Vector2(30, 88)
	best_label.size = Vector2(230, 32)
	root.add_child(best_label)
	shard_label = _label("✦ 0", 25, GOLD)
	shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shard_label.position = Vector2(500, 35)
	shard_label.size = Vector2(185, 45)
	root.add_child(shard_label)

	message_label = _label("", 26, Color.WHITE)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.position = Vector2(55, 350)
	message_label.size = Vector2(610, 300)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(message_label)

	start_button = _button("PLAY", Vector2(205, 760), Vector2(310, 88), Color("ffcf4a"))
	root.add_child(start_button)
	start_button.pressed.connect(_on_start_pressed)

	left_button = _button("◀", Vector2(55, 1090), Vector2(145, 105), Color("26336f"))
	right_button = _button("▶", Vector2(520, 1090), Vector2(145, 105), Color("26336f"))
	dash_button = _button("⚡", Vector2(290, 1095), Vector2(140, 95), Color("6931a8"))
	root.add_child(left_button)
	root.add_child(right_button)
	root.add_child(dash_button)
	left_button.pressed.connect(func(): _change_lane(-1))
	right_button.pressed.connect(func(): _change_lane(1))
	dash_button.pressed.connect(_use_dash)

	pause_button = _button("Ⅱ", Vector2(620, 112), Vector2(62, 62), Color("26336f"))
	root.add_child(pause_button)
	pause_button.pressed.connect(_toggle_pause)
	_update_ui()

func _label(value: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 3)
	return l

func _button(value: String, pos: Vector2, size: Vector2, color: Color) -> Button:
	var b := Button.new()
	b.text = value
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", 34)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _button_style(color, 22))
	b.add_theme_stylebox_override("hover", _button_style(color.lightened(0.18), 22))
	b.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.2), 22))
	return b

func _button_style(color: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = color.lightened(0.35)
	return s

func _on_start_pressed() -> void:
	if paused and state == "playing":
		paused = false
		message_label.text = ""
		start_button.hide()
		_set_game_controls(true)
		pause_button.text = "Ⅱ"
	else:
		_start_game()

func _show_menu() -> void:
	state = "menu"
	message_label.text = "NOVA RUSH\n\nDODGE • COLLECT • SURVIVE\n\nMove between lanes. Grab energy shards.\nHow long can you survive?"
	start_button.text = "PLAY"
	start_button.show()
	_set_game_controls(false)
	pause_button.hide()
	_update_ui()

func _start_game() -> void:
	state = "playing"
	paused = false
	lane = 1
	player_x = LANES[lane]
	obstacles.clear()
	pickups.clear()
	particles.clear()
	score = 0.0
	shards = 0
	speed = 470.0
	spawn_timer = 0.8
	pickup_timer = 1.1
	shield_time = 0.0
	magnet_time = 0.0
	dash_time = 0.0
	elapsed = 0.0
	hit_flash = 0.0
	message_label.text = ""
	start_button.hide()
	_set_game_controls(true)
	pause_button.show()
	_update_ui()

func _set_game_controls(active: bool) -> void:
	left_button.visible = active
	right_button.visible = active
	dash_button.visible = active

func _process(delta: float) -> void:
	if state != "playing" or paused:
		return
	elapsed += delta
	score += delta * (speed / 90.0)
	speed = minf(470.0 + elapsed * 12.0, 1050.0)
	player_x = lerpf(player_x, LANES[lane], minf(1.0, delta * 14.0))
	spawn_timer -= delta
	pickup_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_obstacle()
		spawn_timer = maxf(0.43, 1.05 - elapsed * 0.008) + rng.randf_range(0.0, 0.22)
	if pickup_timer <= 0.0:
		_spawn_pickup()
		pickup_timer = rng.randf_range(0.9, 1.55)
	_update_objects(delta)
	_update_particles(delta)
	shield_time = maxf(0.0, shield_time - delta)
	magnet_time = maxf(0.0, magnet_time - delta)
	dash_time = maxf(0.0, dash_time - delta)
	hit_flash = maxf(0.0, hit_flash - delta * 2.8)
	_update_ui()
	queue_redraw()

func _spawn_obstacle() -> void:
	var lane_id := rng.randi_range(0, 2)
	var kind := "block"
	var roll := rng.randf()
	if roll > 0.78:
		kind = "laser"
	elif roll > 0.58:
		kind = "mine"
	obstacles.append({"lane": lane_id, "y": -100.0, "kind": kind, "phase": rng.randf() * TAU})
	if elapsed > 25.0 and rng.randf() > 0.76:
		var other := (lane_id + rng.randi_range(1, 2)) % 3
		obstacles.append({"lane": other, "y": -230.0, "kind": "block", "phase": 0.0})

func _spawn_pickup() -> void:
	var lane_id := rng.randi_range(0, 2)
	var kind := "shard"
	if rng.randf() > 0.91:
		kind = "shield"
	elif rng.randf() > 0.86:
		kind = "magnet"
	pickups.append({"lane": lane_id, "y": -70.0, "kind": kind, "phase": 0.0})

func _update_objects(delta: float) -> void:
	for i in range(obstacles.size() - 1, -1, -1):
		var o: Dictionary = obstacles[i]
		o.y += speed * delta
		if absf(o.y - PLAYER_Y) < 58.0 and o.lane == lane and dash_time <= 0.0:
			if shield_time > 0.0:
				shield_time = 0.0
				_burst(Vector2(player_x, PLAYER_Y), CYAN, 22)
				obstacles.remove_at(i)
				continue
			_game_over()
			return
		if o.y > H + 100.0:
			obstacles.remove_at(i)
		else:
			obstacles[i] = o
	for i in range(pickups.size() - 1, -1, -1):
		var p: Dictionary = pickups[i]
		p.y += speed * delta
		var attracted := magnet_time > 0.0 and absf(p.y - PLAYER_Y) < 260.0
		if attracted:
			p.lane = lane
		if absf(p.y - PLAYER_Y) < 62.0 and p.lane == lane:
			_match_pickup(p.kind)
			_burst(Vector2(player_x, PLAYER_Y), GOLD if p.kind == "shard" else CYAN, 12)
			pickups.remove_at(i)
		elif p.y > H + 80.0:
			pickups.remove_at(i)
		else:
			pickups[i] = p

func _match_pickup(kind: String) -> void:
	if kind == "shard":
		shards += 1
		score += 75.0
	elif kind == "shield":
		shield_time = 7.0
	elif kind == "magnet":
		magnet_time = 8.0

func _change_lane(direction: int) -> void:
	if state != "playing" or paused:
		return
	lane = clampi(lane + direction, 0, 2)
	_burst(Vector2(player_x, PLAYER_Y + 25), PINK, 5)

func _use_dash() -> void:
	if state != "playing" or paused or dash_time > 0.0:
		return
	dash_time = 0.72
	_burst(Vector2(player_x, PLAYER_Y), Color.WHITE, 28)

func _toggle_pause() -> void:
	if state != "playing":
		return
	paused = not paused
	message_label.text = "PAUSED\n\nTap RESUME when you're ready" if paused else ""
	start_button.text = "RESUME"
	start_button.visible = paused
	_set_game_controls(not paused)
	pause_button.text = "▶" if paused else "Ⅱ"

func _game_over() -> void:
	state = "over"
	var final_score := int(score)
	if final_score > best:
		best = final_score
		_save_best()
	message_label.text = "RUN OVER\n\nSCORE  %d\nBEST  %d\n✦  %d SHARDS\n\nTry again. Your next run could be legendary." % [final_score, best, shards]
	start_button.text = "RUN AGAIN"
	start_button.show()
	_set_game_controls(false)
	pause_button.hide()
	_burst(Vector2(player_x, PLAYER_Y), PINK, 35)
	_update_ui()

func _burst(pos: Vector2, color: Color, amount: int) -> void:
	for j in range(amount):
		var a := rng.randf_range(0.0, TAU)
		var v := rng.randf_range(70.0, 330.0)
		particles.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * v, "life": rng.randf_range(0.25, 0.75), "max": 0.75, "color": color, "size": rng.randf_range(3.0, 8.0)})

func _update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p.life -= delta
		p.pos += p.vel * delta
		p.vel *= 0.94
		if p.life <= 0.0:
			particles.remove_at(i)
		else:
			particles[i] = p

func _draw() -> void:
	_draw_background()
	_draw_track()
	for p in pickups:
		_draw_pickup(p)
	for o in obstacles:
		_draw_obstacle(o)
	if state == "playing":
		_draw_player()
	for p in particles:
		var alpha: float = clampf(p.life / p.max, 0.0, 1.0)
		draw_circle(p.pos, p.size * alpha, Color(p.color, alpha))
	if hit_flash > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(1.0, 0.1, 0.35, hit_flash * 0.22), true)

func _draw_background() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("08051e"), true)
	for i in range(18):
		var x := float((i * 137 + 41) % 720)
		var y := float((i * 211 + int(elapsed * 30.0)) % 1280)
		draw_circle(Vector2(x, y), 1.5 if i % 3 else 2.5, Color(0.55, 0.48, 1.0, 0.28))
	for i in range(5):
		var y := float(i * 300 + 100)
		draw_line(Vector2(0, y), Vector2(W, y), Color(0.25, 0.16, 0.55, 0.13), 2.0)
	# distant glowing horizon
	draw_circle(Vector2(360, 300), 190, Color(0.22, 0.08, 0.48, 0.08))
	draw_circle(Vector2(360, 300), 115, Color(0.35, 0.1, 0.6, 0.08))

func _draw_track() -> void:
	draw_polygon(PackedVector2Array([Vector2(95, 0), Vector2(625, 0), Vector2(680, H), Vector2(40, H)]), PackedColorArray([Color("17113b"), Color("17113b"), Color("100d2d"), Color("100d2d")]))
	for x in [285.0, 435.0]:
		draw_line(Vector2(x, 0), Vector2(x, H), Color(0.3, 0.25, 0.7, 0.25), 3.0)
	for i in range(13):
		var y := fposmod(float(i * 125) + elapsed * speed * 0.55, H + 125.0) - 125.0
		draw_line(Vector2(100, y), Vector2(620, y), Color(0.42, 0.3, 0.9, 0.09), 2.0)
	for x in [105.0, 615.0]:
		draw_line(Vector2(x, 0), Vector2(x, H), Color(0.15, 0.82, 1.0, 0.55), 4.0)

func _draw_player() -> void:
	var pos := Vector2(player_x, PLAYER_Y)
	var glow := CYAN if shield_time > 0.0 else PINK
	if dash_time > 0.0:
		glow = Color.WHITE
	for r in [48.0, 35.0]:
		draw_circle(pos, r, Color(glow, 0.06 if r == 48.0 else 0.1))
	draw_circle(pos, 27, Color("f4f1ff"))
	draw_circle(pos + Vector2(0, -5), 21, Color("24204e"))
	draw_rect(Rect2(pos.x - 24, pos.y + 4, 48, 13), glow, true)
	draw_circle(pos + Vector2(-8, -6), 3.5, CYAN)
	draw_circle(pos + Vector2(8, -6), 3.5, CYAN)
	draw_line(pos + Vector2(-13, 25), pos + Vector2(-21, 42), glow, 5.0)
	draw_line(pos + Vector2(13, 25), pos + Vector2(21, 42), glow, 5.0)
	if shield_time > 0.0:
		draw_arc(pos, 44, 0, TAU, 48, CYAN, 3.0)
	if dash_time > 0.0:
		for j in range(4):
			draw_line(pos + Vector2(-12, 28 + j * 13), pos + Vector2(12, 28 + j * 13), Color(1, 1, 1, 0.55 - j * 0.1), 4.0)

func _draw_obstacle(o: Dictionary) -> void:
	var pos := Vector2(LANES[o.lane], o.y)
	var kind: String = o.kind
	if kind == "block":
		draw_rect(Rect2(pos.x - 43, pos.y - 38, 86, 76), Color(0.95, 0.12, 0.42, 0.16), true)
		draw_rect(Rect2(pos.x - 35, pos.y - 31, 70, 62), Color("b52267"), true)
		draw_rect(Rect2(pos.x - 35, pos.y - 31, 70, 8), PINK, true)
		draw_line(pos + Vector2(-20, -12), pos + Vector2(20, 12), Color("ff9be8"), 5.0)
		draw_line(pos + Vector2(20, -12), pos + Vector2(-20, 12), Color("ff9be8"), 5.0)
	elif kind == "laser":
		draw_rect(Rect2(pos.x - 54, pos.y - 12, 108, 24), Color(1, 0.15, 0.35, 0.2), true)
		draw_line(pos + Vector2(-52, 0), pos + Vector2(52, 0), Color("ff436f"), 9.0)
		draw_circle(pos + Vector2(-52, 0), 12, PINK)
		draw_circle(pos + Vector2(52, 0), 12, PINK)
	else:
		draw_circle(pos, 40, Color(1, 0.2, 0.35, 0.16))
		draw_circle(pos, 29, Color("7e1c64"))
		draw_circle(pos, 9, GOLD)
		draw_arc(pos, 33, 0, TAU, 32, PINK, 4.0)

func _draw_pickup(p: Dictionary) -> void:
	var pos := Vector2(LANES[p.lane], p.y)
	if p.kind == "shard":
		draw_circle(pos, 25, Color(1.0, 0.78, 0.2, 0.12))
		draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -23), pos + Vector2(18, 0), pos + Vector2(0, 23), pos + Vector2(-18, 0)]), GOLD)
		draw_line(pos + Vector2(0, -13), pos + Vector2(0, 13), Color.WHITE, 3.0)
	elif p.kind == "shield":
		draw_circle(pos, 26, Color(0.2, 0.9, 1.0, 0.13))
		draw_arc(pos, 21, 0, TAU, 32, CYAN, 6.0)
		draw_line(pos + Vector2(0, -12), pos + Vector2(0, 12), Color.WHITE, 4.0)
	else:
		draw_circle(pos, 25, Color(0.8, 0.3, 1.0, 0.15))
		draw_arc(pos, 21, 0, TAU, 32, Color("c78bff"), 6.0)
		draw_line(pos + Vector2(-10, 0), pos + Vector2(10, 0), Color.WHITE, 4.0)

func _update_ui() -> void:
	if not is_instance_valid(score_label):
		return
	score_label.text = str(int(score)) if state == "playing" else "NOVA RUSH"
	best_label.text = "BEST  %d" % best
	shard_label.text = "✦  %d" % shards

func _load_best() -> void:
	if FileAccess.file_exists("user://nova_best.save"):
		var f := FileAccess.open("user://nova_best.save", FileAccess.READ)
		if f:
			best = int(f.get_as_text())

func _save_best() -> void:
	var f := FileAccess.open("user://nova_best.save", FileAccess.WRITE)
	if f:
		f.store_string(str(best))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_change_lane(-1)
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_change_lane(1)
		elif event.keycode == KEY_SPACE:
			if state == "menu" or state == "over":
				_start_game()
			else:
				_use_dash()
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
		else:
			var delta_x := event.position.x - touch_start.x
			if absf(delta_x) > 45.0:
				_change_lane(1 if delta_x > 0 else -1)
	elif event is InputEventScreenDrag:
		var dx := event.position.x - touch_start.x
		if absf(dx) > 95.0:
			_change_lane(1 if dx > 0 else -1)
			touch_start = event.position
