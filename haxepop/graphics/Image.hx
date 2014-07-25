package haxepop.graphics;

import haxepop.graphics.atlas.Atlas;
import haxepop.graphics.atlas.TextureAtlas;
import haxepop.graphics.atlas.TileAtlas;
import haxepop.graphics.atlas.AtlasRegion;
import haxepop.masks.Polygon;
import haxepop.utils.Vector;
import haxepop.utils.Math;
import haxepop.utils.Color;
import haxepop.Graphic;
import haxepop.HXP;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.display.Graphics;
import flash.display.JointStyle;
import flash.display.LineScaleMode;

/**
 * Performance-optimized non-animated image. Can be drawn to the screen with transformations.
 */
class Image extends Graphic
{

	/**
	 * Rotation of the image, in degrees.
	 */
	public var angle:Float;

	/**
	 * Scale of the image, effects both x and y scale.
	 */
	public var scale(get, set):Float;
	private inline function get_scale():Float { return _scale; }
	private inline function set_scale(value:Float):Float { return _scale = value; }

	/**
	 * X scale of the image.
	 */
	public var scaleX:Float;

	/**
	 * Y scale of the image.
	 */
	public var scaleY:Float;

	/**
	 * X origin of the image, determines transformation point.
	 * Defaults to top-left corner.
	 */
	public var originX:Float;

	/**
	 * Y origin of the image, determines transformation point.
	 * Defaults to top-left corner.
	 */
	public var originY:Float;

	/**
	 * Optional blend mode to use when drawing this image.
	 * Use constants from the flash.display.BlendMode class.
	 */
	public var blend:BlendMode;

	/**
	 * Constructor.
	 * @param	source		Source image.
	 * @param	clipRect	Optional rectangle defining area of the source image to draw.
	 */
	public function new(?source:ImageType, ?clipRect:Rectangle)
	{
		super();
		init();

		// check if the _source or _region were set in a higher class
		if (source != null)
		{
			switch (source.type)
			{
				case Left(bitmap):
					blit = true;
					_source = bitmap;
					_sourceRect = bitmap.rect;
				case Right(region):
					blit = false;
					_region = region;
					_sourceRect = new Rectangle(0, 0, _region.width, _region.height);
			}
		}

		if (clipRect != null)
		{
			if (clipRect.width == 0) clipRect.width = _sourceRect.width;
			if (clipRect.height == 0) clipRect.height = _sourceRect.height;
			if (!blit)
			{
				_region = _region.clip(clipRect); // create a new clipped region
			}
			_sourceRect = clipRect;
		}

		if (blit)
		{
			_bitmap = new Bitmap();
			_colorTransform = new ColorTransform();

			createBuffer();
			updateBuffer();
		}
	}

	/** @private Initialize variables */
	private inline function init()
	{
		angle = 0;
		scale = scaleX = scaleY = 1;
		originX = originY = 0;

		_alpha = 1;
		_flipped = false;
		_color = 0x00FFFFFF;
		_red = _green = _blue = 1;
		_matrix = HXP.matrix;
	}

	/** @private Creates the buffer. */
	private function createBuffer()
	{
		_buffer = Assets.createBitmap(Std.int(_sourceRect.width), Std.int(_sourceRect.height), true);
		_bufferRect = _buffer.rect;
		_bitmap.bitmapData = _buffer;
	}

	/** @private Computes the transformation matrix from scale, screen scale, offset, and rotation before rendering. */
	inline function computeMatrix(point:Point, camera:Camera)
	{
		var sx = scale * scaleX,
			sy = scale * scaleY;

		// determine drawing location
		_point.x = point.x + x - originX - camera.x * scrollX;
		_point.y = point.y + y - originY - camera.y * scrollY;

		var angle = angle * HXP.RAD;
		var cos = Math.cos(angle);
		var sin = Math.sin(angle);
		_matrix.a = sx * cos;
		_matrix.b = sx * sin;
		_matrix.c = -sy * sin;
		_matrix.d = sy * cos;
		_matrix.tx = (-originX * sx * cos + originY * sy * sin + originX + _point.x);
		_matrix.ty = (-originX * sx * sin - originY * sy * cos + originY + _point.y);

		// scale and rotate camera
		camera.applyToMatrix(_matrix, rotateWithCamera, scaleWithCamera);
		HXP.screen.applyToMatrix(_matrix);
	}

	/** Renders the image. */
	override public function render(target:BitmapData, point:Point, camera:Camera)
	{
		// only draw if buffer exists
		if (_buffer != null)
		{
			if (angle + (rotateWithCamera ? camera.angle : 0) == 0 && scaleX * HXP.screen.fullScaleX == 1 && scaleY * HXP.screen.fullScaleY == 1 && blend == null)
			{
			_point.x = point.x + x - originX - camera.x * scrollX;
			_point.y = point.y + y - originY - camera.y * scrollY;
				// render without transformation
				target.copyPixels(_buffer, _bufferRect, _point, null, null, true);
			}
			else
			{
				computeMatrix(point, camera);
				target.draw(_bitmap, _matrix, null, blend, null, _bitmap.smoothing);
			}
		}
	}

	override public function renderAtlas(layer:Int, point:Point, camera:Camera)
	{
		var sx = scale * scaleX,
			sy = scale * scaleY;

		// determine drawing location
		_point.x = point.x + x - originX - camera.x * scrollX;
		_point.y = point.y + y - originY - camera.y * scrollY;

		computeMatrix(point, camera);
		_region.drawMatrix(_matrix.tx, _matrix.ty, _matrix.a, _matrix.b, _matrix.c, _matrix.d, layer, _red, _green, _blue, _alpha, smooth);
	}

	/**
	 * Creates a new rectangle Image.
	 * @param	width		Width of the rectangle.
	 * @param	height		Height of the rectangle.
	 * @param	color		Color of the rectangle.
	 * @param	alpha		Alpha of the rectangle.
	 * @return	A new Image object of a rectangle.
	 */
	public static function createRect(width:Int, height:Int, color:Int = 0xFFFFFF, alpha:Float = 1):Image
	{
		if (width == 0 || height == 0)
			throw "Illegal rect, sizes cannot be 0.";

		var source:BitmapData = Assets.createBitmap(width, height, true, 0xFFFFFFFF);
		var image:Image;
#if hardware
		image = new Image(Atlas.loadImageAsRegion(source));
#else
		image = new Image(source);
#end

		image.color = color;
		image.alpha = alpha;

		return image;
	}

	/**
	 * Creates a new circle Image.
	 * @param	radius		Radius of the circle.
	 * @param	color		Color of the circle.
	 * @param	alpha		Alpha of the circle.
	 * @return	A new Image object of a circle.
	 */
	public static function createCircle(radius:Int, color:Int = 0xFFFFFF, alpha:Float = 1):Image
	{
		if (radius == 0)
			throw "Illegal circle, radius cannot be 0.";

		HXP.sprite.graphics.clear();
		HXP.sprite.graphics.beginFill(0xFFFFFF);
		HXP.sprite.graphics.drawCircle(radius, radius, radius);
		var data:BitmapData = Assets.createBitmap(radius * 2, radius * 2, true, 0);
		data.draw(HXP.sprite);

		var image:Image;
#if hardware
		image = new Image(Atlas.loadImageAsRegion(data));
#else
		image = new Image(data);
#end

		image.color = color;
		image.alpha = alpha;

		return image;
	}

	/**
	 * Creates a new polygon Image from an array of points.
	 * @param	polygon		A Polygon object to create the Image from.
	 * @param	color		Color of the polygon.
	 * @param	alpha		Alpha of the polygon.
	 * @param	fill		If the polygon should be filled with the color (true) or just an outline (false).
	 * @param	thick		How thick the outline should be (only applicable when fill = false).
	 * @return	A new Image object.
	 */
	public static function createPolygon(polygon:Polygon, color:Int = 0xFFFFFF, alpha:Float = 1, fill:Bool = true, thick:Int = 1):Image
	{
		var graphics:Graphics = HXP.sprite.graphics;
		var points:Array<Vector> = polygon.points;
		
		var minX:Float;
		var maxX:Float;
		var minY:Float;
		var maxY:Float;
		
		var p:Point;
		var originalAngle:Float = polygon.angle;
		
		polygon.angle = 0;	// set temporarily angle to 0 so we can sync with image angle later
		
		minX = minY = Math.NUMBER_MAX_VALUE;
		maxX = maxY = -Math.NUMBER_MAX_VALUE;
		
		// find polygon bounds
		for (p in points)
		{
			if (p.x < minX) minX = p.x;
			if (p.x > maxX) maxX = p.x;
			if (p.y < minY) minY = p.y;
			if (p.y > maxY) maxY = p.y;
		}
		
		var w:Int = Math.ceil(maxX - minX);
		var h:Int = Math.ceil(maxY - minY);
		
		if (color > 0xFFFFFF) color = 0xFFFFFF & color;
		graphics.clear();
		
		if (fill)
			graphics.beginFill(color, alpha);
		else
			graphics.lineStyle(thick, color, alpha, false, LineScaleMode.NORMAL, null, JointStyle.MITER);
			
		
		graphics.moveTo(points[points.length - 1].x, points[points.length - 1].y);		
		for (p in points)
		{
			graphics.lineTo(p.x, p.y);
		}
		graphics.endFill();
		
		HXP.matrix.identity();
		HXP.matrix.translate( -minX, -minY);

		var data:BitmapData = Assets.createBitmap(w, h, true, 0);
		data.draw(HXP.sprite, HXP.matrix);
		
		var image:Image;
#if hardware
		image = new Image(Atlas.loadImageAsRegion(data));
#else
		image = new Image(data);
#end
		
		// adjust position, origin and angle
		image.x = polygon.x + polygon.origin.x;
		image.y = polygon.y + polygon.origin.y;
		image.originX = image.x - polygon.minX;
		image.originY = image.y - polygon.minY;
		image.angle = originalAngle;
		polygon.angle = originalAngle;
		
		return image;
	}

	/**
	 * Updates the image buffer.
	 */
	public function updateBuffer(clearBefore:Bool = false)
	{
		if (_source == null) return;
		if (clearBefore) _buffer.fillRect(_bufferRect, 0);
		_buffer.copyPixels(_source, _sourceRect, HXP.zero);
		if (_tint != null) _buffer.colorTransform(_bufferRect, _tint);
	}

	private function updateColorTransform()
	{
		if (_alpha == 1 && _color == 0xFFFFFF)
		{
			_tint = null;
		}
		else
		{
			_tint = _colorTransform;
			_tint.redMultiplier = _red;
			_tint.greenMultiplier = _green;
			_tint.blueMultiplier = _blue;
			_tint.alphaMultiplier = _alpha;
		}
		updateBuffer();
	}

	/**
	 * Clears the image buffer.
	 */
	public function clear()
	{
		if (_buffer == null) return;
		_buffer.fillRect(_bufferRect, 0);
	}

	/**
	 * Change the opacity of the Image, a value from 0 to 1.
	 */
	public var alpha(get_alpha, set_alpha):Float;
	private inline function get_alpha():Float { return _alpha; }
	private function set_alpha(value:Float):Float
	{
		value = value < 0 ? 0 : (value > 1 ? 1 : value);
		if (_alpha == value) return value;
		_alpha = value;
		if (blit) updateColorTransform();
		return _alpha;
	}

	/**
	 * The tinted color of the Image. Use 0xFFFFFF to draw the Image normally.
	 */
	public var color(get_color, set_color):Int;
	private inline function get_color():Int { return _color; }
	private function set_color(value:Int):Int
	{
		value &= 0xFFFFFF;
		if (_color == value) return value;
		_color = value;
		// save individual color channel values
		_red = Color.getRed(_color) / 255;
		_green = Color.getGreen(_color) / 255;
		_blue = Color.getBlue(_color) / 255;
		if (blit) updateColorTransform();
		return _color;
	}

	/**
	 * If you want to draw the Image horizontally flipped. This is
	 * faster than setting scaleX to -1 if your image isn't transformed.
	 */
	public var flipped(get_flipped, set_flipped):Bool;
	private inline function get_flipped():Bool { return _flipped; }
	private function set_flipped(value:Bool):Bool
	{
		if (_flipped == value) return value;

		if (blit)
		{
			var temp:BitmapData = _source;
			if (!value || _flip != null)
			{
				_source = _flip;
			}
			else if (_flips.exists(temp))
			{
				_source = _flips.get(temp);
			}
			else
			{
				_source = Assets.createBitmap(_source.width, _source.height, true);
				_flips.set(temp, _source);
				HXP.matrix.identity();
				HXP.matrix.a = -1;
				HXP.matrix.tx = _source.width;
				_source.draw(temp, HXP.matrix);
			}
			_flip = temp;
			updateBuffer();
		}
		_flipped = value;
		return _flipped;
	}

	/**
	 * Centers the Image's originX/Y to its center.
	 */
	public function centerOrigin()
	{
		originX = Std.int(width / 2);
		originY = Std.int(height / 2);
	}

	/**
	 * Centers the Image's originX/Y to its center, and negates the offset by the same amount.
	 */
	public function centerOO()
	{
		x += originX;
		y += originY;
		centerOrigin();
		x -= originX;
		y -= originY;
	}


	/**
	 * If the image should be drawn transformed with pixel smoothing.
	 * This will affect drawing performance, but look less pixelly.
	 */
	#if buffer
	public var smooth(get_smooth, set_smooth):Bool;
	private inline function get_smooth():Bool { return _bitmap.smoothing; }
	private inline function set_smooth(s:Bool):Bool {
		return _bitmap.smoothing = s;
	}
	#else
	public var smooth:Bool = true;
	#end

	/**
	 * Width of the image.
	 */
	public var width(get_width, never):Int;
	private function get_width():Int { return Std.int(blit ? _bufferRect.width : (_region.rotate == 0 ? _region.width : _region.height)); }

	/**
	 * Height of the image.
	 */
	public var height(get_height, never):Int;
	private function get_height():Int { return Std.int(blit ? _bufferRect.height : (_region.rotate == 0 ? _region.height : _region.width)); }

	/**
	 * The scaled width of the image.
	 */
	public var scaledWidth(get_scaledWidth, set_scaledWidth):Float;
	private inline function get_scaledWidth():Float { return width * scaleX * scale; }
	private inline function set_scaledWidth(w:Float):Float {
		return scaleX = w / scale / width;
	}

	/**
	 * The scaled height of the image.
	 */
	public var scaledHeight(get_scaledHeight, set_scaledHeight):Float;
	private inline function get_scaledHeight():Float { return height * scaleY * scale; }
	private inline function set_scaledHeight(h:Float):Float {
		return scaleY = h / scale / height;
	}

	/**
	 * Clipping rectangle for the image.
	 */
	public var clipRect(get_clipRect, null):Rectangle;
	private inline function get_clipRect():Rectangle { return _sourceRect; }

	// Source and buffer information.
	private var _source:BitmapData;
	private var _sourceRect:Rectangle;
	private var _buffer:BitmapData;
	private var _bufferRect:Rectangle;
	private var _bitmap:Bitmap;
	private var _region:AtlasRegion;

	// Color and alpha information.
	private var _alpha:Float;
	private var _color:Int;
	private var _tint:ColorTransform;
	private var _colorTransform:ColorTransform;
	private var _matrix:Matrix;
	private var _red:Float;
	private var _green:Float;
	private var _blue:Float;

	// Flipped image information.
	private var _flipped:Bool;
	private var _flip:BitmapData;
	private static var _flips:Map<BitmapData, BitmapData> = new Map<BitmapData, BitmapData>();

	private var _scale:Float;
}
