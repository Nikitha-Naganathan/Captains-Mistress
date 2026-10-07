# Captains-Mistress

> A polished arcade-style Connect Four game built with Godot, featuring local multiplayer, computer opponents, animated gameplay, and a web-playable version.

<p align="center">

**[▶️ PLAY ONLINE](https://nikitha-naganathan.github.io/Captains-Mistress/)**

</p>

---

## About the Project

**Captains-Mistress** is a modern arcade-inspired take on the classic **Connect Four** game.

The project focuses on combining traditional game mechanics with an engaging visual experience, animated interactions, multiple game modes, and computer-controlled opponents with different difficulty levels.

The game is designed around a 1280 × 720 (16:9) layout and developed using the Godot Engine.

Connnect-4 was initially named as "Captain's Mistress" in the olden days, hence I chose this name.

---

## Key Features

* Classic 6 × 7 Connect Four gameplay
* 2 Player local multiplayer
* Play against the computer
* Easy difficulty
* Medium difficulty
* Hard difficulty
* Animated falling discs
* Four-in-a-row detection
* Horizontal, vertical, and diagonal win detection
* Win animations and confetti effects
* Gameplay sound effects
* Keyboard and mouse controls
* Arcade-inspired visual design
* Web-playable version through GitHub Pages
* Windows desktop build

---

## Game Modes

### Computer

Challenge the computer across three difficulty levels:

| Difficulty | Description                                              |
| ---------- | -------------------------------------------------------- |
| **Easy**   | Makes mostly random moves with occasional defensive play |
| **Medium** | Prioritizes winning moves and blocks immediate threats   |
| **Hard**   | Uses board evaluation and strategic decision-making      |

###  2 Players

Play locally against another player on the same computer.

###  Play Online

> Planned feature: online multiplayer will be added in a future version.

---

##  Controls

### Mouse

Click the column where you want to drop your disc.

### Keyboard

Use the number keys:

`1  2  3  4  5  6  7`

Each number corresponds to its respective column.

---

## How to Play

1. Player 1 uses **Red** discs.
2. Player 2 or the computer uses **Yellow** discs.
3. Players take turns dropping one disc into a column.
4. The disc falls to the lowest available position.
5. The first player to connect **four discs in a row** wins.
6. Four discs can be connected:

   * Horizontally
   * Vertically
   * Diagonally
7. If the board fills without a winner, the game ends in a draw.

---

## 🛠️ Built With

| Technology             | Purpose                             |
| ---------------------- | ----------------------------------- |
| **Godot Engine 4.7.2** | Game engine                         |
| **GDScript**           | Game logic and AI                   |
| **GitHub**             | Version control and project hosting |
| **GitHub Pages**       | Web deployment                      |

---

##  Project Structure

```text
Captains-Mistress/
│
├── new-game-project/
│   ├── Assets/
│   │   ├── Audio/
│   │   └── Fonts/
│   │
│   ├── Exports/
│   │   └── Web build
│   │
│   ├── Scenes/
│   │   └── game.tscn
│   │
│   ├── Scripts/
│   │   └── game.gd
│   │
│   └── project.godot
│
├── index.html
└── README.md
```

---

##  Running the Project Locally

### Requirements

* Godot **4.7.2** or compatible Godot 4.x version
* Git

### Steps

1. Clone the repository:

```bash
git clone https://github.com/Nikitha-Naganathan/Captains-Mistress.git
```

2. Open the project in Godot.

3. Open:

```text
new-game-project/project.godot
```

4. Run the project from Godot.

---

##  Play in the Browser

The web version is deployed using **GitHub Pages**.

### ▶️ [Play Captains-Mistress Online](https://nikitha-naganathan.github.io/Captains-Mistress/)

No installation is required for the web version.

---

##  Design

The game uses an arcade-machine inspired aesthetic with:

* Dark cabinet styling
* Neon-inspired interface elements
* Animated transitions
* Dynamic turn indicators
* Win effects and confetti
* Custom fonts
* Game-specific sound effects

The visual design was created to make a traditional board game feel more like a playable arcade experience.

---

##  Game Logic

The game maintains a 6 × 7 board matrix where:

```text
0 → Empty
1 → Player 1
2 → Player 2 / Computer
```

After every move, the game checks possible winning sequences in four directions:

```text
Horizontal  →
Vertical    ↓
Diagonal    ↘
Diagonal    ↗
```

The computer opponent evaluates possible moves based on the selected difficulty.

---

## Future Development

Planned improvements include:

* Real-time online multiplayer
* Player statistics
* Leaderboards
* Additional arcade themes
* Player profiles
* Improved computer AI
* Additional game modes

---

## Developer

**Nikitha Naganathan**

BTech Computer Science Engineering
VIT Vellore

---

##  Project Status

**Current version:** `v1.0`

The core Connect Four gameplay, local multiplayer, computer modes, animations, sound effects, and web deployment are implemented.

Online multiplayer is planned for a future release.

---

##  Feedback

If you try the game, feedback and suggestions are welcome!
