package haxepop.macros;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.xml.Fast;
import haxe.Serializer;
import haxepop.Platform;


class PlatformMacro
{
	macro static public function build():Array<Field>
	{
		var fields = Context.getBuildFields();
		var defines = Context.getDefines();
		var flags:Map<String, Bool> = new Map();

		for (flag in Platform.platformFlags)
		{
			flags[flag] =  defines.exists(flag);
		}

		for (platformFlag in Platform.platformFlags)
		{
			var name = platformFlag.substr(0,1).toUpperCase() + platformFlag.substr(1);
			fields.push({
				name: name,
				doc: null,
				meta: [{pos:Context.currentPos(), name:":impl"},{pos:Context.currentPos(), name:":enum"}],
				access: [AStatic, APublic],
				kind: FVar(macro : String, macro $v{platformFlag}),
				pos: Context.currentPos(),
			});
		}

		var mappings = [for (k in flags.keys()) macro $v{k} => $v{flags[k]}];
		fields.push({
			name: "flags",
			doc: null,
			meta: [],
			access: [AStatic, APublic],
			kind: FVar(macro : Map<String, Bool>, macro $a{mappings}),
			pos: Context.currentPos(),
		});

		return fields;
	}
}
