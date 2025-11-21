extends CanvasLayer

@onready var dialogue_label = $Panel/VBoxContainer/DialogueLabel
@onready var continue_button = $Panel/VBoxContainer/ContinueButton
@onready var choice_container = $Panel/VBoxContainer/ChoiceContainer

var dialogue_text: String = ""
var is_active: bool = false

# Sistema DLS
var dls_executor: DLSParser.DLSExecutor = null
var current_choices: Array = []
var waiting_for_choice: bool = false
var waiting_timer: float = 0.0
var is_waiting: bool = false

signal dialogue_finished
signal dls_signal(signal_name: String)

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.visible = true

func _process(delta):
	if is_waiting:
		waiting_timer -= delta
		if waiting_timer <= 0.0:
			is_waiting = false
			_process_dls()

func _input(event):
	if not is_active or waiting_for_choice or is_waiting:
		return
		
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_on_continue_pressed()

# Método antigo - mantém compatibilidade
func show_dialogue(text: String):
	dialogue_text = text
	dialogue_label.text = dialogue_text
	is_active = true
	visible = true
	waiting_for_choice = false
	current_choices.clear()
	_clear_choices()
	continue_button.visible = true
	# Pausar o jogo enquanto o diálogo está aberto
	get_tree().paused = true

# Novo método - carrega e executa um arquivo DLS
func show_dls_file(file_path: String, initial_variables: Dictionary = {}):
	var parsed = DLSParser.load_dls_file(file_path)
	if parsed.is_empty():
		push_error("Erro ao carregar arquivo DLS: " + file_path)
		return
	
	dls_executor = DLSParser.DLSExecutor.new(parsed)
	
	# Definir variáveis iniciais
	for key in initial_variables:
		dls_executor.set_variable(key, initial_variables[key])
	
	is_active = true
	visible = true
	waiting_for_choice = false
	_process_dls()

# Novo método - executa conteúdo DLS diretamente
func show_dls_content(content: String, initial_variables: Dictionary = {}):
	var parsed = DLSParser.parse_dls(content)
	if parsed.is_empty():
		push_error("Erro ao parsear conteúdo DLS")
		return
	
	dls_executor = DLSParser.DLSExecutor.new(parsed)
	
	# Definir variáveis iniciais
	for key in initial_variables:
		dls_executor.set_variable(key, initial_variables[key])
	
	is_active = true
	visible = true
	waiting_for_choice = false
	_process_dls()

func _process_dls():
	if dls_executor == null:
		return
	
	while true:
		var line = dls_executor.get_next()
		
		if line.get("type") == "end":
			_finish_dialogue()
			return
		
		match line.get("type"):
			"text":
				var text = dls_executor.replace_variables(line.get("text", ""))
				dialogue_label.text = text
				continue_button.visible = true
				waiting_for_choice = false
				_clear_choices()
				# Pausar o jogo
				get_tree().paused = true
				return  # Aguardar input do usuário
			
			"command":
				var result = dls_executor.execute_command(line.get("command", ""))
				match result.get("type"):
					"wait":
						is_waiting = true
						waiting_timer = result.get("time", 0.0)
						return  # Aguardar timer
					"signal":
						dls_signal.emit(result.get("name", ""))
						# Continuar processando
					"continue":
						# Continuar processando
						pass
			
			"choice":
				# Coletar todas as escolhas
				dls_executor.current_index -= 1  # Voltar uma posição
				var choices = _collect_choices()
				if choices.size() > 0:
					_show_choices(choices)
					waiting_for_choice = true
					continue_button.visible = false
					return  # Aguardar escolha do usuário
			
			"if":
				var condition = line.get("condition", "")
				var result = dls_executor.evaluate_condition(condition)
				if not result:
					dls_executor.skip_if_block(false)
				# Continuar processando se a condição for verdadeira
			
			"endif":
				# Continuar processando
				pass
			
			"label":
				# Continuar processando (labels são apenas pontos de referência)
				pass

func _collect_choices() -> Array:
	if dls_executor == null:
		return []
	
	var choices = []
	var saved_index = dls_executor.current_index
	
	# Coletar todas as escolhas consecutivas
	while dls_executor.current_index < dls_executor.parsed_lines.size():
		var line = dls_executor.parsed_lines[dls_executor.current_index]
		if line.get("type") == "choice":
			var choice_text = line.get("text", "")
			var choice_label = line.get("label", "")
			choices.append({
				"text": choice_text,
				"label": choice_label,
				"index": dls_executor.current_index
			})
			dls_executor.current_index += 1
		else:
			break
	
	return choices

func _show_choices(choices: Array):
	current_choices = choices
	_clear_choices()
	
	for i in range(choices.size()):
		var choice_data = choices[i]
		var button = Button.new()
		button.text = choice_data.get("text", "")
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(_on_choice_selected.bind(i))
		# Aplicar tema do botão
		var font = load("res://assets/fonts/Golden Varsity Outline.ttf")
		if font:
			button.add_theme_font_override("font", font)
			button.add_theme_font_size_override("font_size", 20)
		choice_container.add_child(button)

func _clear_choices():
	for child in choice_container.get_children():
		child.queue_free()
	current_choices.clear()

func _on_choice_selected(choice_index: int):
	if choice_index < 0 or choice_index >= current_choices.size():
		return
	
	var choice = current_choices[choice_index]
	var label = choice.get("label", "")
	
	_clear_choices()
	waiting_for_choice = false
	continue_button.visible = true
	
	if not label.is_empty():
		dls_executor.jump_to_label(label)
	
	# Continuar processando DLS
	_process_dls()

func _on_continue_pressed():
	if waiting_for_choice or is_waiting:
		return
	
	if dls_executor != null:
		# Continuar processando DLS
		_process_dls()
	else:
		# Método antigo - finalizar diálogo
		_finish_dialogue()

func _finish_dialogue():
	is_active = false
	visible = false
	waiting_for_choice = false
	is_waiting = false
	current_choices.clear()
	_clear_choices()
	dls_executor = null
	
	# Despausar o jogo
	get_tree().paused = false
	
	# Emitir sinal
	dialogue_finished.emit()
	
	# Remover o diálogo após um pequeno delay
	call_deferred("queue_free")
