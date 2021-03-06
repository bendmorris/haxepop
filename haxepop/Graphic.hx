package haxepop;

import haxepop.HXP;
import haxepop.Assets;
import haxepop.ds.Either;
import haxepop.graphics.atlas.Atlas;
import haxepop.graphics.atlas.TileAtlas;
import haxepop.graphics.atlas.AtlasRegion;
import flash.display.BitmapData;
import flash.geom.Point;

typedef AssignCallback = Void -> Void;

/**
 * Converts multiple types of image data to a TileType
 * @from String The asset name of a tiled image
 * @from TileAtlas A TileAtlas object
 * @from BitmapData The raw bitmap of a tiled image
 * @to An enum defining a BitmapData or TileAtlas
 */
abstract TileType(Either<BitmapData, TileAtlas>)
{
	private inline function new(e:Either<BitmapData, TileAtlas>) this = e;
	public var type(get,never):Either<BitmapData, TileAtlas>;
	@:to inline function get_type() return this;

	@:from public static inline function fromString(tileset:String) {
#if hardware
			return new TileType(Right(new TileAtlas(tileset)));
#else
			return new TileType(Left(HXP.getBitmap(tileset)));
#end
	}
	@:from public static inline function fromTileAtlas(atlas:TileAtlas) {
		return new TileType(Right(atlas));
	}
	@:from public static inline function fromBitmapData(bd:BitmapData) {
#if hardware
			return new TileType(Right(new TileAtlas(bd)));
#else
			return new TileType(Left(bd));
#end
	}
}

abstract ImageType(Either<BitmapData, AtlasRegion>)
{
	private inline function new(e:Either<BitmapData, AtlasRegion>) this = e;
	public var type(get,never):Either<BitmapData, AtlasRegion>;
	@:to inline function get_type() return this;

	@:from public static inline function fromString(s:String) {
			return Assets.getImage(s);
	}
	@:from public static inline function fromTileAtlas(atlas:TileAtlas) {
		return new ImageType(Right(atlas.getRegion(0)));
	}
	@:from public static inline function fromAtlasRegion(region:AtlasRegion) {
		return new ImageType(Right(region));
	}
	@:from public static inline function fromBitmapData(bd:BitmapData) {
#if hardware
			return new ImageType(Right(Atlas.loadImageAsRegion(bd)));
#else
			return new ImageType(Left(bd));
#end
	}

	public var width(get, never):Int;
	function get_width()
	{
		return Std.int(switch(this)
		{
			case Left(b): b.width;
			case Right(a): a.width;
		});
	}

	public var height(get, never):Int;
	function get_height()
	{
		return Std.int(switch(this)
		{
			case Left(b): b.height;
			case Right(a): a.height;
		});
	}
}

class Graphic
{
	/**
	 * If the graphic should update.
	 */
	public var active:Bool;

	/**
	 * If the graphic should render.
	 */
	public var visible(get, set):Bool;
	private inline function get_visible():Bool { return _visible; }
	private inline function set_visible(value:Bool):Bool { return _visible = value; }

	/**
	 * X offset.
	 */
	@:isVar public var x(get, set):Float;
	private inline function get_x():Float { return x; }
	private inline function set_x(value:Float):Float { return x = value; }

	/**
	 * Y offset.
	 */
	@:isVar public var y(get, set):Float;
	private inline function get_y():Float { return y; }
	private inline function set_y(value:Float):Float { return y = value; }

	/**
	 * X scrollfactor, effects how much the camera offsets the drawn graphic.
	 * Can be used for parallax effect, eg. Set to 0 to follow the camera,
	 * 0.5 to move at half-speed of the camera, or 1 (default) to stay still.
	 */
	public var scrollX:Float = 1;

	/**
	 * Y scrollfactor, effects how much the camera offsets the drawn graphic.
	 * Can be used for parallax effect, eg. Set to 0 to follow the camera,
	 * 0.5 to move at half-speed of the camera, or 1 (default) to stay still.
	 */
	public var scrollY:Float = 1;

	/**
	 * Whether this graphic will be rotated when the camera rotates.
	 */
	public var rotateWithCamera:Bool = true;

	/**
	 * Whether this graphic will be scaled when the camera rotates.
	 */
	public var scaleWithCamera:Bool = true;

	/**
	 * If the graphic should render at its position relative to its parent Entity's position.
	 */
	public var relative:Bool = true;

	/**
	 * A graphic is sticky if it sticks to the screen and doesn't move with the camera.
	 * Setting sticky to true will set rotateWithCamera and scaleWithCamera to false,
	 * and scrollX and scrollY to 0.
	 */
	public var sticky(get, set):Bool;
	inline function get_sticky()
	{
		return !(rotateWithCamera || scaleWithCamera || scrollX > 0 || scrollY > 0);
	}
	inline function set_sticky(sticky:Bool)
	{
		if (sticky)
		{
			rotateWithCamera = scaleWithCamera = false;
			scrollX = scrollY = 0;
		}
		return sticky;
	}

	/**
	 * If we can blit the graphic or not (flash/html5)
	 */
	public var blit(default, null):Bool;

	/**
	 * Constructor.
	 */
	public function new()
	{
		active = false;
		visible = true;
		x = y = 0;
		scrollX = scrollY = 1;
		relative = true;
		_scroll = true;
		_point = new Point();
	}

	/**
	 * Updates the graphic.
	 */
	public function update()
	{

	}

	/**
	 * Removes the graphic from the scene
	 */
	public function destroy() { }

	/**
	 * Renders the graphic to the screen buffer.
	 * @param  target     The buffer to draw to.
	 * @param  point      The position to draw the graphic.
	 * @param  camera     The camera offset.
	 */
	public function render(target:BitmapData, point:Point, camera:Camera) { }

	/**
	 * Renders the graphic as an atlas.
	 * @param  layer      The layer to draw to.
	 * @param  point      The position to draw the graphic.
	 * @param  camera     The camera offset.
	 */
	public function renderAtlas(layer:Int, point:Point, camera:Camera) { }

	/**
	 * Pause updating this graphic.
	 */
	public function pause()
	{
		active = false;
	}

	/**
	 * Resume updating this graphic.
	 */
	public function resume()
	{
		active = true;
	}

	// Graphic information.
	private var _scroll:Bool;
	private var _point:Point;
	private var _entity:Entity;

	private var _visible:Bool;
}
