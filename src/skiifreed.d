module skiifreed;
import helper, g, atlas;
import molto;
import viewportsmod;

class SkierObject : GameObject{
    this(pair _pos){
        super(_pos);
        }
}

enum DIR2{
        UP = 0, DOWN, LEFT, RIGHT,              // 4 dir
        DOWNLEFT, DOWNRIGHT, UPLEFT, UPRIGHT,   // 8 dir
        DOWNDOWNLEFT, DOWNDOWNRIGHT             // 10? dir (two extra turning ones)
    }

class GameObject{
    pair pos;
    pair velocity;
    bmp* sprite; /// placeholder one sprite
    bmp[]* sprites;

    this(pair _pos){
        pos = _pos;
        bmp = bh["blimp"];
        }

    void onTick(){
        }
    
    /// draw object: returns 1 if clipped
    bool onDraw(viewport v){
        return 0;
        }

    void actionUp(){}
    void actionDown(){}
    void actionLeft(){}
    void actionRight(){}

    void actionFire(){}
    void actionJump(){}
    void actionSelect(){}
    void actionButton4(){}
/+
    void actionButton5(){} // L button
    void actionButton6(){} // R button
    void actionButton7(){} // start
    void actionButton8(){} // select

    // D up, down, left, right  4
    // L/R thumb triggers       2

    // L/R trigger axis 2x
+/

    }