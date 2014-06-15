package haxepop;

import haxe.Timer;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Point;
import flash.geom.Rectangle;
import haxepop.HXP;
import haxepop.graphics.Image;
import haxepop.utils.Math;

@:bitmap("assets/graphics/preloader/haxepop.png")
class Logo extends BitmapData {}

class Preloader extends NMEPreloader
{
	public var img:Bitmap;
	public var timer:Timer;
	public var fadeout_time:Float=0;
	public static inline var FADEOUT_TIME:Float=1.25;

	public function new()
	{
		img = new Bitmap(new Logo(0,0));
		img.alpha = 0.2;
		var w = 512;
		var h = 102;

		super();

		outline.y += h - 20;
		progress.y += h - 20;

		img.x = (getWidth() - w) / 2;
		img.y = (getHeight() - h) / 2 - 20;

		addChild(img);
	}

	override public function onInit()
	{
		stage.color = 0xFFFFFF;
	}

	override public function onUpdate(bytesLoaded:Int, bytesTotal:Int)
	{
		super.onUpdate(bytesLoaded, bytesTotal);

		var percentLoaded = bytesLoaded / bytesTotal;
		img.alpha = Math.clamp(percentLoaded, 0.2, 1);
	}

	override public function onLoaded()
	{
		img.alpha = 1;
		timer = new Timer(Std.int(1000/30));
		timer.run = fadeout;
	}

	function fadeout()
	{
		fadeout_time += 1/30/FADEOUT_TIME*2.5;
		if (fadeout_time >= 1) {
			outline.alpha = progress.alpha = img.alpha = progress.alpha = Math.max(0, img.alpha - 1/30/FADEOUT_TIME*2.5);
			if (img.alpha <= 0 && fadeout_time > 2.5) {
				timer.stop();
				done();
			}
		}
	}

	override public function getBackgroundColor():Int
	{
		return 0xFFFFFF;
	}

	function done()
	{
		dispatchEvent (new Event (Event.COMPLETE));
	}

}
