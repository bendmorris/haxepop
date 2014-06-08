import haxepop.Engine;
import haxepop.Entity;
import haxepop.HXP;
import haxepop.Scene;

// dummy entity for testing class types
class TestEntity extends Entity
{
	public function new() { super(); }
}

class TestScene extends haxe.unit.TestCase
{

	public override function setup()
	{
		new Engine();
		scene = new Scene();
	}

	public function testScene()
	{
		HXP.scene = scene;
		assertFalse(HXP.scene == scene);

		// update to set the scene as active
		HXP.engine.update();
		assertTrue(HXP.scene == scene);
	}

	public function testEntityCount()
	{
		var e = new Entity();
		e.type = "foo";
		scene.add(e);
		assertEquals(0, scene.count);

		scene.updateLists();
		assertEquals(1, scene.count);

		scene.add(new Entity());
		scene.add(new Entity());
		scene.add(new Entity());
		scene.remove(e);
		scene.updateLists();
		assertEquals(3, scene.count);
	}

	public function testEntityTypes()
	{
		var e = new Entity();
		e.type = "foo";
		scene.add(e);
		scene.add(new Entity());
		scene.updateLists();
		assertEquals(1, scene.typeCount("foo"));
		assertEquals(0, scene.typeCount("bar"));
		assertEquals(1, scene.uniqueTypes);

		assertEquals(1, scene.classCount("haxepop.Entity"));

		e.type = "bar";
		assertEquals(0, scene.typeCount("foo"));
		assertEquals(1, scene.typeCount("bar"));
		assertEquals(1, scene.uniqueTypes);
	}

	public function testEntityLayers()
	{
		var e = new Entity();
		scene.add(e);
		scene.add(new Entity());
		scene.updateLists();
		assertEquals(0, scene.layerCount(15));
		assertEquals(1, scene.layers);

		e.layer = 15;
		assertEquals(1, scene.layerCount(15));
		assertEquals(2, scene.layers);

		e.layer = 0;
		assertEquals(1, scene.layers);
	}

	public function testEntityName()
	{
		var e = new Entity();
		e.name = "foo";
		scene.add(e);
		scene.updateLists();

		assertEquals(e, scene.getInstance("foo"));

		e.name = "bar";
		assertEquals(e, scene.getInstance("bar"));
		assertEquals(null, scene.getInstance("foo"));
	}

	private var scene:Scene;
}
