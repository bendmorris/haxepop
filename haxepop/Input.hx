package haxepop;

import flash.ui.Keyboard;
import flash.ui.Multitouch;
import flash.ui.MultitouchInputMode;
import haxepop.HXP;
import haxepop.Signal;
import haxepop.ds.Either;
import haxepop.input.InputMethod;
import haxepop.input.Mouse;

typedef InputType =
{
	var type:String;
	var value:Int;
}

typedef InputCallback = InputInstance -> Void;

enum InputEventType
{
	DOWN;
	PRESSED;
	RELEASED;
}

class InputInstance
{
	public var type:String="";

	public var down:Bool = false;
	public var pressed:Bool = false;
	public var released:Bool = false;

	function new() {}
}

class Input
{

	public static var inputMethods:Map<String, InputMethod>;
	public static var onDown:Signal<InputInstance, Void> = new Signal();
	public static var onPress:Signal<InputInstance, Void> = new Signal();
	public static var onRelease:Signal<InputInstance, Void> = new Signal();

	public static function init()
	{
		inputMethods = new Map();

		haxepop.input.Mouse.enable();
		haxepop.input.Key.enable();
#if (mobile)
		haxepop.input.Gesture.enable();
#end
#if (native)
		//haxepop.input.Joystick.enable();
#end

		for (inputMethod in inputMethods)
		{
			inputMethod.init();
		}
	}

	/**
	 * Defines a new input.
	 * @param	name		String to map the input to.
	 * @param	keys		The keys to use for the Input.
	 */
	public static function define(name:String, inputs:Array<InputType>)
	{
		if (!_control.exists(name))
			_control.set(name, []);
		_control.set(name, _control.get(name).concat(inputs));
	}

	/**
	 * If the input or key is held down.
	 * @param	input		An input name or key to check for.
	 * @return	True or false.
	 */
	public static function check(name:String):Bool
	{
		if (_control.exists(name))
		{
			var inputs = _control.get(name);
			for (input in inputs)
			{
				if (inputMethods.exists(input.type))
				{
					if (inputMethods[input.type].inputCheck(input.value))
						return true;
				}
			}
		}
		return false;
	}

	/**
	 * If the input or key was pressed this frame.
	 * @param	input		An input name or key to check for.
	 * @return	True or false.
	 */
	public static function pressed(name:String):Bool
	{
		if (_control.exists(name))
		{
			var inputs = _control.get(name);
			for (input in inputs)
			{
				if (inputMethods.exists(input.type))
				{
					if (inputMethods[input.type].inputPressed(input.value))
						return true;
				}
			}
		}
		return false;
	}

	/**
	 * If the input or key was released this frame.
	 * @param	input		An input name or key to check for.
	 * @return	True or false.
	 */
	public static function released(name:String):Bool
	{
		if (_control.exists(name))
		{
			var inputs = _control.get(name);
			for (input in inputs)
			{
				if (inputMethods.exists(input.type))
				{
					if (inputMethods[input.type].inputReleased(input.value))
						return true;
				}
			}
		}
		return false;
	}

	public static function get(name:String):InputInstance
	{
		if (_control.exists(name))
		{
			var inputs = _control.get(name);
			for (input in inputs)
			{
				if (inputMethods.exists(input.type))
				{
					var i:InputMethod = inputMethods.get(input.type);
					if (i.inputCheck(input.value) || i.inputPressed(input.value) || i.inputReleased(input.value))
						return i.inputGet(input.value);
				}
			}
		}
		return null;
	}

	/**
	 * Updates the input states
	 */
	public static function update()
	{
		if (HXP.engine.active)
		{
			// check callbacks
			for (name in onDown.keys())
			{
				if (check(name))
				{
					onDown.call(name, get(name));
				}
			}

			for (name in onPress.keys())
			{
				if (pressed(name))
				{
					onPress.call(name, get(name));
				}
			}

			for (name in onRelease.keys())
			{
				if (released(name))
				{
					onRelease.call(name, get(name));
				}
			}
		}

		for (inputMethod in inputMethods.iterator())
		{
			inputMethod.update();
		}
	}

	// for backwards compatibility
	public static var mouseDown(get, never):Bool;
	static function get_mouseDown() { return Mouse.mouseDown; }
	public static var mousePressed(get, never):Bool;
	static function get_mousePressed() { return Mouse.mousePressed; }
	public static var mouseReleased(get, never):Bool;
	static function get_mouseReleased() { return Mouse.mouseReleased; }
	public static var rightMouseDown(get, never):Bool;
	static function get_rightMouseDown() { return Mouse.rightMouseDown; }
	public static var rightMousePressed(get, never):Bool;
	static function get_rightMousePressed() { return Mouse.rightMousePressed; }
	public static var rightMouseReleased(get, never):Bool;
	static function get_rightMouseReleased() { return Mouse.rightMouseReleased; }
	public static var mouseX(get, never):Float;
	static function get_mouseX() { return Mouse.mouseX; }
	public static var mouseY(get, never):Float;
	static function get_mouseY() { return Mouse.mouseY; }

	private static var _control:Map<String,Array<InputType>> = new Map<String,Array<InputType>>();
}
