package haxepop.input;

import flash.events.TouchEvent;
import flash.ui.Multitouch;
import flash.ui.MultitouchInputMode;
import haxepop.HXP;

class Touch
{

	/**
	 * Returns true if the device supports multi touch
	 */
	public static var multiTouchSupported(default, null):Bool = false;

	public static var touches(get, never):Map<Int,Touch>;
	private static inline function get_touches():Map<Int,Touch> { return _touches; }

	public static var touchOrder(get, never):Array<Int>;
	private static inline function get_touchOrder():Array<Int> { return _touchOrder; }

	/**
	 * Touch id used for multiple touches
	 */
	public var id(default, null):Int;
	/**
	 * X-Axis coord in window
	 */
	public var x:Float;
	/**
	 * Y-Axis coord in window
	 */
	public var y:Float;
	/**
	 * Starting X position of touch
	 */
	public var startX:Float;
	/**
	 * Starting Y position of touch
	 */
	public var startY:Float;
	/**
	 * The time this touch has been held
	 */
	public var time(default, null):Float;

	/**
	 * Creates a new touch object
	 * @param  x  x-axis coord in window
	 * @param  y  y-axis coord in window
	 * @param  id touch id
	 */
	public function new(id:Int, ?x:Float=0, ?y:Float=0)
	{
		this.startX = this.x = x;
		this.startY = this.y = y;
		this.id = id;
		this.time = 0;
	}

	public static function init()
	{
		multiTouchSupported = Multitouch.supportsTouchEvents;
		if (multiTouchSupported)
		{
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;

			HXP.stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
			HXP.stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
			HXP.stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
		}
	}

	/**
	 * The touch x-axis coord in the scene.
	 */
	public var sceneX(get, never):Float;
	private inline function get_sceneX():Float { return x + HXP.camera.x; }

	/**
	 * The touch y-axis coord in the scene.
	 */
	public var sceneY(get, never):Float;
	private inline function get_sceneY():Float { return y + HXP.camera.y; }

	/**
	 * If the touch was pressed this frame.
	 */
	public var pressed:Bool = true;

	/**
	 * If the touch was released this frame.
	 */
	public var released:Bool = false;

	public var active:Bool = true;

	/**
	 * Updates the touch state.
	 */
	public function update()
	{
        if (time > 0) pressed = false;
		time += HXP.elapsed;
	}

	public static function touchPoints(touchCallback:Touch->Void)
	{
		for (touch in _touches)
		{
			touchCallback(touch);
		}
	}

	private static function onTouchBegin(e:TouchEvent)
	{
		var touch:Touch;
		if (_touches.exists(e.touchPointID))
		{
			touch = _touches.get(e.touchPointID);
		}
		else
		{
			touch = new Touch(e.touchPointID);
			_touches.set(e.touchPointID, touch);
		}
		touch.startX = touch.x = e.stageX / HXP.screen.fullScaleX;
		touch.startY = touch.y = e.stageY / HXP.screen.fullScaleY;
		touch.time = 0;
		touch.pressed = touch.active = true;
		_touchOrder.push(e.touchPointID);
	}

	private static function onTouchMove(e:TouchEvent)
	{
		var point = _touches.get(e.touchPointID);
		point.x = e.stageX / HXP.screen.fullScaleX;
		point.y = e.stageY / HXP.screen.fullScaleY;
	}

	private static function onTouchEnd(e:TouchEvent)
	{
		var touch:Touch = _touches.get(e.touchPointID);
		touch.released = true;
		touch.active = false;
	}

	public static function updateTouches()
	{
		for (touch in _touches)
		{
			touch.update();
		}
	}

	public static function removeTouches()
	{
		for (touch in _touches)
		{
			if (touch.released && !touch.active)
			{
				_touchOrder.remove(touch.id);
				touch.released = false;
			}
		}
	}

	private static var _touches:Map<Int,Touch> = new Map<Int,Touch>();
	private static var _touchOrder:Array<Int> = new Array();
}
