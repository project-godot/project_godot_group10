# Arkenfall - O Sacrifício do Cavaleiro Rubro

## 📖 Sobre o Jogo

**Arkenfall** é um jogo de plataforma 2D desenvolvido em Godot que conta a história épica de Arken, um cavaleiro que veste a coragem de um manto rubro e é o último da Guarda Real.

### A História

Havia um tempo em que as estrelas brilhavam mais forte sobre o reino de Éden. Mas a escuridão chegou, vinda das profundezas sob a Grande Caverna, despertando um exército de ossos. O mal não desejava riqueza, apenas que a vida parasse de se mover.

Arken, um cavaleiro que vestia a coragem de um manto rubro, era o último da Guarda Real. Sua armadura estava amassada e seu estoque de poções era pequeno, mas seu coração era a forja de uma fé inabalável. Ele não lutava por reis ou glória, mas pela pequena vila que o criara, pelos risos que ele ainda podia lembrar, e pela certeza de que o amanhã devia existir.

Ele avança pela planície verdejante, o espectro da morte balançando uma lâmina fria, e desce à escuridão da Caverna de Lava, onde cada passo é um risco e a esperança é uma brasa que precisa ser protegida. Cada esqueleto que tomba não é apenas um inimigo destruído, mas um sacrifício pessoal para comprar um dia a mais de sol para as pessoas que ele jurou proteger.

Arken não sabe se voltará, mas sabe que, enquanto ele estiver de pé, o último vestígio de luz e coragem em Éden ainda vive. Ele é a ponte de ferro entre a escuridão e o amanhecer, e a jornada de Arkenfall é a de um único herói em pé contra o inevitável, por amor e dever.

### 🎯 Objetivo de Desenvolvimento Sustentável (ODS)

Este jogo está alinhado com o **ODS 16: Paz, Justiça e Instituições Eficazes**, representando a luta de um herói solitário para proteger sua comunidade contra forças da escuridão, simbolizando a importância da justiça, proteção dos vulneráveis e manutenção da paz através da coragem e do dever.

---

## 👥 Informações do Projeto

- **Grupo:** 10

---

## 🛠️ Informações Técnicas

### Engine e Tecnologias

- **Engine:** Godot 4.4
- **Linguagem de Programação:** GDScript
- **Renderização:** Forward Plus
- **Tipo de Projeto:** 2D Platformer

### Requisitos do Sistema

#### Mínimos

- **Sistema Operacional:** Windows 10/11, Linux, ou macOS
- **Processador:** Dual-core 2.0 GHz
- **Memória RAM:** 4 GB
- **Placa de Vídeo:** Compatível com OpenGL 3.3 / DirectX 11
- **Espaço em Disco:** 500 MB

#### Recomendados

- **Sistema Operacional:** Windows 10/11, Linux, ou macOS
- **Processador:** Quad-core 2.5 GHz ou superior
- **Memória RAM:** 8 GB ou superior
- **Placa de Vídeo:** Dedicada com suporte a OpenGL 4.0 / DirectX 11
- **Espaço em Disco:** 1 GB

### Para Desenvolvimento

- **Godot Engine:** Versão 4.4 ou superior
- **Editor de Código:** Qualquer editor compatível (recomendado: Visual Studio Code com extensão Godot)

---

## 📁 Estrutura do Projeto

O projeto está organizado de forma modular e bem estruturada:

```
project_godot_group10/
│
├── assets/                    # Recursos do jogo
│   ├── fonts/                # Fontes utilizadas
│   ├── images/               # Imagens e texturas
│   ├── items/                # Itens coletáveis (moedas, plataformas móveis)
│   ├── Scripts/              # Scripts auxiliares (transições, plataformas)
│   ├── skins/                # Sprites do personagem principal
│   ├── sprites/              # Sprites de inimigos, decorações e terreno
│   └── tiles/                # Tilesets para construção de níveis
│
├── dialogues/                 # Arquivos de diálogo (formato DLS)
│   └── level1_intro.dls
│
├── entities/                  # Entidades do jogo
│   ├── enemies/              # Inimigos (skeleton, minotaur, king, etc.)
│   ├── Player/               # Personagem principal (Arken)
│   └── Player2/              # Personagem alternativo (desbloqueável)
│
├── levels/                    # Níveis e interfaces do jogo
│   ├── Level1.gd / level1.tscn
│   ├── Level2.gd / level2.tscn
│   ├── Level3.gd / level3.tscn
│   ├── DialogueBox.gd        # Sistema de diálogos
│   ├── HealthDisplay.gd      # Exibição de vida
│   ├── ScoreDisplay.gd       # Exibição de pontuação
│   ├── PauseMenu.gd          # Menu de pausa
│   ├── GameOverMenu.gd       # Menu de game over
│   └── VictoryMenu.gd        # Menu de vitória
│
├── main/                      # Menus principais
│   ├── MainMenu.gd           # Menu principal
│   ├── LevelSelect.gd        # Seleção de níveis
│   ├── Shop.gd               # Loja de itens
│   └── Controls.tscn         # Tela de controles
│
├── managers/                  # Gerenciadores do sistema
│   ├── GameManager.gd        # Gerenciador principal (autoload)
│   ├── LevelManager.gd       # Gerenciador de níveis (autoload)
│   └── DLSParser.gd          # Parser de diálogos
│
├── sounds/                    # Arquivos de áudio
│   ├── Músicas de fundo
│   └── Efeitos sonoros
│
├── project.godot              # Arquivo de configuração do projeto
└── README.md                  # Este arquivo
```

### Arquitetura do Código

O jogo utiliza uma arquitetura baseada em **singletons (autoload)** para gerenciamento global:

- **GameManager:** Gerencia estado global do jogo (moedas, vida, progresso)
- **LevelManager:** Controla desbloqueio e progressão de níveis

Os scripts principais seguem o padrão de herança do Godot:

- `CharacterBody2D` para o player e inimigos
- `Node2D` para níveis
- `Control` para interfaces de usuário
- `Node` para gerenciadores

---

## 📥 Instalação

### Pré-requisitos

1. **Godot Engine 4.4** ou superior
   - Download disponível em: https://godotengine.org/download
   - Escolha a versão apropriada para seu sistema operacional

### Passo a Passo

1. **Clone ou baixe o repositório**

   ```bash
   git clone <url-do-repositorio>
   cd project_godot_group10
   ```

   Ou baixe o arquivo ZIP e extraia em uma pasta de sua preferência.

2. **Abra o projeto no Godot**

   - Inicie o Godot Engine
   - Clique em "Import" ou "Importar"
   - Navegue até a pasta do projeto
   - Selecione o arquivo `project.godot`
   - Clique em "Import & Edit" ou "Importar e Editar"

3. **Configure o projeto (se necessário)**

   - O projeto já está configurado com as cenas principais
   - A cena principal está definida em `project.godot` como `main/MainMenu.tscn`
   - Os autoloads (GameManager e LevelManager) já estão configurados

4. **Execute o jogo**
   - Pressione `F5` ou clique no botão "Play" no editor
   - O jogo será executado na cena principal (Menu)

### Verificação da Instalação

Após abrir o projeto, verifique se:

- ✅ Não há erros no console do Godot
- ✅ A cena `main/MainMenu.tscn` carrega corretamente
- ✅ Os autoloads aparecem na aba "Remote" do debugger

---

## 🎮 Como Jogar

### Controles

#### Movimento

- **A / Seta Esquerda:** Mover para a esquerda
- **D / Seta Direita:** Mover para a direita
- **W / Espaço / Seta Para Cima:** Pular

#### Combate

- **Botão Esquerdo do Mouse:** Atacar
- **Botão Direito do Mouse:** Defender (bloqueia 100% do dano)

#### Sistema

- **ESC:** Pausar o jogo / Voltar ao menu

### Objetivos do Jogo

1. **Sobreviver:** Mantenha-se vivo enfrentando os inimigos que surgem
2. **Coletar Moedas:** Colete todas as moedas espalhadas pelos níveis
3. **Derrotar Inimigos:** Elimine esqueletos e outras criaturas da escuridão
4. **Progredir:** Complete os níveis para desbloquear novas áreas
5. **Proteger Éden:** Cada inimigo derrotado é um passo a mais na proteção da vila

### Mecânicas Principais

#### Sistema de Vida

- O jogador possui **10 pontos de vida** (5 corações completos)
- Cada coração representa **2 pontos de vida**
- Ao receber dano, a vida diminui
- Se a vida chegar a 0, o jogador morre e pode respawnar (se houver vidas restantes)
- Ao cair do mapa, o jogador perde 0.5 de vida e respawna automaticamente

#### Sistema de Combate

- **Ataque:** Pressione o botão esquerdo do mouse para atacar
  - O ataque tem um tempo de "windup" antes de causar dano
  - Cada ataque causa 1 ponto de dano nos inimigos
  - Inimigos já atingidos não podem ser atingidos novamente no mesmo ataque
- **Defesa:** Mantenha pressionado o botão direito do mouse para defender
  - A defesa bloqueia 100% do dano recebido
  - O jogador pode se mover enquanto defende (mas mais lentamente)
  - A defesa não consome recursos

#### Sistema de Invencibilidade

- Após receber dano, o jogador fica invencível por **0.6 segundos**
- Durante a invencibilidade, o personagem pisca (efeito visual)
- Este sistema previne dano contínuo de múltiplos inimigos

#### Sistema de Moedas

- Moedas são coletadas ao tocar nelas
- Cada moeda coletada aumenta o contador de moedas
- As moedas são salvas automaticamente
- Use as moedas na loja para desbloquear personagens alternativos

#### Sistema de Progressão

- Complete um nível coletando todas as moedas
- Ao completar um nível, o próximo é desbloqueado automaticamente
- O jogo possui **3 níveis** no total
- O progresso de moedas é mantido entre sessões

### Dicas de Jogabilidade

1. **Use a defesa estrategicamente:** Bloquear ataques é essencial para sobreviver
2. **Gerencie sua vida:** Evite cair do mapa, pois isso reduz sua vida
3. **Explore os níveis:** Moedas podem estar em locais escondidos
4. **Aprenda os padrões dos inimigos:** Cada inimigo tem comportamentos diferentes
5. **Economize moedas:** Guarde moedas para desbloquear o Player 2 na loja (60 moedas)

---

## ⚙️ Sistemas do Jogo

### Sistema de Vida e Corações

O sistema de vida utiliza um valor numérico (float) que representa pontos de vida:

- **Máximo:** 10 pontos (5 corações)
- **Exibição:** Interface mostra corações visuais (cada coração = 2 pontos)
- **Dano:** Inimigos causam 0.5 pontos de dano por contato
- **Respawn:** Ao morrer, o jogador respawna com vida máxima se ainda houver vidas globais

**Implementação:**

- Gerenciado pelo `GameManager` (vida global)
- Controlado pelo script `player.gd` (vida local do nível)
- Exibido pelo `HealthDisplay.gd` na interface

### Sistema de Moedas e Economia

O jogo possui um sistema de economia baseado em moedas:

- **Coleta:** Moedas são coletadas ao tocar no objeto
- **Armazenamento:** Moedas são salvas automaticamente em arquivo
- **Persistência:** O progresso é mantido entre sessões
- **Uso:** Moedas podem ser gastas na loja para desbloquear personagens

**Implementação:**

- `GameManager.collect_coin()`: Adiciona moedas ao contador
- `GameManager.save_game()`: Salva progresso em `user://savegame.save`
- `GameManager.load_game()`: Carrega progresso ao iniciar

### Sistema de Níveis e Desbloqueios

O jogo possui 3 níveis progressivos:

- **Nível 1:** Desbloqueado desde o início
- **Nível 2:** Desbloqueado ao completar o Nível 1
- **Nível 3:** Desbloqueado ao completar o Nível 2

**Implementação:**

- `LevelManager.unlock_next_level()`: Desbloqueia o próximo nível
- `LevelManager.get_max_unlocked_level()`: Retorna o nível máximo desbloqueado
- Cada nível possui sua própria cena e script (`Level1.gd`, `Level2.gd`, `Level3.gd`)

### Sistema de Combate

O combate é baseado em ataques corpo a corpo:

- **Ataque do Jogador:**

  - Windup: 0.1 segundos
  - Janela ativa: 0.18 segundos
  - Dano: 1 ponto por ataque
  - Hitbox posicionada na frente do personagem

- **Defesa:**

  - Bloqueia 100% do dano
  - Permite movimento reduzido
  - Sem custo de recursos

- **Inimigos:**
  - Cada inimigo possui seu próprio script e comportamento
  - Diferentes tipos: skeleton, bigskeleton, minotaur, king, necromancer, samurai, soldier, nightmare
  - Cada um possui padrões de movimento e ataque únicos

**Implementação:**

- Sistema de ataque com área de detecção (`AttackArea2D`)
- Lista de inimigos já atingidos para evitar múltiplos hits
- Sistema de invencibilidade após receber dano

### Sistema de Diálogos

O jogo utiliza um sistema de diálogos customizado (DLS - Dialogue Script):

- **Formato:** Arquivos `.dls` com sintaxe própria
- **Parser:** `DLSParser.gd` processa os arquivos de diálogo
- **Recursos:** Suporta variáveis, esperas e formatação

**Exemplo de uso:**

```gdscript
dialogue_box.show_dls_file("res://dialogues/level1_intro.dls", {
    "nivel": 1,
    "vidas": GameManager.player_health
})
```

### Sistema de Save/Load

O jogo salva automaticamente o progresso:

- **Dados salvos:**
  - Total de moedas coletadas
- **Localização:** `user://savegame.save`
- **Formato:** ConfigFile do Godot

**Implementação:**

- `GameManager.save_game()`: Salva dados em arquivo
- `GameManager.load_game()`: Carrega dados ao iniciar
- Salvamento automático ao coletar moedas

### Sistema de Inimigos

Cada tipo de inimigo possui características únicas:

- **Skeleton:** Inimigo básico, movimento simples
- **Big Skeleton:** Versão maior e mais resistente
- **Minotaur:** Inimigo poderoso com barra de vida
- **King:** Chefe com múltiplas fases
- **Necromancer:** Inimigo mágico com ataques especiais
- **Samurai:** Inimigo rápido com ataques precisos
- **Soldier:** Inimigo com padrão de combate
- **Nightmare:** Criatura temática da escuridão

Todos os inimigos herdam de `CharacterBody2D` e implementam o método `take_damage()`.

---

## 🌍 ODS 16 - Paz, Justiça e Instituições Eficazes

### Relação com o Objetivo de Desenvolvimento Sustentável

**Arkenfall** está alinhado com o **ODS 16: Paz, Justiça e Instituições Eficazes** através de sua narrativa e mecânicas de jogo.

#### Representação no Jogo

1. **Proteção da Comunidade:**

   - Arken luta para proteger sua vila natal, representando a importância de instituições que protegem os cidadãos
   - O jogador assume o papel de guardião, defendendo os vulneráveis contra forças da escuridão

2. **Justiça e Dever:**

   - O cavaleiro não luta por glória pessoal, mas por um senso de dever e justiça
   - Cada inimigo derrotado representa a manutenção da ordem e da paz

3. **Resiliência e Perseverança:**

   - Mesmo sendo o último da Guarda Real, Arken continua lutando
   - Isso simboliza a importância de instituições eficazes que persistem mesmo em tempos difíceis

4. **Sacrifício pelo Bem Comum:**
   - A narrativa enfatiza o sacrifício pessoal pelo bem da comunidade
   - Cada ação do jogador contribui para a proteção de Éden

#### Mensagem Educativa

O jogo transmite valores importantes:

- **Responsabilidade:** O jogador é responsável pela proteção da vila
- **Coragem:** Enfrentar desafios mesmo quando as chances são pequenas
- **Justiça:** Lutar contra forças que ameaçam a paz e a vida
- **Perseverança:** Continuar lutando mesmo quando tudo parece perdido

Através da experiência interativa, os jogadores vivenciam a importância de instituições que protegem a paz e a justiça, compreendendo que cada indivíduo tem um papel a desempenhar na manutenção da ordem e da segurança de sua comunidade.

---

## 🔧 Desenvolvimento

### Tecnologias Utilizadas

- **Godot Engine 4.4:** Motor de jogo open-source
- **GDScript:** Linguagem de script nativa do Godot
- **Forward Plus Rendering:** Pipeline de renderização moderno

### Estrutura de Código

O código segue boas práticas de desenvolvimento:

- **Modularidade:** Código organizado em módulos específicos
- **Reutilização:** Scripts genéricos para funcionalidades comuns
- **Sinais:** Comunicação entre objetos através do sistema de sinais do Godot
- **Autoloads:** Gerenciadores globais para estado compartilhado

### Padrões de Design Utilizados

- **Singleton Pattern:** GameManager e LevelManager como instâncias únicas
- **Observer Pattern:** Sistema de sinais para comunicação entre objetos
- **State Pattern:** Estados do jogador (idle, attacking, defending, hurt, dead)
- **Component Pattern:** Entidades compostas por múltiplos nós e scripts

---

## 📚 Créditos e Referências

### Assets Utilizados

- **Sprites:** Recursos de sprites de personagens, inimigos e ambiente
- **Fontes:** Golden Varsity Outline, Maketa-Normal-FFP

### Referências

- **Godot Engine Documentation:** https://docs.godotengine.org/
- **GDScript Reference:** https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html

### Licença

Este projeto foi desenvolvido para fins educacionais como parte de um trabalho acadêmico do Grupo 10.

---

## 📞 Contato e Suporte

Para questões sobre o projeto, entre em contato com o Grupo 10.

---

_"Enquanto ele estiver de pé, o último vestígio de luz e coragem em Éden ainda vive."_
