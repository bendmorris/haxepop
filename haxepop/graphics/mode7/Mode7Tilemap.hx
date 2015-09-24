package haxepop.graphics.mode7;

import flash.geom.Point;
import flash.display.BitmapData;
import haxepop.Assets;
import haxepop.HXP;
import haxepop.Camera;
import haxepop.graphics.Tilemap;
import haxepop.utils.Math;


class Mode7Tilemap extends Tilemap
{
	public var mode7:Mode7;

	public function new(tileset:String, width:Int, height:Int, tileWidth:Int, tileHeight:Int, ?tileSpacingWidth:Int=0, ?tileSpacingHeight:Int=0, ?tileOffsetX=0, ?tileOffsetY=0)
	{
		super(tileset, width, height, tileWidth, tileHeight, tileSpacingWidth, tileSpacingHeight, tileOffsetX, tileOffsetY);

		mode7 = new Mode7();

#if buffer
		_atlas = new haxepop.graphics.atlas.TileAtlas(tileset);
#end
	}

	var tileBuffers:Map<Int, BitmapData>;
	override function initBuffers()
	{
		tileBuffers = new Map();
	}

	inline function getTileBuffer(tile:Int)
	{
		if (!tileBuffers.exists(tile))
		{
			var buffer = tileBuffers[tile] = haxepop.Assets.createBitmap(tileWidth, tileHeight, true);
			_point.x = 0;
			_point.y = 0;
			_tile.x = (tile % _setColumns) * (_tile.width + tileSpacingWidth) + tileOffsetX;
			_tile.y = Std.int(tile / _setColumns) * (_tile.height + tileSpacingHeight) + tileOffsetY;
			buffer.copyPixels(_set.bitmapData, _tile, _point, null, null, true);
		}
		return tileBuffers[tile];
	}

	override public function renderAtlas(layer:Int, point:Point, camera:Camera)
	{
		if (mode7 == null || !mode7.active)
		{
			return super.renderAtlas(layer, point, camera);
		}

		// determine drawing location
		var screenRect = camera.screenRect;
		_point.x = point.x + x - screenRect.x * scrollX;
		_point.y = point.y + y - screenRect.y * scrollY;

		var fsx:Float = HXP.screen.fullScaleX,
			fsy:Float = HXP.screen.fullScaleY,
			tw:Float = tileWidth,
			th:Float = tileHeight;

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

		var stepx:Float = tw * scx,
			stepy:Float = th * scy,
			wx:Float, wy:Float,
			tile:Int = 0;

		for (y in starty ... desty)
		{
			wy = y * stepy;

			for (x in startx...destx)
			{
				wx = x * stepx;
				var ty = y % rows, tx = x % columns;
				if (ty < 0) ty += rows;
				if (tx < 0) tx += columns;

				tile = _map[ty][tx];

				if (tile >= 0)
				{
					var px1 = _point.x + wx;
					var px2 = _point.x + (x+1) * stepx;
					var py1 = _point.y + wy;
					var py2 = _point.y + (y+1) * stepy;

					var vy1 = mode7.ty(py1 * fsy);
					var vy2 = mode7.ty(py2 * fsy);
					var vx11 = mode7.tx(px1 * fsx, vy1);
					var vx12 = mode7.tx(px1 * fsx, vy2);
					var vx21 = mode7.tx(px2 * fsx, vy1);
					var vx22 = mode7.tx(px2 * fsx, vy2);

					var tx = tile % _setColumns;
					var ty = Std.int(tile / _setColumns);
					var twi = (tx*(tw+tileSpacingWidth) + tileOffsetX);
					var thi = (ty*(th+tileSpacingHeight) + tileOffsetY);

					_atlas.prepareTriangles(
						vx11, vy1,
						vx21, vy1,
						vx22, vy2,
						vx12, vy2,
						twi/_atlas.width, thi/_atlas.height,
						(twi+tw)/_atlas.width, thi/_atlas.height,
						(twi+tw)/_atlas.width, (thi+th)/_atlas.height,
						twi/_atlas.width, (thi+th)/_atlas.height,
						(Std.int(0xFF * alpha) << 24) | color
					);
				}
			}
		}
	}

	/*override public function render(target:BitmapData, point:Point, camera:Camera)
	{
		// determine drawing location
		var screenRect = camera.screenRect;
		_point.x = point.x + x - screenRect.x * scrollX;
		_point.y = point.y + y - screenRect.y * scrollY;

		var fsx:Float = HXP.screen.fullScaleX,
			fsy:Float = HXP.screen.fullScaleY,
			tw:Float = tileWidth,
			th:Float = tileHeight;

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

		var stepx:Float = tw * scx,
			stepy:Float = th * scy,
			wx:Float, wy:Float,
			tile:Int = 0;

		haxepop.graphics.atlas.AtlasData.startScene(HXP.scene);
		for (y in starty ... desty)
		{
			wy = y * stepy;

			for (x in startx...destx)
			{
				wx = x * stepx;
				var ty = y % rows, tx = x % columns;
				if (ty < 0) ty += rows;
				if (tx < 0) tx += columns;

				tile = _map[ty][tx];

				if (tile >= 0)
				{
					var px1 = _point.x + wx;
					var px2 = _point.x + (x+1) * stepx;
					var py1 = _point.y + wy;
					var py2 = _point.y + (y+1) * stepy;

					var vy1 = mode7.ty(py1 * fsy);
					var vy2 = mode7.ty(py2 * fsy);
					var vx11 = mode7.tx(px1 * fsx, vy1);
					var vx12 = mode7.tx(px1 * fsx, vy2);
					var vx21 = mode7.tx(px2 * fsx, vy1);
					var vx22 = mode7.tx(px2 * fsx, vy2);

					var tx = tile % _setColumns;
					var ty = Std.int(tile / _setColumns);
					var twi = (tx*(tw+tileSpacingWidth) + tileOffsetX);
					var thi = (ty*(th+tileSpacingHeight) + tileOffsetY);

					_atlas.prepareTriangles(
						vx11, vy1,
						vx21, vy1,
						vx22, vy2,
						vx12, vy2,
						twi/_atlas.width, thi/_atlas.height,
						(twi+tw)/_atlas.width, thi/_atlas.height,
						(twi+tw)/_atlas.width, (thi+th)/_atlas.height,
						twi/_atlas.width, (thi+th)/_atlas.height,
						(Std.int(0xFF * alpha) << 24) | color
					);
				}
			}
		}
		haxepop.graphics.atlas.AtlasData.active = null;
	}*/
}
