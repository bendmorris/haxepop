package haxepop.overlays;

class Overlay
{
	public var width:Int = 0;
	public var height:Int = 0;

	public function update() {}
	public function render() {}

	public function resize()
	{
		width = HXP.windowWidth;
		height = HXP.windowHeight;
	}
}