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

		import flash.display.Sprite;
		import flash.events.Event;
		import flash.utils.getTimer;

	/**
	 *  This class is an application loop intended to replace enterFrame
	 *  event listening as the primary way of executing code over time in 
	 *  a game or application.
	 * 
	 *  <p>For the simplest implementation, you can call ClockManager.registerCallback
	 *  and pass in the function you'd like called every tick.</p> 
	 *  
	 *  <p>For most cases it will be more useful to use this class as a
	 *  singleton and access it's method through static calls. However it is 
	 *  possible to create one or more independent ClockManager instances and access
	 *  its methods directly.</p>
	 */
	public final class ClockManager extends Sprite {

		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------

			/**  @private */
			public static const VERSION:String = '0.0.1';
		
			//  Collection of functions we'll call every frame
			private const CALLBACKS:Vector.<Function> = new Vector.<Function>();
			
			//  Collection of functions we only need to call once
			private const TEMPORARY_CALLBACKS:Vector.<Function> = new Vector.<Function>();

			//  Max number of times we will execute the stack in one marshalled frame slice
			private static const MAX_TICKS_PER_ITERATION:int = 4;

			//  Holds the singleton
			private static const instance:ClockManager = new ClockManager();

		//--------------------------------------
		// STATIC PROPERTIES
		//--------------------------------------

		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------
	
			/**  @private */
			public function ClockManager(){
				super();
				if(!instance) trace('[T-Rex Arms]: ClockManager initialized, v.' + VERSION);
			}

		//--------------------------------------
		//  PUBLIC VARIABLES
		//--------------------------------------

		//--------------------------------------
		//  PRIVATE VARIABLES
		//--------------------------------------

			private var _running:Boolean = false;
			private var _ticksPerSecond:Number = 30;
			private var _msPerTick:Number = 1000 / _ticksPerSecond;
			private var _currentTime:int;
			private var _lastUpdate:int;
			private var _timeBetweenLastTwoFrames:int;	
			private var _timeLeftToProcess:int;		
			private var _maxTicksPerIteration:int;
			private var _callbackIndex:uint;
			private var _tempCallbackLength:uint;
			private var _executing:Boolean;
			private var _functionsAreWaitingToUnregister:Boolean;
			private var _functionsToUnregister:Vector.<Function> = new Vector.<Function>();
			private var _startWhenNewFunctionIsRegistered:Boolean = true;
			private var _frames:int;
			private var _ticks:int;
			private var _averageTimeBetweenFrames:Number = _msPerTick;

		//--------------------------------------
		//  ACCESSORS
		//--------------------------------------

			/**  If true, the stack is being executed every tick */
			public static function get running():Boolean{
				return instance.running;
			}

			/**  If true, the stack is being executed every tick */
			public function get running():Boolean{
				return _running;
			}

			/**  The number of times to execute the callstack in one second. */
			public static function get ticksPerSecond():Number{
				return instance.ticksPerSecond;
			}
			
			/**  The number of times to execute the callstack in one second. */
			public function get ticksPerSecond():Number{
				return _ticksPerSecond;
			}

			/**  @private */
			public static function set ticksPerSecond(value:Number):void{
				instance.ticksPerSecond = value;
			}
			
			/**  @private */
			public function set ticksPerSecond(value:Number):void{
				_ticksPerSecond = value;
				_msPerTick = 1000 / _ticksPerSecond;
			}
			
			/**
			 *  The number of milliseconds since the AVM started. This is the 
			 *  same as getTimer()
			 */
			public static function get currentTime():int{
				return instance.currentTime;
			}
			
			/**
			 *  The number of milliseconds since the AVM started. This is the 
			 *  same as getTimer()
			 */
			public function get currentTime():int{
				return _currentTime;
			}

			/**
			 *  The current time of the tick being executed. This time may
			 *  be shifted backwards to account for the currently executing 
			 *  tick rather than the time of the current frame. 
			 */
			public static function get tickTime():int{
				return instance.tickTime;
			}
			
			/**
			 *  The current time of the tick being executed. This time may
			 *  be shifted backwards to account for the currently executing 
			 *  tick rather than the time of the current frame. 
			 */
			public function get tickTime():int{
				return _currentTime - _timeLeftToProcess;
			}

			/**
			 *  If true (default), the callback stack will start firing as soon
			 *  as callbacks are registered. If false, the stack will not 
			 *  execute until start() is called manually.
			 */
			public static function set autoActivate(value:Boolean):void{
				instance.autoActivate = value;
			}
			
			/**
			 *  If true (default), the callback stack will start firing as soon
			 *  as callbacks are registered. If false, the stack will not 
			 *  execute until start() is called manually.
			 */
			public function set autoActivate(value:Boolean):void{
				_startWhenNewFunctionIsRegistered = value;
			}
			
			/**  @private */
			public static function get autoActivate():Boolean{
				return instance.autoActivate;
			}
			
			/**  @private */
			public function get autoActivate():Boolean{
				return _startWhenNewFunctionIsRegistered;
			}

			/**  The number of callbacks currently in the stack. */
			public static function get length():uint{
				return instance.length;
			}

			/**  The number of callbacks currently in the stack. */
			public function get length():uint{
				return CALLBACKS.length;
			}
			
			/**  Returns the mean milliseconds between all processed frames. */
			public static function get averageTimeBetweenFrames():Number{
				return instance.averageTimeBetweenFrames;
			}
			
			/**  Returns the mean milliseconds between all processed frames. */
			public function get averageTimeBetweenFrames():Number{
				return _averageTimeBetweenFrames;
			}

			/**  Returns the mean FPS. */
			public static function get averageFrameRate():Number{
				return instance.averageFrameRate;
			}
			
			/**  Returns the mean FPS. */
			public function get averageFrameRate():Number{
				return 1000.0 / _averageTimeBetweenFrames;
			}

			/**  Returns the total frames the callstack was executed on */
			public static function get frameCount():int{
				return instance.frameCount;
			}

			/**  Returns the total frames the callstack was executed on */
			public function get frameCount():int{
				return _frames;
			}
			
			/**  Returns the total ticks executed */
			public static function get tickCount():int{
				return instance.tickCount;
			}
			
			/**  Returns the total ticks executed */
			public function get tickCount():int{
				return _ticks;
			}

		//--------------------------------------
		//  PUBLIC METHODS
		//--------------------------------------

			/**
			 *  Starts executing the callback stack once per tick.
			 */
			public static function start():void{
				instance.start();
			}

			/**  @private */
			public function start():void{
				if(!_running){
					addEventListener(Event.FRAME_CONSTRUCTED, onFrame);
					_lastUpdate = getTimer();
					_running = true;
				}
			}
			
			/**
			 *  Stops the callback stack from running. If currently executing,
			 *  the stack will finish the current iteration.
			 */
			public static function stop():void{
				instance.stop();
			}

			/**  @private */
			public function stop():void{
				if(_running){
					removeEventListener(Event.FRAME_CONSTRUCTED, onFrame);
					_startWhenNewFunctionIsRegistered = false;
					_running = false;
				}
			}

			/**
			 *  Adds a function to the stack to be called once per tick.
			 * 
			 *  @param callback The callback function or closure to execute.
			 */
			public static function registerCallback(callback:Function):void{
				instance.registerCallback(callback);
			}
			
			/**  @private */
			public function registerCallback(callback:Function):void{
				//  To allow the same callback to be called more than once per
				//  frame, comment this line out. WARNING: this may cause 
				//  unregisterCallback functions to behave erratically!
				if(CALLBACKS.indexOf(callback) > -1) throw new Error('Callback registered more than once.');

				CALLBACKS.unshift(callback);
				if(_startWhenNewFunctionIsRegistered) start();
			}

			/**
			 *  Takes all instances of a callback off the stack. If the
			 *  immediately flag is false (default) the callback is removed 
			 *  after the currently running stack is finished which may include
			 *  executing the function one final time; if true, the currently 
			 *  running stack is immediately invalidated and the callback will
			 *  not be fired again. WARNING: This is experimental functionality!
			 *
			 *  @param callback The callback to remove from the stack.
			 *  @param immediately If true the call stack is disrupted and the callback removed immediately.
			 */
			public static function unregisterCallback(callback:Function, immediately:Boolean = false):void{
				instance.unregisterCallback(callback, immediately);
			}
			
			/**  @private */
			public function unregisterCallback(callback:Function, immediately:Boolean = false):void{
				//  early out if we don't have this function registered at all
				var index:int = CALLBACKS.indexOf(callback);
				if(index == -1) return;

				if(_executing && immediately){
					//  we want to kill this callback NOW --
					//  since we crawl backwards - we need to worry about 
					//  callbacks with a lower index...
					while(index > -1){
						if(index < _callbackIndex){
							//  the callback is ahead of us in the queue - we
							//  need to make sure we don't break the callback stack
							_callbackIndex--;
						}
						
						CALLBACKS.splice(index, 1);
						index = CALLBACKS.indexOf(callback);
					}
				} else if(_executing && !immediately) {
					//  if we're currently in the stack, we need to be careful
					//  that we don't break the loop or screw with other callbacks
					//  we'll save the unregister until we're finished...
					_functionsToUnregister.push(callback);
					_functionsAreWaitingToUnregister = true;
				} else {
					//  we're not currently crawling the stack so we can just 
					//  splice the callback and be done
					while(index > -1){
						CALLBACKS.splice(index, 1);
						index = CALLBACKS.indexOf(callback);
					}
				}
				
				if(CALLBACKS.length == 0){
					stop();
					
					//  we're calling stop() here to save cpu cycles - 
					//  as far as the user is concerned we're still
					//  running so set the flag to start up again when
					//  new callbacks are added
					_startWhenNewFunctionIsRegistered = true;
				}
			}
			
			/**
			 *  Queues a function or closure to fire one time, after the
			 *  current frame is resolved and just before the next.
			 * 
			 *  @param callback A method or closure to execute
			 *  @param args Optional parameters to pass into the function
			 */
			public static function callNextFrame(callback:Function, ...args):void{
				instance.callNextFrame(callback, args);
			}

			/**  @private */
			public function callNextFrame(callback:Function, ...args):void{
				if(args && args.length){
					TEMPORARY_CALLBACKS.unshift(function():void{
						callback(args);
					});
				} else {
					TEMPORARY_CALLBACKS.unshift(callback);
				}
				++_tempCallbackLength;
			}

		//--------------------------------------
		//  CALLBACKS & EVENT HANDLERS
		//--------------------------------------

			/**
			 *  This function is called once per frame while running. This 
			 *  executes the callback stack one or more times depending on
			 *  the amount of time since the last frame.
			 */
			private function onFrame(e:Event):void{
				_lastUpdate = _currentTime;
				_currentTime = getTimer();
				++_frames;
				_timeBetweenLastTwoFrames = _timeLeftToProcess = _currentTime - _lastUpdate;
				_averageTimeBetweenFrames -= (_averageTimeBetweenFrames - _timeBetweenLastTwoFrames) / _frames;
				_maxTicksPerIteration = MAX_TICKS_PER_ITERATION;
				_executing = true;

				if(_tempCallbackLength){										//  perform our callNextFrames
					while(_tempCallbackLength--) TEMPORARY_CALLBACKS[_tempCallbackLength]();
					TEMPORARY_CALLBACKS.length = 0;
				}
				
				while(_timeLeftToProcess > 0 && _maxTicksPerIteration--){
					++_ticks;
					//  perform the callbacks
					_callbackIndex = CALLBACKS.length;
					while(_callbackIndex--){
						//  NOTE: the iterators in here are class-scoped and
						//  can be screwed with by forcing an unregister...
						CALLBACKS[_callbackIndex]();
					}

					_timeLeftToProcess -= _msPerTick;
				}
				
				_executing = false;

				//  if any code tried to unregister during the frame loop
				//  we need to take care of that now...
				if(_functionsAreWaitingToUnregister){
					_callbackIndex = _functionsToUnregister.length;
					while(_callbackIndex--){
						unregisterCallback(_functionsToUnregister[_callbackIndex]);
					}
					_functionsAreWaitingToUnregister = false;
				}
			}

		//--------------------------------------
		//  PRIVATE & PROTECTED INSTANCE METHODS
		//--------------------------------------

	}
}
