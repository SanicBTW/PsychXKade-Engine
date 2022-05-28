package;

import psych.openfl.display.FPS;
import lime.app.Application;
import openfl.Lib;
import psych.ColorSwap;
import psych.CheckBoxThingie;
#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import flixel.input.mouse.FlxMouseEventManager;

using StringTools;

// TO DO: Redo the menu creation system for not being as dumb
class PsychOptionsState extends MusicBeatState
{
	var options:Array<String> = ['Notes', 'Controls', 'Preferences'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;

    //gotta follow kade stuff
    public static var instance:PsychOptionsState;
    public var acceptInput = true;

	override function create() {
        instance = this;
		#if desktop
		DiscordClient.changePresence("Options Menu", null);
		#end

		var menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = FlxG.save.data.globalAntialiasing;
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true, false);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}
		changeSelection();

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		changeSelection();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

        if(acceptInput)
        {
            if (controls.UP_P) {
                changeSelection(-1);
            }
            if (controls.DOWN_P) {
                changeSelection(1);
            }
    
            if (controls.BACK) {
                FlxG.sound.play(Paths.sound('cancelMenu'));
                MusicBeatState.switchState(new MainMenuState());
            }
    
            if (controls.ACCEPT) {
                for (item in grpOptions.members) {
                    item.alpha = 0;
                }
    
                switch(options[curSelected]) {
                    case 'Notes':
                        openSubState(new NotesSubstate());
    
                    case 'Controls':
                        openSubState(new KeyBindMenu());
    
                    case 'Preferences':
                        openSubState(new PreferencesSubstate());
                }
            }
        }
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}
	}
}



class NotesSubstate extends MusicBeatSubstate
{
	private static var curSelected:Int = 0;
	private static var typeSelected:Int = 0;
	private var grpNumbers:FlxTypedGroup<Alphabet>;
	private var grpNotes:FlxTypedGroup<FlxSprite>;
	private var shaderArray:Array<ColorSwap> = [];
	var curValue:Float = 0;
	var holdTime:Float = 0;
	var hsvText:Alphabet;
	var nextAccept:Int = 5;

	var posX = 250;
	public function new() {
		super();

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);
		grpNumbers = new FlxTypedGroup<Alphabet>();
		add(grpNumbers);

		for (i in 0...FlxG.save.data.arrowHSV.length) {
			var yPos:Float = (165 * i) + 35;
			for (j in 0...3) {
				var optionText:Alphabet = new Alphabet(0, yPos, Std.string(FlxG.save.data.arrowHSV[i][j]));
				optionText.x = posX + (225 * j) + 100 - ((optionText.lettersArray.length * 90) / 2);
				grpNumbers.add(optionText);
			}

			var note:FlxSprite = new FlxSprite(posX - 70, yPos);
			note.frames = Paths.getSparrowAtlas('NOTE_assets');
			switch(i) {
				case 0:
					note.animation.addByPrefix('idle', 'purple0');
				case 1:
					note.animation.addByPrefix('idle', 'blue0');
				case 2:
					note.animation.addByPrefix('idle', 'green0');
				case 3:
					note.animation.addByPrefix('idle', 'red0');
			}
			note.animation.play('idle');
			note.antialiasing = FlxG.save.data.globalAntialiasing;
			grpNotes.add(note);

			var newShader:ColorSwap = new ColorSwap();
			note.shader = newShader.shader;
			newShader.hue = FlxG.save.data.arrowHSV[i][0] / 360;
			newShader.saturation = FlxG.save.data.arrowHSV[i][1] / 100;
			newShader.brightness = FlxG.save.data.arrowHSV[i][2] / 100;
			shaderArray.push(newShader);
		}
		hsvText = new Alphabet(0, 0, "Hue    Saturation  Brightness", false, false, 0, 0.65);
		add(hsvText);
		changeSelection();
	}

	var changingNote:Bool = false;
	var hsvTextOffsets:Array<Float> = [240, 90];
	override function update(elapsed:Float) {
		if(changingNote) {
			if(holdTime < 0.5) {
				if(controls.LEFT_P) {
					updateValue(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.RIGHT_P) {
					updateValue(1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.RESET) {
					resetValue(curSelected, typeSelected);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if(controls.LEFT_R || controls.RIGHT_R) {
					holdTime = 0;
				} else if(controls.LEFT || controls.RIGHT) {
					holdTime += elapsed;
				}
			} else {
				var add:Float = 90;
				switch(typeSelected) {
					case 1 | 2: add = 50;
				}
				if(controls.LEFT) {
					updateValue(elapsed * -add);
				} else if(controls.RIGHT) {
					updateValue(elapsed * add);
				}
				if(controls.LEFT_R || controls.RIGHT_R) {
					FlxG.sound.play(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}
		} else {
			if (controls.UP_P) {
				changeSelection(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.DOWN_P) {
				changeSelection(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.LEFT_P) {
				changeType(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.RIGHT_P) {
				changeType(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if(controls.RESET) {
				for (i in 0...3) {
					resetValue(curSelected, i);
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.ACCEPT && nextAccept <= 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changingNote = true;
				holdTime = 0;
				for (i in 0...grpNumbers.length) {
					var item = grpNumbers.members[i];
					item.alpha = 0;
					if ((curSelected * 3) + typeSelected == i) {
						item.alpha = 1;
					}
				}
				for (i in 0...grpNotes.length) {
					var item = grpNotes.members[i];
					item.alpha = 0;
					if (curSelected == i) {
						item.alpha = 1;
					}
				}
				super.update(elapsed);
				return;
			}
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 9.6, 0, 1);
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			var intendedPos:Float = posX - 70;
			if (curSelected == i) {
				item.x = FlxMath.lerp(item.x, intendedPos + 100, lerpVal);
			} else {
				item.x = FlxMath.lerp(item.x, intendedPos, lerpVal);
			}
			for (j in 0...3) {
				var item2 = grpNumbers.members[(i * 3) + j];
				item2.x = item.x + 265 + (225 * (j % 3)) - (30 * item2.lettersArray.length) / 2;
				if(FlxG.save.data.arrowHSV[i][j] < 0) {
					item2.x -= 20;
				}
			}

			if(curSelected == i) {
				hsvText.setPosition(item.x + hsvTextOffsets[0], item.y - hsvTextOffsets[1]);
			}
		}

		if (controls.BACK || (changingNote && controls.ACCEPT)) {
			changeSelection();
			if(!changingNote) {
				grpNumbers.forEachAlive(function(spr:Alphabet) {
					spr.alpha = 0;
				});
				grpNotes.forEachAlive(function(spr:FlxSprite) {
					spr.alpha = 0;
				});
				close();
			}
			changingNote = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = Std.int(FlxG.save.data.arrowHSV.length) - 1;
		if (curSelected >= FlxG.save.data.arrowHSV.length)
			curSelected = 0;

		curValue = FlxG.save.data.arrowHSV[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			item.alpha = 0.6;
			item.scale.set(1, 1);
			if (curSelected == i) {
				item.alpha = 1;
				item.scale.set(1.2, 1.2);
				hsvText.setPosition(item.x + hsvTextOffsets[0], item.y - hsvTextOffsets[1]);
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeType(change:Int = 0) {
		typeSelected += change;
		if (typeSelected < 0)
			typeSelected = 2;
		if (typeSelected > 2)
			typeSelected = 0;

		curValue = FlxG.save.data.arrowHSV[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}
	}

	function resetValue(selected:Int, type:Int) {
		curValue = 0;
		FlxG.save.data.arrowHSV[selected][type] = 0;
		switch(type) {
			case 0: shaderArray[selected].hue = 0;
			case 1: shaderArray[selected].saturation = 0;
			case 2: shaderArray[selected].brightness = 0;
		}
		grpNumbers.members[(selected * 3) + type].changeText('0');
	}
	function updateValue(change:Float = 0) {
		curValue += change;
		var roundedValue:Int = Math.round(curValue);
		var max:Float = 180;
		switch(typeSelected) {
			case 1 | 2: max = 100;
		}

		if(roundedValue < -max) {
			curValue = -max;
		} else if(roundedValue > max) {
			curValue = max;
		}
		roundedValue = Math.round(curValue);
		FlxG.save.data.arrowHSV[curSelected][typeSelected] = roundedValue;

		switch(typeSelected) {
			case 0: shaderArray[curSelected].hue = roundedValue / 360;
			case 1: shaderArray[curSelected].saturation = roundedValue / 100;
			case 2: shaderArray[curSelected].brightness = roundedValue / 100;
		}
		grpNumbers.members[(curSelected * 3) + typeSelected].changeText(Std.string(roundedValue));
	}
}

class PreferencesSubstate extends MusicBeatSubstate
{
	private static var curSelected:Int = 0;
    static var unselectableOptions:Array<String> = [ //follows kade options menu thingy, might reorder it?? dunno
        'GAMEPLAY',
        'APPEARANCE',
        'MISC'
    ];
    static var noCheckbox:Array<String> = [
        'Judgement',
        'Framerate',
        'Scroll Speed',
        'Accuracy Display',
        'FPS Counter Font'
    ];
    static var options:Array<String> = [
        'GAMEPLAY',
        'Downscroll',
        //'Middlescroll' gotta see this shit
        'Ghost Tapping',
        'Judgement',
        #if desktop
        'Framerate',
        #end
        'Scroll Speed',
        'Accuracy Display',
        'Reset Button',
        //'Customize Gameplay' might get the latest customize gameplay state from psych
        'APPEARANCE',
        'Distractions',
        'Cam Zooms',
        #if desktop
        'Accuracy',
        'NPS Display',
        'Song Position',
        'CPU Strums',
        #end
        'MISC',
        #if desktop
        'FPS Counter',
        //'Replay' why the fuck is replay a thing, bro kade this shit is cool and all but bro
        #end
        'Flashing',
        'Botplay', //might make it available in the pause menu?? or in the gameplay modifiers on freeplay state??? help
        'Score Screen',
		'FPS Counter Font'
    ];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxArray:Array<CheckboxThingie> = [];
	private var checkboxNumber:Array<Int> = [];
	private var grpTexts:FlxTypedGroup<AttachedText>;
	private var textNumber:Array<Int> = [];

	private var characterLayer:FlxTypedGroup<Character>;
	private var showCharacter:Character = null;
	private var descText:FlxText;

	private var judgementBG:FlxSprite;

	private var safeFramesText = "Safe Frames: " + Conductor.safeFrames;
	private var sickWindowsText = "ms SIK: " + HelperFunctions.truncateFloat(22 * Conductor.timeScale, 0);
	private var goodWindowsText = "ms GD: " + HelperFunctions.truncateFloat(45 * Conductor.timeScale, 0);
	private var badWindowsText = "ms BD: " + HelperFunctions.truncateFloat(135 * Conductor.timeScale, 0);
	private var shitWindowsText = "ms SHT: " + HelperFunctions.truncateFloat(155 * Conductor.timeScale, 0);
	private var totalMSText = "ms TOTAL: " + HelperFunctions.truncateFloat(Conductor.safeZoneOffset,0) + "ms";

	private var safeFrameshelp:FlxText;
	private var sickWindowshelp:FlxText;
	private var goodWindowshelp:FlxText;
	private var badWindowshelp:FlxText;
	private var shitWindowshelp:FlxText;
	private var totalMShelp:FlxText;

	public function new()
	{
		super();
		characterLayer = new FlxTypedGroup<Character>();
		add(characterLayer);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		for (i in 0...options.length)
		{
			var isCentered:Bool = unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(0, 70 * i, options[i], false, false);
			optionText.isMenuItem = true;
			if(isCentered) {
				optionText.screenCenter(X);
				optionText.forceX = optionText.x;
			} else {
				optionText.x += 200;
				optionText.forceX = 200;
			}
			optionText.yMult = 90;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if(!isCentered) {
				var useCheckbox:Bool = true;
				for (j in 0...noCheckbox.length) {
					if(options[i] == noCheckbox[j]) {
						useCheckbox = false;
						break;
					}
				}

				if(useCheckbox) { 
					var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, false);
					checkbox.sprTracker = optionText;
					checkboxArray.push(checkbox);
					checkboxNumber.push(i);
					add(checkbox);
				} else { 
					var valueText:AttachedText = new AttachedText('0', optionText.width + 80);
					valueText.sprTracker = optionText;
					grpTexts.add(valueText);
					textNumber.push(i);
				} 
			}
		}

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		judgementBG = new FlxSprite(800, 200).makeGraphic(350, 300, FlxColor.BLACK);
		judgementBG.visible = false;
		judgementBG.alpha = 0.5;

		safeFrameshelp = new FlxText(800, 200, 0, safeFramesText, 32);
		safeFrameshelp.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		safeFrameshelp.scrollFactor.set();
		safeFrameshelp.borderSize = 2.4;

		sickWindowshelp = new FlxText(800, 250, 0, sickWindowsText, 32);
		sickWindowshelp.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		sickWindowshelp.scrollFactor.set();
		sickWindowshelp.borderSize = 2.4;

		goodWindowshelp = new FlxText(800, 300, 0, goodWindowsText, 32);
		goodWindowshelp.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		goodWindowshelp.scrollFactor.set();
		goodWindowshelp.borderSize = 2.4;

		badWindowshelp = new FlxText(800, 350, 0, badWindowsText, 32);
		badWindowshelp.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		badWindowshelp.scrollFactor.set();
		badWindowshelp.borderSize = 2.4;

		shitWindowshelp = new FlxText(800, 400, 0, shitWindowsText, 32);
		shitWindowshelp.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		shitWindowshelp.scrollFactor.set();
		shitWindowshelp.borderSize = 2.4;

		totalMShelp = new FlxText(800, 450, 0, totalMSText, 32);
		totalMShelp.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		totalMShelp.scrollFactor.set();
		totalMShelp.borderSize = 2.4;

		safeFrameshelp.visible = false;
		sickWindowshelp.visible = false;
		goodWindowshelp.visible = false;
		badWindowshelp.visible = false;
		shitWindowshelp.visible = false;
		totalMShelp.visible = false;

		add(judgementBG);

		add(safeFrameshelp);
		add(sickWindowshelp);
		add(goodWindowshelp);
		add(badWindowshelp);
		add(shitWindowshelp);
		add(totalMShelp);

		for (i in 0...options.length) {
			if(!unselectableCheck(i)) {
				curSelected = i;
				break;
			}
		}
		changeSelection();
		reloadValues();
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (controls.UP_P)
		{
			changeSelection(-1);
		}
		if (controls.DOWN_P)
		{
			changeSelection(1);
		}

		if (controls.BACK) {
			grpOptions.forEachAlive(function(spr:Alphabet) {
				spr.alpha = 0;
			});
			grpTexts.forEachAlive(function(spr:AttachedText) {
				spr.alpha = 0;
			});
			for (i in 0...checkboxArray.length) {
				var spr:CheckboxThingie = checkboxArray[i];
				if(spr != null) {
					spr.alpha = 0;
				}
			}
			if(showCharacter != null) {
				showCharacter.alpha = 0;
			}
			descText.alpha = 0;
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		var usesCheckbox = true;
		for (i in 0...noCheckbox.length) {
			if(options[curSelected] == noCheckbox[i]) {
				usesCheckbox = false;
				break;
			}
		}

		if(usesCheckbox) {
			if(controls.ACCEPT && nextAccept <= 0) {
				switch(options[curSelected]) {
                    case 'Downscroll':
                        FlxG.save.data.downscroll = !FlxG.save.data.downscroll;
                    case 'Ghost Tapping':
                        FlxG.save.data.ghost = !FlxG.save.data.ghost;
                    case 'Reset Button':
                        FlxG.save.data.resetButton = !FlxG.save.data.resetButton;
                    case 'Distractions':
                        FlxG.save.data.distractions = !FlxG.save.data.distractions;
                    case 'Cam Zooms':
                        FlxG.save.data.camzoom = !FlxG.save.data.camzoom;
                    case 'Accuracy':
                        FlxG.save.data.accuracyDisplay = !FlxG.save.data.accuracyDisplay;
                    case 'NPS Display':
                        FlxG.save.data.npsDisplay = !FlxG.save.data.npsDisplay;
                    case 'Song Position':
                        FlxG.save.data.songPosition = !FlxG.save.data.songPosition;
                    case 'CPU Strums':
                        FlxG.save.data.cpuStrums = !FlxG.save.data.cpuStrums;
                    case 'FPS Counter':
                        FlxG.save.data.fps = !FlxG.save.data.fps;
                        (cast (Lib.current.getChildAt(0), Main)).toggleFPS(FlxG.save.data.fps);
                    case 'Flashing':
                        FlxG.save.data.flashing = !FlxG.save.data.flashing;
                    case 'Botplay':
                        FlxG.save.data.botplay = !FlxG.save.data.botplay;
                    case 'Score Screen':
                        FlxG.save.data.scoreScreen = !FlxG.save.data.scoreScreen;
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
				reloadValues();
			}
		} else if (!usesCheckbox) {
			if(controls.LEFT || controls.RIGHT) {
                
                var curIdx:Int = controls.LEFT ? -1 : 1;
                var availableOptions:Array<String> = ['hii'];

				var add:Int = controls.LEFT ? -1 : 1;
				if(holdTime > 0.5 || controls.LEFT_P || controls.RIGHT_P)
				switch(options[curSelected]) {
                    case 'Judgement':
						FlxG.save.data.frames += add;
						if(FlxG.save.data.frames < 1) FlxG.save.data.frames = 1;
						else if(FlxG.save.data.frames > 20) FlxG.save.data.frames = 20;
						Conductor.safeFrames = FlxG.save.data.frames;
						Conductor.recalculateTimings();
                    case 'Framerate':
                        var custAdd = controls.LEFT ? -10 : 10;
                        FlxG.save.data.fpsCap += custAdd;
                        if(FlxG.save.data.fpsCap < 60) FlxG.save.data.fpsCap = 60;
                        else if(FlxG.save.data.fpsCap > 290) FlxG.save.data.fpsCap = 290;
                        (cast (Lib.current.getChildAt(0), Main)).setFPSCap(FlxG.save.data.fpsCap);
                    case 'Scroll Speed':
                        var custAdd = controls.LEFT ? -0.1 : 0.1;
                        if(holdTime > 1.5) custAdd = controls.LEFT ? -0.5 : 0.5;
                        FlxG.save.data.scrollSpeed += custAdd;
                        if(FlxG.save.data.scrollSpeed < 1) FlxG.save.data.scrollSpeed = 1;
                        else if(FlxG.save.data.scrollSpeed > 4) FlxG.save.data.scrollSpeed = 4;
                    case 'Accuracy Display':
                        availableOptions = ['Accurate', 'Complex'];
                        if(curIdx > 1) curIdx = 1;
                        else if (curIdx < 0) curIdx = 0;
                        FlxG.save.data.accuracyMod = availableOptions[curIdx];
                    case 'FPS Counter Font':
                        availableOptions = ['Sans', 'VCR OSD']; //0, 1
						var howToSaveIt = "";
						if(curIdx > 1) curIdx = 1; //limit of the array
                        else if (curIdx < 0) curIdx = 0;
						switch(availableOptions[curIdx])
						{
							case "Sans":
								howToSaveIt = "_sans";
							case "VCR OSD":
								howToSaveIt = "VCR OSD Mono";
						}
						FlxG.save.data.fpsCounterFont = howToSaveIt;
						Main.fpsCounter.defaultTextFormat.font = FlxG.save.data.fpsCounterFont;
				}
				reloadValues();

				if(holdTime <= 0) FlxG.sound.play(Paths.sound('scrollMenu'));
				holdTime += elapsed;
			} else {
                holdTime = 0;
            }
		}

		if(showCharacter != null && showCharacter.animation.curAnim.finished) {
			showCharacter.dance();
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}
	
	function changeSelection(change:Int = 0)
	{
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = options.length - 1;
			if (curSelected >= options.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var daText:String = '';
		switch(options[curSelected]) {
			case 'Downscroll':
                daText = "Change the layout of the strumline.";
            case 'Ghost Tapping':
                daText = "Ghost Tapping is when you tap a direction and it doesn't give you a miss.";
            case 'Judgement':
                daText = "Customize your Hit Timings (LEFT or RIGHT)";
            case 'Framerate':
                daText = "Cap your FPS";
            case 'Scroll Speed':
                daText = "Change your scroll speed (1 = Chart dependent)";
            case 'Accuracy Display':
                daText = "Change how accuracy is calculated.\n(Accurate = Simple, Complex = Milisecond Based)";
            case 'Reset Button':
                daText = "Toggle pressing R to gameover.";
            case 'Distractions':
                daText = "Toggle stage distractions that can hinder your gameplay.";
            case 'Cam Zooms':
                daText = "Toggle the camera zoom in-game.";
            case 'Accuracy':
                daText = "Display accuracy information.";
            case 'NPS Display':
                daText = "Shows your current Notes Per Second.";
            case 'Song Position':
                daText = "Show the songs current position (as a bar)";
            case 'CPU Strums':
                daText = "CPU's strumline lights up when a note hits it.";
            case 'FPS Counter':
                daText = "Toggle the FPS Counter";
            case 'Flashing':
                daText = "Toggle flashing lights that can cause epileptic seizures and strain.";
            case 'Botplay':
                daText = "Showcase your charts and mods with autoplay.";
            case 'Score Screen':
                daText = "Show the score screen after the end of a song";
			case 'FPS Counter Font':
				daText = "Changes the FPS Counter Font\nTo apply changes you have to restart the engine";
		}
		descText.text = daText;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}

				for (j in 0...checkboxArray.length) {
					var tracker:FlxSprite = checkboxArray[j].sprTracker;
					if(tracker == item) {
						checkboxArray[j].alpha = item.alpha;
						break;
					}
				}
			}
		}
		for (i in 0...grpTexts.members.length) {
			var text:AttachedText = grpTexts.members[i];
			if(text != null) {
				text.alpha = 0.6;
				if(textNumber[i] == curSelected) {
					text.alpha = 1;
				}
			}
		}

		if(options[curSelected] == 'Anti-Aliasing') {
			if(showCharacter == null) {
				showCharacter = new Character(840, 170, 'bf', true);
				showCharacter.setGraphicSize(Std.int(showCharacter.width * 0.8));
				showCharacter.updateHitbox();
				showCharacter.dance();
				characterLayer.add(showCharacter);
			}
		} else if(showCharacter != null) {
			characterLayer.clear();
			showCharacter = null;
		} else if(options[curSelected] == 'Judgement') {
			judgementBG.visible = true;
			safeFrameshelp.visible = true;
			sickWindowshelp.visible = true;
			goodWindowshelp.visible = true;
			badWindowshelp.visible = true;
			shitWindowshelp.visible = true;
			totalMShelp.visible = true;
		} else if (judgementBG.visible){
			judgementBG.visible = false;
			safeFrameshelp.visible = false;
			sickWindowshelp.visible = false;
			goodWindowshelp.visible = false;
			badWindowshelp.visible = false;
			shitWindowshelp.visible = false;
			totalMShelp.visible = false;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function reloadValues() {
		for (i in 0...checkboxArray.length) {
			var checkbox:CheckboxThingie = checkboxArray[i];
			if(checkbox != null) {
				var daValue:Bool = false;
				switch(options[checkboxNumber[i]]) {
                    case 'Downscroll':
                        daValue = FlxG.save.data.downscroll;
                    case 'Ghost Tapping':
                        daValue = FlxG.save.data.ghost;
                    case 'Reset Button':
                        daValue = FlxG.save.data.resetButton;
                    case 'Distractions':
                        daValue = FlxG.save.data.distractions;
                    case 'Cam Zooms':
                        daValue = FlxG.save.data.camzoom;
                    case 'Accuracy':
                        daValue = FlxG.save.data.accuracyDisplay;
                    case 'NPS Display':
                        daValue = FlxG.save.data.npsDisplay;
                    case 'Song Position':
                        daValue = FlxG.save.data.songPosition;
                    case 'CPU Strums':
                        daValue = FlxG.save.data.cpuStrums;
                    case 'FPS Counter':
                        daValue = FlxG.save.data.fps;
                    case 'Flashing':
                        daValue = FlxG.save.data.flashing;
                    case 'Botplay':
                        daValue = FlxG.save.data.botplay;
                    case 'Score Screen':
                        daValue = FlxG.save.data.scoreScreen;
				}
				checkbox.daValue = daValue;
			}
		}
		for (i in 0...grpTexts.members.length) {
			var text:AttachedText = grpTexts.members[i];
			if(text != null) {
				var daText:String = '';
				switch(options[textNumber[i]]) {
					case 'Judgement':
						safeFramesText = "Safe Frames: " + Conductor.safeFrames;
						sickWindowsText = "ms SIK: " + HelperFunctions.truncateFloat(22 * Conductor.timeScale, 0);
						goodWindowsText = "ms GD: " + HelperFunctions.truncateFloat(45 * Conductor.timeScale, 0);
						badWindowsText  = "ms BD: " + HelperFunctions.truncateFloat(135 * Conductor.timeScale, 0);
						shitWindowsText = "ms SHT: " + HelperFunctions.truncateFloat(155 * Conductor.timeScale, 0);
						totalMSText = "ms TOTAL: " + HelperFunctions.truncateFloat(Conductor.safeZoneOffset,0) + "ms";

						safeFrameshelp.text = safeFramesText;
						sickWindowshelp.text = sickWindowsText;
						goodWindowshelp.text = goodWindowsText;
						badWindowshelp.text = badWindowsText;
						shitWindowshelp.text = shitWindowsText;
						totalMShelp.text = totalMSText;
                    case 'Framerate':
                        daText = FlxG.save.data.fpsCap + (FlxG.save.data.fpsCap == Application.current.window.displayMode.refreshRate ? "Hz (Refresh Rate)" : "");
                    case 'Scroll Speed':
                        daText = '' + FlxG.save.data.scrollSpeed;
                    case 'Accuracy Display':
                        daText = FlxG.save.data.accuracyMod;
					case 'FPS Counter Font':
						var howToDisplay = "";
						switch(FlxG.save.data.fpsCounterFont)
						{
							case "_sans":
								howToDisplay = "Sans";
							case "VCR OSD Mono":
								howToDisplay = "VCR OSD";
						}
						daText = howToDisplay;
				}
				var lastTracker:FlxSprite = text.sprTracker;
				text.sprTracker = null;
				text.changeText(daText);
				text.sprTracker = lastTracker;
			}
		}
	}

	private function unselectableCheck(num:Int):Bool {
		for (i in 0...unselectableOptions.length) {
			if(options[num] == unselectableOptions[i]) {
				return true;
			}
		}
		return options[num] == '';
	}
}