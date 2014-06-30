package haxepop.input;

import flash.events.TouchEvent;
import haxepop.utils.Math;
import haxepop.HXP;
import haxepop.Input;

@:enum
abstract GestureMode(Int)
{
	var READY = 1;
	var SINGLE_TOUCH = 2;
	var SINGLE_MOVE = 3;
	var MULTI_TOUCH = 4;
	var MULTI_MOVE = 5;
	var FINISHED = 6;
}

class GestureInstance extends InputInstance
{

	public var x:Float = 0;
	public var y:Float = 0;
	public var x2:Float = 0;
	public var y2:Float = 0;
	public var magnitude:Float = 0;
	public var time:Float = 0;

	public function new()
	{
		super();
		type = Gesture.name;
		reset();
	}

	function reset()
	{
		x = y = x2 = y2 = time = 0;
		down = pressed = released = false;
	}

	public function start(x:Float=0, y:Float=0)
	{
		down = pressed = true;
		this.x = x;
		this.y = y;
		x2 = y2 = magnitude = 0;
		this.time = 0;
	}

	public var distance(get, never):Float;
	function get_distance()
	{
		return Math.distance(x, y, x2, y2);
	}

	public var velocity(get, never):Float;
	function get_velocity()
	{
		return time == 0 ? 0 : distance / time;
	}

	public var angle(get, never):Float;
	function get_angle()
	{
		// TODO
		return 0;
	}

	public function release()
	{
		released = true;
	}

	public function update()
	{
		if (pressed)
		{
			pressed = false;
		}
		else if (released)
		{
			reset();
		}
		else if (down)
		{
			time += HXP.elapsed;
		}
	}

}

class Gesture implements InputMethod
{

	public static inline var name="gesture";

	public static function enable()
	{
		Input.inputMethods.set(name, new Gesture());
	}

	public static function disable()
	{
		if (Input.inputMethods.exists(name)) Input.inputMethods.remove(name);
	}

	public static function define(input:String, inputs:Array<Int>)
	{
		Input.define(input, [for (i in inputs) {type:name, value:i}]);
	}

	public static var TOUCH=0;
	public static var TAP=1;
	public static var DOUBLE_TAP=2;
	public static var LONG_PRESS=3;
	public static var MOVE=4;
	public static var SWIPE=5;
	public static var PINCH=6;
	public static var TWO_FINGER_TAP=7;

	public function init()
	{
		Touch.init();
	}

	// how long a touch must be held to become a LONG_PRESS
	public static var longPressTime:Float = 0.5;
	// how fast a move must be to become a SWIPE
	public static var swipeTime:Float = 0.25;
	// if two taps register before this much time passes,
	// the second one will be a DOUBLE_TAP
	public static var doubleTapTime:Float = 0.5;
	// if the distance between start and end position of a gesture is
	// less than this value, it will be considered a TAP/LONG_PRESS,
	// not a MOVE
	public static var deadZone:Float = 5;

	public static var gestures:Map<Int, GestureInstance> = new Map();

	inline function getTouch(touches:Map<Int, Touch>, touchOrder:Array<Int>, n:Int):Touch
	{
		if (n >= touchOrder.length) return null;
		return touches[touchOrder[n]];
	}

	public function new() {}

	/**
	 * Returns true if a gesture is active.
	 */
	public static function check(type:Int):Bool
	{
		if (!gestures.exists(type)) return false;
		return (gestures[type].down);
	}

	/**
	 * Returns true if a gesture was started this frame.
	 */
	public static function pressed(type:Int):Bool
	{
		if (!gestures.exists(type)) return false;
		return (gestures[type].pressed);
	}

	/**
	 * Returns true if a gesture was released this frame.
	 */
	public static function released(type:Int):Bool
	{
		if (!gestures.exists(type)) return false;
		return (gestures[type].released);
	}

	/**
	 * Get an object describing an active gesture.
	 */
	public static function get(type:Int):GestureInstance
	{
		if (!check(type)) return null;
		return (gestures[type]);
	}

	public function inputCheck(i:Int) { return check(i); }
	public function inputPressed(i:Int) { return pressed(i); }
	public function inputReleased(i:Int) { return released(i); }
	public function inputGet(i:Int) { return get(i); }

	/**
	 * Start a gesture.
	 */
	function start(type:Int, x:Float=0, y:Float=0)
	{
		if (!gestures.exists(type))
		{
			gestures[type] = new GestureInstance();
		}
		if (!gestures[type].down)
		{
			gestures[type].start(x, y);
		}
	}

	/**
	 * Finish a gesture.
	 */
	function finish(type:Int)
	{
		if (!gestures.exists(type))
		{
			gestures[type] = new GestureInstance();
		}
		gestures[type].release();
	}

	function finishAll()
	{
		for (gesture in gestures)
		{
			if (gesture.down)
			{
				gesture.release();
			}
		}
	}

	/**
	 * Check for gestures.
	 */
	public function update()
	{
		Touch.updateTouches();

		for (gesture in gestures)
		{
			gesture.update();
		}

		var touches = Touch.touches;
		var touchOrder = Touch.touchOrder;
		var touchCount:Int = 0;
		for (touch in touchOrder)
		{
			if (touches.exists(touch))
			{
				if (touches[touch].pressed || touches[touch].active) touchCount += 1;
			}
			else
			{
				touchOrder.remove(touch);
			}
		}

		if (_lastTap > 0) _lastTap = Math.max(0, _lastTap - HXP.elapsed / doubleTapTime);

		if (touchCount > 0 && !check(TOUCH))
		{
			var touch:Touch = getTouch(touches, touchOrder, 0);
			start(TOUCH, touch.x, touch.y);
		}
		else if (touchCount > 0)
		{
			var touch:Touch = getTouch(touches, touchOrder, 0);
			get(TOUCH).x = touch.x;
			get(TOUCH).y = touch.y;
		}
		else if (check(TOUCH)) finish(TOUCH);

		var changed:Bool = true;
		while (changed)
		{
			changed = false;
			switch (mode)
			{
				case READY:
				{
					if (touchCount > 0)
					{
						// start tracking gesture
						mode = touchCount == 1 ? SINGLE_TOUCH : MULTI_TOUCH;
						changed = true;
					}
				}
				case SINGLE_TOUCH:
				{
					if (touchCount == 0)
					{
						// was touching with one finger, now released
						// initiate a tap or long press
						mode = READY;
						var touch:GestureInstance = get(TOUCH);
						var t:Int = (touch.time < longPressTime) ? TAP : LONG_PRESS;

						if (t == TAP && _lastTap > 0) t = DOUBLE_TAP;

						if (!check(t))
						{
							start(t, touch.x, touch.y);
							if (t == TAP) _lastTap = 1;
						}
					}
					else if (touchCount == 1)
					{
						var touch:Touch = getTouch(touches, touchOrder, 0);
						var dist = Math.distance(touch.startX, touch.startY, touch.x, touch.y);
						if (dist > deadZone)
						{
							mode = SINGLE_MOVE;
							changed = true;
						}
						else if (touch.time >= longPressTime && !check(LONG_PRESS))
						{
							start(LONG_PRESS, touch.x, touch.y);
						}
					}
					else if (touchCount > 1)
					{
						mode = MULTI_TOUCH;
						changed = true;
					}
				}
				case SINGLE_MOVE:
				{
					if (touchCount == 0)
					{
						mode = READY;
					}
					else
					{
						var touch:Touch = getTouch(touches, touchOrder, 0);
						var dist = Math.distance(touch.startX, touch.startY, touch.x, touch.y);
						if (!check(MOVE))
						{
							start(MOVE, touch.startX, touch.startY);
						}
						var g = get(MOVE);
						g.x2 = touch.x;
						g.y2 = touch.y;
						g.magnitude = dist;
					}
					if (touchCount > 1)
					{
						var touch:Touch = getTouch(touches, touchOrder, 1);
						start(TWO_FINGER_TAP, touch.x, touch.y);
					}
					else if (check(TWO_FINGER_TAP))
					{
						finish(TWO_FINGER_TAP);
					}
				}
				case MULTI_TOUCH:
				{
					if (touchCount < 2)
					{
						mode = (touchCount == 0 ? READY : FINISHED);
						if (!check(PINCH))
						{
							var t1:Touch = getTouch(touches, touchOrder, 0);
							var t2:Touch = getTouch(touches, touchOrder, 1);
							if (t2 != null)
							{
								var mx = (t1.startX - t2.startX) / 2;
								var my = (t1.startY - t2.startY) / 2;
								start(TWO_FINGER_TAP, mx, my);
							}
						}
						finishAll();
					}
					else
					{
						var t1:Touch = getTouch(touches, touchOrder, 0);
						var t2:Touch = getTouch(touches, touchOrder, 1);
						if (t1 != null && t2 != null)
						{
							var d1 = Math.distance(t1.startX, t1.startY, t1.x, t1.y);
							var d2 = Math.distance(t2.startX, t2.startY, t2.x, t2.y);
							if (d1 > deadZone && d2 > deadZone)
							{
								if (!check(PINCH))
								{
									var mx = (t1.startX - t2.startX) / 2;
									var my = (t1.startY - t2.startY) / 2;
									start(PINCH, mx, my);
								}
								var inner = Math.distance(t1.startX, t1.startY, t2.startX, t2.startY);
								var outer = Math.distance(t1.x, t1.y, t2.x, t2.y);
								get(PINCH).magnitude = inner / outer;
							}
						}
					}
				}
				default:
				{
					if (touchCount == 0)
					{
						mode = READY;
					}
				}
			}
		}

		if (touchCount == 0) finishAll();

		Touch.removeTouches();
	}

	var mode:GestureMode = GestureMode.READY;
	var _lastTap:Float = 0;

}
