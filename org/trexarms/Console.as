package org.trexarms {

	/**
	 *  Flash 10.0 ◆ Actionscript 3.0
	 *  Copyright ©2011 Rob Sampson | rob@hattv.com | www.calypso88.com
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
		import flash.events.FullScreenEvent;
		import flash.events.KeyboardEvent;
		import flash.events.TextEvent;
		import flash.net.navigateToURL;
		import flash.net.URLRequest;
		import flash.system.Capabilities;
		import flash.system.Security;
		import flash.system.SecurityPanel;
		import flash.system.System;
		import flash.text.StyleSheet;
		import flash.text.TextField;
		import flash.text.TextFieldType;
		import flash.text.TextFormat;
		import flash.ui.Keyboard;
		import flash.utils.Dictionary;
		import flash.utils.getTimer;
		
	/**
	 *  Console utility for reading log messages inside a swf.
	 * 
	 *  @author Rob Sampson
	 */
	public final class Console extends Sprite {

		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
			
			/**  This is the main body of the console */
			private const TEXTFIELD:TextField = new TextField();
			
			/**  This is the command-entry line */
			private const INPUT:TextField = new TextField();
			
			/**  This is the readout of what filter is in effect */
			private const FILTER_LABEL:TextField = new TextField();

			/**  Reverse mappings to find the category and text on a given line */
			private const CATEGORY_BY_LINE_NUMBER:Vector.<String> = new Vector.<String>();
			private const HTML_TEXT_BY_LINE_NUMBER:Vector.<String> = new Vector.<String>();

		//--------------------------------------
		// STATIC PROPERTIES
		//--------------------------------------

			/**  @private */
			public static const VERSION:String = '0.0.1';

			/**  Keyboad key that opens and closes the console - default is ` */
			private static const ACTIVATION_KEY:uint = Keyboard.BACKQUOTE;

			/**  Singleton holder */
			private static const INSTANCE:Console = new Console();

			/**  Graphic attributes of the Console background fill */
			private static const BACKGROUND_COLOR:uint = 0x0D152A;
			private static const BACKGROUND_ALPHA:Number = 1;

			/**  Styling objects */
			private static const LINE_NUMBER_STYLE:Object = 		{color:"#4F5E82", fontWeight:"normal", fontStyle:"normal"};
			private static const BODY_STYLE:Object = 				{color:"#F8F8F8", fontWeight:"normal", fontStyle:"normal"};
			private static const WARNING_STYLE:Object = 			{color:"#FBDE2D", fontWeight:"normal", fontStyle:"normal"};
			private static const ERROR_STYLE:Object = 				{color:"#FF6400", fontWeight:"normal", fontStyle:"normal"};
			private static const COMMENT_STYLE:Object = 			{color:"#666666", fontWeight:"normal", fontStyle:"italic"};
			private static const COMMAND_STYLE:Object = 			{color:"#666666", fontWeight:"normal", fontStyle:"italic"};
			private static const LINK_STYLE:Object =				{color:"#8DA6CE", fontWeight:"normal", fontStyle:"normal"};
			private static const HOVER_STYLE:Object =				{color:"#FFFFFF", fontWeight:"normal", fontStyle:"normal"};
			private static const X_BUTTON_STYLE:Object = 			{color:"#C23A2B", fontWeight:"bold", fontStyle:"normal"};
			private static const FILTER_LABEL_STYLE:Object = 		{color:"#5ED363", fontWeight:"normal", fontStyle:"italic"};
			private static const KILL_FILTER_LABEL_STYLE:Object =	{color:"#FF6400", fontWeight:"normal", fontStyle:"normal"};
//			private static const INPUT_COLOR:uint = 0x6b7E9C;
			private static const INPUT_COLOR:uint = 0xDDDDDD;

			/**  Padding around the main textfield for text entry and controls */
			private static const HEADER_HEIGHT:int = 40;
			private static const FOOTER_HEIGHT:int = 28;
			private static const LEFT_PADDING:int = 5;
			private static const RIGHT_PADDING:int = 5;

			/**  Set this true to see line numbering in the Console */
			private static const LINE_NUMBERS_ENABLED:Boolean = true;
			
			/**  Set this true to see the calling Class for each line */
			private static const CATEGORIES_ENABLED:Boolean = true;

			/**  Number of lines visible in the console - this is essentially "height" */
			private static const LINES_OF_TEXT:int = 20;
			
			/**  Graphic attributes of the typeface */
			private static const LINE_HEIGHT_IN_PX:int = 16;
			private static const TYPEFACE:String = '_typewriter';
			private static const TYPESIZE:Number = 11.5;
			
			/**  Special tag to suppress the category for a line - this is used for command entry and special formatting */
			private static const CALLSTACK_BYPASS:String = '!bypass¡';
			
			/**  When true, all messages into the Console are also passed into standard trace() */
			private static const TRACE_ALL_MESSAGES:Boolean = true;

			/**  Collection of our console commands */
			private static var COMMANDS:Vector.<ConsoleCommand>;
			private static const COMMAND_BY_NAME:Dictionary = new Dictionary();
			
			/**  This is a record of everything that goes into the console via the input string */
			private static const SAVED_COMMANDS:Vector.<String> = new Vector.<String>();
			private static var savedCommandIndex:int = -1;
			private static var onDeckCommand:String = '';

			/**  If true, the console should operate as minimally as possible */
			private static var disabled:Boolean;
			
			/**  If true, logging calls will be forwarded to the trace() function when the Console is disabled */
			private static var traceWhileDisabled:Boolean;
			
		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------
	
			/**  @private */
			public function Console(){
				super();
				if(instance) throw new Error('[T-Rex Arms]: More than one Console allocated.');
				
				visible = false;												//  make sure we're invisible until activated

				addEventListener(Event.ADDED_TO_STAGE, addedToStage);
				addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
				addEventListener(Event.ADDED_TO_STAGE, setupStageListeners);
				addEventListener(Event.ADDED_TO_STAGE, buildUI);
			}

		//--------------------------------------
		//  PUBLIC VARIABLES
		//--------------------------------------

		//--------------------------------------
		//  PRIVATE VARIABLES
		//--------------------------------------

			/**  Keeping track of what size stage we're supposed to fit within */
			private var lastRecordedStageWidth:int;
			
			/**  This is a giant String with everything that's ever been logged */
			private var clipboardLog:String = '';

			/**
			 *  This is similar to the clipboardLog but contains styling and
			 *  may change contents depending on what's currently visible.
			 */
			private var displayLog:String = '';
			
			/**  If true, the console is visible to the user */
			private var active:Boolean;
			
			/**  Whether we're in the display tree or not */
			private var onstage:Boolean;
			
			/**  The last-written line in the Console */
			private var currentLineNumber:int = 0;
			
			/**  State of category filtering */
			private var filterActive:Boolean;
			private var currentFilter:String;
			
			
		//--------------------------------------
		//  ACCESSORS
		//--------------------------------------

			/** Returns the singleton instance - should only be used for adding to stage. */
			public static function get instance():Console{
				return INSTANCE;
			}

		//--------------------------------------
		//  PUBLIC METHODS
		//--------------------------------------
		
			/**
			 *  Empties stored data and turns off the Console. Any calls to 
			 *  logging functions after the Console is disabled will return
			 *  immediately. This should be used when deploying release builds.
			 * 
			 *  @param traceMessagesWhileDisabled If true, disabled logging calls will be passed to the trace() function.
			 */
			public static function disable(traceMessagesWhileDisabled:Boolean = true):void{
				disabled = true;
				traceWhileDisabled = traceMessagesWhileDisabled;
				instance.destroy();
			}

			/**
			 *  Writes the arguments passed in to the Console. For any
			 *  argument that is not type String, this function will try
			 *  to call the toString() method, failing that, it will cast
			 *  the object to a String manually.
			 * 
			 *  @param arguments One or more expressions to evaluate.
			 */
			public static function log(...arguments):void{
				if(disabled){													//  early out for globally disabling the Console
					if(traceWhileDisabled) trace.call(null, arguments);
					return;
				}

				var s:String = '';
				for(var i:int = 0; i < arguments.length; ++i){
					if(arguments[i] is String){
						s += arguments[i] + ' ';
					} else if('toString' in arguments[i] && arguments[i]['toString'] is Function){
						s += arguments[i].toString() + ' ';
					} else {
						s += String(arguments[i]) + ' ';
					}
				}
				
				instance.writeLine(s, BODY_STYLE, new Error().getStackTrace());
			}

			/**
			 *  Writes the arguments passed in to the Console. For any
			 *  argument that is not type String, this function will try
			 *  to call the toString() method, failing that, it will cast
			 *  the object to a String manually.
			 * 
			 *  @param arguments One or more expressions to evaluate.
			 */
			public static function warn(...arguments):void{
				if(disabled){													//  early out for globally disabling the Console
					if(traceWhileDisabled) trace.call(null, arguments);
					return;
				}

				var s:String = '';
				for(var i:int = 0; i < arguments.length; ++i){
					if(arguments[i] is String){
						s += arguments[i] + ' ';
					} else if('toString' in arguments[i] && arguments[i]['toString'] is Function){
						s += arguments[i].toString() + ' ';
					} else {
						s += String(arguments[i]) + ' ';
					}
				}
				
				instance.writeLine(s, WARNING_STYLE, new Error().getStackTrace());
			}

			/**
			 *  Writes the arguments passed in to the Console. For any
			 *  argument that is not type String, this function will try
			 *  to call the toString() method, failing that, it will cast
			 *  the object to a String manually.
			 * 
			 *  @param arguments One or more expressions to evaluate.
			 */
			public static function error(...arguments):void{
				if(disabled){													//  early out for globally disabling the Console
					if(traceWhileDisabled) trace.call(null, arguments);
					return;
				}

				var s:String = '';
				for(var i:int = 0; i < arguments.length; ++i){
					if(arguments[i] is String){
						s += arguments[i] + ' ';
					} else if('toString' in arguments[i] && arguments[i]['toString'] is Function){
						s += arguments[i].toString() + ' ';
					} else {
						s += String(arguments[i]) + ' ';
					}
				}
				
				instance.writeLine(s, ERROR_STYLE, new Error().getStackTrace());
			}
			
			/**
			 *  Writes the arguments passed in to the Console. For any
			 *  argument that is not type String, this function will try
			 *  to call the toString() method, failing that, it will cast
			 *  the object to a String manually.
			 * 
			 *  @param arguments One or more expressions to evaluate.
			 */
			public static function comment(...arguments):void{
				if(disabled){													//  early out for globally disabling the Console
					if(traceWhileDisabled) trace.call(null, arguments);
					return;
				}

				var s:String = '';
				for(var i:int = 0; i < arguments.length; ++i){
					if(arguments[i] is String){
						s += arguments[i] + ' ';
					} else if('toString' in arguments[i] && arguments[i]['toString'] is Function){
						s += arguments[i].toString() + ' ';
					} else {
						s += String(arguments[i]) + ' ';
					}
				}
				
				instance.writeLine(s, COMMENT_STYLE, new Error().getStackTrace());
			}
			
			/**
			 *  This function maps the commandName to the function passed in.
			 *  When the commandName is entered, the corresponding function
			 *  will be executed.
			 *
			 *  @param commandName The value to enter in the Console to trigger the command.
			 *  @param action The function to be triggered.
			 *  @param description A brief explanation of the command.
			 */
			public static function registerCommand(commandName:String, action:Function, description:String = ''):void{
				if(COMMAND_BY_NAME[commandName]){
					if(disabled) return;
					instance.writeLine('Unable to register command "' + commandName + '": This command already exists.', ERROR_STYLE, new Error().getStackTrace());
					return;
				}

				COMMAND_BY_NAME[commandName] = new ConsoleCommand(commandName, action, description);
				if(!COMMANDS) COMMANDS = new Vector.<ConsoleCommand>();
				COMMANDS.push(COMMAND_BY_NAME[commandName]);

				//  alphabetize the commands
				COMMANDS.sort(function(a:ConsoleCommand, b:ConsoleCommand):Number{
					if(a.command < b.command) return -1;
					if(a.command == b.command) return 0;
					return 1;
				});
			}

			/**
			 *  @private
			 *
			 *  Removes the Console from view. While hidden, it will continue
			 *  to receive logging messages. The Console can be quickly opened
			 *  and closed using the ` (backquote) key.
			 */
			public function hideConsole():void{
				if(active){
					active = false;
					visible = false;
					filterActive = false;
					FILTER_LABEL.htmlText = '<a href="event:closeConsole">[Hide Console]</a> ';
					if(stage) stage.focus = null;
				}
			}
			
			/**
			 *  @private
			 *
			 *  Shows the conole. The Console can be quickly opened and closed
			 *  using the ` (backquote) key.
			 */
			public function showConsole():void{
				active = true;
				TEXTFIELD.htmlText = displayLog;
				TEXTFIELD.scrollV = TEXTFIELD.maxScrollV;
				visible = true;
				INPUT.text = '';
			}
			
			/**
			 *  @private
			 * 
			 *  This function formats and writes a line of text into the
			 *  Console stream, as well as indexing it's category and mapping
			 *  it for lookup later.
			 *
			 *  THIS FUNCTION SHOULD ONLY BE CALLED BY THE STATIC CLASS METHODS!
			 *
			 *  @param s The raw message to add to the console
			 *  @param style The style object to correspond with the StyleSheet
			 *  @param callStack An Error stack containing the Class that logged this line of text.
			 */
			public function writeLine(s:String, style:Object, callStack:String):void{
				clipboardLog += s + '\n';										//  add the raw text into the master string - this is what goes to the clipboard on a copy-all
				if(TRACE_ALL_MESSAGES) trace(s);

				var line:String = (LINE_NUMBERS_ENABLED) ? formattedLineNumber(++currentLineNumber) : '';

				if(CATEGORIES_ENABLED){
					if(callStack == CALLSTACK_BYPASS){
						CATEGORY_BY_LINE_NUMBER.push('');						//  if we skip a line - make sure our two lookups are still in sync
					} else {
						line += mapLineToCategory(callStack) + ' ';				//  if categories are on - prepend the name of the calling class
					}
				}

				switch(style){
					case BODY_STYLE:
						line += '<span class="body">' + s + '</span>' + '\n';
						break;
					case COMMENT_STYLE:
						line += '<span class="comment">' + s + '</span>' + '\n';
						break;
					case ERROR_STYLE:
						line += '<span class="error">' + s + '</span>' + '\n';
						break;
					case WARNING_STYLE:
						line += '<span class="warning">' + s + '</span>' + '\n';
						break;
					case COMMAND_STYLE:
						//  commands should always use the callstack bypass - so this may need indentation to match
						line += '<span class="command">' + (CATEGORIES_ENABLED ? '           ' : '') + '❚ ' + s + '</span>' + '\n';
						break;
					default:
						line += '<span class="body">' + s + '</span>' + '\n';
						break;
				}

				//  add the text to our lookup vector - this matches the category lookup made in mapLineToCategory
				HTML_TEXT_BY_LINE_NUMBER.push(line);
				
				displayLog += line;												//  TODO: This is where we need to put in virtualization

				if(active){
					if(filterActive){
						if(currentFilter == CATEGORY_BY_LINE_NUMBER[CATEGORY_BY_LINE_NUMBER.length - 1]){
							//  if we're using filtering - only add lines that come from the active filter...otherwise these just get logged.
							TEXTFIELD.htmlText = displayLog;
							TEXTFIELD.scrollV = TEXTFIELD.maxScrollV;
						}
					} else {
						TEXTFIELD.htmlText = displayLog;
						TEXTFIELD.scrollV = TEXTFIELD.maxScrollV;
					}
				}
			}

			/**
			 *  @private
			 *
			 *  Reduces the singleton object to the smallest possible memory
			 *  and cpu footprint.
			 */
			public function destroy():void{
				try{
					if(hasEventListener(Event.ADDED_TO_STAGE)) removeEventListener(Event.ADDED_TO_STAGE, setupStageListeners);
				} catch(err:Error){}

				try{
					if(hasEventListener(Event.ADDED_TO_STAGE)) removeEventListener(Event.ADDED_TO_STAGE, buildUI);
				} catch(err:Error){}

				try{
					if(stage && stage.hasEventListener(KeyboardEvent.KEY_UP)) stage.removeEventListener(KeyboardEvent.KEY_UP, keyUp);
				} catch(err:Error){}
				
				try{
					if(stage && stage.hasEventListener(KeyboardEvent.KEY_DOWN)) stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
				} catch(err:Error){}

				try{
					if(stage && stage.hasEventListener(Event.RESIZE)) stage.removeEventListener(Event.RESIZE, buildUI);
				} catch(err:Error){}

				try{
					if(stage && stage.hasEventListener(FullScreenEvent.FULL_SCREEN)) stage.removeEventListener(FullScreenEvent.FULL_SCREEN, buildUI);
				} catch(err:Error){}
				
				try{
					if(hasEventListener(Event.ADDED_TO_STAGE)) removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
				} catch(err:Error){}
				
				try{
					if(hasEventListener(Event.REMOVED_FROM_STAGE)) removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
				} catch(err:Error){}
				
				try{
					if(TEXTFIELD.hasEventListener(TextEvent.LINK)) TEXTFIELD.removeEventListener(TextEvent.LINK, changeFilter);
				} catch(err:Error){}
				
				try{
					if(FILTER_LABEL.hasEventListener(TextEvent.LINK)) FILTER_LABEL.removeEventListener(TextEvent.LINK, headerClicked);
				} catch(err:Error){}
				
				while(numChildren) removeChildAt(0);
				if(parent) parent.removeChild(this);
				CATEGORY_BY_LINE_NUMBER.length = 0;
				HTML_TEXT_BY_LINE_NUMBER.length = 0;
				TEXTFIELD.htmlText = '';
				INPUT.htmlText = '';
				FILTER_LABEL.htmlText = '';
			}

		//--------------------------------------
		//  CALLBACKS & EVENT HANDLERS
		//--------------------------------------

			/**  Adds event listeners to the stage for keyboard and resize events */
			private function setupStageListeners(e:Event):void{
				removeEventListener(e.type, setupStageListeners);
				stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
				stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
				stage.addEventListener(Event.RESIZE, buildUI);
				stage.addEventListener(FullScreenEvent.FULL_SCREEN, buildUI);

				registerDefaultCommands();
				//  TODO: add scroll wheel support
			}
			
			/**  This gets called every time we detect a change in stage dimensions */
			private function buildUI(e:Event):void{
				if(stage.stageWidth == lastRecordedStageWidth) return;

				lastRecordedStageWidth = (stage.stageWidth > 200) ? stage.stageWidth : 200  //  make sure we don't go too small

				INPUT.width = TEXTFIELD.width = lastRecordedStageWidth - (LEFT_PADDING + RIGHT_PADDING);
				INPUT.x = TEXTFIELD.x = LEFT_PADDING;
				TEXTFIELD.y = HEADER_HEIGHT;
				TEXTFIELD.height = LINE_HEIGHT_IN_PX * LINES_OF_TEXT;
				INPUT.y = HEADER_HEIGHT + (LINE_HEIGHT_IN_PX * LINES_OF_TEXT) + 4;
				INPUT.height = 1 * LINE_HEIGHT_IN_PX + 6;

				addChild(TEXTFIELD);
				addChild(INPUT);
				addChild(FILTER_LABEL);
				
				graphics.clear();
				graphics.beginFill(BACKGROUND_COLOR, BACKGROUND_ALPHA);
				graphics.drawRect(0, 0, stage.stageWidth, HEADER_HEIGHT + (LINE_HEIGHT_IN_PX * LINES_OF_TEXT) + FOOTER_HEIGHT);
				graphics.lineStyle(0, INPUT_COLOR, .5);
				graphics.drawRect(INPUT.x - 1, INPUT.y - 1, INPUT.width + 1, LINE_HEIGHT_IN_PX + 5);

				FILTER_LABEL.x = LEFT_PADDING;
				FILTER_LABEL.y = 6;
				FILTER_LABEL.width = lastRecordedStageWidth - (LEFT_PADDING + RIGHT_PADDING);
				FILTER_LABEL.height = 1 * LINE_HEIGHT_IN_PX + 6;

				if(BACKGROUND_ALPHA == 1){										//  if Alpha is all the way up we can make use of some nice rendering boosts
					opaqueBackground = BACKGROUND_COLOR;
					TEXTFIELD.opaqueBackground = BACKGROUND_COLOR;
					FILTER_LABEL.opaqueBackground = BACKGROUND_COLOR;
				}
				
				if(INPUT.type != TextFieldType.INPUT) buildTextFields();		//  setup the textfields on the first pass through
			}
			
			/**  Keeping track of when we're in the display tree */
			private function addedToStage(e:Event):void{
				onstage = true;
			}
			
			/**  Keeping track of when we're in the display tree */
			private function removedFromStage(e:Event):void{
				onstage = false;
			}

			/**  Processes key-presses. */
			private function keyDown(e:KeyboardEvent):void{
				if(!parent || !stage) return;
				switch(e.keyCode){
					case ACTIVATION_KEY:
						(active) ? hideConsole() : showConsole();
						break;
					case Keyboard.C:
						if(e.shiftKey && e.ctrlKey) System.setClipboard(clipboardLog);
						break;
					case Keyboard.ENTER:
					case Keyboard.NUMPAD_ENTER:
						if(stage && stage.focus == INPUT) processTextInput();
						break;
					case Keyboard.DOWN:
						stepDownThroughCommands();
						break;
					case Keyboard.UP:
						stepUpThroughCommands();
						break;
					case Keyboard.TAB:
						autoCompleteInput();
						break;
					default:
						if(active && stage && !e.ctrlKey) stage.focus = INPUT;	//  if we're typing - make sure we're in the input field
						break;
				}
				
				//  TODO: add more macros here
				//  		page up
				//			page down
				//			tabbed browsing (?)				
			}
			
			/**  Process key-releases. */
			private function keyUp(e:KeyboardEvent):void{
				if(e.keyCode == ACTIVATION_KEY && onstage && stage){
					stage.focus = INPUT;										//  console just opened in keyDown...
					INPUT.text = '';
				}
				
				if(e.keyCode == Keyboard.UP || e.keyCode == Keyboard.TAB){
					INPUT.setSelection(INPUT.length, INPUT.length);				//  move the caret to the end...
				}
				
				
			}
			
			/**  When a category is clicked - filter to show only logs from that class */
			private function textLinkClicked(e:TextEvent):void{
				if(!filterActive || currentFilter != e.text){
					changeFilter(e.text);
				}
			}
			
			private function headerClicked(e:TextEvent):void{
				if(e.text == 'closeConsole'){
					hideConsole();
					return;
				}
				
				if(e.text == 'removeFilter'){
					unFilter();
					return;
				}
			}

		//--------------------------------------
		//  PRIVATE & PROTECTED INSTANCE METHODS
		//--------------------------------------

			/**
			 *  Create the text styling.
			 */
			private function buildTextFields():void{
				var s:StyleSheet = new StyleSheet();
				
				s.setStyle('.lineNumber', LINE_NUMBER_STYLE);
				s.setStyle('.body', BODY_STYLE);
				s.setStyle('.warning', WARNING_STYLE);
				s.setStyle('.error', ERROR_STYLE);
				s.setStyle('.comment', COMMENT_STYLE);
				s.setStyle('.command', COMMAND_STYLE);
				s.setStyle('a:link', LINK_STYLE);								//  the <a> tags are the Category links...
				s.setStyle('a:hover', HOVER_STYLE);
				s.setStyle('a:active', HOVER_STYLE);
				
				TEXTFIELD.defaultTextFormat = new TextFormat(TYPEFACE, TYPESIZE, BODY_STYLE.color);
				TEXTFIELD.styleSheet = s;
				TEXTFIELD.selectable = true;
				TEXTFIELD.addEventListener(TextEvent.LINK, textLinkClicked);

				INPUT.defaultTextFormat = new TextFormat(TYPEFACE, TYPESIZE, INPUT_COLOR);
				INPUT.type = TextFieldType.INPUT;

				s = new StyleSheet();
				s.setStyle('.body', BODY_STYLE);
				s.setStyle('.close', X_BUTTON_STYLE);
				s.setStyle('.currentFilter', FILTER_LABEL_STYLE);
				s.setStyle('.killFilter', KILL_FILTER_LABEL_STYLE);
				s.setStyle('a:link', X_BUTTON_STYLE);
//				s.setStyle('a:hover', X_BUTTON_STYLE);
//				s.setStyle('a:active', X_BUTTON_STYLE);
				
				FILTER_LABEL.defaultTextFormat = new TextFormat(TYPEFACE, TYPESIZE, BODY_STYLE.color);
				FILTER_LABEL.styleSheet = s;
				FILTER_LABEL.selectable = false;
				FILTER_LABEL.addEventListener(TextEvent.LINK, headerClicked);
				FILTER_LABEL.htmlText = '<a href="event:closeConsole">[Hide Console]</a> ';
			}

			/**
			 *  Takes a number and returns a String at least five characters
			 *  long (right justified) plus a trailing space.
			 * 
			 *  @param lineNumber The number to format.
			 */
			private function formattedLineNumber(lineNumber:int):String{
				if(lineNumber < 10) return '    <span class="lineNumber">' + lineNumber + '</span> ';
				if(lineNumber < 100) return '   <span class="lineNumber">' + lineNumber + '</span> ';
				if(lineNumber < 1000) return '  <span class="lineNumber">' + lineNumber + '</span> ';
				if(lineNumber < 10000) return ' <span class="lineNumber">' + lineNumber + '</span> ';
				return '<span class="lineNumber">' + lineNumber + '</span> ';
			}

			/**
			 *  This function parses the name of the calling class out of 
			 *  a callstack. Since the callstack has many formats, this is
			 *  probably not bulletproof yet.
			 * 
			 *  This function also generates the lookup vector to find 
			 *  the category of any given text line in the console.
			 * 
			 *  Borrowed some parsing from http://www.ultrashock.com/forum/viewthread/95261/
			 */
			private function mapLineToCategory(callStack:String):String{
				if(callStack == null){											//  if the callstack is empty, we're running in a release swf - no debug data available
					CATEGORY_BY_LINE_NUMBER.push('');
					return '';
				}

				var line:String = callStack.split('\tat ')[2];					//  isolate the nearest line in the stack
				var packageTerminator:int = line.indexOf('::');					//  index where the package ends
				var classTerminator:int = line.indexOf('()');					//  index where the class ends

				if(packageTerminator == -1){									//  are we in top-level code...
					var func:int = line.indexOf('Function');
					if((func < 2 && func > -1) || classTerminator == -1){	//  is this is a closure
						CATEGORY_BY_LINE_NUMBER.push('_anon');
						return '<a href="event:_anon">   Anonymous</a>';
					} else {
						//  this is probably the main class
						line = line.substring(0, classTerminator);
					}
				} else {
					//  there are a bunch of other formats but we just want what's between the :: and the ()
					line = line.substring(packageTerminator + 2, classTerminator);
				}

				if(line.indexOf('$') > -1) line = line.substring(0, line.indexOf('$'));
				CATEGORY_BY_LINE_NUMBER.push(line);

				//  for long class names, we truncate to fit in 12 characters...
				if(line.length > 12) return '<a href="event:' + line + '">' + line.substr(0, 5) + '..' + line.substr(line.length - 5, 5) + '</a>';

				//  ...otherwise we pad spaces on the left (this gives us right-justification)
				while(line.length < 12) line = ' ' + line;
				return '<a href="event:' + CATEGORY_BY_LINE_NUMBER[CATEGORY_BY_LINE_NUMBER.length - 1] + '">' + line + '</a>';
			}
			
			/**
			 *  Takes the contents of the input textfield and attempts to
			 *  find a corresponding command - if so, it executes and passes
			 *  any trailing text as variables
			 */
			private function processTextInput():void{
				if(!active || disabled || INPUT.text == '') return;				//  make doubly sure we don't execute anything unless open

				var a:Array = INPUT.text.split(' ');
				
				if(SAVED_COMMANDS.length == 0 || INPUT.text != SAVED_COMMANDS[SAVED_COMMANDS.length - 1]){
					SAVED_COMMANDS.push(INPUT.text);
				}

				savedCommandIndex = -1;
				INPUT.text = '';

				var cmd:String = a[0];

				instance.writeLine(cmd, COMMAND_STYLE, CALLSTACK_BYPASS);

				if(COMMAND_BY_NAME[cmd]){
					a.shift();
					
					if(a.length > 0){
						try{
							COMMAND_BY_NAME[cmd].action.apply(null, a);
						} catch(err:Error){
							instance.writeLine('Command failed: ' + cmd + '(' + a + ')', COMMAND_STYLE, CALLSTACK_BYPASS);
							instance.writeLine(err.message, COMMAND_STYLE, CALLSTACK_BYPASS);
						}
					} else {
						try{
							COMMAND_BY_NAME[cmd].action();
						} catch(err:Error){
							instance.writeLine('Command failed: ' + cmd + '()', COMMAND_STYLE, CALLSTACK_BYPASS);
							instance.writeLine(err.message, COMMAND_STYLE, CALLSTACK_BYPASS);
						}
					}
				} else {
					//  no command by that name...
					instance.writeLine((CATEGORIES_ENABLED ? '             ' : '') + 'Command not found.', ERROR_STYLE, CALLSTACK_BYPASS);
				}
			}
			
			private function autoCompleteInput():void{
				if(INPUT.text == '' || COMMAND_BY_NAME[INPUT.text]) return;		//  nothing there, or it's already a full command

				var lc:String = INPUT.text.toLowerCase();

				for(var i:int = 0; i < COMMANDS.length; ++i){
					//  look for match...
					if(COMMANDS[i].commandLC.search(lc) == 0){
						INPUT.text = COMMANDS[i].command;
						INPUT.setSelection(INPUT.length, INPUT.length);			//  move the caret to the end
						return;
					}
				}
				
			}
			
			/**  Removes current filtering */
			private function unFilter(...args):void{
				filterActive = false;
				TEXTFIELD.htmlText = displayLog;
				TEXTFIELD.scrollV = TEXTFIELD.maxScrollV;
				FILTER_LABEL.htmlText = '<a href="event:closeConsole">[Hide Console]</a> ';
			}
			
			/** Restricts Console to only showing logs from a given class. */
			private function changeFilter(...args):void{
				if(!args || args.length < 1 || !args[0] is String || !args[0]){
					instance.writeLine((CATEGORIES_ENABLED ? '             ' : '') + 'Invalid filter entered.', WARNING_STYLE, CALLSTACK_BYPASS);
					filterActive = false;
					FILTER_LABEL.htmlText = '<a href="event:closeConsole">[Hide Console]</a> ';
					if(active){
						TEXTFIELD.htmlText = displayLog;
						TEXTFIELD.scrollV = TEXTFIELD.maxScrollV;
					}
					return;
				} else {
					var filterTag:String = String(args[0]);					
				}

				if(filterActive && currentFilter == filterTag) return;
				filterActive = true;
				currentFilter = filterTag;
				FILTER_LABEL.htmlText = '<a href="event:closeConsole">[Hide Console]</a>      <span class="body">Current Filter:</span> <span class="currentFilter">' + currentFilter + '</span>  <a href="event:removeFilter"><span class="killFilter">[Remove Filter]</span></a>';
				TEXTFIELD.htmlText = '';

				for(var i:int = 0; i < HTML_TEXT_BY_LINE_NUMBER.length; ++i){
					if(CATEGORY_BY_LINE_NUMBER[i] == currentFilter) TEXTFIELD.htmlText += HTML_TEXT_BY_LINE_NUMBER[i];
				}

				if(TEXTFIELD.htmlText == ''){
					filterActive = false;
					TEXTFIELD.htmlText = displayLog;
					FILTER_LABEL.htmlText = '<a href="event:closeConsole">[Hide Console]</a> ';
				}

				TEXTFIELD.scrollV = TEXTFIELD.maxScrollV;
			}
			
			/**
			 *  When UP is pressed, populate the input textfield with a previously
			 *  entered command - moving toward most recent.
			 */
			private function stepDownThroughCommands():void{
				if(savedCommandIndex > -1){													//  are we not at the bottom already?
					++savedCommandIndex;
					if(savedCommandIndex >= SAVED_COMMANDS.length){							//  are we back at the bottom now?
						savedCommandIndex = -1;
						INPUT.text = onDeckCommand;
					} else {
						INPUT.text = SAVED_COMMANDS[savedCommandIndex];
					}
				}

				INPUT.setSelection(INPUT.length, INPUT.length);								//  move the caret to the end
			}

			/**
			 *  When UP is pressed, populate the input textfield with a previously
			 *  entered command - moving toward earliest.
			 */
			private function stepUpThroughCommands():void{
				if(savedCommandIndex > -1){													//  are we not at the top of the stack already?
					savedCommandIndex = Math.max(savedCommandIndex - 1, 0);
					INPUT.text = SAVED_COMMANDS[savedCommandIndex];
				} else if(SAVED_COMMANDS.length > 0){										//  if not - is there any data to cycle?
					onDeckCommand = INPUT.text;												//  save whatever was already typed in case we want to come back
					savedCommandIndex = SAVED_COMMANDS.length - 1;
					INPUT.text = SAVED_COMMANDS[savedCommandIndex];
				}
			}
			
			private function registerDefaultCommands():void{
				registerCommand('version', printVersionCommand, 'Prints the code version of the Console.');
				registerCommand('help', helpCommand, 'List available commands. Use "help -l" for compact list.');
//				registerCommand('filter', changeFilter, '(filterTag:String), Filter the console by the supplied tag.');
				registerCommand('unfilter', unFilter, 'Remove filtering.');
				registerCommand('hide', hideConsoleCommand, 'Hides the Console from view.');
				registerCommand('plugin', printFlashPlayerCommand, 'Print the current Flash plugin version.');
				registerCommand('os', printOSCommand, 'Print the current Operating System.');
				registerCommand('language', printLanguageCommand, 'Print the current system language.');
				registerCommand('system', printSystemSummaryCommand, 'Print a summary of the current system.');
				registerCommand('localstoragesettings', openLocalStorageSettingsCommand, 'Opens the Local Storage Settings panel.');
				registerCommand('globalstoragesettings', openGlobalStorageSettingsCommand, 'Opens the Global Storage Settings panel in a new browser window.');
				registerCommand('globalsecuritysettings', openGlobalSecuritySettingsCommand, 'Opens the Global Security Settings panel in a new browser window.');
				registerCommand('gc', gcCommand, 'Force the Garbage Collector to run.');
				registerCommand('memory', memoryCommand, 'Print the current memory usage.');
				registerCommand('time', timeCommand, 'Print the current system time.');
				registerCommand('uptime', uptimeCommand, 'Print the amount of time this swf has been running.');
				registerCommand('about', aboutCommand, 'About this Console.');
			}
			
			private function helpCommand(...args):void{
				var s:String;
				var i:int;
				var len:int = COMMANDS.length;

				writeLine((CATEGORIES_ENABLED ? '             ' : '') + 'Available console commands:', BODY_STYLE, CALLSTACK_BYPASS);

				if(args && args.length && args[0] == '-l'){
					var rows:int = (len % 3 == 0) ? len / 3 : int(len / 3) + 1;
					for(i = 0; i < rows; ++i){
						s = COMMANDS[i].command;
						while(s.length < 30) s += ' ';
						
						if(COMMANDS.length > i + rows) s += COMMANDS[i + rows].command;
						while(s.length < 60) s += ' ';
						
						if(COMMANDS.length > i + rows + rows) s += COMMANDS[i + rows + rows].command;
						
						writeLine((CATEGORIES_ENABLED ? '             ' : '') + s, BODY_STYLE, CALLSTACK_BYPASS);
					}
				} else {
					for(i = 0; i < len; ++i){
						s = COMMANDS[i].command;
						while(s.length < 25) s += ' ';
						writeLine((CATEGORIES_ENABLED ? '             ' : '') + s + ' ' + COMMANDS[i].description, BODY_STYLE, CALLSTACK_BYPASS);
					}
				}
			}
			
			private function hideConsoleCommand(...args):void{
				hideConsole();
			}
			
			private function printVersionCommand(...args):void{
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + 'Console V' + VERSION, BODY_STYLE, CALLSTACK_BYPASS);
			}
			
			private function printFlashPlayerCommand(...args):void{
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + Capabilities.version + ' ' + (Capabilities.isDebugger ? '[Debug]' : '[Release]'), BODY_STYLE, CALLSTACK_BYPASS);
			}

			private function printOSCommand(...args):void{
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + Capabilities.os, BODY_STYLE, CALLSTACK_BYPASS);
			}
			
			private function printLanguageCommand(...args):void{
				const lookup:Array = ['cs', 'Czech', 'da', 'Danish', 'nl', 'Dutch', 'en', 'English', 'fi', 'Finnish', 'fr', 'French', 'de', 'German', 'hu', 'Hungarian', 'it', 'Italian', 'ja', 'Japanese', 'ko', 'Korean', 'no', 'Norwegian', 'xu', 'Other/Unknown', 'pl', 'Polish', 'pt', 'Portuguese', 'ru', 'Russian', 'zh-CN', 'Simplified Chinese', 'es', 'Spanish', 'sv', 'Swedish', 'zh-TW', 'Traditional Chinese', 'tr', 'Turkish'];
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + lookup[lookup.indexOf(Capabilities.language) + 1], BODY_STYLE, CALLSTACK_BYPASS);
			}
			
			private function printSystemSummaryCommand(...args):void{
				const lookup:Array = ['cs', 'Czech', 'da', 'Danish', 'nl', 'Dutch', 'en', 'English', 'fi', 'Finnish', 'fr', 'French', 'de', 'German', 'hu', 'Hungarian', 'it', 'Italian', 'ja', 'Japanese', 'ko', 'Korean', 'no', 'Norwegian', 'xu', 'Other/Unknown', 'pl', 'Polish', 'pt', 'Portuguese', 'ru', 'Russian', 'zh-CN', 'Simplified Chinese', 'es', 'Spanish', 'sv', 'Swedish', 'zh-TW', 'Traditional Chinese', 'tr', 'Turkish'];
				const ms:uint = getTimer();
				
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + '======================SYSTEM SUMMARY======================', BODY_STYLE, CALLSTACK_BYPASS);
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + '\tOperating System:    ' + Capabilities.os, BODY_STYLE, CALLSTACK_BYPASS);
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + '\tFlash Plugin:        ' + Capabilities.version + ' ' + (Capabilities.isDebugger ? '[Debug]' : '[Release]'), BODY_STYLE, CALLSTACK_BYPASS);
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + '\tSystem Language:     ' + lookup[lookup.indexOf(Capabilities.language) + 1], BODY_STYLE, CALLSTACK_BYPASS);
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + '\tMemory Usage:        ' + (System.totalMemory / 1048576).toFixed(1) + 'mb', BODY_STYLE, CALLSTACK_BYPASS);
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + '\tRun time:            ' + int(ms / 60000) + ' minutes, ' + int((ms % 60000) / 1000) + ' seconds', BODY_STYLE, CALLSTACK_BYPASS);
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + '\tSystem time:         ' + new Date().toLocaleString(), BODY_STYLE, CALLSTACK_BYPASS);
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + '\tDisplay:             ' + '(' + Capabilities.screenResolutionX + ', ' + Capabilities.screenResolutionY + ') ' + Capabilities.screenDPI + 'dpi', BODY_STYLE, CALLSTACK_BYPASS);
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + '\tSecurity Sandbox:    ' + Security.sandboxType, BODY_STYLE, CALLSTACK_BYPASS);
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + '\tLocal File Access:   ' + (Capabilities.localFileReadDisable ? 'prohibited' : 'allowed'), BODY_STYLE, CALLSTACK_BYPASS);
				//  Flash 10.3 and higher
//				writeLine((CATEGORIES_ENABLED ? '             ' : '') + '\tParent domain:     ' + Security.pageDomain, BODY_STYLE, CALLSTACK_BYPASS);
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + '==========================================================', BODY_STYLE, CALLSTACK_BYPASS);
			}
			
			private function openLocalStorageSettingsCommand(...args):void{
				Security.showSettings(SecurityPanel.LOCAL_STORAGE);
			}
			
			private function openGlobalStorageSettingsCommand(...args):void{
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + 'Opening: http://www.macromedia.com/support/documentation/en/flashplayer/help/settings_manager03.html', BODY_STYLE, CALLSTACK_BYPASS);
				navigateToURL(new URLRequest('http://www.macromedia.com/support/documentation/en/flashplayer/help/settings_manager03.html'), '_blank');
			}

			private function openGlobalSecuritySettingsCommand(...args):void{
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + 'Opening: http://www.macromedia.com/support/documentation/en/flashplayer/help/settings_manager04.html', BODY_STYLE, CALLSTACK_BYPASS);
				navigateToURL(new URLRequest('http://www.macromedia.com/support/documentation/en/flashplayer/help/settings_manager04.html'), '_blank');
			}

			private function gcCommand(...args):void{
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + 'Current memory: ' + (System.totalMemory / 1048576).toFixed(1) + 'mb', BODY_STYLE, CALLSTACK_BYPASS);
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + 'Activating Garbage Collection', BODY_STYLE, CALLSTACK_BYPASS);
				System.gc();
				System.gc();
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + 'Current memory: ' + (System.totalMemory / 1048576).toFixed(1) + 'mb', BODY_STYLE, CALLSTACK_BYPASS);
			}
			
			private function memoryCommand(...args):void{
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + (System.totalMemory / 1048576).toFixed(1) + 'mb', BODY_STYLE, CALLSTACK_BYPASS);
			}

			private function timeCommand():void{
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + new Date().toLocaleString(), BODY_STYLE, CALLSTACK_BYPASS);
			}
			
			private function uptimeCommand():void{
				const ms:uint = getTimer();
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + int(ms / 60000) + ' minutes, ' + int((ms % 60000) / 1000) + ' seconds', BODY_STYLE, CALLSTACK_BYPASS);
			}
			
			private function aboutCommand():void{
				writeLine((CATEGORIES_ENABLED ? '             ' : '') + 'This Console is a component of the <a href="http://www.trexarms.org" target="_blank">T-Rex Arms</a> project. <a href="http://www.trexarms.org" target="_blank">www.trexarms.org</a>', BODY_STYLE, CALLSTACK_BYPASS);
			}

	}
}

//----------------------------------------------
//  PRIVATE CLASS
//----------------------------------------------

	/**  Helper class for storing commands. */
	final class ConsoleCommand {

		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------

			/**
			 * Constructor
			 */
			public function ConsoleCommand(_command:String, _action:Function, _description:String = ''){
				command = _command;
				commandLC = _command.toLowerCase();
				action = _action;
				description = _description;
			}

		//--------------------------------------
		//  PUBLIC VARIABLES
		//--------------------------------------

			public var command:String;
			public var commandLC:String;
			public var action:Function;
			public var description:String;

}
