class Keyboard {
  foreign static isKeyDown(key)
}

class Mouse {
    init() {
        x = 0
        y = 0
        left = false
        right = false
        middle = false
    }

    foreign static poll

    foreign static x
    foreign static y
    foreign static left
    foreign static middle
    foreign static right
}

