package haxepop;

import flash.display.BitmapData;
import flash.display.Bitmap;
import flash.display.MovieClip;
import flash.media.Sound;
import flash.text.Font;
import flash.utils.ByteArray;
import openfl.Assets;
import haxepop.Graphic;
import haxepop.graphics.atlas.Atlas;
import haxepop.graphics.atlas.TextureAtlas;
import haxepop.graphics.atlas.AtlasRegion;


class Assets extends openfl.Assets
{
	public static var atlasRegions:Map<String, AtlasRegion> = new Map();
	public static var atlasBitmaps:Map<String, BitmapData> = new Map();

	public static function loadAtlas(atlas:TextureAtlas):Void
	{
		for (regionName in atlas.getRegionNames())
		{
#if hardware
			var region:AtlasRegion = atlas.getRegion(regionName);
			atlasRegions.set(regionName, region);
#else
			var region:AtlasRegion = atlas.getRegion(regionName);
			var bd:BitmapData = region.getBitmapData();
			atlasBitmaps.set(regionName, bd);
#end
		}
	}

	public static function getImage(id:String, useCache:Bool = true):ImageType
	{
#if hardware
		if (atlasRegions.exists(id))
		{
			return ImageType.fromAtlasRegion(atlasRegions.get(id));
		}
		return Atlas.loadImageAsRegion(id);
#else
		if (atlasBitmaps.exists(id))
		{
			return ImageType.fromBitmapData(atlasBitmaps.get(id));
		}
		return ImageType.fromBitmapData(getBitmap(id));
#end
	}

	/**
	 * Fetches a stored BitmapData object represented by the source.
	 * @param	source		Embedded Bitmap class.
	 * @return	The stored BitmapData object.
	 */
	public static function getBitmap(name:String):BitmapData
	{
		if (_bitmap.exists(name))
			return _bitmap.get(name);

		var data:BitmapData = openfl.Assets.getBitmapData(name, false);

		if (data != null)
			_bitmap.set(name, data);

		return data;
	}

	/**
	 * Overwrites the image cache for a given name
	 * @param name  The name of the BitmapData to overwrite.
	 * @param data  The BitmapData object.
	 */
	public static function overwriteBitmapCache(name:String, data:BitmapData):Void
	{
		removeBitmap(name);
		_bitmap.set(name, data);
	}

	/**
	 * Removes a bitmap from the cache
	 * @param name  The name of the bitmap to remove.
	 * @return True if the bitmap was removed.
	 */
	public static function removeBitmap(name:String):Bool
	{
		if (_bitmap.exists(name))
		{
			var bitmap = _bitmap.get(name);
			bitmap.dispose();
			bitmap = null;
			return _bitmap.remove(name);
		}
		return false;
	}

	/**
	 * Creates BitmapData based on platform specifics
	 *
	 * @param	width			BitmapData's width.
	 * @param	height			BitmapData's height.
	 * @param	transparent		If the BitmapData can have transparency.
	 * @param	color			BitmapData's color.
	 *
	 * @return	The BitmapData.
	 */
	public static function createBitmap(width:Int, height:Int, ?transparent:Bool = false, ?color:Int = 0):BitmapData
	{
#if flash
	#if flash8
		var sizeError:Bool = (width > 2880 || height > 2880);
	#else
		var sizeError:Bool = (width * height > 16777215 || width > 8191 || height > 8191); // flash 10 requires size to be under 16,777,215
	#end
		if (sizeError)
		{
			trace("BitmapData is too large (" + width + ", " + height + ")");
			return null;
		}
#end // flash

		return new BitmapData(width, height, transparent, color);
	}

	private static var _bitmap:Map<String,BitmapData> = new Map<String,BitmapData>();

	public static inline function exists (id:String, type:AssetType = null):Bool
		return openfl.Assets.exists(id, type);
	public static inline function getBitmapData (id:String, useCache:Bool = true):BitmapData
		return openfl.Assets.getBitmapData(id, useCache);
	public static inline function getBytes (id:String):ByteArray
		return openfl.Assets.getBytes(id);
	public static inline function getFont (id:String, useCache:Bool = true):Font
		return openfl.Assets.getFont(id, useCache);
	public static inline function getMovieClip (id:String):MovieClip
		return openfl.Assets.getMovieClip(id);
	public static inline function getMusic (id:String, useCache:Bool = true):Sound
		return openfl.Assets.getMusic(id, useCache);
	public static inline function getPath (id:String):String
		return openfl.Assets.getPath(id);
	public static inline function getSound (id:String, useCache:Bool = true):Sound
		return openfl.Assets.getSound(id, useCache);
	public static inline function getText (id:String):String
		return openfl.Assets.getText(id);
	public static inline function list (type:AssetType = null):Array<String>
		return openfl.Assets.list(type);

}
