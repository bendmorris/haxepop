package haxepop.graphics.atlas;

import haxepop.Scene;
import haxepop.ds.Either;
import haxepop.utils.Math;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.geom.Rectangle;
import flash.geom.Point;
import flash.geom.Matrix;
import openfl.display.Tilesheet;

abstract AtlasDataType(AtlasData)
{
	private inline function new(data:AtlasData) this = data;
	@:to public inline function toAtlasData():AtlasData return this;

	@:from public static inline function fromString(s:String) {
		return new AtlasDataType(AtlasData.getAtlasDataByName(s, true));
	}
	@:from public static inline function fromBitmapData(bd:BitmapData) {
		return new AtlasDataType(new AtlasData(bd));
	}
	@:from public static inline function fromAtlasData(data:AtlasData) {
		return new AtlasDataType(data);
	}
}

@:allow(haxepop.graphics.atlas.AtlasRegion)
class AtlasData
{

	public var width(default, null):Int;
	public var height(default, null):Int;

	public static inline var BLEND_NONE:Int = 0;
	public static inline var BLEND_ADD:Int = Tilesheet.TILE_BLEND_ADD;
	public static inline var BLEND_NORMAL:Int = Tilesheet.TILE_BLEND_NORMAL;
#if flash
	public static inline var BLEND_MULTIPLY:Int = BLEND_NONE;
	public static inline var BLEND_SCREEN:Int = BLEND_NONE;
#else
	public static inline var BLEND_MULTIPLY:Int = Tilesheet.TILE_BLEND_MULTIPLY;
	public static inline var BLEND_SCREEN:Int = Tilesheet.TILE_BLEND_SCREEN;
#end

	/**
	 * Creates a new AtlasData class
	 * NOTE: Only create one instace of AtlasData per name. An error will be thrown if you try to create a duplicate.
	 * @param bd     BitmapData image to use for rendering
	 * @param name   A reference to the image data, used with destroy and for setting rendering flags
	 */
	public function new(bd:BitmapData, ?name:String, ?flags:Int)
	{
		_rects = new Array<Rectangle>();
		_data = new Array<Float>();
		_smoothData = new Array<Float>();
		_vertices = new Array<Float>();
		_indices = new Array<Int>();
		_uvtData = new Array<Float>();
		_colors = new Array<Int>();
		_dataIndex = _smoothDataIndex = _uvtDataIndex = _verticesIndex = _indicesIndex = _colorsIndex = 0;

		_source = bd;
		_tilesheet = new Tilesheet(bd);
		// create a unique name if one is not specified
		if (name == null)
		{
			name = "bitmapData_" + (_uniqueId++);
		}
		_name = name;

		if (_dataPool.exists(_name))
		{
			throw "There should never be a duplicate AtlasData instance!";
		}
		else
		{
			_dataPool.set(_name, this);
		}

		_renderFlags = Tilesheet.TILE_TRANS_2x2 | Tilesheet.TILE_ALPHA | Tilesheet.TILE_BLEND_NORMAL | Tilesheet.TILE_RGB;
		_flagAlpha = true;
		_flagRGB = true;

		width = bd.width;
		height = bd.height;
	}

	/**
	 * Get's the atlas data for a specific texture, useful for setting rendering flags
	 * @param	name	The name of the image file
	 * @return	An AtlasData object (will create one if it doesn't already exist)
	 */
	public static inline function getAtlasDataByName(name:String, create:Bool=false):AtlasData
	{
		var data:AtlasData = null;
		if (_dataPool.exists(name))
		{
			data = _dataPool.get(name);
		}
		else if(create)
		{
			var bitmap:BitmapData = Assets.getBitmap(name);
			if (bitmap != null)
			{
				data = new AtlasData(bitmap, name);
			}
		}
		return data;
	}

	/**
	 * String representation of AtlasData
	 * @return the name of the AtlasData
	 */
	public function toString():String
	{
		return _name;
	}

	/**
	 * Reloads the image for a particular atlas object
	 */
	public function reload(bd:BitmapData):Void
	{
		Assets.overwriteBitmapCache(_name, bd);
		_tilesheet = new Tilesheet(bd);
		_source = bd;
		// recreate tile indexes
		for (r in _rects)
		{
			_tilesheet.addTileRect(r);
		}
	}

	/**
	 * Sets the scene object
	 * @param	scene	The scene object to set
	 */
	@:allow(haxepop.Scene)
	private static inline function startScene(scene:Scene):Void
	{
		_scene = scene;
		_scene.sprite.graphics.clear();
	}

	/**
	 * The active atlas data object
	 */
	public static var active(default, set):AtlasData;
	private static inline function set_active(?value:AtlasData):AtlasData
	{
		if (active != value)
		{
			if (active != null)
				active.flush();
			active = value;
		}
		return value;
	}

	/**
	 * Removes the object from memory
	 */
	public function destroy():Void
	{
		Assets.removeBitmap(_name);
		_dataPool.remove(_name);
	}

	/**
	 * Removes all atlases from the display list
	 */
	public static function destroyAll():Void
	{
		for (atlas in _dataPool)
		{
			atlas.destroy();
		}
	}

	/**
	 * Creates a new AtlasRegion
	 * @param	rect	Defines the rectangle of the tile on the tilesheet
	 * @param	center	Positions the local center point to pivot on (not used)
	 *
	 * @return The new AtlasRegion object.
	 */
	public inline function createRegion(rect:Rectangle, ?center:Point, ?rotate:Float=0):AtlasRegion
	{
		var r = rect.clone();
		_rects.push(r);
		var tileIndex = _tilesheet.addTileRect(r, null);
		var region = new AtlasRegion(this, tileIndex, r);
		region.rotate = rotate;
		return region;
	}

	/**
	 * Flushes the renderable data array
	 */
	public inline function flush():Void
	{
		if (_dataIndex != 0)
		{
			_tilesheet.drawTiles(_scene.sprite.graphics, _data, false, _renderFlags, _dataIndex);
			_dataIndex = 0;
		}

		if (_smoothDataIndex != 0)
		{
			_tilesheet.drawTiles(_scene.sprite.graphics, _smoothData, true, _renderFlags, _smoothDataIndex);
			_smoothDataIndex = 0;
		}

		if (_uvtDataIndex > 0)
		{
#if cpp
			_vertices.splice(_verticesIndex, _vertices.length - _verticesIndex);
			_indices.splice(_indicesIndex, _indices.length - _indicesIndex);
			_uvtData.splice(_uvtDataIndex, _uvtData.length - _uvtDataIndex);
			_uvtData.splice(_colorsIndex, _colors.length - _colorsIndex);
#else
			untyped _vertices.length = _verticesIndex;
			untyped _indices.length = _indicesIndex;
			untyped _uvtData.length = _uvtDataIndex;
			untyped _colors.length = _colorsIndex;
#end
			_uvtDataIndex = _verticesIndex = _indicesIndex = _colorsIndex = 0;

			_scene.sprite.graphics.beginBitmapFill(_source);
			_scene.sprite.graphics.drawTriangles(_vertices, _indices, _uvtData, null, _colors);
			_scene.sprite.graphics.endFill();
		}
	}

	/**
	 * Prepares a tile to be drawn using a matrix
	 * @param  tile  The tile index to draw
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
	public inline function prepareTileMatrix(tile:Int, layer:Int,
		tx:Float, ty:Float, a:Float, b:Float, c:Float, d:Float,
		red:Float, green:Float, blue:Float, alpha:Float, ?smooth:Bool)
	{
		active = this;

		if (smooth == null) smooth = Atlas.smooth;

		var _data = smooth ? _smoothData : _data;
		var _dataIndex = smooth ? _smoothDataIndex : _dataIndex;

		_data[_dataIndex++] = tx;
		_data[_dataIndex++] = ty;
		_data[_dataIndex++] = tile;

		// matrix transformation
		_data[_dataIndex++] = a; // m00
		_data[_dataIndex++] = b; // m10
		_data[_dataIndex++] = c; // m01
		_data[_dataIndex++] = d; // m11

		// color
		if (_flagRGB)
		{
			_data[_dataIndex++] = red;
			_data[_dataIndex++] = green;
			_data[_dataIndex++] = blue;
		}
		if (_flagAlpha)
		{
			_data[_dataIndex++] = alpha;
		}

		if (smooth)
		{
			this._smoothDataIndex = _dataIndex;
		}
		else
		{
			this._dataIndex = _dataIndex;
		}
	}

	/**
	 * Prepares a tile to be drawn
	 * @param  tile   The tile index to draw
	 * @param  x      The x-axis value
	 * @param  y      The y-axis value
	 * @param  layer  The layer to draw on
	 * @param  scaleX X-Axis scale
	 * @param  scaleY Y-Axis scale
	 * @param  angle  Angle (in degrees)
	 * @param  red    Red color value
	 * @param  green  Green color value
	 * @param  blue   Blue color value
	 * @param  alpha  Alpha value
	 */
	public inline function prepareTile(tile:Int, x:Float, y:Float, layer:Int,
		scaleX:Float, scaleY:Float, angle:Float,
		red:Float, green:Float, blue:Float, alpha:Float, ?smooth:Bool)
	{
		active = this;

		if (smooth == null) smooth = Atlas.smooth;

		var _data = smooth ? _smoothData : _data;
		var _dataIndex = smooth ? _smoothDataIndex : _dataIndex;

		_data[_dataIndex++] = x;
		_data[_dataIndex++] = y;
		_data[_dataIndex++] = tile;

		// matrix transformation
		if (angle == 0)
		{
			// fast defaults for non-rotated tiles (cos=1, sin=0)
			_data[_dataIndex++] = scaleX; // m00
			_data[_dataIndex++] = 0; // m01
			_data[_dataIndex++] = 0; // m10
			_data[_dataIndex++] = scaleY; // m11
		}
		else
		{
			var cos = Math.cos(-angle * Math.RAD);
			var sin = Math.sin(-angle * Math.RAD);
			_data[_dataIndex++] = cos * scaleX; // m00
			_data[_dataIndex++] = -sin * scaleY; // m10
			_data[_dataIndex++] = sin * scaleX; // m01
			_data[_dataIndex++] = cos * scaleY; // m11
		}

		if (_flagRGB)
		{
			_data[_dataIndex++] = red;
			_data[_dataIndex++] = green;
			_data[_dataIndex++] = blue;
		}
		if (_flagAlpha)
		{
			_data[_dataIndex++] = alpha;
		}

		if (smooth)
		{
			this._smoothDataIndex = _dataIndex;
		}
		else
		{
			this._dataIndex = _dataIndex;
		}
	}

	public inline function prepareTriangles(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, x4:Float, y4:Float,
		u1:Float, v1:Float, u2:Float, v2:Float, u3:Float, v3:Float, u4:Float, v4:Float, color:Int=0xFFFFFFFF)
	{
		active = this;
		var indexStart = Std.int(_verticesIndex / 2);
		_indices[_indicesIndex++] = indexStart++;
		_indices[_indicesIndex++] = indexStart++;
		_indices[_indicesIndex++] = indexStart;
		_indices[_indicesIndex++] = indexStart++;
		_indices[_indicesIndex++] = indexStart++;
		_indices[_indicesIndex++] = indexStart - 4;
		_vertices[_verticesIndex++] = x1;
		_vertices[_verticesIndex++] = y1;
		_vertices[_verticesIndex++] = x2;
		_vertices[_verticesIndex++] = y2;
		_vertices[_verticesIndex++] = x3;
		_vertices[_verticesIndex++] = y3;
		_vertices[_verticesIndex++] = x4;
		_vertices[_verticesIndex++] = y4;
		_uvtData[_uvtDataIndex++] = u1;
		_uvtData[_uvtDataIndex++] = v1;
		_uvtData[_uvtDataIndex++] = u2;
		_uvtData[_uvtDataIndex++] = v2;
		_uvtData[_uvtDataIndex++] = u3;
		_uvtData[_uvtDataIndex++] = v3;
		_uvtData[_uvtDataIndex++] = u4;
		_uvtData[_uvtDataIndex++] = v4;
		_colors[_colorsIndex++] = color;
		_colors[_colorsIndex++] = color;
		_colors[_colorsIndex++] = color;
		_colors[_colorsIndex++] = color;
		_colors[_colorsIndex++] = color;
		_colors[_colorsIndex++] = color;
	}

	/**
	 * Sets the render flag to enable/disable alpha
	 * Default: true
	 */
	public var alpha(get, set):Bool;
	private function get_alpha():Bool { return (_renderFlags & Tilesheet.TILE_ALPHA != 0); }
	private function set_alpha(value:Bool):Bool
	{
		if (value) _renderFlags |= Tilesheet.TILE_ALPHA;
		else _renderFlags &= ~Tilesheet.TILE_ALPHA;
		_flagAlpha = value;
		return value;
	}

	/**
	 * Sets the render flag to enable/disable rgb tinting
	 * Default: true
	 */
	public var rgb(get, set):Bool;
	private function get_rgb():Bool { return (_renderFlags & Tilesheet.TILE_RGB != 0); }
	private function set_rgb(value:Bool)
	{
		if (value) _renderFlags |= Tilesheet.TILE_RGB;
		else _renderFlags &= ~Tilesheet.TILE_RGB;
		_flagRGB = value;
		return value;
	}

	/**
	 * Sets the blend mode for rendering (BLEND_NONE, BLEND_NORMAL, BLEND_ADD)
	 * Default: BLEND_NORMAL
	 */
	public var blend(get, set):Int;
	private function get_blend():Int {
		if (_renderFlags & Tilesheet.TILE_BLEND_NORMAL != 0)
			return BLEND_NORMAL;
		else if (_renderFlags & Tilesheet.TILE_BLEND_ADD != 0)
			return BLEND_ADD;
#if !flash
		else if (_renderFlags & Tilesheet.TILE_BLEND_MULTIPLY != 0)
			return BLEND_MULTIPLY;
		else if (_renderFlags & Tilesheet.TILE_BLEND_SCREEN != 0)
			return BLEND_SCREEN;
#end
		else
			return BLEND_NONE;
	}
	private function set_blend(value:Int):Int
	{
		// unset blend flags
		_renderFlags &= ~(BLEND_ADD | BLEND_SCREEN | BLEND_MULTIPLY | BLEND_NORMAL);

		// check that value is actually a blend flag
		if (value == BLEND_ADD ||
			value == BLEND_MULTIPLY ||
			value == BLEND_SCREEN ||
			value == BLEND_NORMAL)
		{
			// set the blend flag
			_renderFlags |= value;
			return value;
		}
		return BLEND_NONE;
	}

	// used for pooling
	private var _name:String;

	private var _layerIndex:Int = 0;

	private var _renderFlags:Int;
	private var _flagRGB:Bool;
	private var _flagAlpha:Bool;

	private var _source:BitmapData;
	// for drawTiles
	private var _tilesheet:Tilesheet;
	private var _data:Array<Float>;
	private var _dataIndex:Int;
	private var _smoothData:Array<Float>;
	private var _smoothDataIndex:Int;
	private var _rects:Array<Rectangle>;
	// for drawTriangles
	private var _vertices:Array<Float>;
	private var _indices:Array<Int>;
	private var _uvtData:Array<Float>;
	private var _colors:Array<Int>;
	private var _uvtDataIndex:Int;
	private var _verticesIndex:Int;
	private var _indicesIndex:Int;
	private var _colorsIndex:Int;

	private static var _scene:Scene;
	private static var _dataPool:Map<String, AtlasData> = new Map<String, AtlasData>();
	private static var _uniqueId:Int = 0; // allows for unique names
}
