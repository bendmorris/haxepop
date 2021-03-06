package haxepop;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageDisplayState;
import flash.display.StageQuality;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.geom.Rectangle;
import flash.Lib;
import haxe.EnumFlags;
import haxe.Timer;
import haxepop.Screen;
import haxepop.graphics.Image;
import haxepop.utils.Draw;
import haxepop.utils.Input;
import haxepop.Tweener;

/**
 * Main game Sprite class, added to the Flash Stage. Manages the game loop.
 */
class Engine extends Sprite
{
	/**
	 * If the game should stop updating/rendering.
	 */
	public var paused:Bool;

	/**
	 * If updating/rendering should occur.
	 */
	public var active(get, never):Bool;
	function get_active()
	{
		return !(paused || (HXP.autoPause && !(_gainFocus || HXP.focused)));
	}

	/**
	 * Cap on the elapsed time (default at 10 FPS). Raise this to allow for lower framerates.
	 */
	public var maxElapsed:Float;

	/**
	 * The max amount of frames that can be skipped in fixed framerate mode.
	 */
	public var maxFrameSkip:Int;

	/**
	 * The amount of milliseconds between ticks in fixed framerate mode.
	 */
	public var tickRate:Int;

	/**
	 * Constructor. Defines startup information about your game.
	 * @param	width			The width of your game.
	 * @param	height			The height of your game.
	 * @param	frameRate		The game framerate, in frames per second.
	 * @param	fixed			If a fixed-framerate should be used.
	 */
	public function new(width:Int = 0, height:Int = 0, frameRate:Float = 60, fixed:Bool = false, ?scaling:ScalingSettings = null)
	{
		super();

		// global game properties
		HXP.bounds = new Rectangle(0, 0, width, height);
		HXP.assignedFrameRate = frameRate;
		HXP.fixed = fixed;

		// global game objects
		HXP.engine = this;
		HXP.width = width;
		HXP.height = height;
		HXP.screen = new Screen();
		if (scaling == null)
			scaling = {mode: Default, integer: false};
		HXP.screen.scaling = scaling;

		HXP.entity = new Entity();
		HXP.time = Lib.getTimer();

		paused = false;
		maxElapsed = 0.1;
		maxFrameSkip = 5;
		tickRate = 4;
		_frameList = new Array<Int>();
		_systemTime = _delta = _frameListSum = 0;
		_frameLast = 0;

		// on-stage event listener
#if flash
		if (Lib.current.stage != null) onStage();
		else Lib.current.addEventListener(Event.ADDED_TO_STAGE, onStage);
#else
		addEventListener(Event.ADDED_TO_STAGE, onStage);
		Lib.current.addChild(this);
#end
	}

	/**
	 * Override this, called after Engine has been added to the stage.
	 */
	public function init() { }

	/**
	 * Override this, called when game gains focus
	 */
	public function focusGained()
	{
		if (HXP.autoPause && _pauseOverlay != null)
		{
			_pauseOverlay.visible = false;
		}
	}

	/**
	 * Override this, called when game loses focus
	 */
	public function focusLost()
	{
		if (HXP.autoPause && _pauseOverlay != null)
		{
			_pauseOverlay.visible = true;
		}
	}

	/**
	 * Updates the game, updating the Scene and Entities.
	 */
	public function update()
	{
		_scene.updateLists();
		checkScene();
		if (HXP.tweener.active && HXP.tweener.hasTween) HXP.tweener.updateTweens();
		if (_scene.active)
		{
			if (_scene.hasTween) _scene.updateTweens();
			_scene.update();
		}
		_scene.updateLists(false);
		HXP.screen.update();
		if (_gainFocus)
		{
			_gainFocus = false;
			HXP.focused = true;
		}
	}

	/**
	 * Renders the game, rendering the Scene and Entities.
	 */
	public function render()
	{
		if (HXP.screen.needsResize) HXP.resize(HXP.windowWidth, HXP.windowHeight);

		// timing stuff
		var t:Float = Lib.getTimer();
		if (_frameLast == 0) _frameLast = Std.int(t);

		// render loop
#if buffer
		HXP.screen.swap();
		HXP.screen.refresh();
#end
		Draw.resetTarget();

		if (_scene.visible) _scene.render();

#if buffer
		HXP.screen.redraw();
#end

		// update and draw screen overlays
		for (overlay in HXP.screen.overlays) overlay.update();
		for (overlay in HXP.screen.overlays) overlay.render();

		switch (HXP.screen.scaling.mode)
		{
			case Letterbox:
				// draw letterboxes
				if (HXP.screen.x > 0)
				{
					Draw.rect(0, 0, Std.int(HXP.screen.x), HXP.stage.stageHeight, HXP.screen.color, 1, true);
				}
				if (HXP.screen.x + HXP.screen.width < HXP.stage.stageWidth)
				{
					Draw.rect(HXP.screen.x + HXP.screen.width, 0, HXP.stage.stageWidth, HXP.stage.stageHeight, HXP.screen.color, 1, true);
				}
				if (HXP.screen.y > 0)
				{
					Draw.rect(0, 0, HXP.stage.stageWidth, Std.int(HXP.screen.y), HXP.screen.color, 1, true);
				}
				if (HXP.screen.y + HXP.screen.height < HXP.stage.stageHeight)
				{
					Draw.rect(0, HXP.screen.y + HXP.screen.height, HXP.stage.stageWidth, HXP.stage.stageHeight, HXP.screen.color, 1, true);
				}
			default: {}
		}

		// more timing stuff
		t = Lib.getTimer();
		_frameListSum += (_frameList[_frameList.length] = Std.int(t - _frameLast));
		if (_frameList.length > 10) _frameListSum -= _frameList.shift();
		HXP.frameRate = 1000 / (_frameListSum / _frameList.length);
		_frameLast = t;
	}

	/**
	 * Sets the game's stage properties. Override this to set them differently.
	 */
	private function setStageProperties()
	{
		if (HXP.assignedFrameRate <= 0)
		{
			HXP.assignedFrameRate = HXP.stage.frameRate;
		}
		else
		{
			HXP.stage.frameRate = HXP.assignedFrameRate;
		}
		HXP.stage.align = StageAlign.TOP_LEFT;
		HXP.stage.quality = StageQuality.HIGH;
		HXP.stage.scaleMode = StageScaleMode.NO_SCALE;
		HXP.stage.displayState = StageDisplayState.NORMAL;
		HXP.windowWidth = HXP.stage.stageWidth;
		HXP.windowHeight = HXP.stage.stageHeight;

		resize(); // call resize once to initialize the screen

		// set resize event
		HXP.stage.addEventListener(Event.RESIZE, function (e:Event) {
			resize();
		});

		HXP.stage.addEventListener(#if desktop FocusEvent.FOCUS_IN #else Event.ACTIVATE #end, function (e:Event) {
			_gainFocus = true;
			focusGained();
			_scene.focusGained();
		});

		HXP.stage.addEventListener(#if desktop FocusEvent.FOCUS_OUT #else Event.DEACTIVATE #end, function (e:Event) {
			HXP.focused = false;
			focusLost();
			_scene.focusLost();
		});

#if !(flash || html5)
		flash.display.Stage.shouldRotateInterface = function(orientation:Int):Bool {
			if (HXP.indexOf(HXP.orientations, orientation) == -1) return false;
			var tmp = HXP.height;
			HXP.height = HXP.width;
			HXP.width = tmp;
			resize();
			return true;
		}
#end
	}

	/** @private Event handler for stage resize */
	private function resize()
	{
		if (HXP.width == 0) HXP.width = HXP.stage.stageWidth;
		if (HXP.height == 0) HXP.height = HXP.stage.stageHeight;
		// calculate scale from width/height values
		HXP.windowWidth = HXP.stage.stageWidth;
		HXP.windowHeight = HXP.stage.stageHeight;

		HXP.resize(HXP.stage.stageWidth, HXP.stage.stageHeight);

		if (HXP.autoPause) createPauseOverlay();
	}

	/** @private Event handler for stage entry. */
	private function onStage(e:Event = null)
	{
		// remove event listener
#if flash
		if (e != null)
			Lib.current.removeEventListener(Event.ADDED_TO_STAGE, onStage);
		HXP.stage = Lib.current.stage;
		HXP.stage.addChild(this);
#else
		removeEventListener(Event.ADDED_TO_STAGE, onStage);
		HXP.stage = stage;
#end
		setStageProperties();

		// enable input
		Input.init();

		// switch scenes
		checkScene();

		// game start
		Draw.init();
		init();

		// start game loop
		_rate = 1000 / HXP.assignedFrameRate;
		if (HXP.fixed)
		{
			// fixed framerate
			_skip = _rate * (maxFrameSkip + 1);
			_last = _prev = Lib.getTimer();
			_timer = new Timer(tickRate);
			_timer.run = onTimer;
		}
		else
		{
			// nonfixed framerate
			_last = Lib.getTimer();
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

#if buffer
		#if (native && debug)
		HXP.console.log(["Warning: Using #buffer on native target may result in bad performance"]);
		#end
#end
#if hardware
		#if (flash && debug)
		HXP.console.log(["Warning: Using #hardware on flash target may result in corrupt graphics"]);
		#end
#end
	}

	/** @private Framerate independent game loop. */
	private function onEnterFrame(e:Event)
	{
		// update timer
		_time = _gameTime = Lib.getTimer();
		HXP._systemTime = _time - _systemTime;
		_updateTime = _time;
		HXP.elapsed = (_time - _last) / 1000;
		if (HXP.elapsed > maxElapsed) HXP.elapsed = maxElapsed;
		HXP.elapsed *= HXP.rate;
		_last = _time;

		// update loop
		if (active) update();

		// update console
		if (HXP.consoleEnabled()) HXP.console.update();

		Input.update();

		// update timer
		_time = _renderTime = Lib.getTimer();
		HXP._updateTime = _time - _updateTime;

		// render loop
		if (!active) _frameLast = _time; // continue updating frame timer
		else render();

		// update timer
		_time = _systemTime = Lib.getTimer();
		HXP._renderTime = _time - _renderTime;
		HXP._gameTime = _time - _gameTime;
	}

	/** @private Fixed framerate game loop. */
	private function onTimer()
	{
		// update timer
		_time = Lib.getTimer();
		_delta += (_time - _last);
		_last = _time;

		// quit if a frame hasn't passed
		if (_delta < _rate) return;

		// update timer
		_gameTime = Std.int(_time);
		HXP._systemTime = _time - _systemTime;

		// update loop
		if (_delta > _skip) _delta = _skip;
		while (_delta >= _rate)
		{
			HXP.elapsed = _rate * HXP.rate * 0.001;

			// update timer
			_updateTime = _time;
			_delta -= _rate;
			_prev = _time;

			// update loop
			if (active) update();

			// update console
			if (HXP.consoleEnabled()) HXP.console.update();

			// update input
			Input.update();

			// update timer
			_time = Lib.getTimer();
			HXP._updateTime = _time - _updateTime;
		}

		// update timer
		_renderTime = _time;

		// render loop
		if (active) render();

		// update timer
		_time = _systemTime = Lib.getTimer();
		HXP._renderTime = _time - _renderTime;
		HXP._gameTime =  _time - _gameTime;
	}

	/** @private Switch scenes if they've changed. */
	private inline function checkScene()
	{
		if (_scene != null && !_scenes.isEmpty() && _scenes.first() != _scene)
		{
			_scene.end();
			_scene.updateLists();
			if (_scene.autoClear && _scene.hasTween) _scene.clearTweens();
			if (contains(_scene.sprite)) removeChild(_scene.sprite);

			_scene = _scenes.first();

			addChild(_scene.sprite);
			HXP.camera = _scene.camera;
			_scene.updateLists();
			_scene.begin();
			_scene.updateLists();
		}
	}

	/**
	 * Push a scene onto the stack. It will not become active until the next update.
	 * @param value  The scene to push
	 */
	public function pushScene(value:Scene):Void
	{
		_scenes.push(value);
	}

	/**
	 * Pop a scene from the stack. The current scene will remain active until the next update.
	 */
	public function popScene():Scene
	{
		return _scenes.pop();
	}

	/**
	 * The currently active Scene object. When you set this, the Scene is flagged
	 * to switch, but won't actually do so until the end of the current frame.
	 */
	public var scene(get, set):Scene;
	private inline function get_scene():Scene { return _scene; }
	private function set_scene(value:Scene):Scene
	{
		if (_scene == value) return value;
		if (_scenes.length > 0)
		{
			_scenes.pop();
		}
		_scenes.push(value);
		return _scene;
	}

	function createPauseOverlay()
	{
		if (_pauseBitmap == null)
		{
			_pauseBitmap = new Bitmap();
		}
		else
		{
			_pauseBitmap.bitmapData.dispose();
		}
		if (_pauseOverlay != null)
		{
			_pauseOverlay.graphics.clear();
			if (contains(_pauseOverlay)) removeChild(_pauseOverlay);
		}

		var w:Int = HXP.windowWidth, h:Int = HXP.windowHeight;
		_pauseBitmap.bitmapData = Assets.createBitmap(w, h, true, 0x80FFFFFF);

		_pauseOverlay = new Sprite();
		_pauseOverlay.addChild(_pauseBitmap);

		var g = _pauseOverlay.graphics;
		g.moveTo(w / 3, h / 3);
		g.beginFill(0x808080);
		g.lineTo(w * 2 / 3, h / 2);
		g.lineTo(w / 3, h * 2 / 3);
		g.lineTo(w / 3, h / 3);

		_pauseOverlay.visible = false;
		addChild(_pauseOverlay);
	}

	// Scene information.
	private var _scene:Scene = new Scene();
	private var _scenes:List<Scene> = new List<Scene>();

	// Timing information.
	private var _delta:Float;
	private var _time:Float;
	private var _last:Float;
	private var _timer:Timer;
	private var	_rate:Float;
	private var	_skip:Float;
	private var _prev:Float;

	// Debug timing information.
	private var _updateTime:Float;
	private var _renderTime:Float;
	private var _gameTime:Float;
	private var _systemTime:Float;

	// FrameRate tracking.
	private var _frameLast:Float;
	private var _frameListSum:Int;
	private var _frameList:Array<Int>;
	private var _gainFocus:Bool = true;

	private var _pauseOverlay:Sprite;
	private var _pauseBitmap:Bitmap;
}
