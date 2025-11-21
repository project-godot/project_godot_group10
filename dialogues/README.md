# Dialogue Language Script (DLS)

Este é o formato de diálogo usado no projeto. O DLS permite criar diálogos interativos com suporte a múltiplas linhas, escolhas, variáveis e comandos.

## Formato Básico

### Texto Simples
```
Olá! Bem vindo ao jogo!
Esta é uma segunda linha de diálogo.
```

### Variáveis
Você pode usar variáveis no texto usando a sintaxe `{nome_variavel}`:
```
Olá {nome}! Você tem {moedas} moedas.
```

### Comandos
Comandos são escritos entre colchetes `[comando]`:

#### Definir Variável
```
[set nome "João"]
[set moedas 10]
[set nivel 1]
```

#### Aguardar Tempo
```
[wait 1.5]  # Aguarda 1.5 segundos
```

#### Pular para Label
```
[jump inicio]
[goto loja]
```

#### Emitir Sinal
```
[emit level_complete]
[signal player_died]
```

### Labels (Pontos de Salto)
Labels são definidos com `==nome_label==`:
```
==inicio==
Bem vindo ao início!

==loja==
Você entra na loja.
```

### Escolhas Múltiplas
```
O que você gostaria de fazer?

[choice "Opção 1" -> label1]
[choice "Opção 2" -> label2]
[choice "Opção 3" -> label3]
```

### Condicionais
```
[if nivel == "1"]
Você está no nível 1.
[endif]

[if moedas > 10]
Você tem muitas moedas!
[endif]
```

### Comentários
Linhas que começam com `#` são ignoradas:
```
# Este é um comentário
Bem vindo! # Comentário na mesma linha (será parte do texto)
```

## Exemplos de Uso

### Exemplo 1: Diálogo Simples com Variáveis
```
Bem vindo, {nome}!
Você está no nível {nivel}.

[set experiencia 100]
Sua experiência atual: {experiencia}

Continue sua jornada!
```

### Exemplo 2: Diálogo com Escolhas
```
==inicio==
O que você gostaria de fazer?

[choice "Explorar o mundo" -> explorar]
[choice "Ir à loja" -> loja]
[choice "Ver estatísticas" -> stats]

==explorar==
Você decide explorar o mundo.
Muitos segredos aguardam!

==loja==
Você entra na loja.
O comerciante te recebe!

==stats==
Nível: {nivel}
Moedas: {moedas}
Experiência: {exp}
```

### Exemplo 3: Diálogo com Condicionais
```
[if nivel == "1"]
Bem vindo ao nível 1!
Você está começando sua jornada.
[endif]

[if moedas >= 100]
Parabéns! Você tem {moedas} moedas!
Você está rico!
[endif]

[if vidas <= 1]
Cuidado! Você tem apenas {vidas} vida restante!
[endif]
```

### Exemplo 4: Diálogo Completo
```
# Diálogo de introdução do jogo

Bem vindo ao jogo, {nome}!

[wait 1.0]

Você tem {vidas} vidas e {moedas} moedas.

[set tutorial_completo false]

[if tutorial_completo == "false"]
Este é seu primeiro jogo? Vamos aprender!

[choice "Sim, preciso de ajuda" -> tutorial]
[choice "Não, já sei jogar" -> pular_tutorial]

==tutorial==
Vamos começar o tutorial...
[set tutorial_completo true]

==pular_tutorial==
Tudo bem! Vamos começar então!

[wait 0.5]

Boa sorte em sua aventura, {nome}!
```

## Uso no Código

### Carregar Arquivo DLS
```gdscript
var dialogue_box = preload("res://levels/DialogueBox.tscn").instantiate()
add_child(dialogue_box)

# Com variáveis iniciais
dialogue_box.show_dls_file("res://dialogues/welcome.dls", {
	"nome": "João",
	"nivel": 1,
	"moedas": 0,
	"vidas": 3
})
```

### Usar Conteúdo DLS Diretamente
```gdscript
var dialogue_box = preload("res://levels/DialogueBox.tscn").instantiate()
add_child(dialogue_box)

var dls_content = """
Bem vindo, {nome}!
[wait 1.0]
Você está no nível {nivel}.
"""

dialogue_box.show_dls_content(dls_content, {
	"nome": "João",
	"nivel": 1
})
```

### Método Antigo (Ainda Funciona)
```gdscript
# Método antigo - ainda funciona para compatibilidade
dialogue_box.show_dialogue("Bem vindo!")
```

## Sinais

O DialogueBox emite sinais que você pode conectar:

```gdscript
dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
dialogue_box.dls_signal.connect(_on_dls_signal)

func _on_dialogue_finished():
	print("Diálogo terminou!")

func _on_dls_signal(signal_name: String):
	match signal_name:
		"level_complete":
			print("Nível completo!")
		"player_died":
			print("Jogador morreu!")
```

## Operadores Suportados

- `==` - Igualdade
- `!=` - Diferente
- Variáveis simples são avaliadas como booleanas (verdadeiro se existir e tiver valor)

## Notas Importantes

1. Strings em comandos devem estar entre aspas duplas: `[set nome "João"]`
2. Labels são case-sensitive: `==inicio==` é diferente de `==Inicio==`
3. Escolhas devem ser consecutivas no arquivo DLS
4. Comentários com `#` devem estar em linhas separadas
5. O jogo é pausado automaticamente quando um diálogo é exibido

## Estrutura de Arquivos

Coloque seus arquivos `.dls` na pasta `dialogues/`:
```
dialogues/
  ├── welcome.dls
  ├── level1_intro.dls
  ├── level2_intro.dls
  └── README.md
```
