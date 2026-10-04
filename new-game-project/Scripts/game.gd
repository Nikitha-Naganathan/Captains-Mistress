extends Control

const ROWS = 6
const COLS = 7

const CELL_SIZE = 80
const BOARD_OFFSET = Vector2(360, 135)
const DISC_RADIUS = 30
const CONFETTI_COUNT = 80
const CONFETTI_DURATION = 3.0
const CONFETTI_GRAVITY = 500.0

var board = []

var current_player = 1
var game_over = false

var turn_label: Label
var turn_tween: Tween
var win_label: Label
var reset_button: Button
var confetti = []
var win_tween: Tween
var confetti_time = 0.0
var is_animating = false
var falling_disc_position = Vector2.ZERO
var falling_disc_player = 0
var falling_disc_target = Vector2.ZERO
var falling_disc_tween: Tween
var start_screen: Control
var start_button: Button
var game_started = false

var drop_sound: AudioStreamPlayer
var win_sound: AudioStreamPlayer
var draw_sound: AudioStreamPlayer
var click_sound: AudioStreamPlayer

func _ready():
	initialize_board()
	create_turn_label()
	create_win_ui()
	create_sound_players()
	create_start_screen()
	turn_label.visible = false

func initialize_board():
	board.clear()

	for row in range(ROWS):
		board.append([])

		for col in range(COLS):
			board[row].append(0)


func find_empty_row(column):
	for row in range(ROWS - 1, -1, -1):
		if board[row][column] == 0:
			return row

	return -1


func drop_disc(column):
	if not game_started or game_over or is_animating:
		return

	if column < 0 or column >= COLS:
		return

	var row = find_empty_row(column)

	if row == -1:
		print("Column is full!")
		return

	is_animating = true
	falling_disc_player = current_player

	falling_disc_position = Vector2(
		BOARD_OFFSET.x + column * CELL_SIZE + CELL_SIZE / 2,
		BOARD_OFFSET.y - DISC_RADIUS
	)

	falling_disc_target = Vector2(
		BOARD_OFFSET.x + column * CELL_SIZE + CELL_SIZE / 2,
		BOARD_OFFSET.y + row * CELL_SIZE + CELL_SIZE / 2
	)

	falling_disc_tween = create_tween()

	falling_disc_tween.tween_property(
		self,
		"falling_disc_position",
		falling_disc_target,
		0.8
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	falling_disc_tween.tween_callback(
		finish_disc_drop.bind(row, column)
	)

func finish_disc_drop(row, column):
	board[row][column] = falling_disc_player
	drop_sound.play()
	is_animating = false
	falling_disc_player = 0

	queue_redraw()

	if check_win(row, column):
		game_over = true
		win_sound.play()
		show_win_screen()
		create_confetti()
		return

	if check_draw():
		game_over = true
		draw_sound.play()
		show_draw_screen()
		return

	switch_player()
	play_turn_animation()

func check_win(row, col):
	if count_direction(row, col, 0, 1) >= 4:
		return true

	if count_direction(row, col, 1, 0) >= 4:
		return true

	if count_direction(row, col, 1, 1) >= 4:
		return true

	if count_direction(row, col, 1, -1) >= 4:
		return true

	return false

func check_draw():
	for row in range(ROWS):
		for col in range(COLS):
			if board[row][col] == 0:
				return false
	return true

func count_direction(row, col, row_change, col_change):
	var player = board[row][col]
	var count = 1

	var current_row = row + row_change
	var current_col = col + col_change

	while is_valid_position(current_row, current_col):
		if board[current_row][current_col] != player:
			break

		count += 1

		current_row += row_change
		current_col += col_change

	current_row = row - row_change
	current_col = col - col_change

	while is_valid_position(current_row, current_col):
		if board[current_row][current_col] != player:
			break

		count += 1

		current_row -= row_change
		current_col -= col_change

	return count


func is_valid_position(row, col):
	return row >= 0 and row < ROWS and col >= 0 and col < COLS


func switch_player():
	if current_player == 1:
		current_player = 2
	else:
		current_player = 1

	print("Player ", current_player, "'s turn")

	play_turn_animation()


func create_turn_label():
	turn_label = Label.new()

	turn_label.name = "TurnLabel"
	turn_label.text = "PLAYER 1'S TURN"
	turn_label.size = Vector2(320, 60)

	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	turn_label.add_theme_font_size_override("font_size", 32)

	turn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turn_label.z_index = 10

	add_child(turn_label)


func create_win_ui():
	win_label = Label.new()
	win_label.name = "WinLabel"
	win_label.text = ""
	win_label.size = Vector2(500, 100)
	win_label.position = Vector2(390, 250)

	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	win_label.add_theme_font_size_override("font_size", 52)

	win_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_label.z_index = 20
	win_label.visible = false

	add_child(win_label)

	reset_button = Button.new()
	reset_button.name = "ResetButton"
	reset_button.text = "PLAY AGAIN"
	reset_button.size = Vector2(220, 65)
	reset_button.position = Vector2(520, 360)

	reset_button.add_theme_font_size_override("font_size", 24)

	reset_button.z_index = 20
	reset_button.visible = false

	reset_button.pressed.connect(_on_reset_button_pressed)

	add_child(reset_button)

func _on_reset_button_pressed():
	click_sound.play()
	reset_game()

func play_turn_animation():
	if turn_tween:
		turn_tween.kill()

	var screen_width = get_viewport_rect().size.x
	var label_width = turn_label.size.x

	var center_x = (screen_width - label_width) / 2.0

	var center_position = Vector2(
		center_x,
		70
	)

	var start_position
	var exit_position

	if current_player == 1:
		start_position = Vector2(
			screen_width + 40,
			70
		)

		exit_position = Vector2(
			screen_width + 40,
			70
		)

		turn_label.text = "PLAYER 1'S TURN"

		turn_label.add_theme_color_override(
			"font_color",
			Color(0.9, 0.1, 0.1)
		)

	else:
		start_position = Vector2(
			-label_width - 40,
			70
		)

		exit_position = Vector2(
			-label_width - 40,
			70
		)

		turn_label.text = "PLAYER 2'S TURN"

		turn_label.add_theme_color_override(
			"font_color",
			Color(0.95, 0.8, 0.1)
		)

	turn_label.position = start_position

	turn_tween = create_tween()

	turn_tween.tween_property(
		turn_label,
		"position",
		center_position,
		0.65
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	turn_tween.tween_interval(0.6)

	turn_tween.tween_property(
		turn_label,
		"position",
		exit_position,
		0.5
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)


func show_win_screen():
	turn_label.visible = false

	win_label.text = "PLAYER " + str(current_player) + " WINS!"

	if current_player == 1:
		win_label.add_theme_color_override(
			"font_color",
			Color(0.9, 0.1, 0.1)
		)
	else:
		win_label.add_theme_color_override(
			"font_color",
			Color(0.95, 0.8, 0.1)
		)

	win_label.visible = true
	reset_button.visible = true

	win_label.scale = Vector2(0.2, 0.2)
	win_label.modulate.a = 0.0

	win_tween = create_tween()

	win_tween.set_parallel(true)

	win_tween.tween_property(
		win_label,
		"scale",
		Vector2(1.0, 1.0),
		0.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	win_tween.tween_property(
		win_label,
		"modulate:a",
		1.0,
		0.25
	)

	win_tween.set_parallel(false)

	win_tween.tween_interval(0.2)

	win_tween.tween_property(
		reset_button,
		"scale",
		Vector2(1.1, 1.1),
		0.15
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	win_tween.tween_property(
		reset_button,
		"scale",
		Vector2(1.0, 1.0),
		0.15
	)

func show_draw_screen():
	turn_label.visible = false

	win_label.text = "IT'S A DRAW!"
	win_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	win_label.visible = true
	reset_button.visible = true

	win_label.scale = Vector2(0.2, 0.2)
	win_label.modulate.a = 0.0

	win_tween = create_tween()
	win_tween.set_parallel(true)
	win_tween.tween_property(
		win_label,
		"scale",
		Vector2(1.0, 1.0),
		0.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	win_tween.tween_property(
		win_label,
		"modulate:a",
		1.0,
		0.25
	)

	win_tween.set_parallel(false)
	win_tween.tween_interval(0.2)

	win_tween.tween_property(
		reset_button,
		"scale",
		Vector2(1.1, 1.1),
		0.15
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	win_tween.tween_property(
		reset_button,
		"scale",
		Vector2(1.0, 1.0),
		0.15
	)

func create_confetti():
	confetti.clear()
	confetti_time = 0.0

	var center = Vector2(
		get_viewport_rect().size.x / 2.0,
		300
	)

	for i in range(CONFETTI_COUNT):
		var angle = randf_range(-PI, 0.0)
		var speed = randf_range(250.0, 600.0)

		var particle = {
			"position": center + Vector2(
				randf_range(-80.0, 80.0),
				randf_range(-30.0, 30.0)
			),
			"velocity": Vector2(
				cos(angle) * speed,
				sin(angle) * speed
			),
			"rotation": randf_range(0.0, TAU),
			"rotation_speed": randf_range(-8.0, 8.0),
			"size": randf_range(5.0, 11.0),
			"color": Color.from_hsv(
				randf(),
				0.8,
				1.0
			)
		}

		confetti.append(particle)

	queue_redraw()

func create_sound_players():
	drop_sound = AudioStreamPlayer.new()
	drop_sound.stream = load("res://Assets/Audio/drop.wav")
	add_child(drop_sound)

	win_sound = AudioStreamPlayer.new()
	win_sound.stream = load("res://Assets/Audio/win.wav")
	add_child(win_sound)

	draw_sound = AudioStreamPlayer.new()
	draw_sound.stream = load("res://Assets/Audio/draw.wav")
	add_child(draw_sound)

	click_sound = AudioStreamPlayer.new()
	click_sound.stream = load("res://Assets/Audio/click.wav")
	add_child(click_sound)

func create_start_screen():
	start_screen = Control.new()
	start_screen.name = "StartScreen"
	start_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_screen.z_index = 100
	add_child(start_screen)

	var background = ColorRect.new()
	background.color = Color("#080A10")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	start_screen.add_child(background)

	var glow = Label.new()
	glow.text = "CONNECT FOUR"
	glow.position = Vector2(240, 170)
	glow.size = Vector2(800, 130)
	glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glow.add_theme_font_size_override("font_size", 82)
	glow.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0, 0.25))
	start_screen.add_child(glow)

	var title = Label.new()
	title.text = "CONNECT FOUR"
	title.position = Vector2(240, 160)
	title.size = Vector2(800, 130)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 82)
	title.add_theme_color_override("font_color", Color("#E8F1FF"))
	start_screen.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "THE ARCADE CLASSIC"
	subtitle.position = Vector2(340, 300)
	subtitle.size = Vector2(600, 45)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color("#00D9FF"))
	start_screen.add_child(subtitle)

	start_button = Button.new()
	start_button.text = "PLAY"
	start_button.position = Vector2(500, 410)
	start_button.size = Vector2(280, 80)
	start_button.add_theme_font_size_override("font_size", 32)
	start_button.add_theme_color_override("font_color", Color("#E8F1FF"))
	start_button.add_theme_color_override("font_hover_color", Color("#00D9FF"))
	start_button.pressed.connect(_start_game)
	start_screen.add_child(start_button)

func _start_game():
	game_started = true
	start_screen.visible = false
	turn_label.visible = true
	play_turn_animation()

func _process(delta):
	if not confetti.is_empty():
		confetti_time += delta

		for i in range(confetti.size()):
			confetti[i]["velocity"].y += CONFETTI_GRAVITY * delta
			confetti[i]["position"] += confetti[i]["velocity"] * delta
			confetti[i]["rotation"] += confetti[i]["rotation_speed"] * delta

		if confetti_time >= CONFETTI_DURATION:
			confetti.clear()

	if is_animating or not confetti.is_empty():
		queue_redraw()

func reset_game():
	game_over = false
	current_player = 1

	if turn_tween:
		turn_tween.kill()

	if win_tween:
		win_tween.kill()

	initialize_board()

	win_label.visible = false
	reset_button.visible = false

	reset_button.scale = Vector2(1.0, 1.0)
	win_label.scale = Vector2(1.0, 1.0)
	win_label.modulate.a = 1.0

	turn_label.visible = true

	queue_redraw()

	play_turn_animation()


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_7:
			var column = event.keycode - KEY_1
			drop_disc(column)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_position = event.position
			var relative_x = mouse_position.x - BOARD_OFFSET.x
			var column = int(relative_x / CELL_SIZE)
			drop_disc(column)


func _draw():
	var screen_size = get_viewport_rect().size

	draw_rect(
		Rect2(Vector2.ZERO, screen_size),
		Color("#080A10"),
		true
	)

	var glow_center = Vector2(640, 360)

	for i in range(7, 0, -1):
		draw_circle(
			glow_center,
			260.0 + i * 35.0,
			Color(0.0, 0.35, 0.65, 0.012)
		)

	for y in range(80, 700, 80):
		draw_line(
			Vector2(80, y),
			Vector2(1200, y),
			Color(0.0, 0.5, 0.8, 0.018),
			1.0
		)

	var cabinet_shadow = PackedVector2Array([
		Vector2(255, 55),
		Vector2(1025, 55),
		Vector2(1060, 650),
		Vector2(1010, 690),
		Vector2(270, 690),
		Vector2(220, 650)
	])

	draw_colored_polygon(
		cabinet_shadow,
		Color(0.0, 0.0, 0.0, 0.65)
	)

	var cabinet = PackedVector2Array([
		Vector2(245, 45),
		Vector2(1035, 45),
		Vector2(1060, 635),
		Vector2(1010, 675),
		Vector2(270, 675),
		Vector2(220, 635)
	])

	draw_colored_polygon(
		cabinet,
		Color("#20232C")
	)

	var inner_cabinet = PackedVector2Array([
		Vector2(260, 60),
		Vector2(1020, 60),
		Vector2(1040, 625),
		Vector2(995, 655),
		Vector2(285, 655),
		Vector2(240, 625)
	])

	draw_colored_polygon(
		inner_cabinet,
		Color("#111522")
	)

	draw_polyline(
		PackedVector2Array([
			Vector2(245, 45),
			Vector2(1035, 45),
			Vector2(1060, 635),
			Vector2(1010, 675),
			Vector2(270, 675),
			Vector2(220, 635),
			Vector2(245, 45)
		]),
		Color("#00AFCF"),
		2.0
	)

	var marquee = Rect2(
		Vector2(285, 70),
		Vector2(710, 70)
	)

	draw_rect(
		marquee,
		Color("#090C14"),
		true
	)

	draw_rect(
		Rect2(
			marquee.position,
			marquee.size
		),
		Color("#273044"),
		false,
		2.0
	)

	draw_line(
		Vector2(305, 125),
		Vector2(975, 125),
		Color(0.0, 0.75, 0.95, 0.35),
		2.0
	)

	draw_circle(
		Vector2(315, 92),
		4,
		Color("#00D9FF")
	)

	draw_circle(
		Vector2(965, 92),
		4,
		Color("#00D9FF")
	)

	var screen_bezel = Rect2(
		Vector2(335, 145),
		Vector2(610, 480)
	)

	draw_rect(
		screen_bezel,
		Color("#05070C"),
		true
	)

	draw_rect(
		Rect2(
			screen_bezel.position + Vector2(8, 8),
			screen_bezel.size - Vector2(16, 16)
		),
		Color("#171B2A"),
		true
	)

	draw_rect(
		Rect2(
			screen_bezel.position + Vector2(13, 13),
			screen_bezel.size - Vector2(26, 26)
		),
		Color("#0A0D16"),
		true
	)

	draw_line(
		Vector2(350, 150),
		Vector2(930, 150),
		Color(0.0, 0.85, 1.0, 0.55),
		2.0
	)

	for row in range(ROWS):
		for col in range(COLS):
			var cell_position = BOARD_OFFSET + Vector2(
				col * CELL_SIZE,
				row * CELL_SIZE
			)

			draw_rect(
				Rect2(
					cell_position,
					Vector2(CELL_SIZE, CELL_SIZE)
				),
				Color("#151A2B"),
				true
			)

			var center = cell_position + Vector2(
				CELL_SIZE / 2,
				CELL_SIZE / 2
			)

			draw_circle(
				center,
				DISC_RADIUS + 4,
				Color("#070910")
			)

			if board[row][col] == 0:
				draw_circle(
					center,
					DISC_RADIUS,
					Color("#090C15")
				)

				draw_circle(
					center,
					DISC_RADIUS - 5,
					Color("#111624")
				)

			elif board[row][col] == 1:
				draw_circle(
					center,
					DISC_RADIUS + 6,
					Color(0.9, 0.05, 0.05, 0.10)
				)

				draw_circle(
					center,
					DISC_RADIUS,
					Color("#E52323")
				)

				draw_circle(
					center - Vector2(8, 8),
					6,
					Color("#FF7777")
				)

			elif board[row][col] == 2:
				draw_circle(
					center,
					DISC_RADIUS + 6,
					Color(1.0, 0.75, 0.0, 0.10)
				)

				draw_circle(
					center,
					DISC_RADIUS,
					Color("#FFD21F")
				)

				draw_circle(
					center - Vector2(8, 8),
					6,
					Color("#FFF29A")
				)

	draw_rect(
		Rect2(
			BOARD_OFFSET,
			Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)
		),
		Color("#273044"),
		false,
		2.0
	)

	var control_panel = PackedVector2Array([
		Vector2(220, 625),
		Vector2(1060, 625),
		Vector2(1010, 675),
		Vector2(270, 675)
	])

	draw_colored_polygon(
		control_panel,
		Color("#252A35")
	)
	draw_polyline(
		PackedVector2Array([
			Vector2(220, 625),
			Vector2(1060, 625),
			Vector2(1010, 675),
			Vector2(270, 675),
			Vector2(220, 625)
		]),
		Color("#00AFCF"),
		2.0
	)

	draw_circle(
		Vector2(410, 650),
		17,
		Color("#090B12")
	)

	draw_circle(
		Vector2(410, 650),
		12,
		Color("#E52323")
	)

	draw_circle(
		Vector2(450, 650),
		17,
		Color("#090B12")
	)

	draw_circle(
		Vector2(450, 650),
		12,
		Color("#FFD21F")
	)

	draw_circle(
		Vector2(870, 650),
		17,
		Color("#090B12")
	)

	draw_circle(
		Vector2(870, 650),
		12,
		Color("#E52323")
	)

	draw_circle(
		Vector2(910, 650),
		17,
		Color("#090B12")
	)

	draw_circle(
		Vector2(910, 650),
		12,
		Color("#FFD21F")
	)

	draw_line(
		Vector2(640, 660),
		Vector2(640, 638),
		Color("#090B12"),
		9.0
	)

	draw_circle(
		Vector2(640, 632),
		17,
		Color("#00AFCF")
	)

	draw_circle(
		Vector2(640, 632),
		10,
		Color("#182033")
	)

	draw_line(
		Vector2(250, 665),
		Vector2(1030, 665),
		Color(0.0, 0.75, 0.95, 0.18),
		1.0
	)

	if is_animating:
		var falling_color

		if falling_disc_player == 1:
			draw_circle(
				falling_disc_position,
				DISC_RADIUS + 6,
				Color(0.9, 0.05, 0.05, 0.10)
			)

			falling_color = Color("#E52323")
		else:
			draw_circle(
				falling_disc_position,
				DISC_RADIUS + 6,
				Color(1.0, 0.75, 0.0, 0.10)
			)

			falling_color = Color("#FFD21F")

		draw_circle(
			falling_disc_position,
			DISC_RADIUS,
			falling_color
		)

	for particle in confetti:
		var position = particle["position"]
		var size = particle["size"]
		var rotation = particle["rotation"]
		var color = particle["color"]

		var points = PackedVector2Array([
			Vector2(-size, -size / 2),
			Vector2(size, -size / 2),
			Vector2(size, size / 2),
			Vector2(-size, size / 2)
		])

		var cos_r = cos(rotation)
		var sin_r = sin(rotation)
		var transformed_points = PackedVector2Array()

		for point in points:
			var rotated_point = Vector2(
				point.x * cos_r - point.y * sin_r,
				point.x * sin_r + point.y * cos_r
			)

			transformed_points.append(position + rotated_point)

		draw_colored_polygon(
			transformed_points,
			color
		)
