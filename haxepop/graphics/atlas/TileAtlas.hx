package haxepop.graphics.atlas;

import haxepop.HXP;
import haxepop.ds.Either;
import haxepop.graphics.atlas.AtlasData;
import flash.display.BitmapData;

class TileAtlas extends Atlas
{
	/**
	 * Constructor.
	 *
	 * @param	source		Source texture.
	 */
	public function new(source:AtlasDataType)
	{
		super(source);
		_regions = new Array<AtlasRegion>();
	}

	/**
	 * Gets an atlas region based on an identifier
	 * @param 	index	The tile index of the region to retrieve
	 *
	 * @return	The atlas region object.
	 */
	public function getRegion(index:Int):AtlasRegion
	{
		return _regions[index];
	}

	/**
	 * Prepares the atlas for drawing.
	 * @param	tileWidth	With of the tiles.
	 * @param	tileHeight	Height of the tiles.
	 * @param	tileMarginWidth		Tile horizontal margin.
	 * @param	tileMarginHeight	Tile vertical margin.
	 */
	public function prepare(tileWidth:Int, tileHeight:Int, tileMarginWidth:Int=0, tileMarginHeight:Int=0, tileOffsetX:Int=0, tileOffsetY:Int=0)
	{
		if (_regions.length > 0) return; // only prepare once
		var fullTileWidth = tileWidth + tileMarginWidth,
			fullTileHeight = tileHeight + tileMarginHeight;
		var cols:Int = Math.floor(_data.width / fullTileWidth);
		var rows:Int = Math.floor(_data.height / fullTileHeight);

		HXP.rect.width = tileWidth;
		HXP.rect.height = tileHeight;

		HXP.point.x = HXP.point.y = 0;

		for (y in 0...rows)
		{
			HXP.rect.y = y * fullTileHeight + tileOffsetY;

			for (x in 0...cols)
			{
				HXP.rect.x = x * fullTileWidth + tileOffsetX;

				_regions.push(_data.createRegion(HXP.rect, HXP.point));
			}
		}
	}

	private var _regions:Array<AtlasRegion>;
}
