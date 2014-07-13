package haxepop.overlays;

import flash.display.BitmapData;
import flash.display.BlendMode;
import haxepop.utils.Draw;

class RGBNoise extends Overlay
{
	public var low:Int;
	public var high:Int;
	public var seed:Int;

	public function new(high:Int=8, low:Int=0, seed:Int=1)
	{
		this.low = low;
		this.high = high;
		this.seed = seed;

		drawNoise();
	}

	override public function render()
	{
		AdditiveOverlay.render();
	}

	override public function update()
	{
		AdditiveOverlay.update();
	}

	override public function resize()
	{
		if (width == HXP.windowWidth && height == HXP.windowHeight) return;
		AdditiveOverlay.resize();
		drawNoise();
	}

	function drawNoise()
	{
		AdditiveOverlay.init();

		width = HXP.windowWidth;
		height = HXP.windowHeight;
		var bmd = new BitmapData(width, height, false, 0);

		bmd.noise(seed, low, high);

		AdditiveOverlay.bitmapData.draw(bmd, null, null, BlendMode.ADD);
		bmd.dispose();
	}
}