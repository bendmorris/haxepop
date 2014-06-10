package haxepop.utils;

abstract Position ({x:Float, y:Float})
{
	private function new(obj:Dynamic) this = obj;

	public var x(get, set):Float;
	private inline function get_x():Float return this.x;
	private inline function set_x(value:Float):Float return this.x = value;

	public var y(get, set):Float;
	private inline function get_y():Float return this.y;
	private inline function set_y(value:Float):Float return this.y = value;

	@:from public static inline function fromObject(obj:{x:Float, y:Float}) return new Position(obj);
	@:from public static inline function fromEntity(entity:Entity) return new Position(entity);
}
