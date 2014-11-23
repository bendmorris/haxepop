package haxepop.graphics.atlas;

import haxepop.graphics.atlas.AtlasData;
import flash.display.Sprite;
import flash.geom.Rectangle;

class Atlas
{

	/**
	 * Whether or not to use antialiasing (default: false)
	 */
	public static var smooth:Bool = false;

	/**
	 * The width of this atlas
	 */
	public var width(get, never):Int;
	private function get_width():Int { return _data.width; }

	/**
	 * The height of this atlas
	 */
	public var height(get, never):Int;
	private function get_height():Int { return _data.height; }

	private function new(source:AtlasDataType)
	{
		if (source != null)
			_data = source;
	}

	/**
	 * Loads an image and returns the full image as a region
	 * @param	source	The image to use
	 * @return	An AtlasRegion containing the whole image
	 */
	public static function loadImageAsRegion(source:AtlasDataType):AtlasRegion
	{
		var data:AtlasData = source;
		return data.createRegion(new Rectangle(0, 0, data.width, data.height));
	}

	/**
	 * Removes an atlas from the display list
	 */
	public function destroy()
	{
		_data.destroy();
	}

	/**
	 * Prepares tile data for rendering
	 * @param	tile	The tile index of the tilesheet
	 * @param	x		The x-axis location to draw the tile
	 * @param	y		The y-axis location to draw the tile
	 * @param	layer	The layer to draw on
	 * @param	scaleX	The scale value for the x-axis
	 * @param	scaleY	The scale value for the y-axis
	 * @param	angle	An angle to rotate the tile
	 * @param	red		A red tint value
	 * @param	green	A green tint value
	 * @param	blue	A blue tint value
	 * @param	alpha	The tile's opacity
	 */
	public inline function prepareTile(tile:Int, x:Float, y:Float, layer:Int,
		scaleX:Float, scaleY:Float, angle:Float,
		red:Float, green:Float, blue:Float, alpha:Float, ?smooth:Bool)
	{
		_data.prepareTile(tile, x, y, layer, scaleX, scaleY, angle, red, green, blue, alpha, smooth);
	}

	/**
	 * Prepares tile data for rendering using a matrix
	 * @param  tile  The tile index of the tilesheet
	 * @param  layer The layer to draw on
	 * @param  tx    X-Axis translation
	 * @param  ty    Y-Axis translation
	 * @param  a     Top-left
	 * @param  b     Top-right
	 * @param  c     Bottom-left
	 * @param  d     Bottom-right
	 * @param  red   Red color value
	 * @param  green Green color value
	 * @param  blue  Blue color value
	 * @param  alpha Alpha value
	 */
	public inline function prepareTileMatrix(tile:Int, layer:Int, tx:Float, ty:Float, a:Float, b:Float, c:Float, d:Float,
		red:Float=1, green:Float=1, blue:Float=1, alpha:Float=1, ?smooth:Bool)
	{
		if (smooth == null) smooth = Atlas.smooth;

		_data.prepareTileMatrix(tile, layer, tx, ty, a, b, c, d, red, green, blue, alpha, smooth);
	}

	public function prepareTriangles(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, x4:Float, y4:Float,
		u1:Float, v1:Float, u2:Float, v2:Float, u3:Float, v3:Float, u4:Float, v4:Float, color:Int=0xFFFFFFFF)
	{
		_data.prepareTriangles(x1, y1, x2, y2, x3, y3, x4, y4, u1, v1, u2, v2, u3, v3, u4, v4, color);
	}

	/**
	 * How many Atlases are active.
	 */
	// public static var count(get, never):Int;
	// private static inline function get_count():Int { return _atlases.length; }

	private var _data:AtlasData;
}
