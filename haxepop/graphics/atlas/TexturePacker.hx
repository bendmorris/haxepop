package haxepop.graphics.atlas;

import haxepop.HXP;
import openfl.Assets;

class TexturePacker
{
	public static function load(file:String):TextureAtlas
	{
		var xml = Xml.parse(Assets.getText(file));
		var root = xml.firstElement();
		var atlas = new TextureAtlas(root.get("imagePath"));
		for (sprite in root.elements())
		{
			HXP.rect.x = Std.parseInt(sprite.get("x"));
			HXP.rect.y = Std.parseInt(sprite.get("y"));
			if (sprite.exists("w")) HXP.rect.width = Std.parseInt(sprite.get("w"));
			if (sprite.exists("h")) HXP.rect.height = Std.parseInt(sprite.get("h"));

			// set the defined region
			var region = atlas.defineRegion(sprite.get("n"), HXP.rect);

			if (sprite.exists("r") && sprite.get("r") == "y") region.rotate = 90;
		}
		return atlas;
	}
}
