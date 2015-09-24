package haxepop.graphics.mode7;

import flash.geom.Point;
import haxepop.HXP;
import haxepop.Camera;
import haxepop.graphics.Image;
import haxepop.utils.Math;


class Mode7Image extends Image
{
	public var mode7:Mode7;

	override public function renderAtlas(layer:Int, point:Point, camera:Camera)
	{
		if (mode7 == null || !mode7.active)
		{
			super.renderAtlas(layer, point, camera);
			return;
		}

		// determine drawing location
		_point.x = point.x + x - originX * scale * scaleX - camera.x * scrollX;
		_point.y = point.y + y - originY * scale * scaleY - camera.y * scrollY;

		var fsx:Float = HXP.screen.fullScaleX,
			fsy:Float = HXP.screen.fullScaleY,
			stepx = width * scale * scaleX,
			stepy = height * scale * scaleY;

		var px1 = _point.x;
		var px2 = _point.x + stepx;
		var py1 = _point.y;
		var py2 = _point.y + stepy;

		var vy1 = mode7.ty(py1 * fsy);
		var vy2 = mode7.ty(py2 * fsy);
		var vx11 = mode7.tx(px1 * fsx, vy1);
		var vx12 = mode7.tx(px1 * fsx, vy2);
		var vx21 = mode7.tx(px2 * fsx, vy1);
		var vx22 = mode7.tx(px2 * fsx, vy2);

		_region.parent.prepareTriangles(
			vx11, vy1,
			vx21, vy1,
			vx22, vy2,
			vx12, vy2,
			0, 0,
			1, 0,
			1, 1,
			0, 1,
			(Std.int(0xFF * Math.clamp(alpha, 0, 1)) << 24) | color
		);
	}
}
