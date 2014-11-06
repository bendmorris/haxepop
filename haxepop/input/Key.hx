package haxepop.input;

import flash.events.KeyboardEvent;
import haxepop.HXP;
import haxepop.Input;

class KeyPress extends InputInstance
{
	public var keyCode:Int;

	public function new()
	{
		super();
		type = Key.name;
	}
}

class Key implements InputMethod
{
	public static inline var name="key";

	public static function enable()
	{
		Input.inputMethods.set(name, new Key());
	}

	public static function disable()
	{
		if (Input.inputMethods.exists(name)) Input.inputMethods.remove(name);
	}

	public static function define(input:String, inputs:Array<Int>)
	{
		Input.define(input, [for (i in inputs) {type:name, value:i}]);
	}

	public static inline var ANY = -1;

	public static inline var LEFT = 37;
	public static inline var UP = 38;
	public static inline var RIGHT = 39;
	public static inline var DOWN = 40;

	public static inline var ENTER = 13;
	public static inline var COMMAND = 15;
	public static inline var CONTROL = 17;
	public static inline var SPACE = 32;
	public static inline var SHIFT = 16;
	public static inline var BACKSPACE = 8;
	public static inline var CAPS_LOCK = 20;
	public static inline var DELETE = 46;
	public static inline var END = 35;
	public static inline var ESCAPE = 27;
	public static inline var HOME = 36;
	public static inline var INSERT = 45;
	public static inline var TAB = 9;
	public static inline var PAGE_DOWN = 34;
	public static inline var PAGE_UP = 33;
	public static inline var LEFT_SQUARE_BRACKET = 219;
	public static inline var RIGHT_SQUARE_BRACKET = 221;
	public static inline var TILDE = 192;

	public static inline var A = 65;
	public static inline var B = 66;
	public static inline var C = 67;
	public static inline var D = 68;
	public static inline var E = 69;
	public static inline var F = 70;
	public static inline var G = 71;
	public static inline var H = 72;
	public static inline var I = 73;
	public static inline var J = 74;
	public static inline var K = 75;
	public static inline var L = 76;
	public static inline var M = 77;
	public static inline var N = 78;
	public static inline var O = 79;
	public static inline var P = 80;
	public static inline var Q = 81;
	public static inline var R = 82;
	public static inline var S = 83;
	public static inline var T = 84;
	public static inline var U = 85;
	public static inline var V = 86;
	public static inline var W = 87;
	public static inline var X = 88;
	public static inline var Y = 89;
	public static inline var Z = 90;

	public static inline var F1 = 112;
	public static inline var F2 = 113;
	public static inline var F3 = 114;
	public static inline var F4 = 115;
	public static inline var F5 = 116;
	public static inline var F6 = 117;
	public static inline var F7 = 118;
	public static inline var F8 = 119;
	public static inline var F9 = 120;
	public static inline var F10 = 121;
	public static inline var F11 = 122;
	public static inline var F12 = 123;
	public static inline var F13 = 124;
	public static inline var F14 = 125;
	public static inline var F15 = 126;

	public static inline var DIGIT_0 = 48;
	public static inline var DIGIT_1 = 49;
	public static inline var DIGIT_2 = 50;
	public static inline var DIGIT_3 = 51;
	public static inline var DIGIT_4 = 52;
	public static inline var DIGIT_5 = 53;
	public static inline var DIGIT_6 = 54;
	public static inline var DIGIT_7 = 55;
	public static inline var DIGIT_8 = 56;
	public static inline var DIGIT_9 = 57;

	public static inline var NUMPAD_0 = 96;
	public static inline var NUMPAD_1 = 97;
	public static inline var NUMPAD_2 = 98;
	public static inline var NUMPAD_3 = 99;
	public static inline var NUMPAD_4 = 100;
	public static inline var NUMPAD_5 = 101;
	public static inline var NUMPAD_6 = 102;
	public static inline var NUMPAD_7 = 103;
	public static inline var NUMPAD_8 = 104;
	public static inline var NUMPAD_9 = 105;
	public static inline var NUMPAD_ADD = 107;
	public static inline var NUMPAD_DECIMAL = 110;
	public static inline var NUMPAD_DIVIDE = 111;
	public static inline var NUMPAD_ENTER = 108;
	public static inline var NUMPAD_MULTIPLY = 106;
	public static inline var NUMPAD_SUBTRACT = 109;

	public static inline var ANDROID_MENU = 16777234;

	public static var keyString:String = "";
	public static var keyStringMax:Int = 50;
	public static var restrict:String = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

	public function init()
	{
		HXP.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false,  2);
		HXP.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp, false,  2);
		
#if !(flash || js)
		_nativeCorrection.set("0_64", Key.INSERT);
		_nativeCorrection.set("0_65", Key.END);
		_nativeCorrection.set("0_66", Key.DOWN);
		_nativeCorrection.set("0_67", Key.PAGE_DOWN);
		_nativeCorrection.set("0_68", Key.LEFT);
		_nativeCorrection.set("0_69", -1);
		_nativeCorrection.set("0_70", Key.RIGHT);
		_nativeCorrection.set("0_71", Key.HOME);
		_nativeCorrection.set("0_72", Key.UP);
		_nativeCorrection.set("0_73", Key.PAGE_UP);
		_nativeCorrection.set("0_266", Key.DELETE);
		_nativeCorrection.set("123_222", Key.LEFT_SQUARE_BRACKET);
		_nativeCorrection.set("125_187", Key.RIGHT_SQUARE_BRACKET);
		_nativeCorrection.set("126_233", Key.TILDE);

		_nativeCorrection.set("0_80", Key.F1);
		_nativeCorrection.set("0_81", Key.F2);
		_nativeCorrection.set("0_82", Key.F3);
		_nativeCorrection.set("0_83", Key.F4);
		_nativeCorrection.set("0_84", Key.F5);
		_nativeCorrection.set("0_85", Key.F6);
		_nativeCorrection.set("0_86", Key.F7);
		_nativeCorrection.set("0_87", Key.F8);
		_nativeCorrection.set("0_88", Key.F9);
		_nativeCorrection.set("0_89", Key.F10);
		_nativeCorrection.set("0_90", Key.F11);

		_nativeCorrection.set("48_224", Key.DIGIT_0);
		_nativeCorrection.set("49_38", Key.DIGIT_1);
		_nativeCorrection.set("50_233", Key.DIGIT_2);
		_nativeCorrection.set("51_34", Key.DIGIT_3);
		_nativeCorrection.set("52_222", Key.DIGIT_4);
		_nativeCorrection.set("53_40", Key.DIGIT_5);
		_nativeCorrection.set("54_189", Key.DIGIT_6);
		_nativeCorrection.set("55_232", Key.DIGIT_7);
		_nativeCorrection.set("56_95", Key.DIGIT_8);
		_nativeCorrection.set("57_231", Key.DIGIT_9);

		_nativeCorrection.set("48_64", Key.NUMPAD_0);
		_nativeCorrection.set("49_65", Key.NUMPAD_1);
		_nativeCorrection.set("50_66", Key.NUMPAD_2);
		_nativeCorrection.set("51_67", Key.NUMPAD_3);
		_nativeCorrection.set("52_68", Key.NUMPAD_4);
		_nativeCorrection.set("53_69", Key.NUMPAD_5);
		_nativeCorrection.set("54_70", Key.NUMPAD_6);
		_nativeCorrection.set("55_71", Key.NUMPAD_7);
		_nativeCorrection.set("56_72", Key.NUMPAD_8);
		_nativeCorrection.set("57_73", Key.NUMPAD_9);
		_nativeCorrection.set("42_268", Key.NUMPAD_MULTIPLY);
		_nativeCorrection.set("43_270", Key.NUMPAD_ADD);
		//_nativeCorrection.set("", Key.NUMPAD_ENTER);
		_nativeCorrection.set("45_269", Key.NUMPAD_SUBTRACT);
		_nativeCorrection.set("46_266", Key.NUMPAD_DECIMAL); // point
		_nativeCorrection.set("44_266", Key.NUMPAD_DECIMAL); // comma
		_nativeCorrection.set("47_267", Key.NUMPAD_DIVIDE);
#end
	}

	public function new() {}

	public function update()
	{
		while (_pressNum-- > -1) _press[_pressNum] = -1;
		_pressNum = 0;
		while (_releaseNum-- > -1) _release[_releaseNum] = -1;
		_releaseNum = 0;
	}

	public static function check(key:Int):Bool
	{
		return (key < 0 ? _keyNum > 0 : _key.get(key));
	}

	public static function pressed(key:Int):Bool
	{
		return (key < 0 ? _pressNum != 0 : HXP.indexOf(_press, key) >= 0);
	}

	public static function released(key:Int):Bool
	{
		return (key < 0 ? _releaseNum != 0 : HXP.indexOf(_release, key) >= 0);
	}

	public static function get(key:Int):KeyPress
	{
		var keyPress = new KeyPress();
		keyPress.down = check(key);
		keyPress.pressed = pressed(key);
		keyPress.released = released(key);
		keyPress.keyCode = key;
		return keyPress;
	}

	public function inputCheck(i:Int) { return check(i); }
	public function inputPressed(i:Int) { return pressed(i); }
	public function inputReleased(i:Int) { return released(i); }
	public function inputGet(i:Int) { return get(i); }

	/**
	 * Returns the name of the key.
	 * @param	char		The key to name.
	 * @return	The name.
	 */
	public static function nameOfKey(char:Int):String
	{
		if (char == -1) return "";
		
		if (char >= A && char <= Z) return String.fromCharCode(char);
		if (char >= F1 && char <= F15) return "F" + Std.string(char - 111);
		if (char >= 96 && char <= 105) return "NUMPAD " + Std.string(char - 96);
		switch (char)
		{
			case LEFT:  return "LEFT";
			case UP:    return "UP";
			case RIGHT: return "RIGHT";
			case DOWN:  return "DOWN";
			
			case LEFT_SQUARE_BRACKET: return "{";
			case RIGHT_SQUARE_BRACKET: return "}";
			case TILDE: return "~";

			case ENTER:     return "ENTER";
			case CONTROL:   return "CONTROL";
			case SPACE:     return "SPACE";
			case SHIFT:     return "SHIFT";
			case BACKSPACE: return "BACKSPACE";
			case CAPS_LOCK: return "CAPS LOCK";
			case DELETE:    return "DELETE";
			case END:       return "END";
			case ESCAPE:    return "ESCAPE";
			case HOME:      return "HOME";
			case INSERT:    return "INSERT";
			case TAB:       return "TAB";
			case PAGE_DOWN: return "PAGE DOWN";
			case PAGE_UP:   return "PAGE UP";

			case NUMPAD_ADD:      return "NUMPAD ADD";
			case NUMPAD_DECIMAL:  return "NUMPAD DECIMAL";
			case NUMPAD_DIVIDE:   return "NUMPAD DIVIDE";
			case NUMPAD_ENTER:    return "NUMPAD ENTER";
			case NUMPAD_MULTIPLY: return "NUMPAD MULTIPLY";
			case NUMPAD_SUBTRACT: return "NUMPAD SUBTRACT";
		}
		return String.fromCharCode(char);
	}

	private static function onKeyDown(e:KeyboardEvent = null)
	{
		var code:Int = keyCode(e);
		if (code == -1) // No key
			return;

		if (!_key[code])
		{
			_key[code] = true;
			_keyNum++;
			_press[_pressNum++] = code;
		}

		if (code == BACKSPACE) keyString = keyString.substr(0, keyString.length - 1);
		else if (keyString.length < keyStringMax)
		{
			var str = String.fromCharCode(code);
			if (restrict.indexOf(str) > -1)
				keyString += str;
		}
	}

	private static function onKeyUp(e:KeyboardEvent = null)
	{
		var code:Int = keyCode(e);
		if (code == -1) // No key
			return;

		if (_key[code])
		{
			_key[code] = false;
			_keyNum--;
			_release[_releaseNum++] = code;
		}
	}

	public static function keyCode(e:KeyboardEvent) : Int
	{
	#if (flash || js)
		return e.keyCode;
	#else
		var code = _nativeCorrection.get(e.charCode + "_" + e.keyCode);

		if (code == null)
			return e.keyCode;
		else
			return code;
	#end
	}

	private static var _key:Map<Int, Bool> = new Map<Int, Bool>();
	private static var _keyNum:Int = 0;
	private static var _press:Array<Int> = new Array<Int>();
	private static var _pressNum:Int = 0;
	private static var _release:Array<Int> = new Array<Int>();
	private static var _releaseNum:Int = 0;
	private static var _nativeCorrection:Map<String, Int> = new Map<String, Int>();

}
