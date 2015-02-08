package haxepop;


#if !macro
@:build(haxepop.macros.PlatformMacro.build())
#end
@:enum
abstract Platform(String) from String to String
{
	public static var platformFlags:Array<String> = [
		"android",
		"blackberry",
		"cpp",
		"debug",
		"desktop",
		"flash",
		"ios",
		"html5",
		"linux",
		"mac",
		"mobile",
		"native",
		"neko",
		"ouya",
		"tizen",
		"windows",
	];

#if macro
	public static var flags:Map<String, Bool>;
#end

	public static function check(flag:Platform):Bool
	{
		return flags.exists(flag) && flags.get(flag);
	}
}
