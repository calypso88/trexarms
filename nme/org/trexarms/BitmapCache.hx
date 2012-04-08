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

		import nme.Assets;
		import nme.display.Bitmap;
		import nme.display.BitmapData;
		import nme.display.Sprite;

	/**
	 *  @author Rob Sampson
	 *  @langversion HaXe 2
	 */
	class BitmapCache {

		//--------------------------------------
		// EMBEDDED ASSETS
		//--------------------------------------

		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------
	
			/**  Constructor */
			public function new(){}

		//--------------------------------------
		//  PUBLIC STATIC VARIABLES
		//--------------------------------------

			public static var VERSION:String = '0.0.1';

		//--------------------------------------
		//  PRIVATE STATIC VARIABLES
		//--------------------------------------

			private static var BITMAPDATA_BY_PATH:Hash<BitmapData> = new Hash<BitmapData>();

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

			public static function getBitmapData(path:String):BitmapData{
				if(!BITMAPDATA_BY_PATH.exists(path)) BITMAPDATA_BY_PATH.set(path, Assets.getBitmapData(path));
				return BITMAPDATA_BY_PATH.get(path);
			}

			public static function getBitmap(path:String):Bitmap{
				if(!BITMAPDATA_BY_PATH.exists(path)) BITMAPDATA_BY_PATH.set(path, Assets.getBitmapData(path));
				return new Bitmap(BITMAPDATA_BY_PATH.get(path));
			}
			
			public static function getBitmapWrappedInSprite(path:String):Sprite{
				if(!BITMAPDATA_BY_PATH.exists(path)) BITMAPDATA_BY_PATH.set(path, Assets.getBitmapData(path));
				var b:Bitmap = new Bitmap(BITMAPDATA_BY_PATH.get(path));
				b.smoothing = true;
				var s:Sprite = new Sprite();
				s.addChild(b);
				return s;
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