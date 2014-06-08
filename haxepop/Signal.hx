package haxepop;

/**
 * A Signal<M, R> can bind one or more callback functions that will be
 * called with messages of type M and return type R.
 *
 * Typically M is some type of event that will be passed to the callback.
 * R can be Void or some value that needs to be returned to the handler
 * (e.g. a Bool value specifying whether a collision took place.)
 *
 * Callback functions are grouped by an associated String key.
 */
class Signal<M, R>
{
	public var callbacks:Map<String, Array<(M->R)>>;

	public function new()
	{
		callbacks = new Map();
	}

	public function bind(key:String, callback:(M->R))
	{
		get(key).push(callback);
	}

	public function remove(key:String, callback:(M->R))
	{
		get(key).remove(callback);
	}

	public function clear(key:String)
	{
		while (exists(key))
		{
			get(key).pop();
		}
	}

	public function call(key:String, msg:M):Array<R>
	{
		return [for (callback in get(key)) callback(msg)];
	}

	public inline function keys():Array<String>
	{
		return [for (key in callbacks.keys()) if (exists(key)) key];
	}

	public inline function exists(name:String)
	{
		return get(name).length > 0;
	}

	public inline function get(name:String)
	{
		if (!callbacks.exists(name))
			callbacks[name] = [];
		return callbacks[name];
	}
}
