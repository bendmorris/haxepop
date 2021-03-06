package haxepop;

import haxe.CallStack;
import haxe.EnumFlags;
import haxe.Timer;
import flash.display.BitmapData;
import flash.display.Bitmap;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.display.Stage;
import flash.display.StageDisplayState;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
#if flash
import flash.media.SoundMixer;
#end
import flash.media.SoundTransform;
import flash.system.System;
import flash.ui.Mouse;
import flash.utils.ByteArray;
import haxepop.Graphic;
import haxepop.Tween;
import haxepop.debug.Console;
import haxepop.utils.Math;
import haxepop.tweens.misc.Alarm;
import haxepop.tweens.misc.MultiVarTween;
import haxepop.utils.Ease;
import haxepop.utils.HaxelibInfo;

/**
 * Static catch-all class used to access global properties and functions.
 */
class HXP
{
	/**
	 * The HaxePop version.
	 * Format: Major.Minor.Patch
	 */
	public static inline var VERSION:String = HaxelibInfo.version;

	/**
	 * The color black (as an Int)
	 */
	@:deprecated public static inline var blackColor:Int = 0x00000000;

	/**
	 * Width of the game.
	 */
	public static var width:Int = 0;

	/**
	 * Height of the game.
	 */
	public static var height:Int = 0;

	/**
	 * Width of the window.
	 */
	public static var windowWidth:Int = 0;

	/**
	 * Height of the window.
	 */
	public static var windowHeight:Int = 0;

	/**
	 * If the game is running at a fixed framerate.
	 */
	public static var fixed:Bool = false;

	/**
	 * The framerate assigned to the stage.
	 */
	public static var frameRate:Float = 0;

	/**
	 * The framerate assigned to the stage.
	 */
	public static var assignedFrameRate:Float = 0;

	/**
	 * Time elapsed since the last frame (non-fixed framerate only).
	 */
	public static var elapsed:Float = 0;

	/**
	 * Timescale applied to HXP.elapsed (non-fixed framerate only).
	 */
	public static var rate:Float = 1;

	/**
	 * Whether the game should be paused when focus is lost.
	 */
	public static var autoPause:Bool = true;

	/**
	 * The Screen object, use to transform or offset the Screen.
	 */
	public static var screen:Screen;

	/**
	 * The current screen buffer, drawn to in the render loop.
	 */
	public static var buffer:BitmapData;

	/**
	 * A rectangle representing the size of the screen.
	 */
	public static var bounds:Rectangle;

	/**
	 * The default font file to use
	 */
	public static var defaultFont:String = "font/monkey.ttf";
	public static var defaultFontSize:Int = 24;

	/**
	 * Point used to determine drawing offset in the render loop.
	 */
	public static var camera(default, set):Camera = new Camera();
	static inline function set_camera(camera:Camera):Camera
	{
		screen._shakeAngle = 0;
		return HXP.camera = camera;
	}

	/**
	 * Global tweener for tweening between multiple scenes
	 */
	public static var tweener:Tweener = new Tweener();

	/**
	 * Whether the game has focus or not
	 */
	public static var focused:Bool = false;

	/**
	 * Half the screen width.
	 */
	public static var halfWidth(default, null):Float;

	/**
	 * Half the screen height.
	 */
	public static var halfHeight(default, null):Float;

	/**
	 * Defines the allowed orientations
	 */
	public static var orientations:Array<Int> = [];

	/**
	 * Defines how to rende the scene (deprecated; use #if buffer or #if hardware instead.)
	 */
	public static var renderMode(default, never):RenderMode = #if buffer RenderMode.BUFFER #else RenderMode.HARDWARE #end;

	/**
	 * If this is not null, a custom cursor will be drawn at the mouse position.
	 */
	public static var cursor(default, set):Graphic;
	static function set_cursor(c:Graphic)
	{
		if (c == null) Mouse.show()
		else Mouse.hide();
		
		return cursor = c;
	}

	public static function drawCursor()
	{
		var cursor = HXP.cursor;
		if (cursor != null)
		{
			cursor.scrollX = cursor.scrollY = 0;
			cursorPoint.x = screen.mouseX;
			cursorPoint.y = screen.mouseY;
#if buffer
			cursor.render(HXP.buffer, cursorPoint, camera);
#else
			cursor.renderAtlas(0, cursorPoint, camera);
#end
		}
	}

	/**
	 * The choose function randomly chooses and returns one of the provided values.
	 */
	public static var choose = Reflect.makeVarArgs(function(objs:Array<Dynamic>) {
		if (objs == null || objs.length == 0)
		{
			throw "Can't choose a random element on an empty array";
		}

		if (Std.is(objs[0], Array)) // Passed an Array
		{
			var c:Array<Dynamic> = cast(objs[0], Array<Dynamic>);

			if (c.length != 0)
			{
				return c[Std.random(c.length)];
			}
			else
			{
				throw "Can't choose a random element on an empty array";
			}
		}
		else // Passed multiple args
		{
			return objs[Std.random(objs.length)];
		}
	});

	/**
	 * The currently active World object (deprecated)
	 */
	@:deprecated public static var world(get, set):Scene;
	private static inline function get_world():Scene { return get_scene(); }
	private static inline function set_world(value:Scene):Scene { return set_scene(value); }

	/**
	 * The currently active Scene object. When you set this, the Scene is flagged
	 * to switch, but won't actually do so until the end of the current frame.
	 */
	public static var scene(get, set):Scene;
	private static inline function get_scene():Scene { return engine.scene; }
	private static inline function set_scene(value:Scene):Scene { return engine.scene = value; }

	/**
	 * Resize the screen.
	 * @param w	New width.
	 * @param h	New height.
	 */
	public static function resize(w:Int, h:Int)
	{
		// resize scene to scale
		camera.resize(width, height, w, h);
		halfWidth = width / 2;
		halfHeight = height / 2;
		bounds.width = w;
		bounds.height = h;
		screen.resize();
	}

	/**
	 * Empties an array of its' contents
	 * @param array filled array
	 */
	public static inline function clear(array:Array<Dynamic>)
	{
#if (cpp || php)
		array.splice(0, array.length);
#else
		untyped array.length = 0;
#end
	}

	/**
	 * Sets the camera position.
	 * @param	x	X position.
	 * @param	y	Y position.
	 */
	public static inline function setCamera(x:Float = 0, y:Float = 0)
	{
		camera.x = x;
		camera.y = y;
	}

	/**
	 * Resets the camera position.
	 */
	public static inline function resetCamera()
	{
		camera.x = camera.y = 0;
	}

	/**
	 * Toggles between windowed and fullscreen modes
	 */
	public static var fullscreen(get, set):Bool;
	private static inline function get_fullscreen():Bool { return HXP.stage.displayState == StageDisplayState.FULL_SCREEN; }
	private static inline function set_fullscreen(value:Bool):Bool
	{
		if (value) HXP.stage.displayState = StageDisplayState.FULL_SCREEN;
		else HXP.stage.displayState = StageDisplayState.NORMAL;
		return value;
	}

	/**
	 * Global volume factor for all sounds, a value from 0 to 1.
	 */
	public static var volume(get, set):Float;
	private static inline function get_volume():Float { return _volume; }
	private static function set_volume(value:Float):Float
	{
		if (value < 0) value = 0;
		if (_volume == value) return value;
		_soundTransform.volume = _volume = value;
		#if flash
		SoundMixer.soundTransform = _soundTransform;
		#end
		return _volume;
	}

	/**
	 * Global panning factor for all sounds, a value from -1 to 1.
	 */
	public static var pan(get, set):Float;
	private static inline function get_pan():Float { return _pan; }
	private static function set_pan(value:Float):Float
	{
		if (value < -1) value = -1;
		if (value > 1) value = 1;
		if (_pan == value) return value;
		_soundTransform.pan = _pan = value;
		#if flash
		SoundMixer.soundTransform = _soundTransform;
		#end
		return _pan;
	}

	/**
	 * Optimized version of Lambda.indexOf for Array on dynamic platforms (Lambda.indexOf is less performant on those targets).
	 *
	 * @param	arr		The array to look into.
	 * @param	param	The value to look for.
	 * @return	Returns the index of the first element [v] within Array [arr].
	 * This function uses operator [==] to check for equality.
	 * If [v] does not exist in [arr], the result is -1.
	 **/
	public static inline function indexOf<T>(arr:Array<T>, v:T) : Int
	{
		#if (haxe_ver >= 3.1)
		return arr.indexOf(v);
		#else
			#if (flash || js)
			return untyped arr.indexOf(v);
			#else
			return std.Lambda.indexOf(arr, v);
			#end
		#end
	}

	/**
	 * Returns the next item after current in the list of options.
	 * @param	current		The currently selected item (must be one of the options).
	 * @param	options		An array of all the items to cycle through.
	 * @param	loop		If true, will jump to the first item after the last item is reached.
	 * @return	The next item in the list.
	 */
	public static inline function next<T>(current:T, options:Array<T>, loop:Bool = true):T
	{
		if (loop)
			return options[(indexOf(options, current) + 1) % options.length];
		else
			return options[Std.int(Math.max(indexOf(options, current) + 1, options.length - 1))];
	}

	/**
	 * Returns the item previous to the current in the list of options.
	 * @param	current		The currently selected item (must be one of the options).
	 * @param	options		An array of all the items to cycle through.
	 * @param	loop		If true, will jump to the last item after the first is reached.
	 * @return	The previous item in the list.
	 */
	public static inline function prev<T>(current:T, options:Array<T>, loop:Bool = true):T
	{
		if (loop)
			return options[((indexOf(options, current) - 1) + options.length) % options.length];
		else
			return options[Std.int(Math.max(indexOf(options, current) - 1, 0))];
	}

	/**
	 * Swaps the current item between a and b. Useful for quick state/string/value swapping.
	 * @param	current		The currently selected item.
	 * @param	a			Item a.
	 * @param	b			Item b.
	 * @return	Returns a if current is b, and b if current is a.
	 */
	public static inline function swap<T>(current:T, a:T, b:T):T
	{
		return current == a ? b : a;
	}

	/**
	 * Binary insertion sort
	 * @param list     A list to insert into
	 * @param key      The key to insert
	 * @param compare  A comparison function to determine sort order
	 */
	public static function insertSortedKey<T>(list:Array<T>, key:T, compare:T->T->Int):Void
	{
		var result:Int = 0,
			mid:Int = 0,
			min:Int = 0,
			max:Int = list.length - 1;
		while (max >= min)
		{
			mid = min + Std.int((max - min) / 2);
			result = compare(list[mid], key);
			if (result > 0) max = mid - 1;
			else if (result < 0) min = mid + 1;
			else return;
		}

		list.insert(result > 0 ? mid : mid + 1, key);
	}

	/**
	 * Fetches a stored BitmapData object represented by the source.
	 * @param	source		Embedded Bitmap class.
	 * @return	The stored BitmapData object.
	 */
	public static function getBitmap(name:String):BitmapData
	{
		return Assets.getBitmap(name);
	}

	/**
	 * Sets a time flag.
	 * @return	Time elapsed (in milliseconds) since the last time flag was set.
	 */
	public static inline function timeFlag():Float
	{
		var t:Float = Timer.stamp(),
			e:Float = t - _time;
		_time = t;
		return e;
	}

	/**
	 * The global Console object.
	 */
	public static var console(get, never):Console;
	private static inline function get_console():Console
	{
		if (_console == null) _console = new Console();
		return _console;
	}

	/**
	 * Checks if the console is enabled.
	 */
	public static function consoleEnabled()
	{
		return _console != null;
	}

	/**
	 * Logs data to the console.
	 * @param	...data		The data parameters to log, can be variables, objects, etc. Parameters will be separated by a space (" ").
	 */
	public static var log = Reflect.makeVarArgs(function(data:Array<Dynamic>) {
		if (_console != null)
		{
			_console.log(data);
		}
	});

	/**
	 * Adds properties to watch in the console's debug panel.
	 * @param	...properties		The properties (strings) to watch.
	 */
	public static var watch = Reflect.makeVarArgs(function(properties:Array<Dynamic>) {
		if (_console != null)
		{
			_console.watch(properties);
		}
	});

	/**
	 * Tweens numeric public properties of an Object. Shorthand for creating a MultiVarTween tween, starting it and adding it to a Tweener.
	 * @param	object		The object containing the properties to tween.
	 * @param	values		An object containing key/value pairs of properties and target values.
	 * @param	duration	Duration of the tween.
	 * @param	options		An object containing key/value pairs of the following optional parameters:
	 * 						type		Tween type.
	 * 						complete	Optional completion callback function.
	 * 						ease		Optional easer function.
	 * 						tweener		The Tweener to add this Tween to.
	 * @return	The added MultiVarTween object.
	 *
	 * Example: HXP.tween(object, { x: 500, y: 350 }, 2.0, { ease: easeFunction, complete: onComplete } );
	 */
	public static function tween(object:Dynamic, values:Dynamic, duration:Float, options:Dynamic = null):MultiVarTween
	{
		if (options != null && Reflect.hasField(options, "delay"))
		{
			var delay:Float = options.delay;
			Reflect.deleteField( options, "delay" );
			HXP.alarm(delay, function (o:Dynamic):Void { HXP.tween(object, values, duration, options); });
			return null;
		}

		var type:TweenType = TweenType.OneShot,
			complete:CompleteCallback = null,
			ease:EaseFunction = null,
			tweener:Tweener = HXP.tweener;
		if (Std.is(object, Tweener)) tweener = cast(object, Tweener);
		if (options != null)
		{
			if (Reflect.hasField(options, "type")) type = options.type;
			if (Reflect.hasField(options, "complete")) complete = options.complete;
			if (Reflect.hasField(options, "ease")) ease = options.ease;
			if (Reflect.hasField(options, "tweener")) tweener = options.tweener;
		}
		var tween:MultiVarTween = new MultiVarTween(complete, type);
		tween.tween(object, values, duration, ease);
		tweener.addTween(tween);
		return tween;
	}

	/**
	 * Schedules a callback for the future. Shorthand for creating an Alarm tween, starting it and adding it to a Tweener.
	 * @param	delay		The duration to wait before calling the callback.
	 * @param	complete	The function to be called when complete.
	 * @param	type		Tween type.
	 * @param	tweener		The Tweener object to add this Alarm to. Defaults to HXP.tweener.
	 * @return	The added Alarm object.
	 *
	 * Example: HXP.alarm(5.0, callbackFunction, TweenType.Looping); // Calls callbackFunction every 5 seconds
	 */
	public static function alarm(delay:Float, complete:CompleteCallback, ?type:TweenType = null, tweener:Tweener = null):Alarm
	{
		if (type == null) type = TweenType.OneShot;
		if (tweener == null) tweener = HXP.tweener;

		var alarm:Alarm = new Alarm(delay, complete, type);
		tweener.addTween(alarm, true);
		return alarm;
	}

	/**
	 * Gets an array of frame indices.
	 * @param	from	Starting frame.
	 * @param	to		Ending frame.
	 * @param	skip	Skip amount every frame (eg. use 1 for every 2nd frame).
	 *
	 * @return	The array.
	 */
	public static function frames(from:Int, to:Int, skip:Int = 0):Array<Int>
	{
		var a:Array<Int> = new Array<Int>();
		skip ++;
		if (from < to)
		{
			while (from <= to)
			{
				a.push(from);
				from += skip;
			}
		}
		else
		{
			while (from >= to)
			{
				a.push(from);
				from -= skip;
			}
		}
		return a;
	}

	/**
	 * Shuffles the elements in the array.
	 * @param	a		The Object to shuffle (an Array or Vector).
	 */
	public static function shuffle<T>(a:Array<T>)
	{
		var i:Int = a.length, j:Int, t:T;
		while (--i > 0)
		{
			t = a[i];
			a[i] = a[j = Std.random(i + 1)];
			a[j] = t;
		}
	}

	/**
	 * Resize the stage.
	 *
	 * @param	width	New width.
	 * @param	height	New height.
	 */
	public static function resizeStage (width:Int, height:Int)
	{
		#if (cpp || neko)
		HXP.stage.resize(width, height);
		resize(width, height);
		#elseif debug
		trace("Can only resize the stage in cpp or neko targets.");
		#end
	}

	public static var time(null, set):Float;
	private static inline function set_time(value:Float):Float {
		_time = value;
		return _time;
	}

	// Console information.
	private static var _console:Console;

	// Time information.
	private static var _time:Float;
	public static var _updateTime:Float;
	public static var _renderTime:Float;
	public static var _gameTime:Float;
	public static var _systemTime:Float;

	// Pseudo-random number generation (the seed is set in Engine's contructor).
	private static var _seed:Int = 0;

	// Volume control.
	private static var _volume:Float = 1;
	private static var _pan:Float = 0;
	private static var _soundTransform:SoundTransform = new SoundTransform();

	// Included in HXP for backwards compatibility.
	public static var DEG(get, never):Float;
	public static inline function get_DEG(): Float { return Math.DEG; }
	public static var RAD(get, never):Float;
	public static inline function get_RAD(): Float { return Math.RAD; }

	// Global Flash objects.
	public static var stage:Stage;
	public static var engine:Engine;

	// Global objects used for rendering, collision, etc.
	public static var point:Point = new Point();
	public static var point2:Point = new Point();
	public static var cursorPoint:Point = new Point();
	public static var zero:Point = new Point();
	public static var rect:Rectangle = new Rectangle();
	public static var matrix:Matrix = new Matrix();
	public static var sprite:Sprite#if !headless = new Sprite()#end;
	public static var entity:Entity;
}
