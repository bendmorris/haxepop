import haxepop.Engine;
import haxepop.Entity;
import haxepop.Graphic;
import haxepop.HXP;
import haxepop.Mask;
import haxepop.Scene;
import haxepop.Screen;
import haxepop.Sfx;
import haxepop.Tweener;
import haxepop.Tween;
import haxepop.World;
import haxepop.debug.Console;
import haxepop.debug.LayerList;
import haxepop.graphics.Animation;
import haxepop.graphics.Backdrop;
import haxepop.graphics.BitmapText;
import haxepop.graphics.Canvas;
import haxepop.graphics.Emitter;
import haxepop.graphics.Graphiclist;
import haxepop.graphics.Image;
import haxepop.graphics.Particle;
import haxepop.graphics.ParticleType;
import haxepop.graphics.PreRotation;
import haxepop.graphics.Spritemap;
import haxepop.graphics.Stamp;
import haxepop.graphics.Text;
import haxepop.graphics.TiledImage;
import haxepop.graphics.TiledSpritemap;
import haxepop.graphics.Tilemap;
import haxepop.graphics.atlas.AtlasData;
import haxepop.graphics.atlas.Atlas;
import haxepop.graphics.atlas.AtlasRegion;
import haxepop.graphics.atlas.BitmapFontAtlas;
import haxepop.graphics.atlas.TextureAtlas;
import haxepop.graphics.atlas.TileAtlas;
import haxepop.masks.Circle;
import haxepop.masks.Grid;
import haxepop.masks.Hitbox;
import haxepop.masks.Imagemask;
import haxepop.masks.Masklist;
import haxepop.masks.Pixelmask;
import haxepop.masks.Polygon;
import haxepop.masks.SlopedGrid;
import haxepop.math.Projection;
import haxepop.math.Vector;
import haxepop.tweens.TweenEvent;
import haxepop.tweens.misc.Alarm;
import haxepop.tweens.misc.AngleTween;
import haxepop.tweens.misc.ColorTween;
import haxepop.tweens.misc.MultiVarTween;
import haxepop.tweens.misc.NumTween;
import haxepop.tweens.misc.VarTween;
import haxepop.tweens.motion.CircularMotion;
import haxepop.tweens.motion.CubicMotion;
import haxepop.tweens.motion.LinearMotion;
import haxepop.tweens.motion.LinearPath;
import haxepop.tweens.motion.Motion;
import haxepop.tweens.motion.QuadMotion;
import haxepop.tweens.motion.QuadPath;
import haxepop.tweens.sound.Fader;
import haxepop.tweens.sound.SfxFader;
import haxepop.utils.Data;
import haxepop.utils.Draw;
import haxepop.utils.Ease;
import haxepop.utils.Input;
import haxepop.utils.Joystick;
import haxepop.utils.Key;
import haxepop.utils.Touch;

/**
 * Empty test.
 * Import all of HaxePunk classes to make sure everything compile,
 * and that all used openfl functionalities exists.
 */
class TestImport extends haxe.unit.TestCase
{
	public override function setup()
	{
	}

	public override function tearDown()
	{
	}
}
