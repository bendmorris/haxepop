package haxepop;

class EntityList<T:Entity> extends Entity
{
	public var entities:Array<T>;

	public var entityCount(get, never):Int;
	function get_entityCount()
	{
		return entities.length;
	}

	public function new()
	{
		entities = new Array();
		_recycled = new List();
		super();
	}

	override public function added()
	{
		if (scene != null)
		{
			for (entity in entities)
			{
				scene.add(entity);
			}
		}
	}

	override public function removed()
	{
		if (scene != null)
		{
			for (entity in entities)
			{
				scene.remove(entity);
			}
		}
	}

	override function set_x(v:Float):Float
	{
		var diff = v - x;
		for (entity in entities) entity.x += diff;
		return x = v;
	}

	override function set_y(v:Float):Float
	{
		var diff = v - y;
		for (entity in entities) entity.y += diff;
		return y = v;
	}

	override function set_type(value:String):String
	{
		for (entity in entities) entity.type = value;
		return _type = value;
	}

	public function apply(f:(T->Dynamic)):Array<Dynamic>
	{
		return [for (entity in entities) f(entity)];
	}

	public function addEntity(entity:T):T
	{
		entities.push(entity);
		entity.type = type;
		if (scene != null) scene.add(entity);
		return entity;
	}

	public function removeEntity(entity:T):T
	{
		entities.remove(entity);
		if (scene != null) scene.remove(entity);
		return entity;
	}

	/**
	 * Returns a new Entity, or a stored recycled Entity if one exists.
	 * @param	addToScene			Add it to the Scene immediately.
	 * @param	constructorArgs	List of the entity constructor arguments (optional).
	 * @return	The new Entity object.
	 */
	public function create(cls:Class<T>, ?constructorArgs:Array<Dynamic>):T
	{
		var entity:T = _recycled.pop();
		if (entity == null || entity.scene != null)
		{
			if (entity != null)
			{
				recycle(entity);
			}

			if (constructorArgs != null)
			{
				entity = Type.createInstance(cls, constructorArgs);
			}
			else
			{
				entity = Type.createInstance(cls, []);
			}
		}
		entity.active = true;

		return addEntity(entity);
	}

	/**
	 * Removes the Entity from the Scene at the end of the frame and recycles it.
	 * The recycled Entity can then be fetched again by calling the create() function.
	 * @param	e		The Entity to recycle.
	 * @return	The recycled Entity.
	 */
	public function recycle(entity:T):T
	{
		_recycled.push(entity);
		if (entity.scene != null && entity.scene != scene) entity.scene.remove(entity);
		entity.active = false;
		return removeEntity(entity);
	}

	/**
	 * Clears stored reycled Entities of the Class type.
	 */
	public function clearRecycled()
	{
		_recycled.clear();
	}

	var _recycled:List<T>;

}
