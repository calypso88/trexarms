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
	//  PACKAGE DEPENDENCIES
	//-------------------------------------

		import flash.display.Stage;

	/**
	 *  Static utility to consolidate references to the stage.
	 * 
	 *  @author Rob Sampson
	 *  @langversion ActionScript 3.0
	 *  @playerversion Flash 10.0
	 */
	public final class StageManager {

		//--------------------------------------
		// EMBEDDED ASSETS
		//--------------------------------------

		//--------------------------------------
		//  PUBLIC STATIC CONSTANTS
		//--------------------------------------

			public static const VERSION:String = '0.0.3';

		//--------------------------------------
		//  PRIVATE STATIC CONSTANTS
		//--------------------------------------

		//--------------------------------------
		//  PUBLIC CONSTANTS
		//--------------------------------------

		//--------------------------------------
		//  PRIVATE CONSTANTS
		//--------------------------------------

		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------
	
			/**  Constructor */
			public function StageManager(){}

		//--------------------------------------
		//  PUBLIC STATIC VARIABLES
		//--------------------------------------

		//--------------------------------------
		//  PRIVATE STATIC VARIABLES
		//--------------------------------------

			private static var _initialized:Boolean;

			private static var _stage:Stage;

		//--------------------------------------
		//  PUBLIC VARIABLES
		//--------------------------------------

		//--------------------------------------
		//  PRIVATE VARIABLES
		//--------------------------------------

		//--------------------------------------
		//  STATIC ACCESSORS
		//--------------------------------------

			public static function get align():String{
				return (_stage) ? _stage.align : '';
			}
			
			public static function set align(value:String):void{
				if(_stage) _stage.align = value;
			}
			
			public static function get colorCorrection():String{
				return (_stage && 'colorCorrection' in _stage) ? _stage['colorCorrection'] : 'default';
			}
			
			public static function set colorCorrection(value:String):void{
				if(_stage && 'colorCorrection' in _stage) _stage['colorCorrection'] = value;
			}
			
			public static function get colorCorrectionSupport():String{
				return (_stage && 'colorCorrectionSupport' in _stage) ? _stage['colorCorrectionSupport'] : 'unsupported';
			}
			
			public static function get displayState():String{
				return (_stage) ? _stage.displayState : '';
			}
			
			public static function set displayState(value:String):void{
				if(_stage) _stage.displayState = value;
			}
			
			public static function get focus():InteractiveObject{
				return (_stage) ? _stage.focus : null;
			}
			
			public static function set focus(value:InteractiveObject):void{
				if(_stage) _stage.focus = value;
			}
			
			public static function get frameRate():Number{
				return (_stage) ? _stage.frameRate : 0;
			}
			
			public static function set frameRate(value:Number):void{
				if(_stage) _stage.frameRate = value;
			}

			public static function get fullScreenHeight():Number{
				return (_stage) ? _stage.fullScreenHeight : 0;
			}

			public static function get fullScreenSourceRect():Rectangle{
				return (_stage) ? _stage.fullScreenSourceRect : null;
			}
			
			public static function set fullScreenSourceRect(value:Rectangle):void{
				if(_stage) _stage.fullScreenSourceRect = value;
			}

			public static function get fullScreenWidth():Number{
				return (_stage) ? _stage.fullScreenWidth : 0;
			}

			public static function get height():Number{
				return (_stage) ? _stage.height : 0;
			}
			
			public static function set height(value:Number):void{
				if(_stage) _stage.height = value;
			}

			public static function get loaderInfo():LoaderInfo{
				return (_stage) ? _stage.loaderInfo : null;
			}

			public static function get mouseChildren():Boolean{
				return (_stage) ? _stage.mouseChildren : false;
			}

			public static function set mouseChildren(value:Boolean):void{
				if(_stage) _stage.mouseChildren = value;
			}

			public static function get numChildren():Number{
				return (_stage) ? _stage.numChildren : 0;
			}

			public static function get quality():String{
				return (_stage) ? _stage.quality : '';
			}
			
			public static function set quality(value:String):void{
				if(_stage) _stage.quality = value;
			}
			
			public static function get scaleMode():String{
				return (_stage) ? _stage.scaleMode : '';
			}
			
			public static function set scaleMode(value:String):void{
				if(_stage) _stage.scaleMode = value;
			}

			public static function get showDefaultContextMenu():Boolean{
				return (_stage) ? _stage.showDefaultContextMenu : true;
			}
			
			public static function set showDefaultContextMenu(value:Boolean):void{
				if(_stage) _stage.showDefaultContextMenu = value;
			}

			public static function get stageFocusRect():Rectangle{
				return (_stage) ? _stage.stageFocusRect : null;
			}
			
			public static function set stageFocusRect(value:Rectangle):void{
				if(_stage) _stage.stageFocusRect = value;
			}

			public static function get stageHeight():int{
				return (_stage) ? _stage.stageHeight : null;
			}
			
			public static function set stageHeight(value:int):void{
				if(_stage) _stage.stageHeight = value;
			}

			public static function get stageWidth():int{
				return (_stage) ? _stage.stageWidth : null;
			}
			
			public static function set stageWidth(value:int):void{
				if(_stage) _stage.stageWidth = value;
			}

			public static function get tabChildren():Boolean{
				return (_stage) ? _stage.tabChildren : true;
			}
			
			public static function set tabChildren(value:int):Boolean{
				if(_stage) _stage.tabChildren = value;
			}

			public static function get width():Number{
				return (_stage) ? _stage.width : 0;
			}
			
			public static function set width(value:Number):void{
				if(_stage) _stage.width = value;
			}

			public static function get wmodeGPU():Boolean{
				if(_stage && 'wmodeGPU' in _stage) return _stage['wmodeGPU'];
				return false;
			}

			public static function get initialized():Boolean{
				return _initialized;
			}
			
			public static function get stage():Stage{
				return _stage;
			}
			
//			public static function get width():int{
//				if(_stage) return _stage.stageWidth;
//				return 0;
//			}
			
//			public static function get height():int{
//				if(_stage) return _stage.stageHeight;
//				return 0;
//			}

		//--------------------------------------
		//  ACCESSORS
		//--------------------------------------

		//--------------------------------------
		//  PUBLIC STATIC FUNCTIONS
		//--------------------------------------

			public static function initialize(stage:Stage, align:String = null, scaleMode:String = null):void{
				if(stage != _stage){
					_stage = stage;
					if(align) _stage.align = align;
					if(scaleMode) _stage.scaleMode = scaleMode;
					_initialized = true;
					//  would be nice to catch stage events and re-dispatch or pipe into StateManager here...
				}
			}
			
			public static function addChild(child:DisplayObject):DisplayObject{
				return (_stage) ? _stage.addChild(child) : child;
			}
			
			public static function addChildAt(child:DisplayObject, index:ind):DisplayObject{
				return (_stage) ? _stage.addChildAt(child, index) : child;
			}

			public static function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void{
				if(_stage){
					EVENTS_BEING_LISTENED_TO.push(type);
					EVENT_LISTENER_CALLBACKS.push(listener);
					EVENT_LISTENER_CAPTURE.push(useCapture);
					_stage.addEventListener(type, listener, useCapture, priority, useWeakReference);
				}
			}

			/**
			 *  Removes an event listener from the stage. This will work 
			 *  on eventListeners added directly to the stage object, outside
			 *  of StageManager.
			 */
			public static function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void{
				if(!_stage) return;

				var i:int = EVENTS_BEING_LISTENED_TO.length;
				while(i--){
					if(EVENTS_BEING_LISTENED_TO[i] == type && EVENT_LISTENER_CALLBACKS[i] === listener && EVENT_LISTENER_CAPTURE[i] == useCapture){
						EVENTS_BEING_LISTENED_TO.splice(i, 1);
						EVENT_LISTENER_CALLBACKS.splice(i, 1);
						EVENT_LISTENER_CAPTURE.splice(i, 1);
					}
				}

				_stage.removeEventListener(type, listener, useCapture);
			}

			/**
			 *  Removes all event listeners for a given event type.
			 *  
			 *  WARNING: This only works for listeners added through
			 *  StageManager - not directly on the Stage object.
			 */
			public static function removeAllEventListenersOfType(type:String = ''):void{
				var i:int = EVENTS_BEING_LISTENED_TO.length;
				while(i--){
					if(EVENTS_BEING_LISTENED_TO[i] == type){
						_stage.removeEventListener(EVENTS_BEING_LISTENED_TO[i], EVENT_LISTENER_CALLBACKS[i], EVENT_LISTENER_CAPTURE[i]);
						EVENTS_BEING_LISTENED_TO.splice(i, 1);
						EVENT_LISTENER_CALLBACKS.splice(i, 1);
						EVENT_LISTENER_CAPTURE.splice(i, 1);
					}
				}
			}

			/**
			 *  Removes all events listeners attached to the stage. 
			 *  
			 *  WARNING: This only works for listeners added through
			 *  StageManager - not directly on the Stage object.
			 */
			public static function removeAllEventListeners():void{
				var i:int = EVENTS_BEING_LISTENED_TO.length;
				while(i--){
					_stage.removeEventListener(EVENTS_BEING_LISTENED_TO[i], EVENT_LISTENER_CALLBACKS[i], EVENT_LISTENER_CAPTURE[i]);
				}

				EVENTS_BEING_LISTENED_TO.length = 0;
				EVENT_LISTENER_CALLBACKS.length = 0;
				EVENT_LISTENER_CAPTURE.length = 0;
			}

			public static function dispatchEvent(event:Event):Boolean{
				return (_stage) ? _stage.dispatchEvent(event) : false;
			}
			
			public static function hasEventListener(type:String):Boolean{
				return (_stage) ? _stage.hasEventListener(type) : false;
			}

			public static function invalidate():void{
				if(_stage) _stage.invalidate();
			}
			
			public static function isFocusInaccessible():Boolean{
				return (_stage) ? _stage.isFocusInaccessible() : true;
			}

			public static function removeChildAt(index:int):DisplayObject{
				return (_stage) ? _stage.removeChildAt(index) : null;
			}
			
			public static function setChildIndex(child:DisplayObject, index:int):void{
				if(_stage) _stage.setChildIndex(child, index);
			}
			
			public static function swapChildrenAt(index1:int, index2:int):void{
				if(_stage) _stage.swapChildrenAt(index1, index2);
			}
			
			public static function willTrigger(type:String):Boolean{
				return (_stage) ? _stage.willTrigger(type) : false;
			}

		//--------------------------------------
		//  PRIVATE STATIC CALLBACKS & HANDLERS
		//--------------------------------------

		//--------------------------------------
		//  PRIVATE & PROTECTED STATIC FUNCTIONS
		//--------------------------------------

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