/// NPC desires and reputation
/// 
import std;

class BaseObject {
}

// https://streetsofrogue.fandom.com/wiki/NPC_Alignment

enum STATUS { /// Class affiliations
    UPPER, // aristocrat. guards like aristocrats.
    MID,
    LOWER // Hobo, slum dweller, etc
}
// [upper/poor] people hang out together unless overridden by class affiliation

enum CLASS { /// Class affiliations
    SOLDIER,
    MUTANT,
    COP,
    BUSINESSMAN,
    TRADER,
    BARTENDER,
    DRUGDEALER,
    MECHANIC,
    SCIENTIST,
} // probably need a 2d table of affiliations

class NPC{
    RelationshipHandler r;
    this(){
        }
    }

class RelationshipHandler {
    Relationship[] relationships;

    void applyRepTo(BaseObject to, float delta) {
    }

    float getRepFrom() {
        return 0;
    }

    Target whoIsNearestMeThatIHateTheMost(){
        return Target();
        }
}

enum REL {
    ALLY = 0,
    LOYAL,
    FRIENDLY,
    ALIGNED,
    NEUTRAL,
    SUBMISSIVE,
    IRRITATED, // "Get out of my building"
    ENEMY, // NPC will attack but eventually give up
    REVENGE // ? NPC will dedicate their existance to revenge
}

struct RepTag { // instance vs type??
    bool id;                ///
    float repChange;        /// how much rep value changed
    string* nameLookup;     /// text string description
    BaseObject* causedBy;   /// an item, person, etc.
    Target causedByTarget;
    string typeOfRep;
} // HOW do we handle deleted objects that caused something historically?

struct Relationship {
    REL rel;
}

struct Target {
    bool isPerson;
    bool isPlace;
    bool isThing;
    float x, y;
}

int main(){
    writeln("mod1 test");
    return 0;
    }