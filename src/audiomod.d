import std.stdio;
import std.conv;
import std.string;
import std.format;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;
import allegro5.allegro_audio;
import allegro5.allegro_acodec;

import molto;
import helper;
import main;

/// audio setup
alias aid = uint;
struct sampleInstance {
	bool isPositional = true;
	pair pos; // do we want a float position so we can smoothly move them?
	// this is in absolute space, correct? So we'll need an "ear"(ala "viewport") 
}

struct songInstance {
	bool isPlaying;
	int duration;
	sample s;
}

float linearDistance(float distance) {
	return distance;
}

float logDistance(float distance) {
	assert(false, "shit");
	return 9_325_902;
}

float squareDistance(float distance) {
	return distance * distance;
}

class audioSystem {
	pair earPos; // absolute x,y
	float function(float) distanceFunction = &squareDistance; // do we even need this as an option?
	float scaleFactor = 1.0f; // scaling factor. What do we scale? Total volume? Distance?

	sample*[string] samples;
	sample*[string] songs;

	sampleInstance[] activeSamples;
	sampleInstance[] musicTracks;

	sample* loadSample(string path) {
		if (AUDIO_ENABLED) {
			auto x = al_load_sample(path.toStringz);
			if (x is null)
				assert(0, "cannot load sample " ~ path);
			return x;
		}
		return null; //OOOOOOOHHHHHHH fixme todo bug
	}

	void loadResources() {
		if (AUDIO_ENABLED) {
			samples["hit"] = loadSample("./data/extra/snd/pixabay/karate-chop-6357.mp3");
			songs["intro"] = loadSample("./data/extra/snd/pixabay/male-screams-1-6080.mp3");
		}
	}

	void speak() {
		foreach (s; activeSamples) {
			// check if still playing, and keep playing if looping or whatever
		}
	}

	void logic() {
	}

	bool isLiveSample(sampleInstance* s) // an object checks if sample exists before trying to use any functions on it?
	{ // might be able to fold API into instancing so you cannot even get a dead pointer.
		// like you have a possiblePointer<> and only through checking it with the handler, can you get the real pointer
		// otherwise its dead/cleaned/whatever.

		if (s is null)
			return false; // if sample doesn't exist anymore.
		else
			return true;
	}

	void playSample(aid sound, float volumePercent) {
	}

	void playSample(aid sound, float volumePercent, int distance) //alternative name or just overload?
	{
	}

	void stopSample(sampleInstance* s) // how do we handle someone with a bad/stale pointer
	{ // also do we need this.
		// The only real place is say, a looping music file, and we could have music be its own set of functions.
	}

	string currentMusicTrack; // input into the associated array. so we know which specific one is playing.
	void startMusic(string name) {
	}

	void pauseMusic() {
	}

	void adjustMusicVolume(float percent) {
	}

	void stopMusic() {
	}

	void initialize() {
		if (AUDIO_ENABLED) {
			if (!al_init_acodec_addon())
				assert(0, "al_init_acodec_addon failed!");
			if (!al_install_audio())
				assert(0, "al_install_audio failed!");
			al_reserve_samples(32); //not sure how many
			sample* s = al_load_sample("./data/extra/snd/pixabay/karate-chop-6357.mp3");
			if (s is null)
				assert(0, "null sample, file not found likely.");
			auto sample_inst = al_create_sample_instance(s);
			if (sample_inst is null)
				assert(0, "null sample instance");
			al_set_sample_instance_playmode(sample_inst, ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_ONCE /*ALLEGRO_PLAYMODE_LOOP*/ );
			al_attach_sample_instance_to_mixer(sample_inst, al_get_default_mixer());
			al_play_sample_instance(sample_inst);
		}
		//		loadResources();
	}
}

audioSystem audio;
