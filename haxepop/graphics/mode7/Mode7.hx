package haxepop.graphics.mode7;

import haxepop.HXP;
import haxepop.utils.Math;


typedef Mode7Data = {
	var perspectiveMult:Float;
	@:optional var active:Bool;
}

@:forward(perspectiveMult, active)
abstract Mode7(Mode7Data)
{
	public static inline var DEFAULT_PERSPECTIVE:Float = 1.25;

#if (buffer || nomode7)
	public var active(default, set):Bool = false;
	inline function set_active(b:Bool) return active = false;
#end

	public inline function new()
	{
		this = {perspectiveMult: DEFAULT_PERSPECTIVE};
		this.active = this.active != false;
	}

	public var horizon(get, never):Float;
	inline function get_horizon() return -1/(this.perspectiveMult-1);

	public inline function tx(x:Float, y:Float)
		return Math.iround((x - HXP.screen.width/2) * scale(y) * this.perspectiveMult + HXP.screen.width/2);

	public inline function ty(y:Float)
		return Math.iround(y * scale(y));

	public inline function tx2(x:Float, y:Float)
		return HXP.camera.x + tx((x - HXP.camera.x)*HXP.screen.fullScaleX,
			(y - HXP.camera.y)*HXP.screen.fullScaleY)/HXP.screen.fullScaleX;

	public inline function ty2(y:Float)
		return HXP.camera.y + ty((y - HXP.camera.y)*HXP.screen.fullScaleY)/HXP.screen.fullScaleY;

	public inline function scale(y:Float)
		return Math.max(0, this.perspectiveMult * (y-HXP.screen.height*horizon)/(HXP.screen.height-HXP.screen.height*horizon));

	public inline function scale2(y:Float)
		return scale((y-HXP.camera.y)*HXP.screen.fullScaleY);
}
