package haxepop.input;

import haxepop.Input;

interface InputMethod
{

	public function init():Void;
	public function update():Void;

	// check input states
	public function inputCheck(type:Int):Bool;
	public function inputPressed(type:Int):Bool;
	public function inputReleased(type:Int):Bool;
	public function inputGet(type:Int):InputInstance;

}
