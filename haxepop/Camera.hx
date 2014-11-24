package haxepop;

import haxepop.utils.Math;
import flash.geom.Point;
import flash.geom.Matrix;
import flash.geom.Rectangle;

class Camera
{
	public static var zero:Camera = new Camera();

	public var x(get, set):Float;
	inline function get_x() { return point.x; }
	inline function set_x(x:Float) { return point.x = x; }
	public var y(get, set):Float;
	inline function get_y() { return point.y; }
	inline function set_y(y:Float) { return point.y = y; }

	public var point:Point;

	public var angle(default, set):Float = 0;
	inline function set_angle(angle:Float)
	{
		return this.angle = angle % 360;
	}

	
	public var scale(get, set):Float;
	inline function get_scale() { return _scale; };
	inline function set_scale(scale:Float) { setScale(scale, scaleX, scaleY); return scale; }
	public var scaleX(get, set):Float;
	inline function get_scaleX() { return _scaleX; };
	inline function set_scaleX(scaleX:Float) { setScale(scale, scaleX, scaleY); return scale; }
	public var scaleY(get, set):Float;
	inline function get_scaleY() { return _scaleY; };
	inline function set_scaleY(scaleY:Float) { setScale(scale, scaleX, scaleY); return scale; }

	inline function setScale(scale:Float, scaleX:Float, scaleY:Float)
	{
		// TODO: ???
		//point.x -= HXP.halfWidth * _scale * _scaleX - HXP.halfWidth * scale * scaleX;
		//point.y -= HXP.halfHeight * _scale * _scaleY - HXP.halfHeight * scale * scaleY;
		_scale = scale;
		_scaleX = scaleX;
		_scaleY = scaleY;
	}

	public var fullScaleX(get, never):Float;
	inline function get_fullScaleX() { return _scale * _scaleX; }
	public var fullScaleY(get, never):Float;
	inline function get_fullScaleY() { return _scale * _scaleY; }

	public function new(x:Float = 0, y:Float = 0)
	{
		point = new Point(x, y);
	}

	/**
	 * Adjust the camera when resizing the screen.
	 */
	public function resize(oldWidth:Float, oldHeight:Float, width:Float, height:Float):Void
	{
		//x = x - oldWidth/2 + width/2;
		//y = y - oldHeight/2 + height/2;
	}

	/**
	 * Move the camera in its rotated direction.
	 */
	public function move(x:Float = 0, y:Float = 0):Void
	{
		var rads = angle * Math.RAD;
		var cos = Math.cos(rads);
		var sin = Math.sin(rads);
		this.x += x * cos + y * sin;
		this.y += x * sin + y * cos;
	}

	/**
	 * Rotate and scale a transformation matrix (in unscaled screen coordinate)
	 * using the camera's angle/scale.
	 */
	public inline function applyToMatrix(matrix:Matrix, rotate:Bool=true, scale:Bool=true)
	{
		if (rotate)
		{
			var halfWidth = HXP.screen.width/2, halfHeight = HXP.screen.height/2;
			var ox = halfWidth;
			var oy = halfHeight;
			matrix.translate(-ox, -oy);
			matrix.rotate(angle * HXP.RAD);
			matrix.translate(ox, oy);
		}
		if (scale) matrix.scale(fullScaleX, fullScaleY);
	}

	/**
	 * Use the camera angle/scale to transform a point from screen coordinates to
	 * game coordinates.
	 */
	public inline function applyToPoint(point:Point)
	{
		var halfWidth = HXP.screen.width/2, halfHeight = HXP.screen.height/2;
		var rads = -angle * Math.RAD;
		var cos = Math.cos(rads);
		var sin = Math.sin(rads);

		var dx = point.x - halfWidth;
		var dy = point.y - halfHeight;
		point.x = halfWidth + dx * cos - dy * sin;
		point.y = halfHeight + dx * sin + dy * cos;
	}

	public var screenRect(get, never):Rectangle;
	function get_screenRect()
	{
		var w = HXP.width, h = HXP.height;
		var rads = angle * Math.RAD;
		var cos = Math.abs(Math.cos(rads));
		var sin = Math.abs(Math.sin(rads));

		_rect.width = Math.ceil(w * cos + h * sin);
		_rect.height = Math.ceil(w * sin + h * cos);
		_rect.top = Math.floor((y + h/2) - _rect.height / 2);
		_rect.left = Math.floor((x + w/2) - _rect.width / 2);

		return _rect;
	}

	var _scale:Float = 1;
	var _scaleX:Float = 1;
	var _scaleY:Float = 1;
	var _rect:Rectangle = new Rectangle();
}
