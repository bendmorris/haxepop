package haxepop.graphics.atlas;

import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.Path;
import haxe.io.StringInput;
import flash.geom.Rectangle;
import openfl.Assets;
import haxepop.HXP;
import haxepop.graphics.atlas.AtlasData;

using StringTools;

typedef NamedValue<T> = {name:String, value:T};

class GdxTexturePacker
{
	public static function load(file:String):TextureAtlas
	{
		var data:String = Assets.getText(file);
		var inputDir:String = Path.directory(file);
		var atlas:TextureAtlas = new TextureAtlas();
		var reader:StringInput = new StringInput(data);
		var page:AtlasData;
		var pageName:String;
		var extension:String;

		while (true)
		{
			var line:String = null;
			try
			{
				line = reader.readLine();
			}
			catch (e:Eof)
			{
				break;
			}
			if (line == null) break;

			line = line.trim();
			if (line.length == 0) continue;

			// new page
			pageName = line;
			extension = Path.extension(pageName);
			page = AtlasData.getAtlasDataByName(Path.join([inputDir, pageName]), true);
			atlas._pages.set(pageName, page);
			
			var line:String = "";
			while (true)
			{
				try
				{
					line = reader.readLine();
				}
				catch (e:Eof)
				{
					break;
				}
				if (line.indexOf(":") == -1) break;

				var value = getValue(line);
				switch (value.name)
				{
					case "size": {}
					case "format": {}
					case "filter": {}
					case "repeat": {}
				}
			}
			
			while (line != "")
			{
				var regionName:String = line;
				try
				{
					line = reader.readLine();
				}
				catch (e:Eof)
				{
					break;
				}
				var values:Map<String, String> = new Map();
				while (line.indexOf(":") > -1)
				{
					var value = getValue(line);
					values[value.name] = value.value;
					try
					{
						line = reader.readLine();
					}
					catch (e:Eof)
					{
						break;
					}
				}
				var xy:Array<Int> = [for (x in getTuple(values["xy"])) Std.parseInt(x)];
				var size:Array<Int> = [for (x in getTuple(values["size"])) Std.parseInt(x)];
				var rotate:Float = values["rotate"] == "true" ? -90 : 0;
				var r:Rectangle = (rotate != 0) ? new Rectangle(xy[0], xy[1], size[1], size[0]) : new Rectangle(xy[0], xy[1], size[0], size[1]);
				var path:String = Path.join([inputDir, Path.withExtension(regionName, extension)]);
				atlas.defineRegion(path, r, null, rotate, pageName);
			}
		}

		return atlas;
	}

	static inline function getValue(line:String):NamedValue<String>
	{
		var parts:Array<String> = line.split(":");
		return {name: parts[0].trim(), value: parts[1].trim()};
	}

	static inline function getTuple(value:String):Array<String>
	{
		var values:Array<String> = [for (v in value.split(",")) v.trim()];
		return values;
	}
}
