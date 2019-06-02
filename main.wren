import "input" for Keyboard
import "graphics" for Canvas, Color, ImageData, Point
import "audio" for AudioEngine
import "random" for Random
import "game" for Exit
import "./test"

import "io" for FileSystem

// Consider moving Box to "graphics"
class Box {
  construct new(x1, y1, x2, y2) {
    _p1 = Point.new(x1, y1)
    _p2 = Point.new(x2, y2)
  }

  x1 { _p1.x }
  y1 { _p1.y }
  x2 { _p2.x }
  y2 { _p2.y }
}

// -------------------------
// ------- GAME CODE -------
// -------------------------

class Game {
  static init() {
    __state = MainGame
    __state.init()
    __done = false

    __loadSettingsOp = FileSystem.load("setup.sh")
    System.print(__loadSettingsOp.result.length)
  }
  static update() {

    if (__loadSettingsOp.complete && !__done) {
      __settingsFile = __loadSettingsOp.result
      __done = true
      System.print("loaded")
      System.print(__settingsFile.data)
    }

    __state.update()
    if (__state.next) {
      __state = __state.next
      __state.init()
    }
  }
  static draw(dt) {
    __state.draw(dt)
  }
}

class Explosion {
  construct new(x, y) {
    _x = x + OurRandom.int(6)-3
    _y = y + OurRandom.int(6)-3
    _c = [Color.red, Color.orange][OurRandom.int(2)]
    _t = 0
  }

  x { _x }
  y { _y }
  done { _t > 5 }

  update() {
    _t = _t + 1
  }

  draw() {
    Canvas.circlefill(_x, _y, _t, _c)
  }
}

class Star {

  construct new() {
    _x = OurRandom.int(Canvas.width)
    _y = OurRandom.int(Canvas.height)
    _s = OurRandom.float()
  }

  x { _x }
  y { _y }

  update() {
    _y = _y + 0.25 + _s
    if (_y > Canvas.height) {
      _x = OurRandom.int(Canvas.width)
      _y = 0
    }
  }

  draw() {
    Canvas.pset(_x, _y, Color.lightgray)
  }
}

class Bullet {

  construct fire(x, y) {
    _x = x
    _y = y
    _alive = true
  }
  x { _x }
  y { _y }
  h { 2 }
  w { 2 }
  alive { _alive }

  kill() {
    _alive = false
  }

  update() {
    _y = _y - 3
  }

  draw() {
    var color = Color.white
    Canvas.rectfill(_x, _y, 2, 2, Color.white)
    Canvas.rectfill(_x, _y+2, 2, 4, Color.darkgray)
  }
}

class Enemy {
  construct new(x, y) {
    _x = x
    _y = y
    _alive = true
    _image = ImageData.loadFromFile("res/enemy.png")
  }

  alive { _alive }
  x { _x }
  y { _y }
  h { 8 }
  w { 6 }

  kill() {
    _alive = false
  }

  update() {
    _y = _y + 1
  }

  draw() {
    if (alive) {
      Canvas.draw(_image, x, y)
    }
  }
}


class Ship {
  construct new() {
    _x = Canvas.width / 2
    _y = Canvas.height - 20
    _imm = false
    _health = 3
    _t = 0
    _ship = [
      ImageData.loadFromFile("res/ship1.png"),
      ImageData.loadFromFile("res/ship2.png")
    ]
  }

  x { _x }
  y { _y }
  h { 8 }
  w { 6 }
  health { _health }
  imm { _imm }

  damage() {
    if (!_imm) {
      _health = _health - 1
      _imm = true
      _t = 0
    }
  }

  move(x, y) {
    _x = _x + x
    _y = _y + y
    _t = _t + 1
    if (_imm && _t > 30) {
      _imm = false
    }
  }

  draw(t) {
    var frame = (t / 5).floor % 2
    if (_health > 0 && !_imm || (_t/4).floor % 2 == 0) {
      Canvas.draw(_ship[frame], _x, _y)
    }

  }
}
var OurRandom = Random.new(12345)

class MainGame {
  static next { __next}

  static init() {
    __next = null
    __w = 5
    __h = 5
    __t = 0
    __points = 0

    __ship = Ship.new()
    __bullets = []
    __enemies = []
    __explosions = []
    __stars = []

    for (i in 0...30) {
      __stars.add(Star.new())
    }

    for (i in 0...5) {
      __enemies.add(Enemy.new(OurRandom.int(Canvas.width), -OurRandom.int(30)))
    }
    __lastFire = 0
    __heart = ImageData.loadFromFile("res/heart-full.png")
    __heartEmpty = ImageData.loadFromFile("res/heart-empty.png")
    AudioEngine.load("fire", "res/Laser_Shoot.wav")
    AudioEngine.load("explosion", "res/Explosion.wav")
    AudioEngine.load("music", "res/around-the-corner.ogg")
    // AudioEngine.load("music", "res/music.wav")

    __channel = AudioEngine.play("music", 1, true, -0.5)
  }

  static update() {
    __t = __t + 1
    var x = 0
    var y = 0
    AudioEngine.setChannelPan(__channel, (((__t / 60) % 20) * 0.1) - 1 )
    if (__ship.health > 0) {
      if (Keyboard.isKeyDown("left")) {
        x = -1
      }
      if (Keyboard.isKeyDown("right")) {
        x = 1
      }
      if (Keyboard.isKeyDown("up")) {
        y = -1
      }
      if (Keyboard.isKeyDown("down")) {
        y = 1
      }
      if (Keyboard.isKeyDown("space")) {
        if ((__t - __lastFire) > 10) {
          __bullets.add(Bullet.fire(__ship.x+2, __ship.y))
          __lastFire = __t
          AudioEngine.play("fire")
        }
      }
    }
    // TODO: Remove this and embed it in main engine
    // AudioEngine.update()

    __ship.move(x, y)

    for (enemy in __enemies) {
      enemy.update()
      if (!__ship.imm && colliding(__ship, enemy)) {
        __ship.damage()
        enemy.kill()
        AudioEngine.play("explosion")
        for (i in 1..5) {
          __explosions.add(Explosion.new(enemy.x, enemy.y))
        }
      }
    }
    if (__ship.health == 0 && __explosions.count == 0) {
      __next = GameOverState
      AudioEngine.stopAllChannels()
    }

    var bulletCount = 0
    for (bullet in __bullets) {
      bullet.update()

      // check if we hit something
      for (enemy in __enemies) {
        if (enemy.alive && colliding(bullet, enemy)) {
          bullet.kill()
          enemy.kill()
          AudioEngine.play("explosion")
          for (i in 1..5) {
            __explosions.add(Explosion.new(enemy.x, enemy.y))
          }
          __points = __points + 1
        }
      }
    }

    __bullets = __bullets.where {|bullet|
      return bullet.alive && bullet.y > 0
    }.toList
    __enemies = __enemies.where {|enemy|
      var isAlive = enemy.alive && enemy.y < Canvas.height
      if (!isAlive) {
        __enemies.add(Enemy.new(OurRandom.int(Canvas.width), 0))
      }
      return isAlive
    }.toList

    __explosions = __explosions.where {|explosion|
      explosion.update()
      return !explosion.done
    }.toList

    for (star in __stars) {
      star.update()
    }
  }

  static colliding(o1, o2) {
    var box1 = Box.new(o1.x, o1.y, o1.x + o1.w, o1.y+o1.h)
    var box2 = Box.new(o2.x, o2.y, o2.x + o2.w, o2.y+o2.h)
    return box1.x1 < box2.x2 &&
      box1.x2 > box2.x1 &&
      box1.y1 < box2.y2 &&
      box1.y2 > box2.y1
  }

  static draw(dt) {
    Canvas.cls()
    __stars.each {|star| star.draw() }
    __enemies.each {|enemy| enemy.draw() }
    __bullets.each {|bullet| bullet.draw() }
    __ship.draw(__t)
    __explosions.each {|explosion| explosion.draw() }

    Canvas.rectfill(0,0, 320,10, Color.black)
    // Draw UI
    for (i in 1..3) {
      if (i <= __ship.health) {
        Canvas.draw(__heart, 292+6*i, 3)
      } else {
        Canvas.draw(__heartEmpty, 292+6*i, 3)
      }
    }

    Canvas.print("Score: %(__points)", 3, 3, Color.white)
  }
}

// State displays a "Game Over" message and allows a restart
class GameOverState {
  static next { __next}
  static init() {
    __next = null
    __hold = 0
  }
  static update() {
    if (Keyboard.isKeyDown("space")) {
      __hold = __hold + 1
      if (__hold > 4) {
        __next = MainGame
      }
    } else if(Keyboard.isKeyDown("q")) {
        Exit.exit
    } else {
      __hold = 0
    }
  }

  static draw(dt) {
    Canvas.cls()
    Canvas.print("Game Over", 160-27, 120-3, Color.white)
  }
}
