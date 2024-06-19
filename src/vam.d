/+
	virtual asset manager
	VAM?
+/
import atlasmod;

// do we want to set a list of required textures, or a category?
// category is simpler. But if the category doesn't have all lookups then it still fails.

// DETECT DUPLICATES ERROR

class virtualManager {
	atlasHandler[] atlases; // all potential atlases register with us and use a common interface
	string[] deps;
	bool[] depSatisfied;

	bool checkAllDeps() {
		bool allGood = true;
		foreach (d; deps) {
			if (!isSatisfied(d)) {
				allGood = false;
			}
		}
		return allGood;
	}

	bool isSatisfied(string assetName) {
		bool hasFound = false;
		foreach (a; atlases) {
			if (a.hasResource(assetName)) {
				hasFound = true;
			}
		}
		return hasFound;
	}
}
