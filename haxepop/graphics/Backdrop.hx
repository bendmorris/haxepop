package haxepop.graphics;

import haxepop.Graphic;
import haxepop.graphics.atlas.Atlas;
import haxepop.graphics.atlas.AtlasRegion;
import haxepop.HXP;
import haxepop.RenderMode;

import flash.display.BitmapData;
import flash.geom.Point;

/**
 * A background texture that can be repeated horizontally and vertically
 * when drawn. Really useful for parallax backgrounds, textures, etc.
 */
class Backdrop extends Canvas
{
	/**
	 * Constructor.
	 * @param	source		Source texture.
	 * @param	repeatX		Repeat horizontally.
	 * @param	repeatY		Repeat vertically.
	 */
	public function new(source:ImageType, repeatX:Bool = true, repeatY:Bool = true)
	{
		switch (source.type)
		{
			case Left(bitmap):
				blit = true;
				_source = bitmap;
				_textWidth = _source.width;
				_textHeight = _source.height;
			case Right(region):
				blit = false;
				_region = region;
				_textWidth = Std.int(region.width);
				_textHeight = Std.int(region.height);
		}

		_repeatX = repeatX;
		_repeatY = repeatY;

		super(HXP.width * (repeatX ? 1 : 0) + _textWidth, HXP.height * (repeatY ? 1 : 0) + _textHeight);

		if (blit)
		{
			HXP.rect.x = HXP.rect.y = 0;
			HXP.rect.width = _width;
			HXP.rect.height = _height;
			fillTexture(HXP.rect, _source);
		}
	}

	/** Renders the Backdrop. */
	override public function render(target:BitmapData, point:Point, camera:Point)
	{
		_point.x = point.x + x - camera.x * scrollX;
		_point.y = point.y + y - camera.y * scrollY;

		if (_repeatX)
		{
			_point.x %= _textWidth;
			if (_point.x > 0) _point.x -= _textWidth;
		}

		if (_repeatY)
		{
			_point.y %= _textHeight;
			if (_point.y > 0) _point.y -= _textHeight;
		}

		_x = x; _y = y;
		x = y = 0;
		super.render(target, _point, HXP.zero);
		x = _x; y = _y;
	}

	override public function renderAtlas(layer:Int, point:Point, camera:Point)
	{
		_point.x = point.x + x - camera.x * scrollX;
		_point.y = point.y + y - camera.y * scrollY;

		if (_repeatX)
		{
			_point.x %= _textWidth;
			if (_point.x > 0) _point.x -= _textWidth;
		}

		if (_repeatY)
		{
			_point.y %= _textHeight;
			if (_point.y > 0) _point.y -= _textHeight;
		}

		var sx = scale * scaleX,
			sy = scale * scaleY,
			fsx = HXP.screen.fullScaleX,
			fsy = HXP.screen.fullScaleY,
			px:Int = Std.int(_point.x * fsx), py:Int = Std.int(_point.y * fsy);

		var y:Int = 0;
		while (y < _height * sy * fsy)
		{
			var x:Int = 0;
			while (x < _width * sx * fsx)
			{
				_region.draw(px + x, py + y, layer, sx * fsx, sy * fsy, 0, _red, _green, _blue, _alpha);
				x += Std.int(_textWidth * fsx);
			}
			y += Std.int(_textHeight * fsy);
		}
	}

	// Backdrop information.
	private var _source:BitmapData;
	private var _region:AtlasRegion;
	private var _textWidth:Int;
	private var _textHeight:Int;
	private var _repeatX:Bool;
	private var _repeatY:Bool;
	private var _x:Float;
	private var _y:Float;
}
