package haxepop.graphics.atlas;

import haxepop.graphics.atlas.AtlasData;
import haxepop.HXP;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;

@:allow(haxepop.graphics.atlas.TexturePacker)
@:allow(haxepop.graphics.atlas.GdxTexturePacker)
class TextureAtlas extends Atlas
{
	private function new(?source:AtlasDataType)
	{
		_regions = new Map<String, AtlasRegion>();
		_pages = new Map<String, AtlasData>();

		super(source);

		if (source != null)
			_pages.set("", _data);
	}

	/**
	 * Loads a TexturePacker xml file and generates all tile regions.
	 * Uses the Generic XML exporter format from Texture Packer.
	 * @param	file	The TexturePacker file to load
	 * @return	A TextureAtlas with all packed images defined as regions
	 */
	public static function loadTexturePacker(file:String):TextureAtlas
	{
		return TexturePacker.load(file);
	}

	/**
	 * Loads a libGDX TexturePacker atlas file and generates all tile regions.
	 * @param	file	The TexturePacker file to load
	 * @return	A TextureAtlas with all packed images defined as regions
	 */
	public static function loadGdx(file:String):TextureAtlas
	{
		return GdxTexturePacker.load(file);
	}

	/**
	 * Gets an atlas region based on an identifier
	 * @param	name	The name identifier of the region to retrieve.
	 *
	 * @return	The retrieved region.
	 */
	public function getRegion(name:String):AtlasRegion
	{
		if (_regions.exists(name))
			return _regions.get(name);
			
		throw 'Region has not been defined yet "$name".';
	}

	/**
	 * Gets an array of defined region names.
	 *
	 * @return	An array of strings.
	 */
	public function getRegionNames():Array<String>
	{
		return [for (k in _regions.keys()) k];
	}

	/**
	 * Creates a new AtlasRegion and assigns it to a name
	 * @param	name	The region name to create
	 * @param	rect	Defines the rectangle of the tile on the tilesheet
	 * @param	center	Positions the local center point to pivot on
	 * @param	rotate	Amount (in degrees) the image is rotated in the atlas
	 *
	 * @return	The new AtlasRegion object.
	 */
	public function defineRegion(name:String, rect:Rectangle, ?center:Point, ?rotate:Float=0, ?page:String=""):AtlasRegion
	{
		var _data:AtlasData = _pages.get(page);
		var region = _data.createRegion(rect, center, rotate);
		_regions.set(name, region);
		return region;
	}

	private var _regions:Map<String, AtlasRegion>;
	private var _pages:Map<String, AtlasData>;
}
