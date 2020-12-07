
//call to boot server
s.boot;

//loads all the soundfiles from the buffers
//the buffers contain all the percussive elements
(
~path = PathName(thisProcess.nowExecutingPath).parentPath++"buffers";
b = Dictionary.new;
PathName(~path).entries.do{
	arg subfolder;
	b.add(
		subfolder.folderName.asSymbol ->
		Array.fill(
			subfolder.entries.size,
			{
				arg i;
				Buffer.read(s, subfolder.entries[i].fullPath);
			}
		)
	);
};
)

//buffers randomly chosen for each rhythmic element
(
~kickBuffer = b[\kicks][0.rrand(b[\kicks].size - 1)];
~snareBuffer = b[\snares][0.rrand(b[\snares].size - 1)];
~clapBuffer = b[\claps][0.rrand(b[\claps].size - 1)];
~openHatBuffer = b[\openHats][0.rrand(b[\openHats].size - 1)];
~closedHatBuffer = b[\closedHats][0.rrand(b[\closedHats].size - 1)];
~percsBuffer = b[\percs][0.rrand(b[\percs].size - 1)];
~fxBuffer = b[\fx][0.rrand(b[\fx].size - 1)];
)

//tempo is set to the numerator in bpm
(
var tempo = 123.rrand(126);
TempoClock.default.tempo = tempo/60;
"Tempo is: ".post;
tempo.postln;
)

//run this block to change the scale (we only consider Major and Natural Minor)
(
var keys;
var index;
var val;
var scaleLowLow, scaleLow;
var scaleHigh, scaleHighHigh;
//65% chance of a minor scale, 35% chance of a major scale
~scale = Pwrand([Scale.major, Scale.minor], [0.35, 0.65], 1).asStream.next;
keys = ["Key is G Flat", "Key is G", "Key is A flat", "Key is A", "Key is B Flat", "Key is B", "Key is C", "Key is D flat", "Key is D", "Key is E flat", "Key is E", "Key is F"];
~key = -6.rrand(5);
keys.at(~key + 6).post;
" ".post;
~scale.name.postln;
~scale = ~scale.as(Array);
scaleLowLow = Array.new(7);
scaleLow = Array.new(7);
scaleHigh = Array.new(7);
scaleHighHigh = Array.new(7);
index = 0;
7.do({
	val = ~scale.at(index) + ~key + 36;
	scaleLowLow.add(val);
	val = ~scale.at(index) + ~key + 48;
	scaleLow.add(val);
	val = ~scale.at(index) + ~key + 72;
	scaleHigh.add(val);
	val = ~scale.at(index) + ~key + 84;
	scaleHighHigh.add(val);
	val = ~scale.at(index) + ~key + 60;
	~scale.put(index, val);
	index = index + 1;
});
~scale = scaleLowLow ++ scaleLow ++ ~scale ++ scaleHigh ++ scaleHighHigh;
~middleOfScale = 14;
~scale.debug("midi pitches in scale");
)


//band pass filtered saw synth created by Eli Fieldsteel
//I DID NOT MAKE THIS SYNTHDEF see https://youtu.be/lGs7JOOVjag?t=769
(
SynthDef(\bpfsaw, {
	arg atk=2, sus=0, rel=3, c1=1, c2=(-1), freq=500,
	detune=0.2, pan=0, cfhzmin=0.1, cfhzmax=0.3,
	cfmin=500, cfmax=2000, rqmin=0.1, rqmax=0.2,
	lsf=200, ldb=0, amp=1, out=0;
	var sig, env;
	env = EnvGen.kr(Env([0,1,1,0], [atk, sus, rel], [c1, 0, c2]), doneAction:2);
	sig = Saw.ar(freq * {LFNoise1.kr(0.5, detune).midiratio}!2);
	sig = BPF.ar(
		sig,
		{LFNoise1.kr(
			LFNoise1.kr(4).exprange(cfhzmin, cfhzmax)
		).exprange(cfmin, cfmax)}!2,
		{LFNoise1.kr(0.1).exprange(rqmin, rqmax)}!2
	);
	sig = BLowShelf.ar(sig, lsf, 0.5, ldb);
	sig = Balance2.ar(sig[0], sig[1], pan);
	sig = sig*env*amp;
	Out.ar(out, sig);
}).add;
)

//simple synthdef that allows us to play an audio file from the buffer
//you can also specify and envelope, buffer rate, and pan
(
SynthDef(\rbuf, {
	arg atk=0, sus=0, rel=3, c1=1,
	c2=(-1), buf=0, rate=1, amp=1,
	freq=440, pan=0, out=0;
	var sig, env;
	env = EnvGen.kr(Env([0,1,1,0], [atk,sus,rel], [c1, 0, c2]), doneAction:2);
	sig = PlayBuf.ar(2, buf, rate*BufRateScale.ir(buf));
	sig = sig*env;
	sig = Pan2.ar(sig, pan, amp);
	Out.ar(out, sig);
}).add;
)


//patterns used in composition
//some of these patterns (bass, snare) were not used in either composition
(
~kick = Pbind(
	\instrument, \rbuf,
	\dur, 1,
	\buf, ~kickBuffer,
	\freq, 60.midicps,
	\pan, rrand(-0.2, 0.2),
);

~openHat = Pbind(
	\instrument, \rbuf,
	\dur, Pseq([Rest(0.5),0.5], inf),
	\buf, ~openHatBuffer,
	\freq, 60.midicps,
	\pan, rrand(-0.2, 0.2),
);

~clapBasic = Pbind(
	\instrument, \rbuf,
	\dur, Pseq([Rest(1.0), 1.0], inf),
	\buf, ~clapBuffer,
	\freq, 60.midicps,
	\pan, rrand(-0.2, 0.2),
);

~clapLessBasic = Pbind(
	\instrument, \rbuf,
	\dur, Pseq([Rest(1.0), 1.0, Rest(1.0), 1.0, Rest(1.0), 1.0, Rest(1.0), 0.5, 0.25, 0.25], inf),
	\buf, ~clapBuffer,
	\freq, 60.midicps,
	\pan, rrand(-0.2, 0.2),
);

~closedHatEigth = Pbind(
	\instrument, \rbuf,
	\dur, Pn(Pfunc{ 0.05.coin.if { Rest(0.5) } { 0.5 }; }, inf),
	\buf, ~closedHatBuffer,
	\freq, 60.midicps,
	\pan, rrand(-0.4, 0.4),
);

~closedHatSixteenth = Pbind(
	\instrument, \rbuf,
	\dur, Pfunc{ 0.05.coin.if { Prand([Rest(0.5), Rest(0.25)]).asStream.next } { 0.25 }; },
	\buf, ~closedHatBuffer,
	\freq, 60.midicps,
	\pan, rrand(-0.4, 0.4),
);

~percs = Pbind(
	\instrument, \rbuf,
	\dur, Pfunc{ 0.05.coin.if { 0.5 } { Rest(0.5) }; },
	\buf, ~percsBuffer,
	\freq, 60.midicps,
	\pan, rrand(-0.4, 0.4),
);

~snare = Pbind(
	\instrument, \rbuf,
	\dur, Pfunc{ 0.05.coin.if { Rest(0.25) } { 0.25 }; },
	\buf, ~snareBuffer,
	\freq, 60.midicps,
	\pan, rrand(-0.5, 0.5),
	\amp, exprand(0.1, 0.15),
);

~fx = Pbind(
	\instrument, \rbuf,
	\dur, 8,
	\buf, ~fxBuffer,
	\freq, ~scale.at(~middleOfScale),
	\pan, rrand(-0.5, 0.5),
	\amp, 0.5
);

//sawtooth pad that plays a random chord every 4 beats
//the slow, ultraSlow, and fast pads all have a randomized detune parameter
~slowPad = Pbind(
	\instrument, \bpfsaw,
	\dur, 4,
	\midinote, Prand([
		[
			~scale.at(~middleOfScale - 7), ~scale.at(~middleOfScale + 6),
			~scale.at(~middleOfScale + 8), ~scale.at(~middleOfScale + 9),
			~scale.at(~middleOfScale + 11)
		],
		[
			~scale.at(~middleOfScale + 2), ~scale.at(~middleOfScale + 8),
			~scale.at(~middleOfScale + 10), ~scale.at(~middleOfScale + 11),
			~scale.at(~middleOfScale + 13)
		],
		[
			~scale.at(~middleOfScale - 5),
			~scale.at(~middleOfScale + 2), ~scale.at(~middleOfScale + 8),
			~scale.at(~middleOfScale + 10), ~scale.at(~middleOfScale + 11),
			~scale.at(~middleOfScale + 13)
		],
		[
			~scale.at(~middleOfScale - 8), ~scale.at(~middleOfScale + 5),
			~scale.at(~middleOfScale + 7), ~scale.at(~middleOfScale + 8),
			~scale.at(~middleOfScale + 10)
		],
		[
			~scale.at(~middleOfScale - 9), ~scale.at(~middleOfScale + 4),
			~scale.at(~middleOfScale + 6), ~scale.at(~middleOfScale + 7),
			~scale.at(~middleOfScale + 9)
		]
	], inf), //Pseq for controlled
	\detune, Pwhite(0.02, 0.08),
	\cfmin, 100,
	\cfmax, 1500,
	\atk, 0,
	\sus, 2,
	\rel, 2,
	\ldb, 10,
	\amp, 0.2,
	\out, 0,
);

//saw tooth pad that plays a random chord every 8 beats
~ultraSlowPad = Pbind(
	\instrument, \bpfsaw,
	\dur, 8,
	\midinote, Prand([
		[
			~scale.at(~middleOfScale - 7), ~scale.at(~middleOfScale + 6),
			~scale.at(~middleOfScale + 8), ~scale.at(~middleOfScale + 9),
			~scale.at(~middleOfScale + 11)
		],
		[
			~scale.at(~middleOfScale + 2), ~scale.at(~middleOfScale + 8),
			~scale.at(~middleOfScale + 10), ~scale.at(~middleOfScale + 11),
			~scale.at(~middleOfScale + 13)
		],
		[
			~scale.at(~middleOfScale - 5),
			~scale.at(~middleOfScale + 2), ~scale.at(~middleOfScale + 8),
			~scale.at(~middleOfScale + 10), ~scale.at(~middleOfScale + 11),
			~scale.at(~middleOfScale + 13)
		],
		[
			~scale.at(~middleOfScale - 8), ~scale.at(~middleOfScale + 5),
			~scale.at(~middleOfScale + 7), ~scale.at(~middleOfScale + 8),
			~scale.at(~middleOfScale + 10)
		],
		[
			~scale.at(~middleOfScale - 9), ~scale.at(~middleOfScale + 4),
			~scale.at(~middleOfScale + 6), ~scale.at(~middleOfScale + 7),
			~scale.at(~middleOfScale + 9)
		]
	], inf),
	\detune, Pwhite(0.02, 0.08),
	\cfmin, 100,
	\cfmax, 1500,
	\atk, 0,
	\sus, 4,
	\rel, 4,
	\ldb, 10,
	\amp, 0.2,
	\out, 0,
);

//sawtooth pad that plays a random chord every 2 beats
~fastPad = Pbind(
	\instrument, \bpfsaw,
	\dur, 2,
	\midinote, Prand([
		[
			~scale.at(~middleOfScale - 7), ~scale.at(~middleOfScale + 6),
			~scale.at(~middleOfScale + 8), ~scale.at(~middleOfScale + 9),
			~scale.at(~middleOfScale + 11)
		],
		[
			~scale.at(~middleOfScale + 2), ~scale.at(~middleOfScale + 8),
			~scale.at(~middleOfScale + 10), ~scale.at(~middleOfScale + 11),
			~scale.at(~middleOfScale + 13)
		],
		[
			~scale.at(~middleOfScale - 5),
			~scale.at(~middleOfScale + 2), ~scale.at(~middleOfScale + 8),
			~scale.at(~middleOfScale + 10), ~scale.at(~middleOfScale + 11),
			~scale.at(~middleOfScale + 13)
		],
		[
			~scale.at(~middleOfScale - 8), ~scale.at(~middleOfScale + 5),
			~scale.at(~middleOfScale + 7), ~scale.at(~middleOfScale + 8),
			~scale.at(~middleOfScale + 10)
		],
		[
			~scale.at(~middleOfScale - 9), ~scale.at(~middleOfScale + 4),
			~scale.at(~middleOfScale + 6), ~scale.at(~middleOfScale + 7),
			~scale.at(~middleOfScale + 9)
		]
	], inf),
	\detune, Pwhite(0.02, 0.08),
	\cfmin, 100,
	\cfmax, 1500,
	\atk, 0,
	\sus, 1,
	\rel, 1,
	\ldb, 0,
	\amp, 0.2,
	\out, 0,
);


//pad that plays a random chord that lasts for a random amount of beats (2,4,8) with a random pan value from all the way left to all the way right
~suppPad = Pbind(
	\instrument, \apadMH,
	\dur, Prand([2,4,8], inf), //2 for controlled
	\midinote, Prand([
		[
			~scale.at(~middleOfScale) - 21, ~scale.at(~middleOfScale + 6) - 21,
			~scale.at(~middleOfScale + 8) - 21
		],
		[
			~scale.at(~middleOfScale - 1) - 21, ~scale.at(~middleOfScale + 5) - 21,
			~scale.at(~middleOfScale + 7) - 21
		],
	], inf), //for controlled remove the - 21 and change to Pseq
	\atk, 2,
	\dec, 1,
	\sus, 3,
	\rel, 1,
	\pan, Pwhite(-1.0, 1.0),
	\amp, 0.05,
	\out, 0,
);

//simple bass pattern
~bass = Pbind(
	\instrument, \ikedaBass,
	\dur, Pseq([
		2
	], inf),
	\midinote, Pseq([
			~scale.at(~middleOfScale - 7) - 14, ~scale.at(~middleOfScale - 7) - 14,
			~scale.at(~middleOfScale - 5) - 14, ~scale.at(~middleOfScale - 5) - 14,
			~scale.at(~middleOfScale - 8) - 14, ~scale.at(~middleOfScale - 8) - 14,
			~scale.at(~middleOfScale - 9) - 14, ~scale.at(~middleOfScale - 9) - 14
	], inf),
	\legato, 0.8,
);

//simple bass pattern
~bassLessBasic = Pbind(
	\instrument, \ikedaBass,
	\dur, Pseq([1, 2, Rest(1)], inf),
	\midinote, Pseq([
			~scale.at(~middleOfScale - 7) - 14, ~scale.at(~middleOfScale - 7) - 14,
		Rest(1),
			~scale.at(~middleOfScale - 5) - 14, ~scale.at(~middleOfScale - 5) - 14,
		Rest(1),
			~scale.at(~middleOfScale - 8) - 14, ~scale.at(~middleOfScale - 8) - 14,
		Rest(1),
			~scale.at(~middleOfScale - 9) - 14, ~scale.at(~middleOfScale - 9) - 14,
		Rest(1)
	], inf),
	\legato, 0.8,
);

//more complex tech house style bass pattern
~bassLessLessBasic = Pbind(
	\instrument, \ikedaBass,
	\dur, Pseq([1, 1, 2/3, 2/3, 2/3], inf),
	\midinote, Pseq([
			~scale.at(~middleOfScale - 7) - 14, ~scale.at(~middleOfScale - 5) - 14,
			~scale.at(~middleOfScale - 7) - 14, ~scale.at(~middleOfScale - 7) - 14,
		 	~scale.at(~middleOfScale - 5) - 14,
	], inf),
	\atk, 0.01,
	\rel, 0,
	\dec, 0.5,
	\sus, Pseq([1, 1, 2/3, 2/3, 2/3], inf),
	\legato, 0.8,
);

//random percussive droplet like sound with random panning (either 50% left or 50% right)
~dribble = Pbind(
	\instrument, \bpfsaw,
	\dur, 4,
	\midinote, Pseq([
		~scale.at(~middleOfScale), ~scale.at(~middleOfScale),
		~scale.at(~middleOfScale + 2), ~scale.at(~middleOfScale + 2),
		~scale.at(~middleOfScale - 1), ~scale.at(~middleOfScale - 1),
		~scale.at(~middleOfScale - 2), ~scale.at(~middleOfScale - 2)
	], inf), //Pseq for controlled
	\rqmin, 0.005,
	\rqmax, 0.008, //0.008 for controlled
	\cfmin, 300,
	\cfmax, 1000,
	\freq, 10,
	\pan, Prand([-0.5, 0.5], inf),
	\atk, 0,
	\rel, 0,
	\sus, 2,
	\amp, 1.5,
	\out, 0,
);

//melodic saw pattern that plays a random note every 2 beats with a random panning and amplitude
~melSaw = Pbind(
	\instrument, \bpfsaw,
	\dur, Prand([2,4], inf),
	\midinote, Prand([
		~scale.at(~middleOfScale + 7),
		~scale.at(~middleOfScale + 11),
		~scale.at(~middleOfScale + 9),
		~scale.at(~middleOfScale + 8),
		~scale.at(~middleOfScale + 6),
		~scale.at(~middleOfScale + 5),
		~scale.at(~middleOfScale + 2),
		~scale.at(~middleOfScale),
		[~scale.at(~middleOfScale + 2) + 7, ~scale.at(~middleOfScale + 9) + 7],
		[~scale.at(~middleOfScale + 5) + 7, ~scale.at(~middleOfScale + 12) + 7],
		[~scale.at(~middleOfScale + 4) + 7, ~scale.at(~middleOfScale + 11) + 7]
	], inf), //Pseq for controlled
	\detune, 0.08, //0.008 for controlled
	\cfmin, 100,
	\cfmax, 150,
	\pan, Prand([-0.2, 0.2], inf),
	\atk, 0,
	\sus, 4,
	\rel, 0,
	\ldb, 6,
	\amp, Pwhite(0.4, 0.7),
	\out, 0,
);

//melodic lead that plays a random note of random length (2, 4, 8 beats) with random panning and random amplitude
~melLead = Pbind(
	\instrument, \cs80leadMH,
	\dur, Prand([2,4,8], inf), //2 for controlled
	\midinote, Prand([
		~scale.at(~middleOfScale),
		~scale.at(~middleOfScale + 4),
		~scale.at(~middleOfScale + 2),
		~scale.at(~middleOfScale),
		~scale.at(~middleOfScale - 1),
		~scale.at(~middleOfScale - 1),
		~scale.at(~middleOfScale - 2),
		~scale.at(~middleOfScale),
	], inf), //Pseq for controlled
	\pan, Prand([-0.2, 0.2], inf),
	\amp, Pwhite(0.05, 0.1),
	\out, 0,
);
)
//random composition
//run this code to play the composition
(
var timeline = ScTimeline();
timeline.schedBeat(0, 192, ~ultraSlowPad, "ultra slow pad", Color.blue);
timeline.schedBeat(0, 272, ~dribble, "dribble", Color.red);
timeline.schedBeat(16, 224, ~melSaw, "mel saw 1", Color.green);
timeline.schedBeat(16, 224, ~melSaw, "mel saw 2", Color.green);
timeline.schedBeat(32, 240, ~melSaw, "mel saw 6 ", Color.green);
timeline.schedBeat(48, 256, ~melSaw, "mel saw 9", Color.green);
timeline.schedBeat(17, 225, ~melSaw, "mel saw 3", Color.green);
timeline.schedBeat(33, 241, ~melSaw, "mel saw 7", Color.green);
timeline.schedBeat(18, 226, ~melSaw, "mel saw 4", Color.green);
timeline.schedBeat(34, 242, ~melSaw, "mel saw 8", Color.green);
timeline.schedBeat(50, 224, ~melSaw, "mel saw 10", Color.green);
timeline.schedBeat(19, 227, ~melSaw, "mel saw 5", Color.green);
timeline.schedBeat(48, 240, ~fastPad, "fast pad", Color.blue);
timeline.schedBeat(96, 240, ~slowPad, "slow pad", Color.blue);
timeline.schedBeat(96, 224, ~melLead, "mel lead 1", Color.grey);
timeline.schedBeat(96, 225, ~melLead, "mel lead 2", Color.grey);
timeline.schedBeat(97, 226, ~melLead, "mel lead 3", Color.grey);
timeline.schedBeat(98, 226, ~melLead, "mel lead 4", Color.grey);
timeline.schedBeat(192, 272, ~suppPad, "supp pad", Color.cyan);
timeline.plot;
timeline.play;
)

//less random composition
//run this code to play the composition
(
var timeline = ScTimeline();
timeline.schedBeat(0, 93, ~slowPad, "pad slow", Color.blue);
timeline.schedBeat(16, 192, ~dribble, "dribble", Color.red);
timeline.schedBeat(16, 96, ~melSaw, "mel saw 1", Color.green);
timeline.schedBeat(16, 96, ~melSaw, "mel saw 2", Color.green);
timeline.schedBeat(32, 96, ~melSaw, "mel saw 3", Color.green);
timeline.schedBeat(32, 96, ~openHat, "open hat", Color.grey);
timeline.schedBeat(32, 48, ~clapBasic, "clap basic", Color.grey);
timeline.schedBeat(48, 64, ~clapLessBasic, "clap less basic", Color.grey);
timeline.schedBeat(48, 96, ~kick, "kick", Color.grey);
timeline.schedBeat(48, 96, ~percs, "percs", Color.grey);
timeline.schedBeat(48, 80, ~closedHatEigth, "closedHatEigth", Color.grey);
timeline.schedBeat(48, 96, ~melLead, "mel lead", Color.green);
timeline.schedBeat(64, 80, ~clapBasic, "clap basic", Color.grey);
timeline.schedBeat(64, 96, ~fx, "fx", Color.red);
timeline.schedBeat(80, 96, ~closedHatSixteenth, "closedHatSixteenth", Color.grey);
timeline.schedBeat(80, 96, ~clapLessBasic, "clap less basic", Color.grey);
timeline.schedBeat(96, 160, ~suppPad, "strings", Color.green);
timeline.schedBeat(96, 144, ~clapBasic, "clap basic", Color.grey);
timeline.schedBeat(128, 160, ~kick, "kick", Color.grey);
timeline.schedBeat(128, 192, ~slowPad, "pad slow", Color.blue);
timeline.schedBeat(128, 176, ~melSaw, "mel saw 1", Color.green);
timeline.schedBeat(128, 176, ~openHat, "open hat", Color.grey);
timeline.schedBeat(128, 176, ~melSaw, "mel saw 2", Color.green);
timeline.schedBeat(144, 160, ~clapLessBasic, "clap less basic", Color.grey);
timeline.schedBeat(144, 160, ~melSaw, "mel saw 3", Color.green);
timeline.schedBeat(144, 160, ~melSaw, "mel saw 4", Color.green);
timeline.schedBeat(160, 176, ~clapBasic, "clap basic", Color.grey);
timeline.plot;
timeline.play;
)