extends RefCounted
class_name DLSParser

enum TokenType {
	TEXT,
	COMMAND,
	VARIABLE,
	LABEL,
	CHOICE,
	IF,
	ENDIF,
	COMMENT
}

var variables: Dictionary = {}
var current_dialogue: Array = []
var labels: Dictionary = {}

# Carrega e parseia um arquivo DLS
static func load_dls_file(file_path: String) -> Array:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Erro ao abrir arquivo DLS: " + file_path)
		return []
	
	var content = file.get_as_text()
	file.close()
	
	return parse_dls(content)

# Parseia conteúdo DLS
static func parse_dls(content: String) -> Array:
	var lines = content.split("\n")
	var parsed_lines = []
	var current_label = ""
	var in_if_block = false
	var if_condition = false
	var if_depth = 0
	
	for i in range(lines.size()):
		var line = lines[i].strip_edges()
		
		# Ignorar linhas vazias
		if line.is_empty():
			continue
		
		# Comentários
		if line.begins_with("#"):
			continue
		
		# Labels
		if line.begins_with("==") and line.ends_with("=="):
			var label_name = line.substr(2, line.length() - 4).strip_edges()
			current_label = label_name
			parsed_lines.append({
				"type": "label",
				"name": label_name,
				"line": i + 1
			})
			continue
		
		# Comandos
		if line.begins_with("[") and line.ends_with("]"):
			var cmd_content = line.substr(1, line.length() - 2).strip_edges()
			
			# Comando IF
			if cmd_content.begins_with("if "):
				if_depth += 1
				var condition = cmd_content.substr(3).strip_edges()
				var result = _evaluate_condition(condition)
				if in_if_block:
					# Já estamos em um bloco IF, ignorar
					continue
				else:
					in_if_block = true
					if_condition = result
					parsed_lines.append({
						"type": "if",
						"condition": condition,
						"result": result,
						"line": i + 1
					})
					continue
			
			# Comando ENDIF
			if cmd_content == "endif":
				if_depth -= 1
				if if_depth == 0:
					in_if_block = false
					if_condition = false
				parsed_lines.append({
					"type": "endif",
					"line": i + 1
				})
				continue
			
			# Ignorar linhas dentro de bloco IF falso
			if in_if_block and not if_condition:
				continue
			
			# Comando CHOICE
			if cmd_content.begins_with("choice"):
				var choice_text = _extract_quoted_string(cmd_content)
				var choice_label = ""
				# Verificar se tem label após o texto
				var parts = cmd_content.split(" ")
				for j in range(1, parts.size()):
					if parts[j].begins_with("->") or parts[j].begins_with("goto"):
						if j + 1 < parts.size():
							choice_label = parts[j + 1].strip_edges().trim_prefix("->").trim_prefix("goto").strip_edges()
						break
				
				parsed_lines.append({
					"type": "choice",
					"text": choice_text,
					"label": choice_label,
					"line": i + 1
				})
				continue
			
			# Outros comandos
			parsed_lines.append({
				"type": "command",
				"command": cmd_content,
				"line": i + 1
			})
			continue
		
		# Ignorar linhas dentro de bloco IF falso
		if in_if_block and not if_condition:
			continue
		
		# Texto normal
		var processed_text = _process_text_line(line)
		parsed_lines.append({
			"type": "text",
			"text": processed_text,
			"original": line,
			"line": i + 1
		})
	
	# Labels serão indexados pelo executor quando necessário
	
	return parsed_lines

# Processa uma linha de texto, substituindo variáveis e processando comandos inline
static func _process_text_line(line: String) -> String:
	var result = line
	
	# Substituir variáveis {variavel}
	var regex = RegEx.new()
	regex.compile("\\{(\\w+)\\}")
	var matches = regex.search_all(line)
	
	for match in matches:
		var var_name = match.get_string(1)
		# Por enquanto, deixamos a variável como está, será substituída em runtime
		# result = result.replace("{" + var_name + "}", str(get_variable(var_name)))
	
	return result

# Extrai string entre aspas
static func _extract_quoted_string(text: String) -> String:
	var start = text.find('"')
	if start == -1:
		return ""
	var end = text.find('"', start + 1)
	if end == -1:
		return ""
	return text.substr(start + 1, end - start - 1)

# Avalia uma condição simples
static func _evaluate_condition(condition: String) -> bool:
	# Por enquanto, suporta apenas condições simples como "var == value" ou "var"
	condition = condition.strip_edges()
	
	# Se não tem operador, verifica se a variável existe e é verdadeira
	if "==" in condition:
		var parts = condition.split("==")
		if parts.size() == 2:
			var var_name = parts[0].strip_edges()
			var value = parts[1].strip_edges().trim_prefix('"').trim_suffix('"')
			# Será avaliado em runtime com as variáveis do contexto
			return true  # Placeholder
	elif "!=" in condition:
		var parts = condition.split("!=")
		if parts.size() == 2:
			var var_name = parts[0].strip_edges()
			var value = parts[1].strip_edges().trim_prefix('"').trim_suffix('"')
			return true  # Placeholder
	else:
		# Verifica se a variável existe
		return true  # Placeholder
	
	return false

# Constrói índice de labels
static func _build_label_index(parsed_lines: Array) -> Dictionary:
	var index = {}
	for i in range(parsed_lines.size()):
		if parsed_lines[i].get("type") == "label":
			index[parsed_lines[i].get("name")] = i
	return index

# Classe para executar diálogos DLS
class DLSExecutor:
	var variables: Dictionary = {}
	var parsed_lines: Array = []
	var current_index: int = 0
	var label_index: Dictionary = {}
	
	func _init(parsed: Array):
		parsed_lines = parsed
		label_index = DLSParser._build_label_index(parsed)
	
	func get_next() -> Dictionary:
		if current_index >= parsed_lines.size():
			return {"type": "end"}
		
		var line = parsed_lines[current_index]
		current_index += 1
		return line
	
	func jump_to_label(label_name: String) -> bool:
		if label_index.has(label_name):
			current_index = label_index[label_name] + 1
			return true
		return false
	
	func set_variable(name: String, value):
		variables[name] = value
	
	func get_variable(name: String):
		if variables.has(name):
			return variables[name]
		return null
	
	func replace_variables(text: String) -> String:
		var result = text
		var regex = RegEx.new()
		regex.compile("\\{(\\w+)\\}")
		var matches = regex.search_all(text)
		
		for match in matches:
			var var_name = match.get_string(1)
			var value = get_variable(var_name)
			if value != null:
				result = result.replace("{" + var_name + "}", str(value))
			else:
				result = result.replace("{" + var_name + "}", "?")
		
		return result
	
	func execute_command(cmd: String) -> Dictionary:
		var parts = cmd.split(" ", false)
		if parts.size() == 0:
			return {"type": "continue"}
		
		var cmd_name = parts[0].to_lower()
		
		match cmd_name:
			"wait":
				if parts.size() > 1:
					var wait_time = float(parts[1])
					return {"type": "wait", "time": wait_time}
			
			"set":
				if parts.size() >= 3:
					var var_name = parts[1]
					var var_value = " ".join(parts.slice(2))
					# Remover aspas se existirem
					if var_value.begins_with('"') and var_value.ends_with('"'):
						var_value = var_value.substr(1, var_value.length() - 2)
					set_variable(var_name, var_value)
					return {"type": "continue"}
			
			"jump", "goto":
				if parts.size() > 1:
					var label = parts[1]
					jump_to_label(label)
					return {"type": "continue"}
			
			"emit", "signal":
				if parts.size() > 1:
					var signal_name = parts[1]
					return {"type": "signal", "name": signal_name}
			
			_:
				return {"type": "continue"}
		
		return {"type": "continue"}
	
	func evaluate_condition(condition: String) -> bool:
		condition = condition.strip_edges()
		
		if "==" in condition:
			var parts = condition.split("==")
			if parts.size() == 2:
				var var_name = parts[0].strip_edges()
				var value = parts[1].strip_edges().trim_prefix('"').trim_suffix('"')
				var var_value = get_variable(var_name)
				return str(var_value) == value
		elif "!=" in condition:
			var parts = condition.split("!=")
			if parts.size() == 2:
				var var_name = parts[0].strip_edges()
				var value = parts[1].strip_edges().trim_prefix('"').trim_suffix('"')
				var var_value = get_variable(var_name)
				return str(var_value) != value
		else:
			# Verifica se a variável existe e é verdadeira
			var var_value = get_variable(condition)
			if var_value != null:
				return bool(var_value)
			return false
		
		return false
	
	func skip_if_block(result: bool):
		var depth = 1
		while current_index < parsed_lines.size():
			var line = parsed_lines[current_index]
			if line.get("type") == "if":
				depth += 1
			elif line.get("type") == "endif":
				depth -= 1
				if depth == 0:
					current_index += 1
					return
			current_index += 1
	
	func get_choices() -> Array:
		var choices = []
		var saved_index = current_index
		
		# Voltar uma posição (já lemos a primeira linha de choice)
		current_index -= 1
		
		while current_index < parsed_lines.size():
			var line = parsed_lines[current_index]
			if line.get("type") == "choice":
				choices.append({
					"text": line.get("text"),
					"label": line.get("label", ""),
					"index": current_index
				})
				current_index += 1
			else:
				break
		
		return choices

