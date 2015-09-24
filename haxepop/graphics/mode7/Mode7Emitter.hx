package hidenstab.graphics;

import flash.geom.Point;
import flash.display.BitmapData;
import haxepop.Camera;
import haxepop.graphics.Emitter;


class Mode7Emitter extends Emitter
{
	public var mode7:Mode7;

	override public function render(target:BitmapData, point:Point, camera:Camera)
	{
		if (mode7 == null || !mode7.active)
		{
			return super.renderAtlas(layer, point, camera);
		}

		renderParticle(function() {
			_source.x = mode7.tx2(_source.x, _source.y);
			_source.y = mode7.ty2(_source.y);
			_source.scale *= mode7.scale2(_source.y);
			_source.render(target, point, camera);
		}, point, camera);
	}

	override public function renderAtlas(layer:Int, point:Point, camera:Camera)
	{
		if (mode7 == null || !mode7.active)
		{
			return super.renderAtlas(layer, point, camera);
		}

		renderParticle(function() {
			if (mode7.active)
			{
				_source.x = mode7.tx2(_source.x, _source.y);
				_source.y = mode7.ty2(_source.y);
				_source.scale *= mode7.scale2(_source.y);
			}
			_source.renderAtlas(layer, point, camera);
		}, point, camera);
	}
}
