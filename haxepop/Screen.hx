package haxepop;

import haxepop.graphics.atlas.Atlas;
import haxepop.graphics.Image;
import haxepop.overlays.Overlay;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.PixelSnapping;
import flash.display.Sprite;
import flash.filters.BitmapFilter;
import flash.geom.Matrix;
import flash.utils.ByteArray;
import flash.Lib;


@:enum
abstract ScalingMode(Int)
{
	// default scaling: scale to fill the entire window, may be non-uniform
	var Default = 0;
	// uniform scaling: scaleX = scaleY, may make more screen area visible
	var Uniform = 1;
	// letterbox: even scaling with areas outside of viewport blacked out
	var Letterbox = 2;
}

typedef ScalingSettings =
{
	var mode:ScalingMode;
	var integer:Bool;
}

/**
 * Container for the main screen buffer. Can be used to transform the screen.
 */
@:allow(haxepop.HXP)
class Screen
{
	public var scaling:ScalingSettings;

	public var overlays:Array<Overlay>;

	/**
	 * Constructor.
	 */
	public function new()
	{
		_sprite = new Sprite();
		_bitmap = new Array<Bitmap>();
		overlays = new Array();
		init();
	}

	public function init()
	{
		x = y = originX = originY = 0;
		_angle = _current = 0;
		scale = scaleX = scaleY = 1;
		updateTransformation();

		// create screen buffers
		if (HXP.engine.contains(_sprite))
		{
			HXP.engine.removeChild(_sprite);
		}
#if buffer
		HXP.engine.addChild(_sprite);
#end
	}

	private inline function disposeBitmap(bd:Bitmap)
	{
		if (bd != null)
		{
			_sprite.removeChild(bd);
			bd.bitmapData.dispose();
		}
	}

	/**
	 * Resizes the screen by recreating the bitmap buffer.
	 */
	public function resize()
	{
		var width = HXP.width;
		var height = HXP.height;
#if buffer
		disposeBitmap(_bitmap[0]);
		disposeBitmap(_bitmap[1]);

		var w = Math.ceil(HXP.windowWidth);
		var h = Math.ceil(HXP.windowHeight);
		_bitmap[0] = new Bitmap(Assets.createBitmap(w, h, true), PixelSnapping.NEVER);
		_bitmap[1] = new Bitmap(Assets.createBitmap(w, h, true), PixelSnapping.NEVER);

		_sprite.addChild(_bitmap[0]).visible = true;
		_sprite.addChild(_bitmap[1]).visible = false;
		HXP.buffer = _bitmap[0].bitmapData;
#end

		// adjust screen scale based on scaling mode
		switch (scaling.mode)
		{
			case Default:
				scaleX = HXP.stage.stageWidth / width;
				scaleY = HXP.stage.stageHeight / height;
			case Uniform, Letterbox:
				var newScale = Math.max(Math.min(
					HXP.stage.stageWidth / width,
					HXP.stage.stageHeight / height
				), 1);
				if (scaling.integer) newScale = Std.int(newScale);
				scaleX = scaleY = newScale;

				// center screen
				var dx = HXP.stage.stageWidth - (width * scaleX);
				var dy = HXP.stage.stageHeight - (height * scaleY);
				x = Std.int(dx / 2);
				y = Std.int(dy / 2);
		}

		_current = 0;
		needsResize = false;

		this.width = Std.int(width * scaleX);
		this.height = Std.int(height * scaleY);

		for (overlay in overlays) overlay.resize();
	}

	/**
	 * Swaps screen buffers.
	 */
	public function swap()
	{
#if buffer
		_current = 1 - _current;
		HXP.buffer = _bitmap[_current].bitmapData;
#end
	}

	/**
	 * Add a filter.
	 *
	 * @param	filter	The filter to add.
	 */
	public function addFilter(filter:Array<BitmapFilter>)
	{
		_sprite.filters = filter;
	}

	/**
	 * Refreshes the screen.
	 */
	public function refresh()
	{
		// refreshes the screen
		HXP.buffer.fillRect(HXP.bounds, HXP.stage.color);
	}

	/**
	 * Redraws the screen.
	 */
	public function redraw()
	{
#if buffer
		// refresh the buffers
		_bitmap[_current].visible = true;
		_bitmap[1 - _current].visible = false;
#end
	}

	/** @private Re-applies transformation matrix. */
	private function updateTransformation()
	{
		if (_matrix == null)
		{
			_matrix = new Matrix();
		}
		_matrix.b = _matrix.c = 0;
		_matrix.a = 1;
		_matrix.d = 1;
		_matrix.tx = -originX * _matrix.a;
		_matrix.ty = -originY * _matrix.d;
		if (_angle != 0) _matrix.rotate(_angle);
		_matrix.tx += originX * fullScaleX + x;
		_matrix.ty += originY * fullScaleY + y;
		_sprite.transform.matrix = _matrix;
	}

	public function update()
	{
		// screen shake
		if (_shakeTime > 0)
		{
			var sx:Int = Std.random(_shakeMagnitude*2+1) - _shakeMagnitude;
			var sy:Int = Std.random(_shakeMagnitude*2+1) - _shakeMagnitude;
			var sa:Int = Std.random(_shakeAngularMagnitude*2+1) - _shakeAngularMagnitude;

			HXP.camera.x += sx - _shakeX;
			HXP.camera.y += sy - _shakeY;
			HXP.camera.angle += sa - _shakeAngle;

			_shakeX = sx;
			_shakeY = sy;
			_shakeAngle = sa;

			_shakeTime -= HXP.elapsed;
			if (_shakeTime < 0) _shakeTime = 0;
		}
		else if (_shakeX != 0 || _shakeY != 0 || _shakeAngle != 0)
		{
			HXP.camera.x -= _shakeX;
			HXP.camera.y -= _shakeY;
			HXP.camera.angle -= _shakeAngle;
			HXP.camera.scale /= _shakeZoom;
			_shakeX = _shakeY = _shakeAngle = 0;
		}
	}

	/**
	 * Refresh color of the screen.
	 */
	public var color(get, set):Int;
	private function get_color():Int { return HXP.stage.color; }
	private function set_color(value:Int):Int
	{
		HXP.stage.color = value;
		
		return value;
	}

	/**
	 * X offset of the screen.
	 */
	public var x(default, set):Int = 0;
	private function set_x(value:Int):Int
	{
		if (x == value) return value;
		HXP.engine.x = x = value;
		updateTransformation();
		return x;
	}

	/**
	 * Y offset of the screen.
	 */
	public var y(default, set):Int = 0;
	private function set_y(value:Int):Int
	{
		if (y == value) return value;
		HXP.engine.y = y = value;
		updateTransformation();
		return y;
	}

	/**
	 * X origin of transformations.
	 */
	public var originX(default, set):Int = 0;
	private function set_originX(value:Int):Int
	{
		if (originX == value) return value;
		originX = value;
		updateTransformation();
		return originX;
	}

	/**
	 * Y origin of transformations.
	 */
	public var originY(default, set):Int = 0;
	private function set_originY(value:Int):Int
	{
		if (originY == value) return value;
		originY = value;
		updateTransformation();
		return originY;
	}

	/**
	 * X scale of the screen.
	 */
	public var scaleX(default, set):Float = 1;
	private function set_scaleX(value:Float):Float
	{
		if (scaleX == value) return value;
		scaleX = value;
		fullScaleX = scaleX * scale;
		updateTransformation();
		needsResize = true;
		return scaleX;
	}

	/**
	 * Y scale of the screen.
	 */
	public var scaleY(default, set):Float = 1;
	private function set_scaleY(value:Float):Float
	{
		if (scaleY == value) return value;
		scaleY = value;
		fullScaleY = scaleY * scale;
		updateTransformation();
		needsResize = true;
		return scaleY;
	}

	/**
	 * Scale factor of the screen. Final scale is scaleX * scale by scaleY * scale, so
	 * you can use this factor to scale the screen both horizontally and vertically.
	 */
	public var scale(default, set):Float = 1;
	private function set_scale(value:Float):Float
	{
		if (scale == value) return value;
		scale = value;
		fullScaleX = scaleX * scale;
		fullScaleY = scaleY * scale;
		updateTransformation();
		needsResize = true;
		return scale;
	}

	/**
	 * Final X scale value of the screen
	 */
	public var fullScaleX(default, null):Float = 1;

	/**
	 * Final Y scale value of the screen
	 */
	public var fullScaleY(default, null):Float = 1;

	/**
	 * True if the scale of the screen has changed.
	 */
	public var needsResize(default, null):Bool = false;

	/**
	 * Rotation of the screen, in degrees.
	 */
	public var angle(get, set):Float;
	private function get_angle():Float { return _angle * HXP.DEG; }
	private function set_angle(value:Float):Float
	{
		if (_angle == value * HXP.RAD) return value;
		_angle = value * HXP.RAD;
		updateTransformation();
		return _angle;
	}

	/**
	 * Whether screen smoothing should be used or not.
	 */
	public var smoothing(get, set):Bool;
	private function get_smoothing():Bool
	{
#if buffer
		return _bitmap[0].smoothing;
#else
		return Atlas.smooth;
#end
	}
	private function set_smoothing(value:Bool):Bool
	{
#if buffer
		_bitmap[0].smoothing = _bitmap[1].smoothing = value;
#else
		Atlas.smooth = value;
#end
		return value;
	}

	/**
	 * Width of the screen.
	 */
	public var width(default, null):Int;

	/**
	 * Height of the screen.
	 */
	public var height(default, null):Int;

	public var mouseX(get, null):Int;
	inline function get_mouseX():Int { return Std.int(_sprite.mouseX / fullScaleX); }

	public var mouseY(get, null):Int;
	inline function get_mouseY():Int { return Std.int(_sprite.mouseY / fullScaleY); }

	public var mouseUnscaledX(get, null):Int;
	inline function get_mouseUnscaledX():Int { return Std.int(_sprite.mouseX); }

	public var mouseUnscaledY(get, null):Int;
	inline function get_mouseUnscaledY():Int { return Std.int(_sprite.mouseY); }

	/**
	 * Captures the current screen as a BitmapData.
	 * @return	A new BitmapData object.
	 */
	public function capture():BitmapData
	{
#if buffer
		return _bitmap[_current].bitmapData.clone();
#else
		var screenshotBuffer = new BitmapData(HXP.windowWidth, HXP.windowHeight);
		screenshotBuffer.draw(HXP.stage);
		return screenshotBuffer;
#end
	}

	/**
	 * Saves a screenshot of the current stage as a PNG.
	 *
	 * @param	path	Filepath to save the screenshot.
	 */
	public function screenshot(path:String):Void
	{
#if native
		var img:BitmapData = capture();
		var encoded:ByteArray = img.encode("png", 1);
		var file = sys.io.File.write(path, true);
		file.writeString(encoded.toString());
		file.close();
#else
		throw "Screenshots are only available on native.";
#end
	}

	/**
	 * Cause the screen to shake for a specified length of time.
	 *
	 * @param	magnitude	Number of pixels to shake in any direction.
	 * @param	duration	Duration of shake effect, in seconds.
	 */
	public function shake(magnitude:Int, duration:Float, angularMagnitude:Int=0)
	{
		if (_shakeTime < duration) _shakeTime = duration;
		_shakeMagnitude = magnitude;
		_shakeAngularMagnitude = angularMagnitude;
	}

	/**
	 * Stop the screen from shaking immediately.
	 */
	public function shakeStop()
	{
		_shakeTime = 0;
	}

	public inline function applyToMatrix(matrix:Matrix):Void
	{
		matrix.a *= fullScaleX;
		matrix.b *= fullScaleY;
		matrix.c *= fullScaleX;
		matrix.d *= fullScaleY;
		matrix.tx *= fullScaleX;
		matrix.ty *= fullScaleY;
	}

	// Screen infromation.
	private var _sprite:Sprite;
	private var _bitmap:Array<Bitmap>;
	private var _current:Int;
	private var _matrix:Matrix;
	private var _angle:Float;
	private var _shakeTime:Float=0;
	private var _shakeMagnitude:Int=0;
	private var _shakeAngularMagnitude:Int=0;
	private var _shakeX:Int=0;
	private var _shakeY:Int=0;
	private var _shakeAngle:Int=0;
	private var _shakeZoom:Float=1;
}
