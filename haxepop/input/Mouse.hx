package haxepop.input;

import flash.events.MouseEvent;
import haxepop.HXP;
import haxepop.Input;

class MouseClick extends InputInstance
{
	public var x:Float;
	public var y:Float;

	public function new()
	{
		super();
		type = Mouse.name;
	}
}

class Mouse implements InputMethod
{
	public static inline var name="mouse";

	public static function enable()
	{
		Input.inputMethods.set(name, new Mouse());
	}

	public static function disable()
	{
		if (Input.inputMethods.exists(name)) Input.inputMethods.remove(name);
	}

	public static function define(input:String, inputs:Array<Int>)
	{
		Input.define(input, [for (i in inputs) {type:name, value:i}]);
	}

	public static inline var LEFT_MOUSE_BUTTON=1;
	public static inline var RIGHT_MOUSE_BUTTON=2;
	public static inline var MIDDLE_MOUSE_BUTTON=3;

	public function init()
	{
		HXP.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false,  2);
		HXP.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false,  2);
		HXP.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false,  2);
		HXP.stage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMiddleMouseDown, false, 2);
		HXP.stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMiddleMouseUp, false, 2);
		HXP.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown, false, 2);
		HXP.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUp, false, 2);
	}

	/**
	 * If the left button mouse is held down
	 */
	public static var mouseDown:Bool = false;
	/**
	 * If the left button mouse is up
	 */
	public static var mouseUp:Bool = true;
	/**
	 * If the left button mouse was recently pressed
	 */
	public static var mousePressed:Bool = false;
	/**
	 * If the left button mouse was recently released
	 */
	public static var mouseReleased:Bool = false;

	/**
	 * If the right button mouse is held down
	 */
	public static var rightMouseDown:Bool = false;
	/**
	 * If the right button mouse is up
	 */
	public static var rightMouseUp:Bool = true;
	/**
	 * If the right button mouse was recently pressed
	 */
	public static var rightMousePressed:Bool = false;
	/**
	 * If the right button mouse was recently released
	 */
	public static var rightMouseReleased:Bool = false;

	/**
	 * If the middle button mouse is held down
	 */
	public static var middleMouseDown:Bool = false;
	/**
	 * If the middle button mouse is up
	 */
	public static var middleMouseUp:Bool = true;
	/**
	 * If the middle button mouse was recently pressed
	 */
	public static var middleMousePressed:Bool = false;
	/**
	 * If the middle button mouse was recently released
	 */
	public static var middleMouseReleased:Bool = false;

	/**
	 * If the mouse wheel has moved
	 */
	public static var mouseWheel:Bool;

	public function new() {}

	public static function check(type:Int):Bool
	{
		return switch(type)
		{
			case LEFT_MOUSE_BUTTON: mouseDown;
			case RIGHT_MOUSE_BUTTON: rightMouseDown;
			case MIDDLE_MOUSE_BUTTON: middleMouseDown;
			default: false;
		}
	}

	public static function pressed(type:Int):Bool
	{
		return switch(type)
		{
			case LEFT_MOUSE_BUTTON: mousePressed;
			case RIGHT_MOUSE_BUTTON: rightMousePressed;
			case MIDDLE_MOUSE_BUTTON: middleMousePressed;
			default: false;
		}
	}

	public static function released(type:Int):Bool
	{
		return switch(type)
		{
			case LEFT_MOUSE_BUTTON: mouseReleased;
			case RIGHT_MOUSE_BUTTON: rightMouseReleased;
			case MIDDLE_MOUSE_BUTTON: middleMouseReleased;
			default: false;
		}
	}

	public static function get(type:Int):MouseClick
	{
		var instance:MouseClick = new MouseClick();
		instance.x = mouseX;
		instance.y = mouseY;
		instance.down = check(type);
		instance.pressed = pressed(type);
		instance.released = released(type);
		return instance;
	}

	public function inputCheck(i:Int) { return check(i); }
	public function inputPressed(i:Int) { return pressed(i); }
	public function inputReleased(i:Int) { return released(i); }
	public function inputGet(i:Int) { return get(i); }

	public function update()
	{
		if (mousePressed) mousePressed = false;
		if (mouseReleased) mouseReleased = false;
		if (middleMousePressed) middleMousePressed = false;
		if (middleMouseReleased) middleMouseReleased = false;
		if (rightMousePressed) rightMousePressed = false;
		if (rightMouseReleased) rightMouseReleased = false;
	}

	/**
	 * If the mouse wheel was moved this frame, this was the delta.
	 */
	public static var mouseWheelDelta(get, never):Int;
	public static function get_mouseWheelDelta():Int
	{
		if (mouseWheel)
		{
			mouseWheel = false;
			return _mouseWheelDelta;
		}
		return 0;
	}

	/**
	 * X position of the mouse on the screen.
	 */
	public static var mouseX(get, never):Int;
	private static function get_mouseX():Int
	{
		return HXP.screen.mouseX;
	}

	/**
	 * Y position of the mouse on the screen.
	 */
	public static var mouseY(get, never):Int;
	private static function get_mouseY():Int
	{
		return HXP.screen.mouseY;
	}

	/**
	 * The absolute mouse x position on the screen (unscaled).
	 */
	public static var mouseFlashX(get, never):Int;
	private static function get_mouseFlashX():Int
	{
		return Std.int(HXP.stage.mouseX - HXP.screen.x);
	}

	/**
	 * The absolute mouse y position on the screen (unscaled).
	 */
	public static var mouseFlashY(get, never):Int;
	private static function get_mouseFlashY():Int
	{
		return Std.int(HXP.stage.mouseY - HXP.screen.y);
	}

	private static function onMouseDown(e:MouseEvent)
	{
		if (!mouseDown)
		{
			mouseDown = true;
			mouseUp = false;
			mousePressed = true;
		}
	}

	private static function onMouseUp(e:MouseEvent)
	{
		mouseDown = false;
		mouseUp = true;
		mouseReleased = true;
	}

	private static function onMouseWheel(e:MouseEvent)
	{
		mouseWheel = true;
		_mouseWheelDelta = e.delta;
	}

	private static function onMiddleMouseDown(e:MouseEvent)
	{
		if (!middleMouseDown)
		{
			middleMouseDown = true;
			middleMouseUp = false;
			middleMousePressed = true;
		}
	}

	private static function onMiddleMouseUp(e:MouseEvent)
	{
		middleMouseDown = false;
		middleMouseUp = true;
		middleMouseReleased = true;
	}

	private static function onRightMouseDown(e:MouseEvent)
	{
		if (!rightMouseDown)
		{
			rightMouseDown = true;
			rightMouseUp = false;
			rightMousePressed = true;
		}
	}

	private static function onRightMouseUp(e:MouseEvent)
	{
		rightMouseDown = false;
		rightMouseUp = true;
		rightMouseReleased = true;
	}

	private static var _mouseWheelDelta:Int = 0;
}
