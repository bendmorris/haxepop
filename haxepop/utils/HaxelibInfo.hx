package haxepop.utils;


#if !macro @:build(haxepop.macros.HaxelibInfoMacro.build()) #end
class HaxelibInfo
{
#if macro
	public static var version:String;
#end
}
