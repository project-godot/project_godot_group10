# Implementação do Interpretador DLS

## O que foi implementado

Foi criado um **interpretador completo de Dialogue Language Script (DLS)** para o projeto Godot, permitindo criar diálogos interativos avançados.

## Arquivos Criados

### 1. `managers/DLSParser.gd`
- Classe principal que interpreta arquivos DLS
- Suporta parsing de comandos, variáveis, labels, escolhas e condicionais
- Classe interna `DLSExecutor` para executar diálogos

### 2. `dialogues/welcome.dls`
- Exemplo de diálogo completo com escolhas múltiplas

### 3. `dialogues/level1_intro.dls`
- Exemplo de diálogo de introdução de nível

### 4. `dialogues/README.md`
- Documentação completa do formato DLS
- Exemplos de uso
- Guia de referência

## Arquivos Modificados

### 1. `levels/DialogueBox.gd`
- Adicionado suporte completo para DLS
- Mantida compatibilidade com o método antigo `show_dialogue()`
- Novos métodos:
  - `show_dls_file(file_path, variables)` - Carrega arquivo DLS
  - `show_dls_content(content, variables)` - Usa conteúdo DLS direto
- Suporte para escolhas múltiplas
- Sinais emitidos:
  - `dialogue_finished` - Quando o diálogo termina
  - `dls_signal(signal_name)` - Quando um comando [emit] é executado

### 2. `levels/DialogueBox.tscn`
- Adicionado container para escolhas múltiplas

### 3. `levels/Level1.gd`
- Atualizado para usar o novo sistema DLS

## Recursos do DLS

✅ **Texto simples** - Linhas de diálogo normais
✅ **Variáveis** - `{nome_variavel}` para substituição dinâmica
✅ **Comandos** - `[comando]` para ações
  - `[set var value]` - Define variável
  - `[wait tempo]` - Aguarda segundos
  - `[jump label]` - Salta para label
  - `[emit sinal]` - Emite sinal
✅ **Labels** - `==nome_label==` para pontos de salto
✅ **Escolhas** - `[choice "texto" -> label]` para múltiplas opções
✅ **Condicionais** - `[if condição] ... [endif]` para lógica condicional
✅ **Comentários** - `#` para anotações

## Como Usar

### Método 1: Arquivo DLS
```gdscript
var dialogue_box = preload("res://levels/DialogueBox.tscn").instantiate()
add_child(dialogue_box)
dialogue_box.show_dls_file("res://dialogues/welcome.dls", {
    "nome": "João",
    "nivel": 1
})
```

### Método 2: Conteúdo Direto
```gdscript
var dialogue_box = preload("res://levels/DialogueBox.tscn").instantiate()
add_child(dialogue_box)
dialogue_box.show_dls_content("""
Bem vindo, {nome}!
[wait 1.0]
Você está no nível {nivel}.
""", {"nome": "João", "nivel": 1})
```

### Método 3: Método Antigo (Compatível)
```gdscript
dialogue_box.show_dialogue("Bem vindo!")  # Ainda funciona!
```

## Exemplo de Arquivo DLS

```
# Diálogo de boas-vindas
Bem vindo ao jogo!

[set nome "Jogador"]
Seu nome é {nome}.

[choice "Explorar" -> explorar]
[choice "Lutar" -> lutar]

==explorar==
Você decide explorar.

==lutar==
Você decide lutar.
```

## Próximos Passos

1. Criar mais diálogos DLS para outros níveis
2. Conectar sinais do DLS a eventos do jogo
3. Adicionar mais comandos conforme necessário
4. Personalizar a UI do DialogueBox se necessário

## Compatibilidade

✅ **100% compatível** com código existente
✅ O método antigo `show_dialogue()` continua funcionando
✅ Nenhuma mudança breaking foi feita

