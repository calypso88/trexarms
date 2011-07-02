package org.trexarms {

	/**
	 *	Flash 10.0 ◆ Actionscript 3.0
	 *	Copyright ©2011 Rob Sampson | rob@hattv.com | www.calypso88.com
	 *
	 *	www.TRexArms.org
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
	//  PACKAGES
	//-------------------------------------

		import flash.utils.Dictionary;
		import flash.utils.getDefinitionByName;
		import flash.utils.getQualifiedClassName;

	/**
	 *  Utility class for keeping and distributing objects between active uses. 
	 */
	public final class ObjectPool {

		//--------------------------------------
		// EMBEDDED ASSETS
		//--------------------------------------

		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------

			/**  @private */
			public static const VERSION:String = '0.0.2';

		//--------------------------------------
		// STATIC PROPERTIES
		//--------------------------------------

			//  Holds the singleton
//			private static const instance:ObjectPool = new ObjectPool();
			
			//  Our directory of pooled objects, keyed by Class.
			private static const POOL:Dictionary = new Dictionary();
			
			//  Since we make things by Class and reclaim them by instance,
			//  we need a way to quickly link an instance to it's Class -
			//  the best way to keep things straight is a cross-reference
			//  with the constructor...
			private static const CLASS_LOOKUP:Dictionary = new Dictionary();

		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------
	
			/**  @private */
			public function ObjectPool(){
//				if(!instance) trace('[T-Rex Arms]: ObjectPool initialized, v.' + VERSION);
				//  still waffling about whether to make this a singleton or not...
			}

		//--------------------------------------
		//  PUBLIC VARIABLES
		//--------------------------------------

		//--------------------------------------
		//  PRIVATE VARIABLES
		//--------------------------------------

		//--------------------------------------
		//  ACCESSORS
		//--------------------------------------

		//--------------------------------------
		//  PUBLIC METHODS
		//--------------------------------------

			/**
			 *  Returns an instance of the class passed in. If the ObjectPool
			 *  has un-used copies of this class, one of those will be 
			 *  returned, otherwise a new object is allocated and returned.
			 * 
			 *  @param type The class of object to return.
			 *  @return An instance of the class passed in.
			 */
			public static function get(type:Class):*{
				if(POOL[type]){
					if(POOL[type].length){										//  we've seen this class before - do we have any to give away?
						return POOL[type].pop() as type;
					} else {
						return new type() as type;
					}
				} else {
					//  we've never seen this class before...
					var o:Object = new type();
					CLASS_LOOKUP[o.constructor] = type;
					POOL[type] = [];
					return o as type;
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
			public static function give(object:*):void{
				//  clean up the object if possible
				if('destroy' in object && object['destroy'] is Function) object.destroy();

				//  if this object doesn't exist in our tables, we
				//  need to figure out what it is and create the pool for it
				if(!CLASS_LOOKUP[object.constructor] || !POOL[CLASS_LOOKUP[object.constructor]]){
					//  nifty lookup from Dave at http://www.actionscriptdeveloper.co.uk/getting-the-class-of-an-object-in-as3
					var type:Class = Class(getDefinitionByName(getQualifiedClassName(object)));
					POOL[type] = [];
					CLASS_LOOKUP[object.constructor] = type;
				}

				//  add this object to the un-used pool
				POOL[CLASS_LOOKUP[object.constructor]].push(object);
			}

			/**
			 *  Allows the ObjectPooler to remove un-used objects for 
			 *  garbage collection. If a specified type is given, just those 
			 *  objects will be destroyed, otherwise the entire ObjectPool
			 *  is emptied.
			 * 
			 *  @param type A specific type of object to destroy.
			 */
			public static function gc(type:Class = null):void{
				if(type){
					if(POOL[type]){
						POOL[type].length = 0;
//						delete POOL[type];
					}
				} else {
//					for(var key:* in POOL){										//  this loop destroys the pool as well...
//						type = Class(key);										//  since we just want to kill the stuff inside, 
//						POOL[type].length = 0;									//  the loop below is faster for now
//						delete POOL[type];
//					}
					
					for each(var a:Array in POOL) a.length = 0;
				}
			}

		//--------------------------------------
		//  EVENT HANDLERS
		//--------------------------------------

		//--------------------------------------
		//  PRIVATE & PROTECTED INSTANCE METHODS
		//--------------------------------------

	}
}
