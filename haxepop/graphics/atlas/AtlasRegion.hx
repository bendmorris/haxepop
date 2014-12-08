package haxepop.graphics.atlas;

import flash.display.BitmapData;
import flash.geom.Rectangle;
import flash.geom.Point;
import flash.geom.Matrix;

class AtlasRegion
{

	public var parent:AtlasData;
	public var rect:Rectangle;

	/**
	 * Amount to rotate the image, in degrees (used for sprite packing)
	 */
	public var rotate:Float;
	/**
	 * The tile index used for rendering
	 */
	public var tileIndex(default, null):Int;
	/**
	 * Width of this region
	 */
	public var width(get, never):Float;
	/**
	 * Height of this region
	 */
	public var height(get, never):Float;

	/**
	 * Creates a new AtlasRegion
	 * @param  parent    The AtlasData parent to use for rendering
	 * @param  tileIndex The tile index to use for drawTiles
	 * @param  rect      Rectangle to set for width/height
	 */
	public function new(parent:AtlasData, rect:Rectangle)
	{
		this.parent = parent;
		this.rect = rect;
		this.rotate = 0;
	}

	/**
	 * Clips an atlas region
	 * @param	clipRect	A clip rectangle with coordinates local to the region
	 * @param	center		The new center point
	 * @return	A new atlas region with the clipped coordinates
	 */
	public function clip(clipRect:Rectangle, ?center:Point):AtlasRegion
	{
		// make a copy of clipRect, to avoid modifying the original
		var clipRectCopy = new Rectangle( clipRect.x, clipRect.y, clipRect.width, clipRect.height );

		// only clip within the current region
		if (clipRectCopy.x + clipRectCopy.width > rect.width)
			clipRectCopy.width = rect.width - clipRectCopy.x;
		if (clipRectCopy.y + clipRectCopy.height > rect.height)
			clipRectCopy.height = rect.height - clipRectCopy.y;

		// do not allow negative width/height
		if (clipRectCopy.width < 0) clipRectCopy.width = 0;
		if (clipRectCopy.height < 0) clipRectCopy.height = 0;

		// position clip rect where the last image was
		clipRectCopy.x += rect.x;
		clipRectCopy.y += rect.y;
		return parent.createRegion(clipRectCopy, center);
	}

	/**
	 * Prepares tile data for rendering
	 * @param	x		The x-axis location to draw the tile
	 * @param	y		The y-axis location to draw the tile
	 * @param	layer	The layer to draw on
	 * @param	scaleX	The scale value for the x-axis
	 * @param	scaleY	The scale value for the y-axis
	 * @param	angle	An angle to rotate the tile in degrees
	 * @param	red		A red tint value
	 * @param	green	A green tint value
	 * @param	blue	A blue tint value
	 * @param	alpha	The tile's opacity
	 */
	public inline function draw(x:Float, y:Float, layer:Int,
		scaleX:Float=1, scaleY:Float=1, angle:Float=0,
		red:Float=1, green:Float=1, blue:Float=1, alpha:Float=1, ?smooth:Bool)
	{
		if (smooth == null) smooth = Atlas.smooth;
		if (rotate != 0)
		{
			angle += rotate;
			x += height * scaleX;
		}

		parent.prepareTile(rect, x, y, layer, scaleX, scaleY, angle, red, green, blue, alpha, smooth);
	}

	/**
	 * Prepares tile data for rendering using a matrix
	 * @param  tx    X-Axis translation
	 * @param  ty    Y-Axis translation
	 * @param  a     Top-left
	 * @param  b     Top-right
	 * @param  c     Bottom-left
	 * @param  d     Bottom-right
	 * @param  layer The layer to draw on
	 * @param  red   Red color value
	 * @param  green Green color value
	 * @param  blue  Blue color value
	 * @param  alpha Alpha value
	 */
	public inline function drawMatrix(tx:Float, ty:Float, a:Float, b:Float, c:Float, d:Float,
		layer:Int, red:Float=1, green:Float=1, blue:Float=1, alpha:Float=1, ?smooth:Bool)
	{
		if (smooth == null) smooth = Atlas.smooth;

		if (rotate != 0)
		{
			var matrix = new Matrix(a, b, c, d, tx, ty);
			matrix.rotate(rotate * HXP.RAD);
			//matrix.tx += height * scaleX;
			parent.prepareTileMatrix(rect, layer,
				matrix.tx, matrix.ty, matrix.a, matrix.b, matrix.c, matrix.d,
				red, green, blue, alpha, smooth);
		}
		else
		{
			parent.prepareTileMatrix(rect, layer, tx, ty, a, b, c, d, red, green, blue, alpha, smooth);
		}
	}

	public inline function drawTriangles(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, x4:Float, y4:Float, color:Int=0xFFFFFFFF)
	{
		var u1 = rect.x / parent.width;
		var v1 = rect.y / parent.height;
		var u2 = (rect.x + rect.width) / parent.width;
		var v2 = v1;
		var u3 = u2;
		var v3 = (rect.y + rect.height) / parent.height;
		var u4 = u1;
		var v4 = v3;
		parent.prepareTriangles(x1,y1,x2,y2,x3,y3,x4,y4,u1,v1,u2,v2,u3,v3,u4,v4,color);
	}

	public function destroy():Void
	{
		if (parent != null)
		{
			parent.destroy();
			parent = null;
		}
	}

	public function getBitmapData():BitmapData
	{
		var bd:BitmapData = new BitmapData(Std.int(width), Std.int(height), true, 0);
		bd.copyPixels(parent._source, rect, new Point());
		if (rotate != 0)
		{
			var newBd:BitmapData = new BitmapData(Std.int(height), Std.int(width), true, 0);
			// TODO: this matrix is only correct for GDX's rotation
			var m:Matrix = new Matrix(0, 1, -1, 0, height, 0);
			newBd.draw(bd, m);
			bd.dispose();
			bd = newBd;
		}
		return bd;
	}

	/**
	 * Prints the region as a string
	 *
	 * @return	String version of the object.
	 */
	public function toString():String
	{
		return '[AtlasRegion ${rect.x},${rect.y} ${rect.width}x${rect.height}';
	}

	private inline function get_width():Float { return rect.width; }
	private inline function get_height():Float { return rect.height; }
}
