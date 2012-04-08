package org.trexarms;

	/**
	 *  HaXe
	 *
	 *  www.TRexArms.org
	 *  Licensed under the MIT License
	 *  
	 *  Permission is hereby granted, free of charge, to any person obtaining a copy of
	 *  this software and associated documentation files (the "Software"), to deal in
	 *  the Software without restriction, including without limitation the rights to
	 *  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
	 *  the Software, and to permit persons to whom the Software is furnished to do so,
	 *  subject to the following conditions:
	 *  
	 *  The above copyright notice and this permission notice shall be included in all
	 *  copies or substantial portions of the Software.
	 *  
	 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
	 *  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
	 *  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
	 *  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
	 *  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	 */

	//-------------------------------------
	//  PACKAGE DEPENDENCIES
	//-------------------------------------

	/**
	 *  Utility class for keeping and distributing objects between active uses. 
	 */
	class ObjectPool {

		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------
	
			/**  @private */
			public function new(){}

		//--------------------------------------
		//  PUBLIC STATIC VARIABLES
		//--------------------------------------

			public static var VERSION:String = '0.0.2';

		//--------------------------------------
		//  PRIVATE STATIC VARIABLES
		//--------------------------------------

			//  Our directory of pooled objects, keyed by class name (as String).
			private static var POOL:Hash<List<Dynamic>> = new Hash<List<Dynamic>>();
			
			//  This is a shorthand
			private static var BLANK_ARRAY:Array<Dynamic> = [];

		//--------------------------------------
		//  STATIC ACCESSORS
		//--------------------------------------

		//--------------------------------------
		//  PUBLIC STATIC FUNCTIONS
		//--------------------------------------

			/**
			 *  Returns an instance of the class passed in. If the ObjectPool
			 *  has un-used copies of this class, one of those will be 
			 *  returned, otherwise a new object is allocated and returned.
			 * 
			 *  @param type The class of object to return.
			 *  @return An instance of the class passed in.
			 */
			public static function get(type:Class<Dynamic>):Dynamic{
				var className:String = Type.getClassName(type);

				//  if we've never seen this class before - allocate a new silo for it
				if(!POOL.exists(className)) POOL.set(className, new List<Dynamic>());

				if(POOL.get(className).length > 0){
					return POOL.get(className).pop();
				} else {
					return Type.createInstance(type, BLANK_ARRAY);
				}
			}

			/**
			 *  Takes an object and stores it in the pool for later re-use.
			 *  This method attempts to run the destroy() method on any object
			 *  that has it before storage.
			 * 
			 *  <p>It is critical that objects given to the ObjectPooler are 
			 *  reset to the same state as when they were created new. This 
			 *  includes destroying pointers to the object, removing it from
			 *  the display list, and removing event listeners on the object.</p>
			 * 
			 *  @param object An instance of a class to store for re-use later.
			 */
			public static function give(object:Dynamic):Void{
				var objectClass:Class<Dynamic> = Type.getClass(object);
				if(objectClass == null) return;

				//  clean up the object if possible
				if(Reflect.hasField(object, 'destroy') && Reflect.isFunction(Reflect.field(object, 'destroy'))){
					Reflect.callMethod(object, Reflect.field(object, 'destroy'), BLANK_ARRAY);
				}

				//  if this object doesn't exist in our tables, we
				//  need to figure out what it is and create the pool for it
				var className:String = Type.getClassName(objectClass);
				if(!POOL.exists(className)) POOL.set(className, new List<Dynamic>());

				//  add this object to the un-used pool
				POOL.get(className).push(object);
			}

			/**
			 *  Allows the ObjectPooler to remove un-used objects for 
			 *  garbage collection. If a specified type is given, just those 
			 *  objects will be destroyed, otherwise the entire ObjectPool
			 *  is emptied.
			 * 
			 *  @param type A specific type of object to destroy.
			 */
			public static function gc(type:Class<Dynamic> = null):Void{
				if(type != null){
					if(POOL.exists(Type.getClassName(type))) POOL.get(Type.getClassName(type)).clear();
				} else {
					var l:Class<Dynamic>;
					for(l in POOL) l.clear();
				}
			}

		//--------------------------------------
		//  PRIVATE STATIC CALLBACKS & HANDLERS
		//--------------------------------------

		//--------------------------------------
		//  PRIVATE & PROTECTED STATIC FUNCTIONS
		//--------------------------------------

}