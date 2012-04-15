package org.trexarms;

	/**
	 *  Flash 10.0 ◆ Actionscript 3.0
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

		import nme.display.Sprite;
		import nme.events.Event;

	/**
	 *  StateManager is a replacement for the event model of application
	 *  communication. Notifications in StateManager are still keyed off of
	 *  strings, but messaging is done on a broadcast model so listeners do
	 *  not need to know who the sender is.
	 * 
	 *  <p>Callbacks registered to StateManager must accept one payload parameter,
	 *  typed to whatever the expected data being sent is. If unsure, it is 
	 *  safer to use a wildcard or ...(rest) parameter in your callback
	 *  signature and perform data sanitation before consuming the data.</p>
	 * 
	 *  <p>One important thing to note when using StateManager is that the data
	 *  coming into each callback should be treated as read-only. While it is
	 *  possible to change the values on complex objects, it invalidates the 
	 *  data for any other callbacks listening to the same state that have not 
	 *  been alerted yet.</p>
	 * 
	 *  <p>This version of StateManager uses four tiers of priority. All single-use
	 *  callbacks are executed before all Model callbacks, which are fired 
	 *  before all Controller callbacks, which in turn are called before all 
	 *  View callbacks. Within each of these tiers, callbacks will be triggered
	 *  in the order that they were added (unless registered with dependencies).</p>
	 *  
	 *  <p>StateManager also has dependency chaining. When a callback is registered
	 *  with dependent states, it is not added to the callback queue until 
	 *  all the dependent states have been set. If a dependent state has already 
	 *  been set before the callback is registered, it is cleared from the list.</p>
	 */
	class StateManager {

		//--------------------------------------
		//  PUBLIC STATIC VARIABLES
		//--------------------------------------a

			/**  @private */
			public static var VERSION(getVersion, null):String;
			
			/**
			 *  The number of items that will be processed from the queue.
			 *  Increasing this number may cause slowdowns in state-heavy
			 *  applications. 
			 */
			public static var maxStatesToProcessPerTick:Int = 1;

		//--------------------------------------
		//  PRIVATE STATIC VARIABLES
		//--------------------------------------

			/**
			 *  This is the top of a data structure to hold all our callbacks,
			 *  indexed first by priority, then by the name of the state.
			 *  
			 *  The internal structure here is a Vector of Dictionaries, which 
			 *  are indexed by the state name and hold Vectors of callback functions.
			 *  
			 *  The indices on this object correspond to the priority tiers:
			 *    [0] Single-use listeners	(processed first)
			 *    [1] Model listeners		(processed second)
			 *    [2] Controller listeners	(processed third)
			 *    [3] View listeners		(processed last)
			 */
//			private static var LISTENERS:Array<Dynamic> = new Array<Dynamic>();
			private static var SINGLE_USE_LISTENERS:Hash<List<Dynamic->Dynamic>> = new Hash<List<Dynamic->Dynamic>>();
			private static var      MODEL_LISTENERS:Hash<List<Dynamic->Dynamic>> = new Hash<List<Dynamic->Dynamic>>();
			private static var CONTROLLER_LISTENERS:Hash<List<Dynamic->Dynamic>> = new Hash<List<Dynamic->Dynamic>>();
			private static var       VIEW_LISTENERS:Hash<List<Dynamic->Dynamic>> = new Hash<List<Dynamic->Dynamic>>();

			/**
			 *  This indexes every state that gets set and saves the most 
			 *  recent value.
			 */
			private static var STATE_ARCHIVE:Hash<Dynamic> = new Hash<Dynamic>();

			/**
			 *  Ordered list of states that have been 'set' but have not been
			 *  distributed to the callbacks yet. This is done to throttle
			 *  callbacks so we only perform a few per frame. 
			 */
			private static var PENDING_STATE_KEYS:List<String> = new List<String>();

			/**
			 *  This list is the corresponding payload to go with each state
			 *  in the PENDING_STATES collection.
			 */
			private static var PENDING_STATE_DATA:List<Dynamic> = new List<Dynamic>();

			/**
			 *	Flag so we can differentiate adding and removing listeners
			 *	inside the setState loop
			 */
			private static var _settingState:Bool;
			
			/**  Whether we have asked for onTick callbacks from ClockManager */
			private static var _ticking:Bool;

			/**  Counter for how many states we will touch this tick */
			private static var _statesToProcessThisTick:Int;
			
			/**  Sprite object, used for tracking enterFrame events. */
			private static var _ticker:Sprite = new Sprite();

		//--------------------------------------
		//  STATIC ACCESSORS
		//--------------------------------------

			/**  @private */
			private static function getVersion():String{
				return '0.0.3';
			}

		//--------------------------------------
		//  PUBLIC STATIC FUNCTIONS
		//--------------------------------------

			/**
			 *  Sets a listener to fire one time the next time its state is set.
			 *  These listeners are the highest priority.
			 * 
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting.
			 */
			public static function addSingleUseListener(state:String, callbackMethod:Dynamic->Dynamic, populateImmediately:Bool = true):Void{
				if(populateImmediately && STATE_ARCHIVE.exists(state)){
					callbackMethod(STATE_ARCHIVE.get(state));
				} else {
					if(SINGLE_USE_LISTENERS.get(state) == null) SINGLE_USE_LISTENERS.set(state, new List<Dynamic->Dynamic>());
					SINGLE_USE_LISTENERS.get(state).add(callbackMethod);	//  go to end
				}
			}

			/**
			 *  Sets a single use listener to fire after one or more other 
			 *  states have been resolved.
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param dependentStates An array of states that must be triggered before this callback will be executed.
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting, if all dependencies are already resolved.
			 */
			public static function addSingleUseListenerWithDependencies(state:String, callbackMethod:Dynamic->Dynamic, dependentStates:Array<String> = null, populateImmediately:Bool = true):Void{
				if(dependentStates == null || dependentStates.length <= 0){		//  if no dependencies - add as normal
					addSingleUseListener(state, callbackMethod, populateImmediately);
					return;
				}
				
				//  try to cull some of the states out before we allocate a new object...
				var i:Int = dependentStates.length - 1;
				while(i-- > 0){
					if(STATE_ARCHIVE.exists(dependentStates[i])) dependentStates.splice(i, 1);
				}
				
				if(dependentStates.length <= 0){
					//  all the dependencies are already defined - add as normal
					addSingleUseListener(state, callbackMethod, populateImmediately);
				} else {
					new DependencyChain(state, callbackMethod, RegistryMethod.SINGLE_USE, populateImmediately, dependentStates);
				}
			}

			/**
			 *  Sets a listener to fire when the given state is set. This 
			 *  should be used for all listeners in the Data Model tier to be
			 *  executed before View or Controller callbacks.
			 * 
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting.
			 */
			public static function addModelListener(state:String, callbackMethod:Dynamic->Dynamic, populateImmediately:Bool = true):Void{
				if(MODEL_LISTENERS.get(state) == null) MODEL_LISTENERS.set(state, new List<Dynamic->Dynamic>());
				MODEL_LISTENERS.get(state).add(callbackMethod);
				if(populateImmediately && STATE_ARCHIVE.exists(state)) callbackMethod(STATE_ARCHIVE.get(state));
			}

			/**
			 *  Sets a Model listener to fire after one or more other 
			 *  states have been resolved.
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param dependentStates An array of states that must be triggered before this callback will be executed.
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting, if all dependencies are already resolved.
			 */
			public static function addModelListenerWithDependencies(state:String, callbackMethod:Dynamic->Dynamic, dependentStates:Array<String> = null, populateImmediately:Bool = true):Void{
				if(dependentStates == null || dependentStates.length <= 0){		//  if no dependencies - add as normal
					addModelListener(state, callbackMethod, populateImmediately);
					return;
				}
				
				//  try to cull some of the states out before we allocate a new object...
				var i:Int = dependentStates.length - 1;
				while(i-- > 0){
					if(STATE_ARCHIVE.exists(dependentStates[i])) dependentStates.splice(i, 1);
				}

				if(dependentStates.length <= 0){
					//  all the dependencies are already defined - add as normal
					addModelListener(state, callbackMethod, populateImmediately);
				} else {
					new DependencyChain(state, callbackMethod, RegistryMethod.MODEL, populateImmediately, dependentStates);
				}
			}

			/**
			 *  Sets a listener to fire when the given state is set. This 
			 *  should be used for all listeners in the Controller tier to be
			 *  executed after Data Model callbacks but before View callbacks.
			 * 
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting.
			 */
			public static function addControllerListener(state:String, callbackMethod:Dynamic->Dynamic, populateImmediately:Bool = true):Void{
				if(CONTROLLER_LISTENERS.get(state) == null) CONTROLLER_LISTENERS.set(state, new List<Dynamic->Dynamic>());
				CONTROLLER_LISTENERS.get(state).add(callbackMethod);
				if(populateImmediately && STATE_ARCHIVE.exists(state)) callbackMethod(STATE_ARCHIVE.get(state));
			}

			/**
			 *  Sets a Controller listener to fire after one or more other 
			 *  states have been resolved.
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param dependentStates An array of states that must be triggered before this callback will be executed.
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting, if all dependencies are already resolved.
			 */
			public static function addControllerListenerWithDependencies(state:String, callbackMethod:Dynamic->Dynamic, dependentStates:Array<String> = null, populateImmediately:Bool = true):Void{
				if(dependentStates == null || dependentStates.length <= 0){		//  if no dependencies - add as normal
					addControllerListener(state, callbackMethod, populateImmediately);
					return;
				}

				//  try to cull some of the states out before we allocate a new object...
				var i:Int = dependentStates.length - 1;
				while(i-- > 0){
					if(STATE_ARCHIVE.exists(dependentStates[i])) dependentStates.splice(i, 1);
				}

				if(dependentStates.length <= 0){
					//  all the dependencies are already defined - add as normal
					addControllerListener(state, callbackMethod, populateImmediately);
				} else {
					new DependencyChain(state, callbackMethod, RegistryMethod.CONTROLLER, populateImmediately, dependentStates);
				}
			}

			/**
			 *  Sets a listener to fire when the given state is set. This 
			 *  should be used for all listeners in the View/Display tier to be
			 *  executed after Data Model and Controller tiers have updated.
			 * 
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting.
			 */
			public static function addViewListener(state:String, callbackMethod:Dynamic->Dynamic, populateImmediately:Bool = true):Void{
				if(VIEW_LISTENERS.get(state) == null) VIEW_LISTENERS.set(state, new List<Dynamic->Dynamic>());
				VIEW_LISTENERS.get(state).add(callbackMethod);
				if(populateImmediately && STATE_ARCHIVE.exists(state)) callbackMethod(STATE_ARCHIVE.get(state));
			}

			/**
			 *  Sets a View listener to fire after one or more other 
			 *  states have been resolved.
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param dependentStates An array of states that must be triggered before this callback will be executed.
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting, if all dependencies are already resolved.
			 */
			public static function addViewListenerWithDependencies(state:String, callbackMethod:Dynamic->Dynamic, dependentStates:Array<String> = null, populateImmediately:Bool = true):Void{
				if(dependentStates == null || dependentStates.length <= 0){		//  if no dependencies - add as normal
					addViewListener(state, callbackMethod, populateImmediately);
					return;
				}
				
				//  try to cull some of the states out before we allocate a new object...
				var i:Int = dependentStates.length - 1;
				while(i-- > 0){
					if(STATE_ARCHIVE.exists(dependentStates[i])) dependentStates.splice(i, 1);
				}

				if(dependentStates.length <= 0){
					//  all the dependencies are already defined - add as normal
					addViewListener(state, callbackMethod, populateImmediately);
				} else {
					new DependencyChain(state, callbackMethod, RegistryMethod.VIEW, populateImmediately, dependentStates);
				}
			}

			/**
			 *  Returns the most recent setting of a given state, or null.
			 * 
			 *  @param state The state to lookup.
			 *  @return The most recent value put into the given state.
			 */
			public static function getState(state:String):Dynamic{
				return STATE_ARCHIVE.get(state);
			}

			/**
			 *  Removes a state from the catalog and (optionally) broadcasts
			 *  the nullification. This method may also be used to destroy 
			 *  all associated listeners.
			 * 
			 *  @param state The state to remove
			 *  @param notifyListeners If true, a null value will be sent to any callbacks listening to this state
			 *  @param removeAllListeners If true, all functions listening to this state will be removed
			 */
			public static function clearState(state:String, notifyListeners:Bool = false, removeAllListeners:Bool = false):Void{
//				if(notifyListeners) setState(state, null);
				STATE_ARCHIVE.remove(state);
				
				if(removeAllListeners){
					SINGLE_USE_LISTENERS.remove(state);
					MODEL_LISTENERS.remove(state);
					CONTROLLER_LISTENERS.remove(state);
					VIEW_LISTENERS.remove(state);
				}
			}
			

			/**
			 *  Triggers all callbacks on the given state, passing the 
			 *  most recently set value.
			 *
			 *  @param state The state to refresh
			 *  @return The current value of the tickled state.
			 */
			public static function tickleState(state:String):Dynamic{
				setState(state, STATE_ARCHIVE.get(state));
			}

			/**
			 *  Applies the data to all callbacks registered against the state.
			 * 
			 *  <p>In normal operation, this will only call a few states per tick,
			 *  however, a special flag is included to force a state to fire 
			 *  at the time it is called. This is useful for multi-part states,
			 *  such as a callback in a Controller class requesting an immediate
			 *  update of the UI by triggering a second state.</p>
			 *
			 *  <p><strong>WARNING:</strong> Using the processImmediately flag can lead to 
			 *  states updating out of order!</p>
			 *
			 *  @param state The name of the state to set
			 *  @param data The parameter to pass into the callbacks
			 *  @param processImmediately If true this request skips any queued setState calls and fires immediately.
			 *  @return The data package passed in.
			 */
			public static function setState(state:String, data:Dynamic, processImmediately:Bool = false):Dynamic{
				//  we use this flag to find the cases when a callback triggers
				//  a second setState - since we don't want to get into recursion
				//  we add the new state onto the stack as normal and process 
				//  later. If the immediate flag is on - we will handle this
				//  state now - no matter what.
				if(_settingState && !processImmediately){
					PENDING_STATE_KEYS.push(state);				//  add to beginning
					PENDING_STATE_DATA.push(data);
					if(!_ticking) startTicking();
					return;
				}
				
				_settingState = true;
				STATE_ARCHIVE.set(state, data);
				--_statesToProcessThisTick;

				if(SINGLE_USE_LISTENERS.get(state) != null){
					while(SINGLE_USE_LISTENERS.get(state).length > 0){
						var callbackMethod:Dynamic->Dynamic = SINGLE_USE_LISTENERS.get(state).pop();		//  pull from beginning
						callbackMethod(data);
					}
				}
				
				var l:List<Dynamic->Dynamic> = MODEL_LISTENERS.get(state);
				if(l != null && l.length > 0){
					for(call in l) call(data);
				}

				l = CONTROLLER_LISTENERS.get(state);
				if(l != null && l.length > 0){
					for(call in l) call(data);
				}

				l = VIEW_LISTENERS.get(state);
				if(l != null && l.length > 0){
					for(call in l) call(data);
				}

				_settingState = false;
				return data;
			}

		//--------------------------------------
		//  PRIVATE STATIC CALLBACKS & HANDLERS
		//--------------------------------------

			private static function onTick(e:Event = null):Void{
				_statesToProcessThisTick = maxStatesToProcessPerTick;
				while(_statesToProcessThisTick > 0 && PENDING_STATE_KEYS.length > 0){
					setState(PENDING_STATE_KEYS.pop(), PENDING_STATE_DATA.pop());
				}
				
				if(PENDING_STATE_KEYS.length <= 0){
					//  we've gotten to the end of the queue
					//  we can go to sleep for a bit...
//					ClockManager.unregisterCallback(onTick);
					_ticker.removeEventListener(Event.ENTER_FRAME, onTick);
					_ticking = false;
				}
			}

		//--------------------------------------
		//  PRIVATE & PROTECTED STATIC FUNCTIONS
		//--------------------------------------

			private static function startTicking():Void{
				if(!_ticking){
					_ticker.addEventListener(Event.ENTER_FRAME, onTick);
					_ticking = true;
				}
			}

	}



	/**
	 *	@private
	 *  Used to differentiate the register__Listener methods internally.
	 */
	enum RegistryMethod {
		SINGLE_USE;
		MODEL;
		CONTROLLER;
		VIEW;
	}



	/**
	 *	@private
	 *  Internal class for managing dependencies inside StateManager.
	 */
	private class DependencyChain {

		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------
	
			/**  Constructor */
			public function new(state:String, callbackMethod:Dynamic->Dynamic, registryMethod:RegistryMethod, populateImmediately:Bool, blockers:Array<String>){
				_state = state;
				_callbackMethod = callbackMethod;
				_registryMethod = registryMethod;
				_populateImmediately = populateImmediately;
				_blockers = blockers;
				
				//  start waiting for the first dependency
				listenForNextBlocker();
			}

		//--------------------------------------
		//  PRIVATE VARIABLES
		//--------------------------------------

			private var _state:String;
			private var _callbackMethod:Dynamic->Dynamic;
			private var _registryMethod:RegistryMethod;
			private var _populateImmediately:Bool;
			private var _blockers:Array<String>;

		//--------------------------------------
		//  PRIVATE CALLBACKS & EVENT HANDLERS
		//--------------------------------------

			private function listenForNextBlocker(state:Dynamic = null):Void{
				if(_blockers.length <= 0){
					//  we're clear to go - finally time to add the real callback
					switch(_registryMethod){
						case RegistryMethod.SINGLE_USE:		StateManager.addSingleUseListener(_state, _callbackMethod, _populateImmediately);
						case RegistryMethod.MODEL:			StateManager.addModelListener(_state, _callbackMethod, _populateImmediately);
						case RegistryMethod.CONTROLLER:		StateManager.addControllerListener(_state, _callbackMethod, _populateImmediately);
						case RegistryMethod.VIEW:			StateManager.addViewListener(_state, _callbackMethod, _populateImmediately);
					}

					//  since we don't have any dependencies pointing in here
					//  any longer, as soon as this function closes, there will
					//  be no more pointers to this object so it gets collected
					_callbackMethod = null;
					_registryMethod = null;
					_blockers = null;
				} else {
					//  we still have blockers - listen for the next one to clear
					//  (we force populateImmediately to speed through these...)
					StateManager.addSingleUseListener(_blockers.pop(), listenForNextBlocker, true);
				}
			}

}

