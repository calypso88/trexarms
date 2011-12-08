package org.trexarms {

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
	//  PACKAGES
	//-------------------------------------

		import org.trexarms.ClockManager;
		import flash.utils.Dictionary;

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
	public final class StateManager {

		//--------------------------------------
		// EMBEDDED ASSETS
		//--------------------------------------

		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------

			/**  @private */
			public static const VERSION:String = '0.0.2';

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
			 *    [3] View listeners		(processed fourth)
			 *    [4] Generic listeners		(processed last)
			 */
			private const LISTENERS:Vector.<Dictionary> = Vector.<Dictionary>([new Dictionary(), new Dictionary(), new Dictionary(), new Dictionary(), new Dictionary]);

			/**  Number of priority tiers to crawl */
			private const LISTENER_LENGTH:int = LISTENERS.length;

			/**
			 *  This indexes every state that gets set and saves the most 
			 *  recent value.
			 */
			private const STATE_ARCHIVE:Dictionary = new Dictionary();

			/**
			 *  Ordered list of states that have been 'set' but have not been
			 *  distributed to the callbacks yet. This is done to throttle
			 *  callbacks so we only perform a few per frame. 
			 */
			private const PENDING_STATE_KEYS:Vector.<String> = new Vector.<String>();

			/**
			 *  This list is the corresponding payload to go with each state
			 *  in the PENDING_STATES collection.
			 */
			private const PENDING_STATE_DATA:Vector.<Object> = new Vector.<Object>();

		//--------------------------------------
		// STATIC PROPERTIES
		//--------------------------------------

			//  Holds the singleton
			private static const instance:StateManager = new StateManager();

			//  Flag so we can differentiate adding and removing listeners inside the setState loop
			private static var _settingState:Boolean;

		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------

			/**  @private */
			public function StateManager(){
				super();
				LISTENERS.fixed = true;
				if(!instance) trace('[T-Rex Arms]: StateManager initialized, v.' + VERSION);
			}

		//--------------------------------------
		//  PUBLIC VARIABLES
		//--------------------------------------

			/**
			 *  The number of items that will be processed from the queue.
			 *  Increasing this number may cause slowdowns in state-heavy
			 *  applications. 
			 */
			public var maxStatesToProcessPerTick:int = 1;

		//--------------------------------------
		//  PRIVATE VARIABLES
		//--------------------------------------

			/**  Whether we have asked for onTick callbacks from ClockManager */
			private var _ticking:Boolean;

			/**  Counter for how many states we will touch this tick */
			private var _statesToProcessThisTick:int;

		//--------------------------------------
		//  ACCESSORS
		//--------------------------------------

			/**
			 *  The number of items that will be processed from the queue.
			 *  Increasing this number may cause slowdowns in state-heavy
			 *  applications. 
			 */
			public static function set maxStatesToProcessPerTick(value:int):void{
				instance.maxStatesToProcessPerTick = value;
			}

			/**  @private */
			public static function get maxStatesToProcessPerTick():int{
				return instance.maxStatesToProcessPerTick;
			}

		//--------------------------------------
		//  PUBLIC METHODS
		//--------------------------------------

			/**
			 *  Immediately removes a listener from a given state.
			 *
			 *  @param state The state being listened to.
			 *  @param callback The function that would be triggered.
			 */
			public static function removeListener(state:String, callback:Function):void{
				instance.removeListener(state, callback);
			}

			/**
			 *  @private
			 *  Immediately removes a listener from a given state.
			 *
			 *  @param state The state being listened to.
			 *  @param callback The function that would be triggered.
			 */
			public function removeListener(state:String, callback:Function):void{
				if(state in LISTENERS[0] && LISTENERS[0][state]){
					while(LISTENERS[0][state].indexOf(callback) > -1) LISTENERS[0][state].splice(LISTENERS[0][state].indexOf(callback), 1);
				}

				if(state in LISTENERS[1] && LISTENERS[1][state]){
					while(LISTENERS[1][state].indexOf(callback) > -1) LISTENERS[1][state].splice(LISTENERS[1][state].indexOf(callback), 1);
				}

				if(state in LISTENERS[2] && LISTENERS[2][state]){
					while(LISTENERS[2][state].indexOf(callback) > -1) LISTENERS[2][state].splice(LISTENERS[2][state].indexOf(callback), 1);
				}

				if(state in LISTENERS[3] && LISTENERS[3][state]){
					while(LISTENERS[3][state].indexOf(callback) > -1) LISTENERS[3][state].splice(LISTENERS[3][state].indexOf(callback), 1);
				}

				if(state in LISTENERS[4] && LISTENERS[4][state]){
					while(LISTENERS[4][state].indexOf(callback) > -1) LISTENERS[4][state].splice(LISTENERS[4][state].indexOf(callback), 1);
				}
			}

			/**
			 *  Sets a listener to fire one time the next time its state is set.
			 *  These listeners are the highest priority.
			 * 
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting.
			 */
			public static function addSingleUseListener(state:String, callback:Function, populateImmediately:Boolean = true):void{
				instance.addListenerAtPriority(state, callback, populateImmediately, 0);
			}

			/**
			 *  Sets a single use listener to fire after one or more other 
			 *  states have been resolved.
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param dependentStates An array of states that must be triggered before this callback will be executed.
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting, if all dependencies are already resolved.
			 */
			public static function addSingleUseListenerWithDependencies(state:String, callback:Function, dependentStates:Array, populateImmediately:Boolean = true):void{
				instance.addListenerAtPriorityWithDependencies(state, callback, dependentStates, populateImmediately, 0);
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
			public static function addModelListener(state:String, callback:Function, populateImmediately:Boolean = true):void{
				instance.addListenerAtPriority(state, callback, populateImmediately, 1);
			}

			/**
			 *  Sets a Model listener to fire after one or more other 
			 *  states have been resolved.
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param dependentStates An array of states that must be triggered before this callback will be executed.
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting, if all dependencies are already resolved.
			 */
			public static function addModelListenerWithDependencies(state:String, callback:Function, dependentStates:Array, populateImmediately:Boolean = true):void{
				instance.addListenerAtPriorityWithDependencies(state, callback, dependentStates, populateImmediately, 1);
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
			public static function addControllerListener(state:String, callback:Function, populateImmediately:Boolean = true):void{
				instance.addListenerAtPriority(state, callback, populateImmediately, 2);
			}

			/**
			 *  Sets a Controller listener to fire after one or more other 
			 *  states have been resolved.
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param dependentStates An array of states that must be triggered before this callback will be executed.
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting, if all dependencies are already resolved.
			 */
			public static function addControllerListenerWithDependencies(state:String, callback:Function, dependentStates:Array, populateImmediately:Boolean = true):void{
				instance.addListenerAtPriorityWithDependencies(state, callback, dependentStates, populateImmediately, 2);
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
			public static function addViewListener(state:String, callback:Function, populateImmediately:Boolean = true):void{
				instance.addListenerAtPriority(state, callback, populateImmediately, 3);
			}

			/**
			 *  Sets a View listener to fire after one or more other 
			 *  states have been resolved.
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param dependentStates An array of states that must be triggered before this callback will be executed.
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting, if all dependencies are already resolved.
			 */
			public static function addViewListenerWithDependencies(state:String, callback:Function, dependentStates:Array, populateImmediately:Boolean = true):void{
				instance.addListenerAtPriorityWithDependencies(state, callback, dependentStates, populateImmediately, 3);
			}

			/**
			 *  Sets a listener to fire when the given state is set.
			 * 
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting.
			 */
			public static function addListener(state:String, callback:Function, populateImmediately:Boolean = true):void{
				instance.addListenerAtPriority(state, callback, populateImmediately, 4);
			}
			
			/**
			 *  Sets a listener to fire after one or more other states have 
			 *  been resolved.
			 * 
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param dependentStates An array of states that must be triggered before this callback will be executed.
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting, if all dependencies are already resolved.
			 */
			public static function addListenerWithDependencies(state:String, callback:Function, dependentStates:Array, populateImmediately:Boolean = true):void{
				instance.addListenerAtPriorityWithDependencies(state, callback, dependentStates, populateImmediately, 4);
			}

			/** 
			 *  @private
			 *  This is exposed for the Dependency Chain - it should not be 
			 *  called from outside.
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting, if all dependencies are already resolved.
			 *  @param priority The priority tier to add this listener to
			 */
			public static function addListenerAtPriority(state:String, callback:Function, populateImmediately:Boolean = true, priority:uint = 4):void{
				instance.addListenerAtPriority(state, callback, populateImmediately, priority);
			}

			/**
			 *  @private
			 *  Sets a listener at the given priority level. This should only be accessed
			 *  by the static access functions.
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting, if all dependencies are already resolved.
			 *  @param priority The priority tier to add this listener to
			 */
			public function addListenerAtPriority(state:String, callback:Function, populateImmediately:Boolean = true, priority:uint = 4):void{
				if(priority == 0 && populateImmediately && state in STATE_ARCHIVE){
					callback(STATE_ARCHIVE[state]);											//  catch single-use listeners and don't add them if appropriate
					return;
				}

				if(priority >= LISTENER_LENGTH) priority = LISTENER_LENGTH - 1;
				if(!LISTENERS[priority][state]) LISTENERS[priority][state] = new Vector.<Function>();
				LISTENERS[priority][state].push(callback);
				if(populateImmediately && state in STATE_ARCHIVE) callback(STATE_ARCHIVE[state]);
			}
			
			/**
			 *  @private
			 *  Sets a listener at the given priority - after one or more other states 
			 *  have been satisfied.
			 *
			 *  @param state The state key to listen to
			 *  @param callback Callback method or closure
			 *  @param dependentStates An array of states that must be triggered before this callback will be executed.
			 *  @param populateImmediately If true, the state will attempt to be set from the most recent setting, if all dependencies are already resolved.
			 *  @param priority The priority tier to add this listener to
			 */
			public function addListenerAtPriorityWithDependencies(state:String, callback:Function, dependentStates:Array, populateImmediately:Boolean = true, priority:uint = 4):void{
				if(!dependentStates || dependentStates.length < 1){
					addListenerAtPriority(state, callback, populateImmediately, priority);
					return;
				}

				//  try to cull some of the states out before we allocate a new object...
				var i:int = dependentStates.length;
				while(i--){
					if(dependentStates[i] in STATE_ARCHIVE) dependentStates.splice(i, 1);
				}

				if(dependentStates.length < 1){
					//  all these dependencies are already handled - add as normal
					addListenerAtPriority(state, callback, populateImmediately, priority);
				} else {
					//  this object will hook back into StateManager until it's 
					//  spent, then it will free itself for GC.
					new DependencyChain(state, callback, populateImmediately, dependentStates, priority);
				}
			}

			/**
			 *  Returns the most recent setting of a given state. 
			 * 
			 *  @param state The state to lookup.
			 *  @return The most recent value put into the given state.
			 */
			public static function getState(state:String):*{
				return instance.getState(state);
			}

			/**  @private */
			public function getState(state:String):*{
				if(state in STATE_ARCHIVE) return STATE_ARCHIVE[state];
				return undefined;
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
			public static function clearState(state:String, notifyListeners:Boolean = false, removeAllListeners:Boolean = false):void{
				instance.clearState(state, notifyListeners, removeAllListeners);
			}

			/**  @private */
			public function clearState(state:String, notifyListeners:Boolean = false, removeAllListeners:Boolean = false):void{
				if(notifyListeners) setState(state, null);

				if(state in STATE_ARCHIVE) delete STATE_ARCHIVE[state];

				if(removeAllListeners){
					if(state in LISTENERS[0]) delete LISTENERS[0][state];
					if(state in LISTENERS[1]) delete LISTENERS[1][state];
					if(state in LISTENERS[2]) delete LISTENERS[2][state];
					if(state in LISTENERS[3]) delete LISTENERS[3][state];
					if(state in LISTENERS[4]) delete LISTENERS[4][state];
				}
			}

			/**
			 *  Triggers all callbacks on the given state, passing the 
			 *  most recently set value.
			 *
			 *  @param state The state to refresh
			 *  @return The current value of the tickled state.
			 */
			public static function tickleState(state:String):*{
				return instance.tickleState(state);
			}

			/**  @private */
			public function tickleState(state:String):*{
				return setState(state, (state in STATE_ARCHIVE) ? STATE_ARCHIVE[state] : void);
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
			public static function setState(state:String, data:* = void, processImmediately:Boolean = false):*{
				return instance.setState(state, data, processImmediately);
			}

			/**  @private */
			public function setState(state:String, data:* = void, processImmediately:Boolean = false):*{
				//  we use this flag to find the cases when a callback triggers
				//  a second setState - since we don't want to get into recursion
				//  we add the new state onto the stack as normal and process 
				//  later. If the immediate flag is on - we will handle this
				//  state now - no matter what.
				if(_settingState && !processImmediately){
					PENDING_STATE_KEYS.unshift(state);
					PENDING_STATE_DATA.unshift(data || void);
					if(!_ticking) ClockManager.registerCallback(onTick);		//  we need to be called in the future - so register for updates
					_ticking = true;
					return;
				}

				_settingState = true;
				STATE_ARCHIVE[state] = data || void;
				--_statesToProcessThisTick;
				//  handle single-use listeners here
				if(state in LISTENERS[0]){
					while(LISTENERS[0][state].length){
						var callback:Function = LISTENERS[0][state].pop();
						(data === void) ? callback() : callback(data);			//  this allows us to have callbacks with no parameters
					}
				}

				for(var tier:int = 1; tier < LISTENER_LENGTH; ++tier){
					if(state in LISTENERS[tier] && LISTENERS[tier][state].length){
						var i:int = LISTENERS[tier][state].length;
						while(i--){
							(data === void) ? LISTENERS[tier][state][i]() : LISTENERS[tier][state][i](data);
						}
					}
				}

				_settingState = false;
				return data;
			}

		//--------------------------------------
		//  CALLBACKS & EVENT LISTENERS
		//--------------------------------------

			/**
			 *  Called each tick by ClockManager. If their are queued states, 
			 *  this will distribute a few to the callbacks. 
			 */
			private function onTick():void{
				_statesToProcessThisTick = maxStatesToProcessPerTick;
				while(_statesToProcessThisTick > 0 && PENDING_STATE_KEYS.length){
					setState(PENDING_STATE_KEYS.pop(), PENDING_STATE_DATA.pop());
				}

				if(PENDING_STATE_KEYS.length == 0){
					//  we've gotten to the end of the queue
					//  we can go to sleep for a bit...
					ClockManager.unregisterCallback(onTick);
					_ticking = false;
				}
			}

		//--------------------------------------
		//  PRIVATE & PROTECTED INSTANCE METHODS
		//--------------------------------------

	}
}


//----------------------------------------------
//  PRIVATE CLASS
//----------------------------------------------

	import org.trexarms.StateManager;

	/**  private class for managing dependencies inside StateManager. */
	final class DependencyChain {

		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------

			/**  Creates a new DependencyChain object. */
			public function DependencyChain(state:String, callback:Function, populateImmediately:Boolean, blockers:Array, priority:uint = 0){
				_state = state;
				_callback = callback;
				_populateImmediately = populateImmediately;
				_blockers = blockers;
				_priority = priority;

				//  start waiting for the first dependency
				listenForNextBlocker();
			}

		//--------------------------------------
		//  PRIVATE VARIABLES
		//--------------------------------------

			private var _state:String;
			private var _callback:Function;
			private var _populateImmediately:Boolean;
			private var _blockers:Array;
			private var _priority:uint;

		//--------------------------------------
		//  CALLBACKS
		//--------------------------------------

			private function listenForNextBlocker(...args):void{
				if(_blockers.length){
					//  we still have blockers - listen for the next one to clear
					//  (we force populateImmediately to speed through these...)
					//  (these go into priority 0 so they are single-use)
					StateManager.addListenerAtPriority(_blockers.pop(), listenForNextBlocker, true, 0);
				} else {
					//  we're clear to go - finally time to add the real callback
					StateManager.addListenerAtPriority(_state, _callback, _populateImmediately, _priority);

					//  since we don't have any dependencies pointing in here
					//  any longer, as soon as this function closes, their will
					//  be no more pointers to this object so it gets collected
					_callback = null;
					_blockers = null;
				}
			}

	}