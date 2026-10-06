extends Control

const ROWS = 6
const COLS = 7

const CELL_SIZE = 80
const BOARD_OFFSET = Vector2(360, 135)
const DISC_RADIUS = 30
const CONFETTI_COUNT = 80
const CONFETTI_DURATION = 3.0
const CONFETTI_GRAVITY = 500.0
const MENU_BG = Color("#080A10")

var board = []

var current_player = 1
var game_over = false
var hovered_column = -1
var full_column = -1
var full_column_time = 0.0
var winning_discs = []
var win_pulse = 0.0

var turn_label: Label
var controls_label: Label
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
var rules_screen: Control
var rules_button: Button
var start_info_screen: Control

var game_mode_screen: Control
var game_mode_button: Button
var computer_mode = false
var computer_difficulty = ""
var computer_thinking = false
var difficulty_screen: Control

var neon_orb: ColorRect
var neon_orb_glow: ColorRect
var neon_orb_core: ColorRect
var neon_orb_position = 0.0
var neon_trail: Array[Vector2] = []
var neon_trail_line: Line2D
var neon_trail_glow: Line2D
var start_info_button: Button

var shutter: Control
var shutter_slats: Array[Panel] = []
var shutter_tween: Tween

var drop_sound: AudioStreamPlayer
var win_sound: AudioStreamPlayer
var draw_sound: AudioStreamPlayer
var click_sound: AudioStreamPlayer

func _ready():
	initialize_board()
	create_turn_label()
	create_win_ui()
	create_shutter()
	create_sound_players()
	create_start_screen()
	create_rules_screen()
	create_game_mode_screen()
	create_difficulty_screen()
	create_start_info_screen()
	turn_label.visible = false
	game_started = false

func add_menu_stars(screen):
	var stars = [
		Vector2(70, 85), Vector2(210, 125),
		Vector2(390, 70), Vector2(520, 105),
		Vector2(680, 65), Vector2(820, 115),
		Vector2(980, 75), Vector2(1130, 120),

		Vector2(110, 250), Vector2(250, 330),
		Vector2(1030, 280), Vector2(1160, 350),

		Vector2(80, 470), Vector2(190, 540),
		Vector2(1080, 480), Vector2(1180, 540),

		Vector2(250, 650), Vector2(390, 600),
		Vector2(520, 665), Vector2(680, 620),
		Vector2(820, 660), Vector2(960, 600),
		Vector2(1110, 650)
	]

	for star_pos in stars:
		var star = Label.new()
		star.text = "✦"
		star.position = star_pos
		star.size = Vector2(30, 30)
		star.add_theme_font_size_override("font_size", 22)
		star.add_theme_color_override("font_color", Color("#00E5FF"))
		star.add_theme_color_override("font_outline_color", Color("#00E5FF"))
		star.add_theme_constant_override("outline_size", 6)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star.z_index = 1
		screen.add_child(star)

func create_shutter():
	shutter = Control.new()
	shutter.name = "Shutter"
	shutter.position = Vector2(360, -480)
	shutter.size = Vector2(560, 480)
	shutter.z_index = 15
	shutter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shutter.visible = false
	add_child(shutter)

	for i in range(8):
		var slat = Panel.new()
		slat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slat.position = Vector2(0, i * 60)
		slat.size = Vector2(560, 54)

		var style = StyleBoxFlat.new()
		style.bg_color = Color("#252833")
		style.border_color = Color("#00AFCF")
		style.set_border_width_all(2)
		style.shadow_color = Color(0, 0, 0, 0.7)
		style.shadow_size = 8
		style.set_corner_radius_all(3)

		slat.add_theme_stylebox_override("panel", style)
		shutter.add_child(slat)
		shutter_slats.append(slat)

func close_shutter():
	shutter.visible = true
	shutter.position.y = -480

	if shutter_tween:
		shutter_tween.kill()

	shutter_tween = create_tween()
	shutter_tween.tween_property(
		shutter,
		"position:y",
		135.0,
		0.8
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	shutter_tween.tween_callback(_reveal_end_screen)

func _reveal_end_screen():
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
	if computer_mode and current_player == 2 and not computer_thinking:
		return
	if column < 0 or column >= COLS:
		return

	var row = find_empty_row(column)

	if row == -1:
		print("Column is full!")
		click_sound.play()
		full_column = column
		full_column_time = 0.3
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

	if computer_mode and current_player == 2:
		computer_take_turn()
	else:
		play_turn_animation()

func computer_take_turn():
	if game_over or is_animating or computer_thinking:
		return

	computer_thinking = true
	play_turn_animation()
	
	await get_tree().create_timer(0.6).timeout

	var column = get_computer_move()

	drop_disc(column)
	computer_thinking = false

func get_computer_move():
	if computer_difficulty == "Easy":
		return get_random_valid_column()

	if computer_difficulty == "Medium":
		return get_medium_move()

	if computer_difficulty == "Hard":
		return get_hard_move()

	return get_random_valid_column()

func get_random_valid_column():
	var valid_columns = []

	for col in range(COLS):
		if find_empty_row(col) != -1:
			valid_columns.append(col)

	return valid_columns[randi() % valid_columns.size()]

func get_medium_move():
	var winning_move = find_winning_move(2)

	if winning_move != -1:
		return winning_move

	return get_random_valid_column()

func get_hard_move():
	var winning_move = find_winning_move(2)

	if winning_move != -1:
		return winning_move

	var blocking_move = find_winning_move(1)

	if blocking_move != -1:
		return blocking_move

	return get_random_valid_column()

func find_winning_move(player):
	for col in range(COLS):
		var row = find_empty_row(col)

		if row == -1:
			continue

		board[row][col] = player
		var wins = check_win(row, col)
		board[row][col] = 0

		if wins:
			return col

	return -1

func check_win(row, col):
	if count_direction(row, col, 0, 1) >= 4:
		winning_discs = get_winning_discs(row, col, 0, 1)
		return true

	if count_direction(row, col, 1, 0) >= 4:
		winning_discs = get_winning_discs(row, col, 1, 0)
		return true

	if count_direction(row, col, 1, 1) >= 4:
		winning_discs = get_winning_discs(row, col, 1, 1)
		return true

	if count_direction(row, col, 1, -1) >= 4:
		winning_discs = get_winning_discs(row, col, 1, -1)
		return true

	return false

func get_winning_discs(row, col, dr, dc):
	var discs = []
	
	var start_row = row
	var start_col = col
	
	while is_valid_position(start_row - dr, start_col - dc) and board[start_row - dr][start_col - dc] == current_player:
		start_row -= dr
		start_col -= dc
	
	var r = start_row
	var c = start_col
	
	while is_valid_position(r, c) and board[r][c] == current_player:
		discs.append(Vector2i(r, c))
		r += dr
		c += dc
	
	return discs

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

func create_turn_label():
	var curvey_font = load("res://Assets/Fonts/Font3.ttf")
	turn_label = Label.new()

	turn_label.name = "TurnLabel"
	turn_label.text = "PLAYER 1'S TURN"
	turn_label.size = Vector2(320, 60)

	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	turn_label.add_theme_font_size_override("font_size", 32)
	turn_label.add_theme_font_override("font", curvey_font)
	turn_label.add_theme_constant_override("outline_size", 8)
	turn_label.add_theme_color_override("font_outline_color", Color("#080A10"))

	turn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turn_label.z_index = 10

	add_child(turn_label)
	controls_label = Label.new()
	controls_label.name = "ControlsLabel"
	controls_label.text = "CLICK A COLUMN  •  KEYS 1–7"
	controls_label.size = Vector2(500, 40)
	controls_label.position = Vector2(390, 650)
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.add_theme_font_size_override("font_size", 10)
	controls_label.add_theme_font_override("font", curvey_font)
	controls_label.add_theme_color_override("font_color", Color("#8FA3B8"))
	controls_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls_label.visible = false
	add_child(controls_label)


func create_win_ui():
	win_label = Label.new()
	win_label.name = "WinLabel"
	win_label.text = ""
	win_label.size = Vector2(500, 100)
	win_label.position = Vector2(390, 235)

	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	win_label.add_theme_font_size_override("font_size", 58)
	win_label.add_theme_constant_override("outline_size", 10)
	win_label.add_theme_color_override("font_outline_color", Color("#080A10"))
	win_label.add_theme_constant_override("shadow_offset_x", 0)
	win_label.add_theme_constant_override("shadow_offset_y", 4)
	win_label.add_theme_constant_override("shadow_outline_size", 8)
	win_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))

	win_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_label.z_index = 20
	win_label.visible = false

	add_child(win_label)

	reset_button = Button.new()
	reset_button.name = "ResetButton"
	reset_button.text = "PLAY AGAIN"
	reset_button.size = Vector2(240, 68)
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color("#171A3A")
	normal_style.border_color = Color("#00AFCF")
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(12)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color("#202A4A")
	hover_style.border_color = Color("#00D9FF")
	hover_style.set_border_width_all(3)
	hover_style.set_corner_radius_all(12)
	hover_style.shadow_color = Color(0.0, 0.85, 1.0, 0.45)
	hover_style.shadow_size = 12

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color("#0D1025")
	pressed_style.border_color = Color("#00D9FF")
	pressed_style.set_border_width_all(2)
	pressed_style.shadow_color = Color(0.0, 0.85, 1.0, 0.3)
	pressed_style.shadow_size = 6
	pressed_style.set_corner_radius_all(12)

	reset_button.add_theme_stylebox_override("normal", normal_style)
	reset_button.add_theme_stylebox_override("hover", hover_style)
	reset_button.add_theme_stylebox_override("pressed", pressed_style)
	normal_style.shadow_color = Color(0.0, 0.7, 1.0, 0.25)
	normal_style.shadow_size = 8
	reset_button.position = Vector2(530, 370)

	reset_button.add_theme_font_size_override("font_size", 24)
	reset_button.add_theme_color_override("font_color", Color("#E8F1FF"))
	reset_button.add_theme_color_override("font_hover_color", Color("#00D9FF"))
	reset_button.add_theme_color_override("font_pressed_color", Color("#FFFFFF"))

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
	turn_label.visible = true

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

		turn_label.text = "YOUR TURN" if computer_mode else "PLAYER 1'S TURN"

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

		turn_label.text = "COMPUTER'S TURN" if computer_mode else "PLAYER 2'S TURN"

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
	turn_tween.tween_callback(func(): turn_label.visible = false)

func show_win_screen():
	turn_label.visible = false

	win_label.text = "YOU WIN!" if computer_mode and current_player == 1 else ("COMPUTER WINS!" if computer_mode else "PLAYER " + str(current_player) + " WINS!")

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
	win_label.visible = false
	reset_button.visible = false
	get_tree().create_timer(1.2).timeout.connect(close_shutter)

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
	var curvey_font = load("res://Assets/Fonts/Font2.ttf")
	glow.add_theme_font_override("font", curvey_font)
	glow.position = Vector2(240, 170)
	glow.size = Vector2(800, 130)
	glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glow.add_theme_font_size_override("font_size", 72)
	glow.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0, 0.25))
	start_screen.add_child(glow)

	var title = Label.new()
	title.text = "CONNECT FOUR"
	title.add_theme_font_override("font", curvey_font)
	title.position = Vector2(240, 160)
	title.size = Vector2(800, 130)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color("#E8F1FF"))
	start_screen.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "THE ARCADE CLASSIC"
	subtitle.add_theme_font_override("font", curvey_font)
	subtitle.position = Vector2(340, 300)
	subtitle.size = Vector2(600, 45)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color("#00D9FF"))
	start_screen.add_child(subtitle)

	start_button = Button.new()
	start_button.text = "PLAY"
	start_button.add_theme_font_override("font", curvey_font)
	start_button.position = Vector2(500, 410)
	start_button.size = Vector2(280, 80)
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color("#171A3A")
	normal_style.border_color = Color("#00AFCF")
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(12)
	normal_style.shadow_color = Color(0.0, 0.7, 1.0, 0.25)
	normal_style.shadow_size = 8

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color("#202A4A")
	hover_style.border_color = Color("#00D9FF")
	hover_style.set_border_width_all(3)
	hover_style.set_corner_radius_all(12)
	hover_style.shadow_color = Color(0.0, 0.85, 1.0, 0.45)
	hover_style.shadow_size = 12

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color("#0D1025")
	pressed_style.border_color = Color("#00D9FF")
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(12)

	start_button.add_theme_stylebox_override("normal", normal_style)
	start_button.add_theme_stylebox_override("hover", hover_style)
	start_button.add_theme_stylebox_override("pressed", pressed_style)
	start_button.add_theme_font_size_override("font_size", 32)
	start_button.add_theme_color_override("font_color", Color("#E8F1FF"))
	start_button.add_theme_color_override("font_hover_color", Color("#00D9FF"))

	start_button.add_theme_color_override("font_pressed_color", Color("#FFFFFF"))
	start_button.add_theme_color_override("font_focus_color", Color("#E8F1FF"))

	start_button.pressed.connect(_on_start_button_pressed)
	start_screen.add_child(start_button)
	
	neon_orb = ColorRect.new()
	neon_orb.size = Vector2(12, 12)
	neon_orb.color = Color("#00E5FF")
	neon_orb_core = ColorRect.new()
	neon_orb_core.size = Vector2(7, 7)
	neon_orb_core.color = Color("#E6FCFF")
	neon_orb_core.z_index = 106
	start_screen.add_child(neon_orb_core)
	neon_orb.z_index = 105
	start_screen.add_child(neon_orb)
	neon_trail_line = Line2D.new()
	neon_trail_line.width = 18.0
	neon_trail_line.default_color = Color(0.0, 0.8, 1.0, 0.65)
	neon_trail_line.z_index = 104
	start_screen.add_child(neon_trail_line)
	neon_trail_glow = Line2D.new()
	neon_trail_glow.width = 32.0
	neon_trail_glow.default_color = Color(0.0, 0.8, 1.0, 0.16)
	neon_trail_glow.z_index = 103
	start_screen.add_child(neon_trail_glow)
	
	var stars = [
	Vector2(70, 85), Vector2(210, 125),
	Vector2(390, 70), Vector2(520, 105), Vector2(680, 65),
	Vector2(820, 115), Vector2(980, 75), Vector2(1130, 120),

	Vector2(110, 250), Vector2(250, 330),
	Vector2(1030, 280), Vector2(1160, 350),

	Vector2(80, 470), Vector2(190, 540),
	Vector2(1080, 480), Vector2(1180, 540),

	Vector2(250, 650), Vector2(390, 600),
	Vector2(520, 665), Vector2(680, 620),
	Vector2(820, 660), Vector2(960, 600),
	Vector2(1110, 650)
]

	for star_pos in stars:
		var star = Label.new()
		star.text = "✦"
		star.position = star_pos
		star.size = Vector2(30, 30)
		star.add_theme_font_size_override("font_size", 22)
		star.add_theme_color_override("font_color", Color("#00E5FF"))
		star.add_theme_color_override("font_outline_color", Color("#00E5FF"))
		star.add_theme_constant_override("outline_size", 6)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		start_screen.add_child(star)

func _on_start_button_pressed():
	click_sound.play()
	_start_game()

func _start_game():
	start_screen.visible = false

	if has_seen_rules():
		start_actual_game()
	else:
		move_neon_snake_to(rules_screen)
		rules_screen.visible = true

func start_actual_game():
	game_started = true
	turn_label.visible = true
	if computer_mode:
		current_player = 1
	game_started = true
	turn_label.visible = true
	if computer_mode and current_player == 2:
		computer_take_turn()
	play_turn_animation()
	controls_label.visible = true

func _on_rules_continue():
	mark_rules_seen()
	move_neon_snake_to(game_mode_screen)
	rules_screen.visible = false
	game_mode_screen.visible = true
	click_sound.play()
	
func create_game_mode_screen():
	game_mode_screen = Control.new()
	var background = ColorRect.new()
	background.color = MENU_BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_mode_screen.add_child(background)
	game_mode_screen.name = "GameModeScreen"
	game_mode_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_mode_screen.z_index = 110
	game_mode_screen.visible = false
	add_child(game_mode_screen)
	
	add_menu_stars(game_mode_screen)

	var title = Label.new()
	title.text = "GAME MODE"
	title.position = Vector2(0, 170)
	title.size = Vector2(1280, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("#00AFCF"))
	game_mode_screen.add_child(title)

	var computer_button = Button.new()
	computer_button.text = "COMPUTER"
	computer_button.position = Vector2(440, 300)
	computer_button.size = Vector2(400, 80)
	computer_button.add_theme_font_size_override("font_size", 28)
	game_mode_screen.add_child(computer_button)

	var two_player_button = Button.new()
	two_player_button.text = "2 PLAYERS"
	two_player_button.position = Vector2(440, 410)
	two_player_button.size = Vector2(400, 80)
	two_player_button.add_theme_font_size_override("font_size", 28)
	game_mode_screen.add_child(two_player_button)

	computer_button.pressed.connect(_on_computer_mode_pressed)
	two_player_button.pressed.connect(_on_two_player_mode_pressed)
	
func _on_computer_mode_pressed():
	click_sound.play()
	computer_mode = true
	computer_difficulty = ""

	game_mode_screen.visible = false
	difficulty_screen.visible = true

	move_neon_snake_to(difficulty_screen)
	
func _on_two_player_mode_pressed():
	click_sound.play()
	computer_mode = false
	game_mode_screen.visible = false
	move_neon_snake_to(start_info_screen)
	start_info_screen.visible = true

func move_neon_snake_to(screen):
	for node in [neon_trail_glow, neon_trail_line, neon_orb, neon_orb_core]:
		node.reparent(screen, false)
	neon_orb.position = Vector2.ZERO
	neon_orb_core.position = Vector2(3, 3)
	neon_trail.clear()
	neon_trail_line.points = PackedVector2Array()
	neon_trail_glow.points = PackedVector2Array()

func create_rules_screen():
	var curvey_font = load("res://Assets/Fonts/Font2.ttf")
	var third_font = load("res://Assets/Fonts/Font3.ttf")
	rules_screen = Control.new()
	rules_screen.name = "RulesScreen"
	rules_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rules_screen.z_index = 110
	rules_screen.visible = false
	add_child(rules_screen)
	add_menu_stars(rules_screen)

	var background = ColorRect.new()
	background.color = Color("#080A10")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rules_screen.add_child(background)

	var title = Label.new()
	title.text = "HOW TO PLAY"
	title.position = Vector2(340, 80)
	title.size = Vector2(600, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_font_override("font", curvey_font)
	title.add_theme_color_override("font_color", Color("#E8F1FF"))
	rules_screen.add_child(title)

	var rules = Label.new()
	rules.text = "• PLAYERS TAKE TURNS DROPPING DISCS INTO THE COLUMNS.\n\n• Player 1 uses RED discs.\n\n• Player 2 uses YELLOW discs.\n\n• Connect four discs horizontally, vertically, or diagonally to win.\n\n• If the board fills before anyone connects four, the game is a draw."
	rules.position = Vector2(90, 150)
	rules.size = Vector2(680, 330)
	rules.add_theme_font_size_override("font_size", 13)
	rules.add_theme_font_override("font", third_font)
	rules.add_theme_color_override("font_color", Color("#E8F1FF"))
	rules.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rules_screen.add_child(rules)

	rules_button = Button.new()
	rules_button.text = "PLAY"
	rules_button.position = Vector2(500, 480)
	rules_button.size = Vector2(280, 70)
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color("#171A3A")
	normal_style.border_color = Color("#00AFCF")
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(12)
	normal_style.shadow_color = Color(0.0, 0.7, 1.0, 0.25)
	normal_style.shadow_size = 8

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color("#202A4A")
	hover_style.border_color = Color("#00D9FF")
	hover_style.set_border_width_all(3)
	hover_style.set_corner_radius_all(12)
	hover_style.shadow_color = Color(0.0, 0.85, 1.0, 0.45)
	hover_style.shadow_size = 12

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color("#0D1025")
	pressed_style.border_color = Color("#00D9FF")
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(12)

	rules_button.add_theme_stylebox_override("normal", normal_style)
	rules_button.add_theme_stylebox_override("hover", hover_style)
	rules_button.add_theme_stylebox_override("pressed", pressed_style)
	rules_button.add_theme_font_size_override("font_size", 28)
	rules_button.add_theme_font_override("font", curvey_font)
	rules_button.add_theme_color_override("font_color", Color("#E8F1FF"))
	rules_button.add_theme_color_override("font_hover_color", Color("#00D9FF"))
	rules_button.pressed.connect(_on_rules_continue)
	rules_screen.add_child(rules_button)

func create_difficulty_screen():
	difficulty_screen = Control.new()
	var background = ColorRect.new()
	background.color = MENU_BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	difficulty_screen.add_child(background)
	difficulty_screen.name = "DifficultyScreen"
	difficulty_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	difficulty_screen.z_index = 110
	difficulty_screen.visible = false
	add_child(difficulty_screen)
	add_menu_stars(difficulty_screen)

	var title = Label.new()
	title.text = "SELECT DIFFICULTY"
	title.position = Vector2(0, 170)
	title.size = Vector2(1280, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("#00AFCF"))
	difficulty_screen.add_child(title)

	var easy_button = Button.new()
	easy_button.text = "EASY"
	easy_button.position = Vector2(440, 285)
	easy_button.size = Vector2(400, 70)
	easy_button.add_theme_font_size_override("font_size", 26)
	difficulty_screen.add_child(easy_button)

	var medium_button = Button.new()
	medium_button.text = "MEDIUM"
	medium_button.position = Vector2(440, 380)
	medium_button.size = Vector2(400, 70)
	medium_button.add_theme_font_size_override("font_size", 26)
	difficulty_screen.add_child(medium_button)

	var hard_button = Button.new()
	hard_button.text = "HARD"
	hard_button.position = Vector2(440, 475)
	hard_button.size = Vector2(400, 70)
	hard_button.add_theme_font_size_override("font_size", 26)
	difficulty_screen.add_child(hard_button)

	easy_button.pressed.connect(_on_difficulty_selected.bind("Easy"))
	medium_button.pressed.connect(_on_difficulty_selected.bind("Medium"))
	hard_button.pressed.connect(_on_difficulty_selected.bind("Hard"))

func _on_difficulty_selected(difficulty):
	click_sound.play()
	computer_difficulty = difficulty
	difficulty_screen.visible = false
	move_neon_snake_to(start_info_screen)
	start_info_screen.visible = true

func create_start_info_screen():
	var curvey_font = load("res://Assets/Fonts/Font3.ttf")
	start_info_screen = Control.new()
	start_info_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_info_screen.z_index = 110
	start_info_screen.visible = false
	add_child(start_info_screen)

	var background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("#080A10")
	start_info_screen.add_child(background)
	
	var start_label = Label.new()
	start_label.text = "PLAYER RED STARTS...."
	start_label.position = Vector2(200, 250)
	start_label.size = Vector2(500, 100)
	start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	start_label.add_theme_font_size_override("font_size", 40)
	start_label.add_theme_font_override("font", curvey_font)
	start_label.add_theme_color_override("font_color", Color("#E52323"))
	start_label.add_theme_color_override("font_outline_color", Color("#080A10"))
	start_label.add_theme_constant_override("outline_size", 10)
	start_info_screen.add_child(start_label)
	
	start_info_button = Button.new()
	start_info_button.text = "START"
	start_info_button.position = Vector2(500, 400)
	start_info_button.size = Vector2(280, 70)
	start_info_button.add_theme_font_size_override("font_size", 28)
	start_info_button.add_theme_font_override("font", curvey_font)
	var info_normal = StyleBoxFlat.new()
	info_normal.bg_color = Color("#171A3A")
	info_normal.border_color = Color("#00AFCF")
	info_normal.set_border_width_all(2)
	info_normal.set_corner_radius_all(12)
	info_normal.shadow_color = Color(0.0, 0.7, 1.0, 0.25)
	info_normal.shadow_size = 8

	var info_hover = StyleBoxFlat.new()
	info_hover.bg_color = Color("#202A4A")
	info_hover.border_color = Color("#00D9FF")
	info_hover.set_border_width_all(3)
	info_hover.set_corner_radius_all(12)
	info_hover.shadow_color = Color(0.0, 0.85, 1.0, 0.45)
	info_hover.shadow_size = 12

	start_info_button.add_theme_stylebox_override("normal", info_normal)
	start_info_button.add_theme_stylebox_override("hover", info_hover)
	start_info_button.add_theme_font_size_override("font_size", 28)
	
	start_info_screen.add_child(start_info_button)
	start_info_button.pressed.connect(_on_start_info_button_pressed)
	
	var stars = [
	Vector2(70, 85), Vector2(210, 125),
	Vector2(390, 70), Vector2(520, 105), Vector2(680, 65),
	Vector2(820, 115), Vector2(980, 75), Vector2(1130, 120),

	Vector2(110, 250), Vector2(250, 330),
	Vector2(1030, 280), Vector2(1160, 350),

	Vector2(80, 470), Vector2(190, 540),
	Vector2(1080, 480), Vector2(1180, 540),

	Vector2(250, 650), Vector2(390, 600),
	Vector2(520, 665), Vector2(680, 620),
	Vector2(820, 660), Vector2(960, 600),
	Vector2(1110, 650)
]

	for star_pos in stars:
		var star = Label.new()
		star.text = "✦"
		star.position = star_pos
		star.size = Vector2(30, 30)
		star.add_theme_font_size_override("font_size", 22)
		star.add_theme_color_override("font_color", Color("#00E5FF"))
		star.add_theme_color_override("font_outline_color", Color("#00E5FF"))
		star.add_theme_constant_override("outline_size", 6)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		start_info_screen.add_child(star)

func _on_start_info_button_pressed():
	click_sound.play()
	_on_start_info_continue()

func _on_start_info_continue():
	start_info_screen.visible = false
	start_actual_game()

func has_seen_rules():
	return false

func mark_rules_seen():
	var file = FileAccess.open("user://connect_four_rules_seen.save", FileAccess.WRITE)
	file.store_string("seen")

func _process(delta):
	if (start_screen and start_screen.visible) or (rules_screen and rules_screen.visible) or (game_mode_screen and game_mode_screen.visible) or (difficulty_screen and difficulty_screen.visible) or (start_info_screen and start_info_screen.visible):
		neon_orb_position += delta * 1000.0
	if neon_orb_position >= 4000.0:
		neon_orb_position = 0.0

	var p = neon_orb_position
	if p < 1280.0:
		neon_orb.position = Vector2(p, 0)
	elif p < 2000.0:
		neon_orb.position = Vector2(1270, p - 1280.0)
	elif p < 3280.0:
		neon_orb.position = Vector2(1270 - (p - 2000.0), 690)
	else:
		neon_orb.position = Vector2(0, 690 - (p - 3280.0))
	
	neon_trail.push_front(neon_orb.position + Vector2(6, 6))
	if neon_trail.size() > 35:
		neon_trail.pop_back()
	neon_trail_line.points = PackedVector2Array(neon_trail)
	neon_trail_glow.points = PackedVector2Array(neon_trail)
	neon_orb_core.position = neon_orb.position + Vector2(3, 3)
	queue_redraw()
	
	var mouse_x = get_local_mouse_position().x
	win_pulse += delta * 4.0
	
	if full_column != -1:
		full_column_time -= delta
	if full_column_time <= 0.0:
		full_column = -1
	if mouse_x >= BOARD_OFFSET.x and mouse_x < BOARD_OFFSET.x + COLS * CELL_SIZE:
		hovered_column = int((mouse_x - BOARD_OFFSET.x) / CELL_SIZE)
	else:
		hovered_column = -1
	
	if not confetti.is_empty():
		confetti_time += delta

		for i in range(confetti.size()):
			confetti[i]["velocity"].y += CONFETTI_GRAVITY * delta
			confetti[i]["position"] += confetti[i]["velocity"] * delta
			confetti[i]["rotation"] += confetti[i]["rotation_speed"] * delta

		if confetti_time >= CONFETTI_DURATION:
			confetti.clear()
	queue_redraw()

func reset_game():
	if computer_mode:
		game_started = false
		win_label.visible = false
		reset_button.visible = false
		difficulty_screen.visible = false
		start_info_screen.visible = false
		game_mode_screen.visible = true
		move_neon_snake_to(game_mode_screen)
		return
	game_over = false
	current_player = 1
	computer_thinking = false
	winning_discs = []
	confetti.clear()
	confetti_time = 0.0

	if turn_tween:
		turn_tween.kill()

	if win_tween:
		win_tween.kill()
	if shutter_tween:
		shutter_tween.kill()

	initialize_board()

	win_label.visible = false
	reset_button.visible = false
	
	shutter.visible = false
	shutter.position.y = -480

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
	
		elif event.keycode >= KEY_KP_1 and event.keycode <= KEY_KP_7:
			var column = event.keycode - KEY_KP_1
			drop_disc(column)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_position = event.position
			var relative_x = mouse_position.x - BOARD_OFFSET.x
			var column = int(relative_x / CELL_SIZE)
			drop_disc(column)


func _draw():
	if not game_started:
		return
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
	if hovered_column != -1 and game_started and not game_over and find_empty_row(hovered_column) != -1:
		var highlight_x = BOARD_OFFSET.x + hovered_column * CELL_SIZE
		draw_rect(
			Rect2(highlight_x, BOARD_OFFSET.y, CELL_SIZE, ROWS * CELL_SIZE),
			Color(0.0, 0.85, 1.0, 0.07)
		)
	if full_column != -1:
		var flash_x = BOARD_OFFSET.x + full_column * CELL_SIZE
		draw_rect(
			Rect2(flash_x, BOARD_OFFSET.y, CELL_SIZE, ROWS * CELL_SIZE),
			Color(1.0, 0.1, 0.1, 0.18)
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
			if Vector2i(row, col) in winning_discs:
				draw_arc(
					center,
					DISC_RADIUS + 8 + sin(win_pulse) * 3.0,
					0,
					TAU,
					32,
					Color(1, 1, 1, 0.75 + sin(win_pulse) * 0.25),
					4.0
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
