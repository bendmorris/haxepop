package haxepop.overlays;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import openfl.display.Tilesheet;
import haxepop.HXP;

/**
 * This is an abstract class that allows combining multiple static overlay
 * effects with additive blending..
 */
class AdditiveOverlay
{
	public static function render()
	{
		if (rendered) return;

		var sprite = HXP.scene.sprite;
		if (sprite != null && bitmapData != null)
		{
#if buffer
			if (bitmap == null)
			{
				bitmap = new Bitmap(bitmapData);
				bitmap.blendMode = BlendMode.ADD;
			}
			if (!sprite.contains(bitmap))
			{
				sprite.addChild(bitmap);
			}
#else
			if (tilesheet == null)
			{
				tilesheet = new Tilesheet(bitmapData);
				tilesheet.addTileRect(bitmapData.rect, null);
			}
			tilesheet.drawTiles(sprite.graphics, renderData, false, renderFlags);
#end
		}
		rendered = true;
	}

	public static function init()
	{
		if (initialized) return;
		bitmapData = new BitmapData(HXP.windowWidth, HXP.windowHeight, false, 0);
		initialized = true;
	}

	public static function update()
	{
		rendered = false;
	}

	public static function resize()
	{
		if (bitmapData != null)
		{
			if (bitmapData.width == HXP.windowWidth && bitmapData.height == HXP.windowHeight)
			{
				return;
			}

			bitmapData.dispose();

#if buffer
			var sprite = HXP.scene.sprite;
			if (sprite != null && bitmap != null && sprite.contains(bitmap))
			{
				sprite.removeChild(bitmap);
			}
#end

			initialized = false;
			bitmap = null;
			tilesheet = null;
			init();
		}
	}

	public static var initialized:Bool = false;
	public static var rendered:Bool = false;
	public static var bitmap:Bitmap;
	public static var bitmapData:BitmapData;
	public static var tilesheet:Tilesheet;

	static var renderFlags:Int = Tilesheet.TILE_TRANS_2x2 | Tilesheet.TILE_ALPHA | Tilesheet.TILE_BLEND_ADD;
	static var renderData:Array<Float> = [0,0,0,1,0,0,1,1];
}