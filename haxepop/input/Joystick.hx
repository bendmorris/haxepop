package haxepop.input;

import flash.geom.Point;
import haxepop.HXP;
import haxepop.ds.Either;

#if (cpp || neko)
	import openfl.events.JoystickEvent;
#end

#if ouya
import tv.ouya.console.api.OuyaController;
import openfl.utils.JNI;
#end
import haxepop.HXP;
import haxepop.Input;

class ButtonPress extends InputInstance
{
	public var button:Int;

	public function new()
	{
		super();
		type = Joystick.name;
	}
}

enum JoyButtonState
{
	BUTTON_ON;
	BUTTON_OFF;
	BUTTON_PRESSED;
	BUTTON_RELEASED;
}

class Joystick implements InputMethod
{
	public static inline var name="joystick";

	public static function enable()
	{
		Input.inputMethods.set(name, new Joystick());
	}

	public static function disable()
	{
		if (Input.inputMethods.exists(name)) Input.inputMethods.remove(name);
	}

	public static function define(input:String, inputs:Array<Int>)
	{
		Input.define(input, [for (i in inputs) {type:name, value:i}]);
	}

	public function init()
	{
		HXP.stage.addEventListener(JoystickEvent.AXIS_MOVE, onJoyAxisMove);
		HXP.stage.addEventListener(JoystickEvent.BALL_MOVE, onJoyBallMove);
		HXP.stage.addEventListener(JoystickEvent.BUTTON_DOWN, onJoyButtonDown);
		HXP.stage.addEventListener(JoystickEvent.BUTTON_UP, onJoyButtonUp);
		HXP.stage.addEventListener(JoystickEvent.HAT_MOVE, onJoyHatMove);

#if ouya
		// Initializing OuyaController
		var getContext = JNI.createStaticMethod("org.haxe.lime.GameActivity", "getContext", "()Landroid/content/Context;",true);
		OuyaController.init(getContext());
#end
	}

	/**
	 * Returns a joystick object (creates one if not connected)
	 * @param  id The id of the joystick, starting with 0
	 * @return    A Joystick object
	 */
	public static function joystick(id:Int):Joystick
	{
		var joy:Joystick = _joysticks.get(id);
		if (joy == null)
		{
			joy = new Joystick();
			_joysticks.set(id, joy);
		}
		return joy;
	}

	/**
	 * Returns the number of connected joysticks
	 */
	public static var joysticks(get, never):Int;
	private static function get_joysticks():Int
	{
		var count:Int = 0;
		for (joystick in _joysticks)
		{
			if (joystick.connected)
			{
				count += 1;
			}
		}
		return count;
	}

	/**
	 * A map of buttons and their states
	 */
	public var buttons:Map<Int,JoyButtonState>;
	/**
	 * Each axis contained in an array.
	 */
	public var axis(null, default):Array<Float>;
	/**
	 * A Point containing the joystick's hat value.
	 */
	public var hat:Point;
	/**
	 * A Point containing the joystick's ball value.
	 */
	public var ball:Point;

	/**
	 * Determines the joystick's deadZone. Anything under this value will be considered 0 to prevent jitter.
	 */
	public static inline var deadZone:Float = 0.15;

	/**
	 * Creates and initializes a new Joystick.
	 */
	public function new()
	{
		buttons = new Map<Int,JoyButtonState>();
		ball = new Point(0, 0);
		axis = new Array<Float>();
		hat = new Point(0, 0);
		connected = false;
		_timeout = 0;
	}

	/**
	 * Updates the joystick's state.
	 */
	public function update()
	{
		for (joystick in _joysticks) joystick.update();

		_timeout -= HXP.elapsed;
		for (button in buttons.keys())
		{
			switch (buttons.get(button))
			{
				case BUTTON_PRESSED:
					buttons.set(button, BUTTON_ON);
				case BUTTON_RELEASED:
					buttons.set(button, BUTTON_OFF);
				default:
			}
		}
	}

	/**
	 * If the joystick button was pressed this frame.
	 * Omit argument to check for any button.
	 * @param  button The button index to check.
	 */
	public static function pressed(button:Int):Bool
	{
		if (buttons.exists(button))
		{
			return buttons.get(button) == BUTTON_PRESSED;
		}
		return false;
	}

	/**
	 * If the joystick button was released this frame.
	 * Omit argument to check for any button.
	 * @param  button The button index to check.
	 */
	public static function released(button:Int):Bool
	{
		if (buttons.exists(button))
		{
			return buttons.get(button) == BUTTON_RELEASED;
		}
		return false;
	}

	/**
	 * If the joystick button is held down.
	 * Omit argument to check for any button.
	 * @param  button The button index to check.
	 */
	public static function check(button:Int):Bool
	{
		if (buttons.exists(button))
		{
			var b = buttons.get(button);
			return b != BUTTON_OFF && b != BUTTON_RELEASED;
		}
		return false;
	}

	public function inputGet(button:Int):ButtonPress
	{
		var press = new ButtonPress();
		press.down = check(button);
		press.pressed = pressed(button);
		press.released = released(button);
		press.button = button;
		return press;
	}

	public function inputCheck(i:Int) { return check(i); }
	public function inputPressed(i:Int) { return pressed(i); }
	public function inputReleased(i:Int) { return released(i); }
	public function inputGet(i:Int) { return get(i); }

	/**
	 * Returns the axis value (from 0 to 1)
	 * @param  a The axis index to retrieve starting at 0
	 */
	public inline function getAxis(a:Int):Float
	{
		if (a < 0 || a >= axis.length) return 0;
		else return (Math.abs(axis[a]) < deadZone) ? 0 : axis[a];
	}

	/**
	 * If the joystick is currently connected.
	 */
	public var connected(get, set):Bool;
	private function get_connected():Bool { return _timeout > 0; }
	private function set_connected(value:Bool):Bool
	{
		if (value) _timeout = 3; // 3 seconds to timeout
		else _timeout = 0;
		return value;
	}

	private static function onJoyAxisMove(e:JoystickEvent)
	{
	#if ouya
		var joy:Joystick = joystick(OuyaController.getPlayerNumByDeviceId(e.device));
	#else
		var joy:Joystick = joystick(e.device);
	#end

		joy.connected = true;
		joy.axis = e.axis;
	}

	private static function onJoyBallMove(e:JoystickEvent)
	{
	#if ouya
		var joy:Joystick = joystick(OuyaController.getPlayerNumByDeviceId(e.device));
	#else
		var joy:Joystick = joystick(e.device);
	#end

		joy.connected = true;
		joy.ball.x = (Math.abs(e.x) < Joystick.deadZone) ? 0 : e.x;
		joy.ball.y = (Math.abs(e.y) < Joystick.deadZone) ? 0 : e.y;
	}

	private static function onJoyButtonDown(e:JoystickEvent)
	{
	#if ouya
		var joy:Joystick = joystick(OuyaController.getPlayerNumByDeviceId(e.device));
	#else
		var joy:Joystick = joystick(e.device);
	#end
		joy.connected = true;
		joy.buttons.set(e.id, BUTTON_PRESSED);
	}

	private static function onJoyButtonUp(e:JoystickEvent)
	{
	#if ouya
		var joy:Joystick = joystick(OuyaController.getPlayerNumByDeviceId(e.device));
	#else
		var joy:Joystick = joystick(e.device);
	#end
		joy.connected = true;
		joy.buttons.set(e.id, BUTTON_RELEASED);
	}

	private static function onJoyHatMove(e:JoystickEvent)
	{
	#if ouya
		var joy:Joystick = joystick(OuyaController.getPlayerNumByDeviceId(e.device));
	#else
		var joy:Joystick = joystick(e.device);
	#end
		joy.connected = true;
		joy.hat.x = (Math.abs(e.x) < Joystick.deadZone) ? 0 : e.x;
		joy.hat.y = (Math.abs(e.y) < Joystick.deadZone) ? 0 : e.y;
	}

	private var _timeout:Float;

	private static var _joysticks:Map<Int,ActiveJoystick> = new Map<Int,ActiveJoystick>();

}

class OUYA_GAMEPAD
{
#if ouya	// ouya console mapping
	// buttons
	public static inline var O_BUTTON:Int = 0; // 96
	public static inline var U_BUTTON:Int = 3; // 99
	public static inline var Y_BUTTON:Int = 4; // 100
	public static inline var A_BUTTON:Int = 1; // 97
	public static inline var LB_BUTTON:Int = 6; // 102
	public static inline var RB_BUTTON:Int = 7; // 103
	public static inline var BACK_BUTTON:Int = 5;
	public static inline var START_BUTTON:Int = 4;
	public static inline var LEFT_ANALOGUE_BUTTON:Int = 10; // 106
	public static inline var RIGHT_ANALOGUE_BUTTON:Int = 11; // 107
	public static inline var LEFT_TRIGGER_BUTTON:Int = 8;
	public static inline var RIGHT_TRIGGER_BUTTON:Int = 9;
	public static inline var DPAD_UP:Int = 19;
	public static inline var DPAD_DOWN:Int = 20;
	public static inline var DPAD_LEFT:Int = 21;
	public static inline var DPAD_RIGHT:Int = 22;

	/**
	 * The Home button event is handled as a keyboard event!
	 * Also, the up and down events happen at once,
	 * therefore, use pressed() or released().
	 */
	public static inline var HOME_BUTTON:Int = 16777234; // 82


	// axis
	public static inline var LEFT_ANALOGUE_X:Int = 0;
	public static inline var LEFT_ANALOGUE_Y:Int = 1;
	public static inline var RIGHT_ANALOGUE_X:Int = 11;
	public static inline var RIGHT_ANALOGUE_Y:Int = 14;
	public static inline var LEFT_TRIGGER:Int = 17;
	public static inline var RIGHT_TRIGGER:Int = 18;
	
#else	// desktop mapping
	public static inline var O_BUTTON:Int = 0;
	public static inline var U_BUTTON:Int = 1;
	public static inline var Y_BUTTON:Int = 2;
	public static inline var A_BUTTON:Int = 3;
	public static inline var LB_BUTTON:Int = 4;
	public static inline var RB_BUTTON:Int = 5;
	public static inline var BACK_BUTTON:Int = 20; // no back button!
	public static inline var START_BUTTON:Int = 20; // no start button!
	public static inline var LEFT_ANALOGUE_BUTTON:Int = 6;
	public static inline var RIGHT_ANALOGUE_BUTTON:Int = 7;
	public static inline var LEFT_TRIGGER_BUTTON:Int = 12;
	public static inline var RIGHT_TRIGGER_BUTTON:Int = 13;
	public static inline var DPAD_UP:Int = 8;
	public static inline var DPAD_DOWN:Int = 9;
	public static inline var DPAD_LEFT:Int = 10;
	public static inline var DPAD_RIGHT:Int = 11;
	
	/**
	 * The Home button only works on the Ouya-console
	 */
	public static inline var HOME_BUTTON:Int = 16777234;

	public static inline var LEFT_ANALOGUE_X:Int = 0;
	public static inline var LEFT_ANALOGUE_Y:Int = 1;
	public static inline var RIGHT_ANALOGUE_X:Int = 5;
	public static inline var RIGHT_ANALOGUE_Y:Int = 4;
	public static inline var LEFT_TRIGGER:Int = 2;	// negative values before button trigger, positive values after
	public static inline var RIGHT_TRIGGER:Int = 3;	// negative values before button trigger, positive values after
#end
}

class XBOX_GAMEPAD
{
#if mac
	/**
	 * Button IDs
	 */
	public static inline var A_BUTTON:Int = 0;
	public static inline var B_BUTTON:Int = 1;
	public static inline var X_BUTTON:Int = 2;
	public static inline var Y_BUTTON:Int = 3;
	public static inline var LB_BUTTON:Int = 4;
	public static inline var RB_BUTTON:Int = 5;
	public static inline var BACK_BUTTON:Int = 9;
	public static inline var START_BUTTON:Int = 8;
	public static inline var LEFT_ANALOGUE_BUTTON:Int = 6;
	public static inline var RIGHT_ANALOGUE_BUTTON:Int = 7;
	
	public static inline var XBOX_BUTTON:Int = 10;

	public static inline var DPAD_UP:Int = 11;
	public static inline var DPAD_DOWN:Int = 12;
	public static inline var DPAD_LEFT:Int = 13;
	public static inline var DPAD_RIGHT:Int = 14;
	
	/**
	 * Axis array indicies
	 */
	public static inline var LEFT_ANALOGUE_X:Int = 0;
	public static inline var LEFT_ANALOGUE_Y:Int = 1;
	public static inline var RIGHT_ANALOGUE_X:Int = 3;
	public static inline var RIGHT_ANALOGUE_Y:Int = 4;
	public static inline var LEFT_TRIGGER:Int = 2;
	public static inline var RIGHT_TRIGGER:Int = 5;
#elseif linux
	/**
	 * Button IDs
	 */
	public static inline var A_BUTTON:Int = 0;
	public static inline var B_BUTTON:Int = 1;
	public static inline var X_BUTTON:Int = 2;
	public static inline var Y_BUTTON:Int = 3;
	public static inline var LB_BUTTON:Int = 4;
	public static inline var RB_BUTTON:Int = 5;
	public static inline var BACK_BUTTON:Int = 6;
	public static inline var START_BUTTON:Int = 7;
	public static inline var LEFT_ANALOGUE_BUTTON:Int = 9;
	public static inline var RIGHT_ANALOGUE_BUTTON:Int = 10;
	
	public static inline var XBOX_BUTTON:Int = 8;
	
	public static inline var DPAD_UP:Int = 13;
	public static inline var DPAD_DOWN:Int = 14;
	public static inline var DPAD_LEFT:Int = 11;
	public static inline var DPAD_RIGHT:Int = 12;
	
	/**
	 * Axis array indicies
	 */
	public static inline var LEFT_ANALOGUE_X:Int = 0;
	public static inline var LEFT_ANALOGUE_Y:Int = 1;
	public static inline var RIGHT_ANALOGUE_X:Int = 3;
	public static inline var RIGHT_ANALOGUE_Y:Int = 4;
	public static inline var LEFT_TRIGGER:Int = 2;
	public static inline var RIGHT_TRIGGER:Int = 5;
#else // windows
	/**
	 * Button IDs
	 */
	public static inline var A_BUTTON:Int = 10;
	public static inline var B_BUTTON:Int = 11;
	public static inline var X_BUTTON:Int = 12;
	public static inline var Y_BUTTON:Int = 13;
	public static inline var LB_BUTTON:Int = 8;
	public static inline var RB_BUTTON:Int = 9;
	public static inline var BACK_BUTTON:Int = 5;
	public static inline var START_BUTTON:Int = 4;
	public static inline var LEFT_ANALOGUE_BUTTON:Int = 6;
	public static inline var RIGHT_ANALOGUE_BUTTON:Int = 7;
	
	public static inline var XBOX_BUTTON:Int = 14;
	
	public static inline var DPAD_UP:Int = 0;
	public static inline var DPAD_DOWN:Int = 1;
	public static inline var DPAD_LEFT:Int = 2;
	public static inline var DPAD_RIGHT:Int = 3;
	
	/**
	 * Axis array indicies
	 */
	public static inline var LEFT_ANALOGUE_X:Int = 0;
	public static inline var LEFT_ANALOGUE_Y:Int = 1;
	public static inline var RIGHT_ANALOGUE_X:Int = 2;
	public static inline var RIGHT_ANALOGUE_Y:Int = 3;
	public static inline var LEFT_TRIGGER:Int = 4;
	public static inline var RIGHT_TRIGGER:Int = 5;
#end
}

class PS3_GAMEPAD
{
	public static inline var TRIANGLE_BUTTON:Int = 12;
	public static inline var CIRCLE_BUTTON:Int = 13;
	public static inline var X_BUTTON:Int = 14;
	public static inline var SQUARE_BUTTON:Int = 15;
	public static inline var L1_BUTTON:Int = 10;
	public static inline var R1_BUTTON:Int = 11;
	public static inline var L2_BUTTON:Int = 8;
	public static inline var R2_BUTTON:Int = 9;
	public static inline var SELECT_BUTTON:Int = 0;
	public static inline var START_BUTTON:Int = 3;
	public static inline var PS_BUTTON:Int = 16;
	public static inline var LEFT_ANALOGUE_BUTTON:Int = 1;
	public static inline var RIGHT_ANALOGUE_BUTTON:Int = 2;
	public static inline var DPAD_UP:Int = 4;
	public static inline var DPAD_DOWN:Int = 6;
	public static inline var DPAD_LEFT:Int = 7;
	public static inline var DPAD_RIGHT:Int = 5;

	public static inline var LEFT_ANALOGUE_X:Int = 0;
	public static inline var LEFT_ANALOGUE_Y:Int = 1;
	public static inline var TRIANGLE_BUTTON_PRESSURE:Int = 16;
	public static inline var CIRCLE_BUTTON_PRESSURE:Int = 17;
	public static inline var X_BUTTON_PRESSURE:Int = 18;
	public static inline var SQUARE_BUTTON_PRESSURE:Int = 19;

}
