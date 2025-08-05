import curses
import random
import time
import os
import itertools

# Symbols and constants
DOGE = "🐶🐶"
BOMB = "💣"
GOLD_BOMB = "💰💰"
HEART = "❤"
PAW = "🐾"
TITLE_NAME = "BombDodge: Save the Doge!"
HIGHSCORE_FILE = "highscore.txt"
DOG_VARIANTS = ["🐶", "🐕", "🦮", "🐩"]


def load_highscore():
    if os.path.exists(HIGHSCORE_FILE):
        with open(HIGHSCORE_FILE, 'r', encoding='utf-8') as f:
            try:
                return int(f.read())
            except ValueError:
                return 0
    return 0


def save_highscore(score):
    with open(HIGHSCORE_FILE, 'w', encoding='utf-8') as f:
        f.write(str(score))


def pause_game(stdscr, sh, sw):
    pause_msg = "⏸ Game Paused - Press any key to resume"
    stdscr.addstr(sh // 2, (sw - len(pause_msg)) // 2, pause_msg, curses.A_REVERSE)
    stdscr.refresh()
    stdscr.nodelay(False)
    stdscr.getch()
    stdscr.nodelay(True)


def difficulty_menu(stdscr, sh, sw):
    stdscr.nodelay(True)
    paw_frames = itertools.cycle([PAW * i + " " * (10 - i) for i in range(1, 6)] + [" " * 10] * 2)
    greeting = "Hello everyone!"
    prompt = "Choose difficulty level:"

    paw_positions = [0] * (sh - 4)
    dog_positions = [random.randint(1, sw - 2) for _ in range(5)]
    dog_y_positions = [random.randint(1, sh - 10) for _ in range(5)]

    name_tick = 0

    while True:
        paw = next(paw_frames)
        if name_tick % 5 == 0:
            title = f"{paw} ✨ {TITLE_NAME} ✨ {paw}"
        name_tick += 1

        stdscr.clear()
        stdscr.bkgd(' ', curses.color_pair(0))
        stdscr.addstr(sh // 2 - 5, (sw - len(title)) // 2, title, curses.A_BOLD)
        stdscr.addstr(sh // 2 - 3, (sw - len(greeting)) // 2, greeting)
        stdscr.addstr(sh // 2 - 1, (sw - len(prompt)) // 2, prompt)
        stdscr.addstr(sh // 2,     (sw - len("1. Easy    — Very Slow Start")) // 2, "1. Easy    — Very Slow Start")
        stdscr.addstr(sh // 2 + 1, (sw - len("2. Normal  — Default Speed")) // 2, "2. Normal  — Default Speed")
        stdscr.addstr(sh // 2 + 2, (sw - len("3. Hard    — Fast & Furious")) // 2, "3. Hard    — Fast & Furious")

        for i in range(len(paw_positions)):
            if random.random() < 0.03:
                paw_positions[i] = random.randint(1, sw - 2)
            if paw_positions[i] > 0:
                stdscr.addstr(i, paw_positions[i], PAW)
                paw_positions[i] = 0 if random.random() < 0.1 else paw_positions[i]

        for dx, dy in zip(dog_positions, dog_y_positions):
            stdscr.addstr(dy, dx, random.choice(DOG_VARIANTS))

        stdscr.refresh()
        time.sleep(0.1)
        key = stdscr.getch()
        if key == ord('1'):
            stdscr.nodelay(False)
            return 300
        elif key == ord('2'):
            stdscr.nodelay(False)
            return 150
        elif key == ord('3'):
            stdscr.nodelay(False)
            return 100


def main(stdscr):
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_WHITE, -1)
    curses.init_pair(2, curses.COLOR_RED, -1)
    curses.init_pair(3, curses.COLOR_YELLOW, -1)

    curses.curs_set(0)
    stdscr.nodelay(True)
    curses.mousemask(curses.ALL_MOUSE_EVENTS)

    sh, sw = stdscr.getmaxyx()
    highscore = load_highscore()
    speed = difficulty_menu(stdscr, sh, sw)

    level = 1
    score = 0
    lives = 3
    doge_x = sw // 2
    doge_y = sh - 2
    bombs = []

    stdscr.timeout(speed)

    stdscr.clear()
    splash_title = f"✨ {TITLE_NAME} ✨"
    stdscr.addstr(sh // 2 - 2, (sw - len(splash_title)) // 2, splash_title, curses.A_BOLD)
    stdscr.addstr(sh // 2, (sw - 26) // 2, "Press any key to start 🎮")
    stdscr.addstr(sh // 2 + 2, (sw - 20) // 2, f"High Score: {highscore}")
    stdscr.refresh()
    stdscr.getch()

    while True:
        stdscr.clear()
        stdscr.bkgd(' ', curses.color_pair(1))
        stdscr.border()

        lives_display = HEART * lives
        hud = f" Score: {score} | Level: {level} | Lives: "
        stdscr.addstr(1, 2, hud, curses.A_BOLD)
        stdscr.addstr(1, 2 + len(hud), lives_display, curses.color_pair(2) | curses.A_BOLD)
        hud2 = f" | High Score: {highscore} | Press 'p' to Pause | 'q' to Quit "
        stdscr.addstr(1, 2 + len(hud) + len(lives_display), hud2, curses.A_BOLD)

        stdscr.addstr(doge_y, doge_x, DOGE)

        roll = random.randint(1, 30)
        if roll <= 5:
            bombs.append(["bomb", 1, random.randint(1, sw - len(BOMB) - 1)])
        elif roll == 6:
            bombs.append(["gold", 1, random.randint(1, sw - len(GOLD_BOMB) - 1)])
        elif roll == 7 and lives < 5:
            bombs.append(["heart", 1, random.randint(1, sw - len(HEART) - 1)])

        new_bombs = []
        for item in bombs:
            item[1] += 1
            if item[1] < sh - 1:
                symbol = ""
                color = curses.color_pair(1)
                if item[0] == "bomb":
                    symbol = BOMB
                    color = curses.color_pair(2) | curses.A_BOLD
                elif item[0] == "gold":
                    symbol = GOLD_BOMB
                    color = curses.color_pair(3) | curses.A_BOLD
                elif item[0] == "heart":
                    symbol = HEART
                    color = curses.color_pair(2) | curses.A_BOLD

                stdscr.addstr(item[1], item[2], symbol, color)
                new_bombs.append(item)
        bombs = new_bombs

        for item in bombs[:]:
            if item[1] == doge_y and (doge_x <= item[2] <= doge_x + len(DOGE) - 1):
                bombs.remove(item)
                if item[0] == "bomb":
                    lives -= 1
                    curses.beep()  # 💥 sound when bomb hits
                elif item[0] == "gold":
                    score += 20
                elif item[0] == "heart":
                    if lives < 5:
                        lives += 1
                if lives <= 0:
                    if score > highscore:
                        save_highscore(score)
                        highscore = score
                    stdscr.clear()
                    msg = "💥 GAME OVER 💥"
                    stdscr.addstr(sh // 2 - 1, (sw - len(msg)) // 2, msg, curses.A_BOLD)
                    stdscr.addstr(sh // 2, (sw - 20) // 2, f"Final Score: {score}")
                    stdscr.addstr(sh // 2 + 1, (sw - 24) // 2, f"High Score: {highscore}")
                    stdscr.refresh()
                    time.sleep(3)
                    return

        key = stdscr.getch()
        if key == curses.KEY_LEFT and doge_x > 1:
            doge_x -= 2
        elif key == curses.KEY_RIGHT and doge_x < sw - len(DOGE) - 1:
            doge_x += 2
        elif key == ord('p'):
            pause_game(stdscr, sh, sw)
        elif key == ord('q'):
            break
        elif key == curses.KEY_MOUSE:
            try:
                _, mx, my, _, bstate = curses.getmouse()
                doge_x = max(1, min(mx, sw - len(DOGE) - 1))
                if bstate & curses.BUTTON1_CLICKED:
                    doge_x = max(1, min(doge_x + 3, sw - len(DOGE) - 1))
                elif bstate & curses.BUTTON3_CLICKED:
                    doge_x = max(1, min(doge_x - 3, sw - len(DOGE) - 1))
            except curses.error:
                pass

        score += 1
        if score % 50 == 0:
            level += 1
            speed = max(20, speed - 5)
            stdscr.timeout(speed)

        stdscr.refresh()


curses.wrapper(main)
