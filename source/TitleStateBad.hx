package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.Assets;
import shaders.ColorMaskShader;

using StringTools;

class TitleStateBad extends MusicBeatState
{
	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var textGroup:FlxGroup;

	var tbdSpr:FlxSprite;

	var curWacky:Array<String> = [];

	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		persistentUpdate = true;

		curWacky = FlxG.random.getObject(getIntroTextShit());

		startIntro();

		super.create();
	}

	var logoBl:FlxSprite;
	var backdrop:FlxBackdrop;
	var scanline:FlxBackdrop;
	var gradient:FlxSprite;
	var titleText:FlxSprite;

	function startIntro()
	{
		if (!initialized)
		{
			FlxG.sound.playMusic(Paths.music('menuEvil'), 0);
			Conductor.changeBPM(82.5);
			FlxG.sound.music.fadeIn(2, 0, 0.7);
		}

		backdrop = new FlxBackdrop(Paths.image('scrolling_BG'));
		backdrop.velocity.set(-10, 0);
		backdrop.antialiasing = SaveData.globalAntialiasing;
		//backdrop.shader = new ColorMaskShader(0xFFFDEBF7, 0xFFFDDBF1);
		add(backdrop);

		var scanline:FlxBackdrop = new FlxBackdrop(Paths.image('credits/scanlines', 'doki'));
		scanline.velocity.set(0, 20);
		scanline.antialiasing = SaveData.globalAntialiasing;
		add(scanline);

		var gradient:FlxSprite = new FlxSprite().loadGraphic(Paths.image('badending/gradent', 'doki'));
		gradient.antialiasing = SaveData.globalAntialiasing;
		gradient.scrollFactor.set(0.1, 0.1);
		gradient.screenCenter();
		gradient.setGraphicSize(Std.int(gradient.width * 1.4));
		add(gradient);

		logoBl = new FlxSprite(0, 0);
		logoBl.frames = Paths.getSparrowAtlas('logoBadEnding');
		logoBl.antialiasing = SaveData.globalAntialiasing;
		logoBl.setGraphicSize(Std.int(logoBl.width * 0.8));
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, true);
		logoBl.updateHitbox();
		logoBl.screenCenter();
		add(logoBl);
		logoBl.animation.play('bump', true);

		titleText = new FlxSprite(170, FlxG.height * 0.8);
		titleText.frames = Paths.getSparrowAtlas('titleEnterEvil', 'preload', true);
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = SaveData.globalAntialiasing;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		tbdSpr = new FlxSprite(0, FlxG.height * .45).loadGraphic(Paths.image('TBDLogoBW'));
		tbdSpr.visible = false;
		tbdSpr.setGraphicSize(Std.int(tbdSpr.width * 0.9));
		tbdSpr.updateHitbox();
		tbdSpr.screenCenter(X);
		tbdSpr.antialiasing = SaveData.globalAntialiasing;
		add(tbdSpr);

		if (initialized)
			skipIntro();
		else
			initialized = true;
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('data/introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
			swagGoodArray.push(i.split('--'));

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		var pressedEnter:Bool = controls.ACCEPT || FlxG.mouse.justPressed;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		if (pressedEnter && !transitioning && skippedIntro)
		{
			if (SaveData.flashing)
				titleText.animation.play('press');

			FlxG.camera.flash(FlxColor.WHITE, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			transitioning = true;

			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				MusicBeatState.switchState(new MainMenuStateBad());
			});
		}

		if (pressedEnter && !skippedIntro && initialized)
			skipIntro();

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 200;
			credGroup.add(money);
			textGroup.add(money);
		}
	}

	function addMoreText(text:String)
	{
		var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 60) + 200;
		credGroup.add(coolText);
		textGroup.add(coolText);
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	override function beatHit()
	{
		super.beatHit();

		switch (curBeat)
		{
			case 1:
				createCoolText(['']);
			case 3:
				addMoreText('Team TBD');
			case 5:
				tbdSpr.visible = true;
			case 7:
				deleteCoolText();
				tbdSpr.visible = false;
			case 8:
				createCoolText([curWacky[0]]);
			case 10:
				addMoreText(curWacky[1]);
			case 12:
				deleteCoolText();
			case 13:
				addMoreText('DDTO');
			case 14:
				addMoreText('Bad');
			case 15:
				addMoreText('Ending');
			case 16:
				skipIntro();
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(tbdSpr);

			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(credGroup);
			skippedIntro = true;
		}
	}
}
