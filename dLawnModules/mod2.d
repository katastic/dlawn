module mod2;

struct bitmap {
}

bitmap* bmpSkier;

struct pair {
    float x, y;
}

class Viewport {
}

class Component {
    void setup() { /// initial setup
    }

    void onTick() {
    }

    bool onDraw(Viewport V) {
        return 0;
    }
}

class PhysicsCom : Component {
    pair pos; // physics?
    pair vel; // physics?

    override void onTick() {

    }

    pair getPos() {
        return pos;
    }

    pair getVel() {
        return vel;
    }
}

class SkiierPhysicsCom : PhysicsCom {
    override void onTick() {
        pos.x += vel.x;
        pos.y += vel.y;
    }
}

class AICom : Component {
}

class AudioCom : Component {
}

class GraphicsCom : Component {
}

struct ButtonSnoop {
    bool isPressed;
    bool* source;

    void onTick() {
        isPressed = *source;
    }
}

struct AxisSnoop {
    float isPressed;
    float* source;

    void onTick() {
        isPressed = *source;
    }
}

class InputHandler {
    bool[256] keys;

    void eventCallback() {
    }
}

InputHandler inputhandler;

class InputCom : Component {
    ButtonSnoop up;
    ButtonSnoop down;
    ButtonSnoop left;
    ButtonSnoop right;
    ButtonSnoop fire;
    ButtonSnoop jump;
    ButtonSnoop special1;
    ButtonSnoop special2;

    float axisHorizontal;
    float axisVertical;
    float axisLeftBumper;
    float axisRightBumper;

    bool isDown() {
        return true;
    }

    override void onTick() {
        // update values
        //inputhandler()lkgfn
    }
}

class UnitBase {
    InputCom input;
    AICom ai;
    PhysicsCom physics;
    GraphicsCom gfx;
    AudioCom audio;

    this() {
    }

    void onTick() {
    }

    bool onDraw(Viewport V) {
        return 0;
    }
}

enum DIR {
    UP, // 1
    DOWN,
    LEFT,
    RIGHT, // 4
    UPLEFT,
    UPRIGHT,
    DOWNRIGHT,
    DOWNLEFT // 8
}

struct CircularInt {
    int val;
    int min;
    int max;

    void set() {
    }

    void add(int value) {
        if (val + value > max) { // NOTE: if this exceeds container.max, it will fail.
            val += value - max;
        } else {
            val += value;
        }
    }
}

struct ClampedInt {
    int val;
    int min;
    int max;
    this(_value, _min, _max) {
        val = _value;
        min = _min;
        max = _max;
    }
}

class Animation {
    DIR dir;
    int frame;
    int frameMax;
}

class UnitGraphicsCom : GraphicsCom {
    bitmap* bmp;

    bool onDraw(Viewport v) { /// draw bmp
    }
}

class AnimatedUnitGraphicsCom : GraphicsCom {
    //bitmap* bmp;
    Animation anim;
    bool onDraw(Viewport v) {
        // draw anim
    }

    void nextFrame() {
        frame++;
        if (frame > frameMax)
            frame = 0;
    }
}

class SkiierGraphicsCom : UnitGraphicsCom {
    override void setup() {
        bmp = bmpSkier;
    }
}

class Skiier : UnitBase {
    this() {
        input = new InputCom();
        ai = new AICom();
        physics = new PhysicsCom();
        gfx = new UnitGraphicsCom();
        audio = new AudioCom();
        super();
    }

    override void onTick() {
        input.onTick();
        ai.onTick();
        physics.onTick();
        gfx.onTick();
        audio.onTick();
    }

    override void onDraw(Viewport v) {
        gfx.onDraw(v);
        }
}

int main() {
    Skiier sk;
    return 0;
}
