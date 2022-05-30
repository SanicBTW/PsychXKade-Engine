import openfl.Lib;
import flixel.FlxG;

class KadeEngineData
{
    public static function initSave()
    {
        if (FlxG.save.data.newInput == null)
			FlxG.save.data.newInput = true;

		if (FlxG.save.data.downscroll == null)
			FlxG.save.data.downscroll = false;

		if (FlxG.save.data.dfjk == null)
			FlxG.save.data.dfjk = false;
			
		if (FlxG.save.data.accuracyDisplay == null)
			FlxG.save.data.accuracyDisplay = true;

		if (FlxG.save.data.offset == null)
			FlxG.save.data.offset = 0;

		if (FlxG.save.data.songPosition == null)
			FlxG.save.data.songPosition = false;

		if (FlxG.save.data.fps == null)
			FlxG.save.data.fps = false;

		if (FlxG.save.data.changedHit == null)
		{
			FlxG.save.data.changedHitX = -1;
			FlxG.save.data.changedHitY = -1;
			FlxG.save.data.changedHit = false;
		}

		if (FlxG.save.data.fpsCap == null)
			FlxG.save.data.fpsCap = 60;

		if (FlxG.save.data.fpsCap > 290 || FlxG.save.data.fpsCap < 60)
			FlxG.save.data.fpsCap = 60;
		
		if (FlxG.save.data.scrollSpeed == null)
			FlxG.save.data.scrollSpeed = 1;

		if (FlxG.save.data.npsDisplay == null)
			FlxG.save.data.npsDisplay = false;

		if (FlxG.save.data.frames == null)
			FlxG.save.data.frames = 10;

		if (FlxG.save.data.accuracyMod == null)
			FlxG.save.data.accuracyMod = 'Accurate';

		if (FlxG.save.data.watermark == null)
			FlxG.save.data.watermark = true;

		if (FlxG.save.data.ghost == null)
			FlxG.save.data.ghost = true;

		if (FlxG.save.data.distractions == null)
			FlxG.save.data.distractions = true;

		if (FlxG.save.data.flashing == null)
			FlxG.save.data.flashing = true;

		if (FlxG.save.data.resetButton == null)
			FlxG.save.data.resetButton = false;
		
		if (FlxG.save.data.botplay == null)
			FlxG.save.data.botplay = false;

		if (FlxG.save.data.cpuStrums == null)
			FlxG.save.data.cpuStrums = false;

		if (FlxG.save.data.strumline == null)
			FlxG.save.data.strumline = false;
		
		if (FlxG.save.data.customStrumLine == null)
			FlxG.save.data.customStrumLine = 0;

		if (FlxG.save.data.camzoom == null)
			FlxG.save.data.camzoom = true;

		//psych options in kade go brrr
		if(FlxG.save.data.arrowHSV == null)
			FlxG.save.data.arrowHSV = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];

		if(FlxG.save.data.globalAntialiasing == null)
			FlxG.save.data.globalAntialiasing = true;

		if(FlxG.save.data.lowQuality == null)
			FlxG.save.data.lowQuality = false;

		if(FlxG.save.data.noteSplashes == null)
			FlxG.save.data.noteSplashes = true;

		if(FlxG.save.data.middleScroll == null)
			FlxG.save.data.middleScroll = false;

		//taken from my sexy engine 
		if(FlxG.save.data.classicMiddlescroll == null)
			FlxG.save.data.classicMiddlescroll = false;

		if(FlxG.save.data.timeBarType == null)
			FlxG.save.data.timeBarType = 'Time Left';

		if(FlxG.save.data.hideHud == null)
			FlxG.save.data.hideHud = false;

		if(FlxG.save.data.healthBarAlpha == null)
			FlxG.save.data.healthBarAlpha = 1.0;

		if(FlxG.save.data.hitSoundVolume == null)
			FlxG.save.data.hitSoundVolume = 0.0;

		//custom options tho
		if(FlxG.save.data.fpsCounterFont == null)
			FlxG.save.data.fpsCounterFont = "_sans";

		Conductor.recalculateTimings();
		PlayerSettings.player1.controls.loadKeyBinds();
		KeyBinds.keyCheck();

		(cast (Lib.current.getChildAt(0), Main)).setFPSCap(FlxG.save.data.fpsCap);
	}
}