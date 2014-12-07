package haxepop.graphics;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.geom.Matrix;
import haxepop.Graphic;
import haxepop.HXP;
import haxepop.graphics.atlas.TileAtlas;
import haxepop.masks.Grid;
import haxepop.utils.Color;

typedef Array2D = Array<Array<Int>>

class Tilemap extends Graphic
{
	/**
	 * Rotation of the tilemap, in degrees.
	 */
	public var angle:Float;

	/**
	 * Scale of the tilemap, effects both x and y scale.
	 */
	public var scale:Float;

	/**
	 * X scale of the tilemap.
	 */
	public var scaleX:Float;

	/**
	 * Y scale of the tilemap.
	 */
	public var scaleY:Float;

	/**
	 * If x/y positions should be used instead of columns/rows.
	 */
	public var usePositions:Bool;

	/**
	 * Wrap the tilemap horizontally.
	 */
	public var wrapX:Bool = false;

	/**
	 * Wrap the tilemap vertically.
	 */
	public var wrapY:Bool = false;

	/**
	 * Constructor.
	 * @param	tileset				The source tileset image.
	 * @param	width				Width of the tilemap, in pixels.
	 * @param	height				Height of the tilemap, in pixels.
	 * @param	tileWidth			Tile width.
	 * @param	tileHeight			Tile height.
	 * @param	tileSpacingWidth	Tile horizontal spacing.
	 * @param	tileSpacingHeight	Tile vertical spacing.
	 */
	public function new(tileset:TileType, width:Int, height:Int, tileWidth:Int, tileHeight:Int, ?tileSpacingWidth:Int=0, ?tileSpacingHeight:Int=0, ?tileOffsetX:Int=0, ?tileOffsetY:Int=0)
	{
		super();

		_rect = HXP.rect;

		var fullTileWidth = tileWidth + tileSpacingWidth,
			fullTileHeight = tileHeight + tileSpacingHeight;

		// set some tilemap information
		_width = width - (width % tileWidth);
		_height = height - (height % tileHeight);
		_columns = Std.int(_width / tileWidth);
		_rows = Std.int(_height / tileHeight);

		this.tileSpacingWidth = tileSpacingWidth;
		this.tileSpacingHeight = tileSpacingHeight;
		this.tileOffsetX = tileOffsetX;
		this.tileOffsetY = tileOffsetY;

		if (_columns == 0 || _rows == 0)
			throw "Cannot create a bitmapdata of width/height = 0";

		// create the canvas
#if neko
		_maxWidth = 4000 - 4000 % tileWidth;
		_maxHeight = 4000 - 4000 % tileHeight;
#else
		_maxWidth -= _maxWidth % tileWidth;
		_maxHeight -= _maxHeight % tileHeight;
#end

		_color = 0xFFFFFF;
		_red = _green = _blue = 1;
		_alpha = 1;
		_graphics = HXP.sprite.graphics;
		_matrix = new Matrix();
		_rect = new Rectangle();
		_colorTransform = new ColorTransform();
		_buffers = new Array<BitmapData>();
		_midBuffers = new Array<BitmapData>();
		angle = 0;
		scale = scaleX = scaleY = 1;

		_width = width;
		_height = height;

#if buffer
		initBuffers();
#end

		// initialize map
		_tile = new Rectangle(0, 0, tileWidth, tileHeight);
		_map = new Array2D();
		for (y in 0..._rows)
		{
			_map[y] = new Array<Int>();
			for (x in 0..._columns)
			{
				_map[y][x] = -1;
			}
		}

		// load the tileset graphic
		switch (tileset.type)
		{
			case Left(bd):
				blit = true;
				_set = new Bitmap(bd);
			case Right(atlas):
				blit = false;
				_atlas = atlas;
				atlas.prepare(tileWidth, tileHeight, tileSpacingWidth, tileSpacingHeight, tileOffsetX, tileOffsetY);
		}

		if (_set == null && _atlas == null)
			throw "Invalid tileset graphic provided.";

		if (blit)
		{
			_setColumns = Std.int(_set.width / fullTileWidth);
			_setRows = Std.int(_set.height / fullTileHeight);
		}
		else
		{
			_setColumns = Std.int(_atlas.width / fullTileWidth);
			_setRows = Std.int(_atlas.height / fullTileHeight);
		}
		_setCount = _setColumns * _setRows;
	}

	function initBuffers()
	{
		_refWidth = Math.ceil(width / _maxWidth);
		_refHeight = Math.ceil(height / _maxHeight);
		_ref = Assets.createBitmap(_refWidth, _refHeight);
		var x:Int = 0, y:Int = 0, w:Int, h:Int, i:Int = 0,
			ww:Int = _width % _maxWidth,
			hh:Int = _height % _maxHeight;
		if (ww == 0) ww = _maxWidth;
		if (hh == 0) hh = _maxHeight;
		while (y < _refHeight)
		{
			h = y < _refHeight - 1 ? _maxHeight : hh;
			while (x < _refWidth)
			{
				w = x < _refWidth - 1 ? _maxWidth : ww;
				_ref.setPixel(x, y, i);
				_buffers[i] = Assets.createBitmap(w, h, true);
				i ++; x ++;
			}
			x = 0; y ++;
		}
	}

	/**
	 * Sets the index of the tile at the position.
	 * @param	column		Tile column.
	 * @param	row			Tile row.
	 * @param	index		Tile index.
	 */
	public function setTile(column:Int, row:Int, index:Int = 0)
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
		}
		index %= _setCount;
		column %= _columns;
		row %= _rows;
		_map[row][column] = index;
#if buffer
		_tile.x = (index % _setColumns) * (_tile.width + tileSpacingWidth) + tileOffsetX;
		_tile.y = Std.int(index / _setColumns) * (_tile.height + tileSpacingHeight) + tileOffsetY;
		draw(column * _tile.width, row * _tile.height, _set.bitmapData, _tile);
#end
	}

	/**
	 * Clears the tile at the position.
	 * @param	column		Tile column.
	 * @param	row			Tile row.
	 */
	public function clearTile(column:Int, row:Int)
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
		}
		column %= _columns;
		row %= _rows;
		_map[row][column] = -1;
		if (blit)
		{
			_tile.x = column * _tile.width;
			_tile.y = row * _tile.height;
			fill(_tile, 0, 0);
		}
	}

	/**
	 * Gets the tile index at the position.
	 * @param	column		Tile column.
	 * @param	row			Tile row.
	 * @return	The tile index.
	 */
	public function getTile(column:Int, row:Int):Int
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
		}
		return _map[row % _rows][column % _columns];
	}

	/**
	 * Sets a rectangular region of tiles to the index.
	 * @param	column		First tile column.
	 * @param	row			First tile row.
	 * @param	width		Width in tiles.
	 * @param	height		Height in tiles.
	 * @param	index		Tile index.
	 */
	public function setRect(column:Int, row:Int, width:Int = 1, height:Int = 1, index:Int = 0)
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
			width = Std.int(width / _tile.width);
			height = Std.int(height / _tile.height);
		}
		column %= _columns;
		row %= _rows;
		var c:Int = column,
			r:Int = column + width,
			b:Int = row + height,
			u:Bool = usePositions;
		usePositions = false;
		while (row < b)
		{
			while (column < r)
			{
				setTile(column, row, index);
				column ++;
			}
			column = c;
			row ++;
		}
		usePositions = u;
	}

	/**
	 * Clears the rectangular region of tiles.
	 * @param	column		First tile column.
	 * @param	row			First tile row.
	 * @param	width		Width in tiles.
	 * @param	height		Height in tiles.
	 */
	public function clearRect(column:Int, row:Int, width:Int = 1, height:Int = 1)
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
			width = Std.int(width / _tile.width);
			height = Std.int(height / _tile.height);
		}
		column %= _columns;
		row %= _rows;
		var c:Int = column,
			r:Int = column + width,
			b:Int = row + height,
			u:Bool = usePositions;
		usePositions = false;
		while (row < b)
		{
			while (column < r)
			{
				clearTile(column, row);
				column ++;
			}
			column = c;
			row ++;
		}
		usePositions = u;
	}

	/**
	 * Set the tiles from an array.
	 * The array must be of the same size as the Tilemap.
	 *
	 * @param	array	The array to load from.
	 */
	public function loadFrom2DArray(array:Array2D):Void
	{
		if (blit)
		{
			for (y in 0...array.length)
			 {
				for (x in 0...array[0].length)
				{
					setTile(x, y, array[y][x]);
				}
			 }
		}
		_map = array;
	}

	/**
	* Loads the Tilemap tile index data from a string.
	* The implicit array should not be bigger than the Tilemap.
	* @param str			The string data, which is a set of tile values separated by the columnSep and rowSep strings.
	* @param columnSep		The string that separates each tile value on a row, default is ",".
	* @param rowSep			The string that separates each row of tiles, default is "\n".
	*/
	public function loadFromString(str:String, columnSep:String = ",", rowSep:String = "\n")
	{
		var row:Array<String> = str.split(rowSep),
			rows:Int = row.length,
			col:Array<String>, cols:Int, x:Int, y:Int;
		for (y in 0...rows)
		{
			if (row[y] == '') continue;
			col = row[y].split(columnSep);
			cols = col.length;
			for (x in 0...cols)
			{
				if (col[x] == '') continue;

				if (blit)
					setTile(x, y, Std.parseInt(col[x]));
				_map[y][x] = Std.parseInt(col[x]);
			}
		}
	}

	/**
	* Saves the Tilemap tile index data to a string.
	* @param columnSep		The string that separates each tile value on a row, default is ",".
	* @param rowSep			The string that separates each row of tiles, default is "\n".
	*
	* @return	The string version of the array.
	*/
	public function saveToString(columnSep:String = ",", rowSep:String = "\n"): String
	{
		var s:String = '',
			x:Int, y:Int;
		for (y in 0..._rows)
		{
			for (x in 0..._columns)
			{
				s += Std.string(getTile(x, y));
				if (x != _columns - 1) s += columnSep;
			}
			if (y != _rows - 1) s += rowSep;
		}
		return s;
	}

	/**
	 * Gets the index of a tile, based on its column and row in the tileset.
	 * @param	tilesColumn		Tileset column.
	 * @param	tilesRow		Tileset row.
	 * @return	Index of the tile.
	 */
	public inline function getIndex(tilesColumn:Int, tilesRow:Int):Int
	{
		return (tilesRow % _setRows) * _setColumns + (tilesColumn % _setColumns);
	}

	/** Renders the canvas. */
	override public function render(target:BitmapData, point:Point, camera:Camera)
	{
		// TODO: handle wrapX/wrapY in buffer mode
		var sx = scale * scaleX,
			sy = scale * scaleY,
			fsx = HXP.screen.fullScaleX,
			fsy = HXP.screen.fullScaleY;

		// determine drawing location
		_point.x = point.x + x - camera.x * scrollX;
		_point.y = point.y + y - camera.y * scrollY;

		_rect.x = _rect.y = 0;
		_rect.width = _maxWidth*sx;
		_rect.height = _maxHeight*sy;

		// render the buffers
		var xx:Int = 0, yy:Int = 0, buffer:BitmapData, px:Float = _point.x;

		while (yy < _refHeight)
		{
			while (xx < _refWidth)
			{
				buffer = _buffers[_ref.getPixel(xx, yy)];

				if (false)//angle + (rotateWithCamera ? camera.angle : 0) == 0)
				{
					if (sx*fsx == 1 && sy*fsy == 1 && _tint == null)
					{
						// copy the pixels directly onto the buffer
						_rect.width = buffer.width;
						_rect.height = buffer.height;
						target.copyPixels(buffer, _rect, _point, null, null, true);
					}
					else
					{
						// rescale first onto an intermediate buffer, then copy
						var i = Std.int(_ref.getPixel(xx, yy));
						var w = Std.int(buffer.width * sx * fsx);
						var h = Std.int(buffer.height * sy * fsy);
						var wrongSize = i >= _midBuffers.length ||
							_midBuffers[i].width != w ||
							_midBuffers[i].height != h;
						if (_redrawBuffers || wrongSize)
						{
							if (wrongSize)
							{
								if (i < _midBuffers.length)
								{
									_midBuffers[i].dispose();
								}
								_midBuffers[i] = Assets.createBitmap(w, h, true);
							}
							else
							{
								_midBuffers[i].fillRect(_midBuffers[i].rect, 0);
							}
							_matrix.b = _matrix.c = 0;
							_matrix.a = fsx * sx;
							_matrix.d = fsy * sy;
							_matrix.tx = _point.x;
							_matrix.ty = _point.y;

							_midBuffers[i].draw(buffer, _matrix, _tint);
						}

						_rect.width = w;
						_rect.height = h;
						target.copyPixels(_midBuffers[i], _rect, _point, null, null, true);
					}
				}
				else
				{
					// render with transformation
					_matrix.b = _matrix.c = 0;
					_matrix.a = sx;
					_matrix.d = sy;
					_matrix.tx = _point.x;
					_matrix.ty = _point.y;

					// scale and rotate camera
					camera.applyToMatrix(_matrix, rotateWithCamera, scaleWithCamera);
					HXP.screen.applyToMatrix(_matrix);

					target.draw(buffer, _matrix, _tint);
				}

				_point.x += _maxWidth * sx * fsx;
				xx ++;
			}
			_point.x = px;
			_point.y += _maxHeight * sy * fsy;
			xx = 0;
			yy ++;
		}

		_redrawBuffers = false;
	}

	override public function renderAtlas(layer:Int, point:Point, camera:Camera)
	{
		// determine drawing location
		var screenRect = camera.screenRect;
		_point.x = point.x + x - screenRect.x * scrollX;
		_point.y = point.y + y - screenRect.y * scrollY;

		var fsx:Float = HXP.screen.fullScaleX,
			fsy:Float = HXP.screen.fullScaleY,
			tw:Int = Std.int(tileWidth),
			th:Int = Std.int(tileHeight);

		var scx = scale * scaleX,
			scy = scale * scaleY;

		// determine start and end tiles to draw (optimization)
		var startx = Math.floor( -_point.x / (tw * scx)),
			starty = Math.floor( -_point.y / (th * scy)),
			destx = startx + 1 + Math.ceil(screenRect.width / (tw * scx)),
			desty = starty + 1 + Math.ceil(screenRect.height / (th * scy));

		// nothing will render if we're completely off screen
		if ((!wrapX && (startx > _columns || destx < 0)) || (!wrapY && (starty > _rows || desty < 0)))
			return;

		// clamp values to boundaries
		if (!wrapX)
		{
			if (startx < 0) startx = 0;
			if (destx > _columns) destx = _columns;
		}
		if (!wrapY)
		{
			if (starty < 0) starty = 0;
			if (desty > _rows) desty = _rows;
		}

		var wx:Float, sx:Float = _point.x + startx * tw * scx + screenRect.x - camera.x,
			wy:Float = _point.y + starty * th * scy + screenRect.y - camera.y,
			stepx:Float = tw * scx,
			stepy:Float = th * scy,
			tile:Int = 0;

		for (y in starty...desty)
		{
			wx = sx;
			// ensure no vertical overlap between this and next tile
			scy = (Math.floor((wy+stepy)*fsy) - Math.floor(wy*fsy)) / tileHeight;

			for (x in startx...destx)
			{
				var ty = y % rows, tx = x % columns;
				if (ty < 0) ty += rows;
				if (tx < 0) tx += columns;
				tile = _map[ty][tx];
				if (tile >= 0)
				{
					// ensure no horizontal overlap between this and next tile
					scx = (Math.floor((wx+stepx)*fsx) - Math.floor(wx*fsx)) / tileWidth;

					if (angle + (rotateWithCamera ? camera.angle : 0) == 0)
					{
						// draw the tile
						_atlas.getRegion(tile).draw(Math.floor(wx * fsx), Math.floor(wy * fsy), layer, scx, scy, 0, _red, _green, _blue, alpha, smooth);
					}
					else
					{
						// draw with rotation
						_matrix.a = scx/fsx;
						_matrix.d = scy/fsy;
						_matrix.b = _matrix.c = 0;
						_matrix.tx = Math.floor(wx*fsx)/fsx;
						_matrix.ty = Math.floor(wy*fsy)/fsy;
						camera.applyToMatrix(_matrix, rotateWithCamera, scaleWithCamera);
						HXP.screen.applyToMatrix(_matrix);

						_atlas.getRegion(tile).drawMatrix(
							_matrix.tx, _matrix.ty, _matrix.a, _matrix.b, _matrix.c, _matrix.d,
							layer, _red, _green, _blue, alpha, smooth);
					}
				}
				wx += stepx;
			}
			wy += stepy;
		}
	}

	/** @private Used by shiftTiles to update a tile from the tilemap. */
	private function updateTile(column:Int, row:Int)
	{
		setTile(column, row, _map[row % _rows][column % _columns]);
	}

	/**
	 * Draws to the canvas.
	 * @param	x			X position to draw.
	 * @param	y			Y position to draw.
	 * @param	source		Source BitmapData.
	 * @param	rect		Optional area of the source image to draw from. If null, the entire BitmapData will be drawn.
	 */
	public function draw(x:Float, y:Float, source:BitmapData, rect:Rectangle = null)
	{
		var xx:Int = 0, yy:Int = 0;
		var i = 0;
		for (buffer in _buffers)
		{
			_point.x = x - xx;
			_point.y = y - yy;
			buffer.copyPixels(source, rect != null ? rect : source.rect, _point, null, null, true);
			xx += _maxWidth;
			if (xx >= _width)
			{
				xx = 0;
				yy += _maxHeight;
			}
		}
		_redrawBuffers = true;
	}

	/**
	 * Fills the rectangular area of the canvas. The previous contents of that area are completely removed.
	 * @param	rect		Fill rectangle.
	 * @param	color		Fill color.
	 * @param	alpha		Fill alpha.
	 */
	public function fill(rect:Rectangle, color:Int = 0, alpha:Float = 1)
	{
		var xx:Int = 0, yy:Int = 0, buffer:BitmapData;
		_rect.width = rect.width;
		_rect.height = rect.height;
		if (alpha >= 1) color |= 0xFF000000;
		else if (alpha <= 0) color = 0;
		else color = (Std.int(alpha * 255) << 24) | (0xFFFFFF & color);
		for (buffer in _buffers)
		{
			_rect.x = rect.x - xx;
			_rect.y = rect.y - yy;
			buffer.fillRect(_rect, color);
			xx += _maxWidth;
			if (xx >= _width)
			{
				xx = 0;
				yy += _maxHeight;
			}
		}
	}

	/**
	 * The tinted color of the Tilemap. Use 0xFFFFFF to draw the it normally.
	 */
	public var color(get, set):Int;
	private function get_color():Int { return _color; }
	private function set_color(value:Int):Int
	{
		value %= 0xFFFFFF;
		if (_color == value) return _color;
		_color = value;
		_red = Color.getRed(color) / 255;
		_green = Color.getGreen(color) / 255;
		_blue = Color.getBlue(color) / 255;

		if (_alpha == 1 && _color == 0xFFFFFF)
		{
			_tint = null;
			return _color;
		}
		_tint = _colorTransform;
		_tint.redMultiplier = _red;
		_tint.greenMultiplier = _green;
		_tint.blueMultiplier = _blue;
		_tint.alphaMultiplier = _alpha;
		_redrawBuffers = true;
		return _color;
	}

	/**
	 * Change the opacity of the Tilemap, a value from 0 to 1.
	 */
	public var alpha(get, set):Float;
	private function get_alpha():Float { return _alpha; }
	private function set_alpha(value:Float):Float
	{
		if (value < 0) value = 0;
		if (value > 1) value = 1;
		if (_alpha == value) return _alpha;
		_alpha = value;
		if (_alpha == 1 && _color == 0xFFFFFF)
		{
			_tint = null;
			_redrawBuffers = true;
			return _alpha;
		}
		_tint = _colorTransform;
		_tint.redMultiplier = _red;
		_tint.greenMultiplier = _green;
		_tint.blueMultiplier = _blue;
		_tint.alphaMultiplier = _alpha;
		_redrawBuffers = true;
		return _alpha;
	}

	/**
	 * Width of the tilemap.
	 */
	public var width(get, null):Int;
	private function get_width():Int { return _width; }

	/**
	 * Height of the tilemap.
	 */
	public var height(get, null):Int;
	private function get_height():Int { return _height; }

	/**
	 * The tile width.
	 */
	public var tileWidth(get, never):Int;
	private inline function get_tileWidth():Int { return Std.int(_tile.width); }

	/**
	 * The tile height.
	 */
	public var tileHeight(get, never):Int;
	private inline function get_tileHeight():Int { return Std.int(_tile.height); }

	/**
	 * The tile horizontal spacing of tile.
	 */
	public var tileSpacingWidth(default, null):Int;

	/**
	 * The tile vertical spacing of tile.
	 */
	public var tileSpacingHeight(default, null):Int;


	public var tileOffsetX(default, null):Int;
	public var tileOffsetY(default, null):Int;

	/**
	 * How many tiles the tilemap has.
	 */
	public var tileCount(get, never):Int;
	private inline function get_tileCount():Int { return _setCount; }

	/**
	 * How many columns the tilemap has.
	 */
	public var columns(get, null):Int;
	private inline function get_columns():Int { return _columns; }

	/**
	 * How many rows the tilemap has.
	 */
	public var rows(get, null):Int;
	private inline function get_rows():Int { return _rows; }

	public var smooth:Bool = true;

	// Buffer information.
	private var _buffers:Array<BitmapData>;
	private var _midBuffers:Array<BitmapData>;
	private var _redrawBuffers:Bool=false;
	private var _width:Int;
	private var _height:Int;
	private var _maxWidth:Int = 4000;
	private var _maxHeight:Int = 4000;

	// Color tinting information.
	private var _color:Int;
	private var _alpha:Float;
	private var _tint:ColorTransform;
	private var _colorTransform:ColorTransform;
	private var _matrix:Matrix;
	private var _red:Float;
	private var _green:Float;
	private var _blue:Float;

	// Canvas reference information.
	private var _ref:BitmapData;
	private var _refWidth:Int;
	private var _refHeight:Int;

	// Global objects.
	private var _rect:Rectangle;
	private var _graphics:Graphics;


	// Tilemap information.
	private var _map:Array2D;
	private var _columns:Int;
	private var _rows:Int;

	// Tileset information.
	private var _set:Bitmap;
	private var _atlas:TileAtlas;
	private var _setColumns:Int;
	private var _setRows:Int;
	private var _setCount:Int;
	private var _tile:Rectangle;
}
