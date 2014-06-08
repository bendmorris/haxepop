import haxepop.utils.HaxelibInfo;

class Setup
{
	public static function setup()
	{
		Sys.command('haxelib run $OPENFL setup');
	}

	public static function update()
	{
		Sys.command("haxelib update haxepop");
	}

	private static inline var OPENFL = "lime";
}
