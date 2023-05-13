package;

import Song.SwagSong;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.effects.FlxFlicker;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.mouse.FlxMouseEventManager;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	public static var instance:FreeplayState;
	public var acceptInput:Bool = true;

	var songs:Array<SongMetadataEvil> = [];

	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var sayori:FlxSprite;
	var natsuki:FlxSprite;
	var yuri:FlxSprite;

	var sayoritween:FlxTween;
	var natsukitween:FlxTween;
	var yuritween:FlxTween;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	var songname:FlxText;
	var vignette:FlxSprite;

	var bg:FlxSprite;

	var isCharting:Bool = false;

	public static var songData:Map<String, Array<SwagSong>> = [];

	public static function loadDiff(diff:Int, name:String, array:Array<SwagSong>)
	{
		try
		{
			array.push(Song.loadFromJson(Highscore.formatSong(name, diff), name));
		}
		catch (ex)
		{
		}
	}

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		instance = this;

		PlayState.isStoryMode = false;

		#if FEATURE_DISCORD
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('data/freeplay/badEnding'));

		for (i in 0...initSonglist.length)
		{
			var data:Array<String> = initSonglist[i].split(':');
			var meta = new SongMetadataEvil(data[0], Std.parseInt(data[2]), data[1]);

			var diffs = [];
			loadDiff(0, meta.songName, diffs);
			loadDiff(1, meta.songName, diffs);
			loadDiff(2, meta.songName, diffs);
			songData.set(meta.songName, diffs);

			songs.push(meta);
		}

		var space = new FlxBackdrop(Paths.image('bigmonika/SkyEvil', 'doki'));
		space.scrollFactor.set(0.1, 0.1);
		space.velocity.set(-7, 0);
		space.antialiasing = SaveData.globalAntialiasing;
		space.scale.set(0.7, 0.7);
		add(space);

		bg = new FlxSprite().loadGraphic(Paths.image('bigmonika/BG', 'doki'));
		bg.setPosition(-239, -3);
		bg.antialiasing = SaveData.globalAntialiasing;
		add(bg);

		natsuki = new FlxSprite().loadGraphic(Paths.image('freeplay/badending/natsu', 'preload'));
		natsuki.setPosition(37, 0);
		natsuki.antialiasing = SaveData.globalAntialiasing;
		add(natsuki);

		yuri = new FlxSprite().loadGraphic(Paths.image('freeplay/badending/yuri', 'preload'));
		yuri.setPosition(177, 0);
		yuri.antialiasing = SaveData.globalAntialiasing;
		add(yuri);

		sayori = new FlxSprite().loadGraphic(Paths.image('freeplay/badending/sayso', 'preload'));

		vignette = new FlxSprite(0, 0).loadGraphic(Paths.image('menuvignette'));
		vignette.alpha = 0.8;
		add(vignette);

		sayori.setPosition(107, 0);
		sayori.antialiasing = SaveData.globalAntialiasing;
		add(sayori);

		songname = new FlxText(0, 550, 0, 'hueh', 72);
		songname.screenCenter(X);
		songname.font = LangUtil.getFont('animal');
		songname.color = 0xFFFFFFFF;
		songname.setBorderStyle(OUTLINE, FlxColor.BLACK, 3, 1);
		songname.antialiasing = SaveData.globalAntialiasing;
		add(songname);

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 50, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		add(scoreText);

		if (curSelected >= songs.length)
			curSelected = 0;

		changeSelection();

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song / Press M to open the Modifiers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press M to open the Modifiers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.screenCenter(X);
		text.scrollFactor.set();
		add(text);
		
		#if android
		addVirtualPad(FULL, A_B);
		#end

		super.create();
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new SongMetadataEvil(songName, weekNum, songCharacter));
	}

	var instPlaying:Int = -1;

	private static var vocals:FlxSound = null;

	override function update(elapsed:Float)
	{
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		scoreText.text = 'PERSONAL BEST: ' + lerpScore;
		positionHighscore();

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;
		var accepted = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE;

		if (FlxG.keys.pressed.SHIFT)
			isCharting = true;
		else
			isCharting = false;

		if (acceptInput)
		{
			if (rightP)
			{
				changeSelection(-1);
			}
			if (leftP)
			{
				changeSelection(1);
			}

			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuStateBad());
			}

			if (FlxG.keys.justPressed.M)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				openSubState(new DokiModifierSubState());
			}

			if (space && !SaveData.cacheSong)
				playSong();
			else if (accepted)
				startsong();
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);
	}

	public function startsong()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));

		if (SaveData.flashing)
		{
			switch (songs[curSelected].songName.toLowerCase())
			{
				case 'stagnant':
					FlxFlicker.flicker(sayori, 1, 0.06, false, false, function(flick:FlxFlicker)
					{
						loadSong();
					});
				case 'home':
					FlxFlicker.flicker(natsuki, 1, 0.06, false, false, function(flick:FlxFlicker)
					{
						loadSong();
					});
				case 'markov':
					FlxFlicker.flicker(yuri, 1, 0.06, false, false, function(flick:FlxFlicker)
					{
						loadSong();
					});
				default:
					FlxFlicker.flicker(sayori, 1, 0.06, false, false, function(flick:FlxFlicker)
					{
						loadSong();
					});
			}
		}
		else
		{
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				loadSong();
			});
		}
	}

	function loadSong()
	{
		var poop:String = Highscore.formatSong(songs[curSelected].songName, curDifficulty);

		PlayState.isStoryMode = false;

		try
		{
			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			PlayState.storyDifficulty = curDifficulty;
		}
		catch (e)
		{
			poop = Highscore.formatSong(songs[curSelected].songName, 1);
			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			PlayState.storyDifficulty = 1;
		}

		PlayState.storyWeek = songs[curSelected].week;

		if (FlxG.keys.pressed.P)
			PlayState.practiceMode = true;

		// force disable dialogue
		if (FlxG.keys.pressed.F)
			PlayState.ForceDisableDialogue = true;

		if (isCharting)
			LoadingState.loadAndSwitchState(new ChartingState());
		else
			LoadingState.loadAndSwitchState(new PlayState());
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		#end

		getSongData(songs[curSelected].songName, curDifficulty);

		if (SaveData.cacheSong)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.stop();
				FlxG.sound.music.destroy();
				FlxG.sound.music = null;
			}

			playSong();
		}

		PlayState.storyWeek = songs[curSelected].week;

		songname.text = songs[curSelected].songName.toLowerCase();
		songname.screenCenter(X);

		if (sayoritween != null)
		{
			sayoritween.cancel();
			natsukitween.cancel();
			yuritween.cancel();	
		}


		switch (songs[curSelected].songName.toLowerCase())
		{
			case 'stagnant':
				yuritween = FlxTween.tween(yuri, {x: 177}, 0.25);
				natsukitween = FlxTween.tween(natsuki, {x: 37}, 0.25);

				yuritween = FlxTween.color(yuri, 0.25, yuri.color, 0xFF444444);
				natsukitween = FlxTween.color(natsuki, 0.25, natsuki.color, 0xFF444444);
				sayoritween = FlxTween.color(sayori, 0.25, sayori.color, 0xFFffffff);
			case 'home':
				yuritween = FlxTween.tween(yuri, {x: 177}, 0.25);
				natsukitween = FlxTween.tween(natsuki, {x: 107}, 0.25);

				yuritween = FlxTween.color(yuri, 0.25, yuri.color, 0xFF444444);
				natsukitween = FlxTween.color(natsuki, 0.25, natsuki.color, 0xFFffffff);
				sayoritween = FlxTween.color(sayori, 0.25, sayori.color, 0xFF444444);
			case 'markov':
				yuritween = FlxTween.tween(yuri, {x: 107}, 0.25);
				natsukitween = FlxTween.tween(natsuki, {x: 37}, 0.25);

				yuritween = FlxTween.color(yuri, 0.25, yuri.color, 0xFFffffff);
				natsukitween = FlxTween.color(natsuki, 0.25, natsuki.color, 0xFF444444);
				sayoritween = FlxTween.color(sayori, 0.25, sayori.color, 0xFF444444);
			default:
				yuritween = FlxTween.tween(yuri, {x: 177}, 0.25);
				natsukitween = FlxTween.tween(natsuki, {x: 37}, 0.25);

				yuritween = FlxTween.color(yuri, 0.25, yuri.color, 0xFF444444);
				natsukitween = FlxTween.color(natsuki, 0.25, natsuki.color, 0xFF444444);
				sayoritween = FlxTween.color(sayori, 0.25, sayori.color, 0xFF444444);
		}

	}

	function playSong()
	{
		FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), SaveData.cacheSong ? 0 : 1);

		var hmm;
		try
		{
			hmm = songData.get(songs[curSelected].songName)[0]; // curDifficulty
			if (hmm != null)
				Conductor.changeBPM(hmm.bpm);
		}
		catch (ex)
		{
			Conductor.changeBPM(102);
		}
	}

	function getSongData(songName:String, diff:Int)
	{
		intendedScore = Highscore.getScore(songName, diff);
	}

	private function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
	}
}

class SongMetadataEvil
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";

	public function new(song:String, week:Int, songCharacter:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
	}
}
