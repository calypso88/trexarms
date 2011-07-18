package org.trexarms.helpers {

	/**
	 *	Flash 10.0 ◆ Actionscript 3.0
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
	//  PACKAGE DEPENDENCIES
	//-------------------------------------

		import flash.display.DisplayObject;
		import flash.display.DisplayObjectContainer;
		import flash.display.Sprite;
		import flash.display.Stage;
		import flash.events.Event;
		import flash.events.KeyboardEvent;
		import flash.events.MouseEvent;
		import flash.filters.GlowFilter;
		import flash.geom.Point;
		import flash.ui.Keyboard;
		import flash.utils.getDefinitionByName;
		import flash.utils.getQualifiedClassName;

	/**
	 *  This class is a static "mode" that can be applied to a running swf to
	 *  test layouts and fine-tune positioning of stage elements. This class
	 *  is designed to work in conjunction with the T-Rex Arms Console,
	 *  although it is not strictly required.
	 * 
	 *  <p><strong>NOTE:</strong> While active, this class will intercept
	 *  mouse and keyboard inputs to the rest of the application. When 
	 *  de-activated, inputs will return to normal. You may hold the CTRL key
	 *  to pass events through as normal while DesignTime is active.</p>
	 *
	 *  <p><strong>USE:</strong> Click on an object to select it. The active displayObject will
	 *  have a yellow border. An active object can be dragged or nudged with
	 *  the arrow keys. Additionally, the following keyboard commands are
	 *  available:</p>
	 *  	<ul>
	 *  		<li><strong>ESCAPE:</strong> Exit DesignTime and return to normal operation</li>
	 *  		<li><strong>TAB:</strong> Select the next sibling display object in the tree</li>
	 *  		<li><strong>ENTER:</strong> Select the topmost child object of the currently selected object</li>
	 *  		<li><strong>DELETE:</strong> Deselect the current object</li>
	 *  		<li><strong>X:</strong> Deselect the current object</li>
	 *  		<li><strong>ARROW KEYS:</strong> Nudge the current object 1px</li>
	 *  		<li><strong>SHIFT + ARROW:</strong> Nudge the current object 10px</li>
	 *  	</ul>
	 *
	 *  <p><strong>DISCLAIMER:</strong> DesignTime puts applications into an
	 *  experimental state! Applications that use complex positioning or updates
	 *  over time, such as games, timeline animations, tweened movements, etc.
	 *  may cause unexpected behavior, including crashing or lockups. This 
	 *  code should NEVER be available to end-users. The author assumes no
	 *  responsibility or liability for any damages, or work lost.
	 *  <strong> Use at your own risk!</strong></p>
	 * 
	 *  @langversion ActionScript 3.0
	 *  @playerversion Flash 10.0
	 */
	public final class DesignTime {

		//--------------------------------------
		// EMBEDDED ASSETS
		//--------------------------------------

		//--------------------------------------
		//  PUBLIC STATIC CONSTANTS
		//--------------------------------------

			/**  If true, DesignTime will be blocked from turning on. */
			public static const DISABLED:Boolean = false;

			/**  @private */
			public static const VERSION:String = '0.0.1';

		//--------------------------------------
		//  PRIVATE STATIC CONSTANTS
		//--------------------------------------

			/**
			 *  If true, DesignTime will attempt to communicate with the
			 *  Console provided in T-Rex Arms. If false, output will be
			 *  channeled into the standard trace output.
			 */
			private static const USE_TREX_ARMS_CONSOLE:Boolean = true;

			//  used to find the top left corner of display objects
			private static const ORIGIN:Point = new Point(0, 0);

			/**  Used to store the distance between the _activeObject's x/y and the mouse cursor while dragging */
			private static const DELTA:Point = new Point();

			/**  Where the object was when we started */
			private static const ORIGINAL_POSITION:Point = new Point();

		//--------------------------------------
		//  PUBLIC CONSTANTS
		//--------------------------------------

		//--------------------------------------
		//  PRIVATE CONSTANTS
		//--------------------------------------

		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------
	
			/**
 			 * Constructor
			 */
			public function DesignTime(){
				super();
			}

		//--------------------------------------
		//  PUBLIC STATIC VARIABLES
		//--------------------------------------

		//--------------------------------------
		//  PRIVATE STATIC VARIABLES
		//--------------------------------------

			/**  True when designTime has taken over the display tree */
			private static var _designTimeActive:Boolean;
			
			/**  A reference to the Stage */
			private static var _stageInstance:Stage;

			/**  A reference to org.trexarms.Console - if necessary */
			private static var _console:Class;
			
			/**  fast reference to Console.inject */
			private static var _consoleInject:Function;

			/**  The object that we're currently playing with */
			private static var _activeObject:DisplayObject;
		
			/**  What we're calling the active object in the logs */
			private static var _activeObjectName:String = '';

			/**  When we select an object we filter it - this is the revert state */
			private static var _originalFilters:Array;

			/**  Whether we're in drag mode or not */
			private static var _dragging:Boolean;
		
		//--------------------------------------
		//  PUBLIC VARIABLES
		//--------------------------------------

		//--------------------------------------
		//  PRIVATE VARIABLES
		//--------------------------------------

		//--------------------------------------
		//  STATIC ACCESSORS
		//--------------------------------------

		//--------------------------------------
		//  ACCESSORS
		//--------------------------------------

		//--------------------------------------
		//  PUBLIC STATIC FUNCTIONS
		//--------------------------------------

			public static function designTime(stageInstance:Stage = null):void{
				if(DISABLED) return;
				if(stageInstance != null) _stageInstance = stageInstance;
				if(!_stageInstance || _designTimeActive) return;
				_designTimeActive = true;

				//  we need to get a reference to the Console class - but 
				//  only if we're using it - this gets us around importing the
				//  class and using a hard dependency.
				if(USE_TREX_ARMS_CONSOLE && _console == null){
					try{
						_console = getDefinitionByName('org.trexarms.Console') as Class;						
					} catch(err:Error){
						_console = null;
					}
					
					if(_console){
						try{
							if('inject' in _console && _console['inject'] is Function){
								_consoleInject = _console['inject'] as Function;
							}
						} catch(err:Error){
							_consoleInject = null;
						}

						try{
							if('hideConsole' in _console) _console['hideConsole']();
						} catch(err:Error){}
					}
				}				
trace('console: ', _console)
				//  we're going to try to catch all the inputs and deny them
				//  to the rest of the application...this is possible to  
				//  break but it's unlikely...also we need to make sure we
				//  can get out of this mode later!!

				//  listen on the capture phase at the highest possible priority...
				_stageInstance.addEventListener(MouseEvent.CLICK, mouseClick, true, int.MAX_VALUE);
				_stageInstance.addEventListener(KeyboardEvent.KEY_DOWN, keyDown, true, int.MAX_VALUE);
				_stageInstance.addEventListener(KeyboardEvent.KEY_UP, keyUp, true, int.MAX_VALUE);
				_stageInstance.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, true, int.MAX_VALUE);
				_stageInstance.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoved, true, int.MAX_VALUE);
				_stageInstance.addEventListener(MouseEvent.MOUSE_UP, mouseUp, true, int.MAX_VALUE);
				_stageInstance.addEventListener(Event.MOUSE_LEAVE, mouseLeave, true, int.MAX_VALUE);

				//  these aren't used, but we still want to deny them to the rest of the app
				_stageInstance.addEventListener(MouseEvent.DOUBLE_CLICK, swallowMouseEvent, true, int.MAX_VALUE);
				_stageInstance.addEventListener(MouseEvent.MOUSE_DOWN, swallowMouseEvent, true, int.MAX_VALUE);
				_stageInstance.addEventListener(MouseEvent.MOUSE_OUT, swallowMouseEvent, true, int.MAX_VALUE);
				_stageInstance.addEventListener(MouseEvent.MOUSE_OVER, swallowMouseEvent, true, int.MAX_VALUE);
				_stageInstance.addEventListener(MouseEvent.ROLL_OVER, swallowMouseEvent, true, int.MAX_VALUE);
				_stageInstance.addEventListener(MouseEvent.ROLL_OUT, swallowMouseEvent, true, int.MAX_VALUE);
			}

			public static function runTime():void{
				if(_designTimeActive){
					_designTimeActive = false;
					deselect();
					
					_stageInstance.removeEventListener(MouseEvent.CLICK, mouseClick);
					_stageInstance.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
					_stageInstance.removeEventListener(KeyboardEvent.KEY_UP, keyUp);
					_stageInstance.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
					_stageInstance.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoved);
					_stageInstance.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
					_stageInstance.removeEventListener(Event.MOUSE_LEAVE, mouseLeave);
					_stageInstance.removeEventListener(MouseEvent.DOUBLE_CLICK, swallowMouseEvent);
					_stageInstance.removeEventListener(MouseEvent.MOUSE_DOWN, swallowMouseEvent);
					_stageInstance.removeEventListener(MouseEvent.MOUSE_OUT, swallowMouseEvent);
					_stageInstance.removeEventListener(MouseEvent.MOUSE_OVER, swallowMouseEvent);
					_stageInstance.removeEventListener(MouseEvent.ROLL_OVER, swallowMouseEvent);
					_stageInstance.removeEventListener(MouseEvent.ROLL_OUT, swallowMouseEvent);
				}
			}

		//--------------------------------------
		//  PRIVATE STATIC CALLBACKS & HANDLERS
		//--------------------------------------

			/**  Turn the mouse target into the "selected" object on click */
			private static function mouseClick(e:MouseEvent):void{
				if(e.altKey || e.ctrlKey) return;								//  modifier keys allow events to go through
				e.stopImmediatePropagation();									//  block the input event from reaching the rest of the app
				select(e.target as DisplayObject);								//  make whatever was clicked the active object
			}

			/**  Update drag position */
			private static function mouseMoved(e:MouseEvent):void{
				if((e.altKey || e.ctrlKey) && !_dragging) return;				//  modifier keys allow events to go through
				e.stopImmediatePropagation();									//  block the input event from reaching the rest of the app
				if(!_dragging || !_activeObject) return;
				_activeObject.x = e.stageX - DELTA.x;
				_activeObject.y = e.stageY - DELTA.y;
			}
			
			/**  Start dragging if "picking up" the active object */
			private static function mouseDown(e:MouseEvent):void{
				if(e.altKey || e.ctrlKey) return;								//  modifier keys allow events to go through
				e.stopImmediatePropagation();									//  block the input event from reaching the rest of the app
				
				if(!_activeObject) return;
				if(e.target == _activeObject && !_dragging){
					_dragging = true;

					//  this is screwy...
					const p:Point = _activeObject.localToGlobal(ORIGIN);
					DELTA.x = e.stageX - p.x;
					DELTA.y = e.stageY - p.y;
				}
			}
			
			/**  Release dragging on mouseUp */
			private static function mouseUp(e:MouseEvent):void{
				if(!e.altKey && !e.ctrlKey) e.stopImmediatePropagation();	//  block the input event from reaching the rest of the app
				if(_dragging){
					stopDragging();
					injectToConsole(_activeObjectName, '(x=' + _activeObject.x + ', y=' + _activeObject.y + ')');
				}
			}

			/**  Release mouse-drag if you leave the stage */
			private static function mouseLeave(e:Event):void{
				if(_dragging) stopDragging();
			}
			
			/**  Handle keyboard input */
			private static function keyDown(e:KeyboardEvent):void{
				if(e.altKey || e.ctrlKey) return;								//  modifier keys allow events to go through
				e.stopImmediatePropagation();									//  block the input event from reaching the rest of the app
				if(!_activeObject) return;
				
				switch(e.keyCode){
					case Keyboard.DOWN:
						_activeObject.y += (e.shiftKey) ? 10 : 1;
						injectToConsole(_activeObjectName, '(x=' + _activeObject.x + ', y=' + _activeObject.y + ')');
						break;
					case Keyboard.UP:
						_activeObject.y -= (e.shiftKey) ? 10 : 1;
						injectToConsole(_activeObjectName, '(x=' + _activeObject.x + ', y=' + _activeObject.y + ')');
						break;
					case Keyboard.LEFT:
						_activeObject.x -= (e.shiftKey) ? 10 : 1;
						injectToConsole(_activeObjectName, '(x=' + _activeObject.x + ', y=' + _activeObject.y + ')');
						break;
					case Keyboard.RIGHT:
						_activeObject.x += (e.shiftKey) ? 10 : 1;
						injectToConsole(_activeObjectName, '(x=' + _activeObject.x + ', y=' + _activeObject.y + ')');
						break;
					case Keyboard.TAB:
						selectNextPeer();
						break;
					case Keyboard.ENTER:
					case Keyboard.NUMPAD_ENTER:
						selectFirstChild();
						break;
					case Keyboard.DELETE:
					case Keyboard.X:
//						_activeObject.x = ORIGINAL_POSITION.x;					//  back to original position
//						_activeObject.y = ORIGINAL_POSITION.y;
						deselect();
						break;
					case Keyboard.T:
						//  free transform
						break;
					case Keyboard.ESCAPE:
						runTime();
						return;
						break;
				}
			}

			/**  Right now this is essentially swallowKeyboardEvent */
			private static function keyUp(e:KeyboardEvent):void{
				if(e.altKey || e.ctrlKey) return;								//  modifier keys allow events to go through
				e.stopImmediatePropagation();									//  block the input event from reaching the rest of the app
			}

			/**  Block these events from entering the rest of the app */
			private static function swallowMouseEvent(e:MouseEvent):void{
				if(e.altKey || e.ctrlKey) return;								//  modifier keys allow events to go through
				e.stopImmediatePropagation();									//  block the input event from reaching the rest of the app
			}

		//--------------------------------------
		//  PRIVATE & PROTECTED STATIC FUNCTIONS
		//--------------------------------------

			private static function stopDragging():void{
				if(!_dragging) return;
				_dragging = false;
				if(!_activeObject) return;
				DELTA.x = DELTA.y = 0;
			}
			
			private static function select(displayObject:DisplayObject):void{
				if(_activeObject){
					if(_activeObject == displayObject) return;					//  clicked the active thing again...do nothing
					deselect();
				}
				
				if(displayObject is Stage){
					deselect();													//  no designTime on the stage itself
					return;
				}
				
				if(_console && (displayObject is _console || (displayObject.parent && displayObject.parent is _console))){
					deselect();												//  try not to select the Console or it's children
					return;
				}
				
				_activeObject = displayObject;
				_originalFilters = _activeObject.filters;						//  save the original filters
				ORIGINAL_POSITION.x = _activeObject.x;
				ORIGINAL_POSITION.y = _activeObject.y;

				if(_activeObject.name.indexOf('instance') == -1){
					_activeObjectName = _activeObject.name;						//  use the real name if it's provided
				} else {
					_activeObjectName = getQualifiedClassName(_activeObject);	//  otherwise grab the object type
					_activeObjectName = _activeObjectName.substr(_activeObjectName.lastIndexOf('::') + 2);
				}

				const a:Array = _activeObject.filters;							//  add a yellow stroke
				a.unshift(new GlowFilter(0xFFFF00, 1, 4, 4, 8, 1, true));
				_activeObject.filters = a;
			}
			
			private static function deselect():void{
				if(!_activeObject) return;
				if(_dragging) stopDragging();
				_activeObject.filters = _originalFilters;
				ORIGINAL_POSITION.x = ORIGINAL_POSITION.y = 0;
				DELTA.x = DELTA.y = 0;
				_activeObjectName = '';
			}
			
			/**
			 *  If the currently active object has siblings, select the next 
			 *  deepest peer object. (Index 0 wraps back to highest child)
			 */
			private static function selectNextPeer():void{
				if(!_activeObject) return selectFirstChild(); 					//  grab the top stage element if nothing is already active
				
				if(_activeObject.parent && _activeObject.parent.numChildren > 1){
					if(_activeObject.parent.getChildIndex(_activeObject) == 0){
						select(_activeObject.parent.getChildAt(_activeObject.parent.numChildren - 1));
					} else {
						select(_activeObject.parent.getChildAt(_activeObject.parent.getChildIndex(_activeObject) - 1));
					}
				}
			}

			/**
			 *  If the currently active object has children, select the
			 *  frontmost child object.
			 */
			private static function selectFirstChild():void{
				if(!_activeObject){
					if(!_stageInstance || _stageInstance.numChildren < 1) return;
					//  if there is nothing already selected - just grab the frontmost stage element
					return select(_stageInstance.getChildAt(_stageInstance.numChildren - 1));
				}

				if(_activeObject && _activeObject is DisplayObjectContainer){
					if(DisplayObjectContainer(_activeObject).numChildren){
						select(DisplayObjectContainer(_activeObject).getChildAt(DisplayObjectContainer(_activeObject).numChildren - 1));
					}
				}
			}
			
			/**
			 *  If the currently active object is not the stage, select it's
			 *  parent DisplayObjectContainer instead.
			 */
			private static function selectParent():void{
				if(!_activeObject){
					if(!_stageInstance || _stageInstance.numChildren < 1) return;
					//  if there is nothing already selected - just grab the frontmost stage element
					return select(_stageInstance.getChildAt(_stageInstance.numChildren - 1));
				}
				
				if(_activeObject && _activeObject.parent && !_activeObject.parent is Stage){
					select(_activeObject.parent);
				}
			}
			
			/**
			 *  This is a lot of fancy logic to make sure we can still call 
			 *  Console.inject when it's wanted, but if it's not wanted, we 
			 *  can avoid importing the Console class.
			 */
			private static function injectToConsole(key:String, ...arguments):void{
				if(!_console || _consoleInject == null){
					trace.call(null, [key].concat(arguments));					//  if we don't have a console to write to - use normal trace
					return;
				}

				_consoleInject.call(null, [key].concat(arguments));
			}

		//--------------------------------------
		//  PUBLIC INSTANCE METHODS
		//--------------------------------------

		//--------------------------------------
		//  PRIVATE CALLBACKS & EVENT HANDLERS
		//--------------------------------------

		//--------------------------------------
		//  PRIVATE & PROTECTED INSTANCE METHODS
		//--------------------------------------

	}
}