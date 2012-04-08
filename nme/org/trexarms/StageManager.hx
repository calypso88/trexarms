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

		import nme.display.Stage;
		import nme.events.Event;
		import nme.display.StageScaleMode;
		import nme.display.StageAlign;

	/**
	 *  @author Rob Sampson
	 *  @langversion HaXe 2
	 *  
	 *  Utility class for holding a copy of the Stage statically and making
	 *  general logic about the stage easily accessible across the application.
	 */
	class StageManager {

		//--------------------------------------
		// EMBEDDED ASSETS
		//--------------------------------------

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

			//  reference to our Stage object
			private static var _stage:Stage;

		//--------------------------------------
		//  PUBLIC VARIABLES
		//--------------------------------------

			public static var stage(getStage, setStage):Stage;
			public static var width(getWidth, null):Int;
			public static var height(getHeight, null):Int;
			
			public static var iPhone(getIsIphone, null):Bool;
			public static var iPhoneRetina(getIsIphoneRetina, null):Bool;
			
			public static var iPad(getIsIpad, null):Bool;
			public static var iPadRetina(getIsIpadRetina, null):Bool;

		//--------------------------------------
		//  PRIVATE VARIABLES
		//--------------------------------------

			private static var _width:Int;
			private static var _height:Int;

			private static var _landscape:Bool;

			private static var _isIphone:Bool;
			private static var _isIphoneRetina:Bool;
			private static var _isIpad:Bool;
			private static var _isIpadRetina:Bool;

		//--------------------------------------
		//  STATIC ACCESSORS
		//--------------------------------------

		//--------------------------------------
		//  ACCESSORS
		//--------------------------------------

			public static function getStage():Stage{
				return _stage;
			}
			
			public static function setStage(value:Stage):Stage{
				_stage = value;
				return _stage;
			}
			
			public static function getWidth():Int{
				if(_stage != Void) return _stage.stageWidth;
				return 0;
			}
			
			public static function getHeight():Int{
				if(_stage != Void) return _stage.stageHeight;
				return 0;
			}
			
			public static function getIsIphone():Bool{
				return _isIphone;
			}
			
			public static function getIsIphoneRetina():Bool{
				return _isIphoneRetina;
			}

			public static function getIsIpad():Bool{
				return _isIpad;
			}
			
			public static function getIsIpadRetina():Bool{
				return _isIpadRetina;
			}

		//--------------------------------------
		//  PUBLIC STATIC FUNCTIONS
		//--------------------------------------

			public static function initialize(stage:Stage):Void{
				_stage = stage;
				
				_stage.align = StageAlign.TOP_LEFT;
				_stage.scaleMode = StageScaleMode.NO_SCALE;

				updateScreenDetection();
				_stage.addEventListener(Event.RESIZE, updateScreenDetection);
//				_stage.addEventListener(FullScreenEvent.FULL_SCREEN, updateScreenDetection);
			}

		//--------------------------------------
		//  PRIVATE STATIC CALLBACKS & HANDLERS
		//--------------------------------------

			private static function updateScreenDetection(e:Event = null):Void{
				_width = _stage.stageWidth;
				_height = _stage.stageHeight;

				_landscape = (_width > height);

				if(_landscape && _width == 480 && _height == 320){
					_isIphone = true;
					_isIphoneRetina = false;
				}
				
				
				if(_landscape){
					if(_width == 480 && _height == 320){
						_isIphone = true;
						_isIphoneRetina = false;
						_isIpad = false;
						_isIpadRetina = false;
					} else if(_width == 960 && _height == 640){
						_isIphone = true;
						_isIphoneRetina = true;
						_isIpad = false;
						_isIpadRetina = false;
					} else if(_width == 1024 && _height == 768){
						_isIphone = false;
						_isIphoneRetina = false;
						_isIpad = true;
						_isIpadRetina = false;
					} else if(_width == 2048 && _height == 1536){
						_isIphone = false;
						_isIphoneRetina = false;
						_isIpad = true;
						_isIpadRetina = true;
					} else {
						_isIphone = false;
						_isIphoneRetina = false;
						_isIpad = false;
						_isIpadRetina = false;
					}
				} else {
					if(_height == 480 && _width == 320){
						_isIphone = true;
						_isIphoneRetina = false;
						_isIpad = false;
						_isIpadRetina = false;
					} else if(_height == 960 && _width == 640){
						_isIphone = true;
						_isIphoneRetina = true;
						_isIpad = false;
						_isIpadRetina = false;
					} else if(_height == 1024 && _width == 768){
						_isIphone = false;
						_isIphoneRetina = false;
						_isIpad = true;
						_isIpadRetina = false;
					} else if(_height == 2048 && _width == 1536){
						_isIphone = false;
						_isIphoneRetina = false;
						_isIpad = true;
						_isIpadRetina = true;
					} else {
						_isIphone = false;
						_isIphoneRetina = false;
						_isIpad = false;
						_isIpadRetina = false;
					}
				}
			}

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