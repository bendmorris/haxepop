package haxepop.overlays;

import flash.display.BitmapData;
import flash.display.BlendMode;
import haxepop.utils.Draw;

class Scanlines extends Overlay
{
	public var frequency:Int;
	public var thickness:Int;
	public var color:Int;

	public function new(frequency:Int=2, thickness:Int=1, color:Int=0x202020)
	{
		this.frequency = frequency;
		this.thickness = thickness;
		this.color = color;

		drawScanlines();
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
		drawScanlines();
	}

	function drawScanlines()
	{
		AdditiveOverlay.init();

		width = HXP.windowWidth;
		height = HXP.windowHeight;
		var bmd = new BitmapData(width, height, false, 0);

		Draw.setTarget(bmd);
		for (i in 0 ... Math.floor(height / frequency)) {
			var yi = Math.floor(i * frequency);
			for (j in 0 ... thickness)
			{
				Draw.line(0, yi + j, Math.floor(width), yi + j, color);
			}
		}

		AdditiveOverlay.bitmapData.draw(bmd, null, null, BlendMode.ADD);
		bmd.dispose();
	}
}