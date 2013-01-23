/*
 *      _________  __      __
 *    _/        / / /____ / /________ ____ ____  ___
 *   _/        / / __/ -_) __/ __/ _ `/ _ `/ _ \/ _ \
 *  _/________/  \__/\__/\__/_/  \_,_/\_, /\___/_//_/
 *                                   /___/
 * 
 * Tetragon : Game Engine for multi-platform ActionScript projects.
 * http://www.tetragonengine.com/ - Copyright (C) 2012 Sascha Balkau
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
package tetragon.view.render2d.core
{
	import tetragon.Main;
	import tetragon.debug.Log;
	import tetragon.view.render2d.animation.Juggler2D;
	import tetragon.view.render2d.display.DisplayObject2D;
	import tetragon.view.render2d.display.Sprite2D;
	import tetragon.view.render2d.display.Stage2D;
	import tetragon.view.render2d.events.Event2D;
	import tetragon.view.render2d.events.EventDispatcher2D;
	import tetragon.view.render2d.events.KeyboardEvent2D;
	import tetragon.view.render2d.events.ResizeEvent2D;
	import tetragon.view.render2d.touch.TouchPhase2D;
	import tetragon.view.render2d.touch.TouchProcessor2D;

	import com.hexagonstar.constants.HAlign;
	import com.hexagonstar.constants.VAlign;

	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Program3D;
	import flash.errors.IllegalOperationError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Mouse;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	
	/** Dispatched when a new render context is created. */
	[Event(name="context3DCreate", type="tetragon.view.render2d.events.Event2D")]
	/** Dispatched when the root class has been created. */
	[Event(name="rootCreated", type="tetragon.view.render2d.events.Event2D")]
	
	
	/**
	 * The Render2D class represents the core of the Render2D framework.
	 * <p>
	 * The Render2D framework makes it possible to create 2D applications and games that
	 * make use of the Stage3D architecture introduced in Flash Player 11. It implements a
	 * display tree system that is very similar to that of conventional Flash, while
	 * leveraging modern GPUs to speed up rendering.
	 * </p>
	 * <p>
	 * The Render2D class represents the link between the conventional Flash display tree
	 * and the Render2D display tree. To create a Render2D-powered application, you have
	 * to create an instance of the Render2D class:
	 * </p>
	 * 
	 * <pre>var Render2D:Render2D = new Render2D(Game, stage);</pre>
	 * <p>
	 * The first parameter has to be a Render2D display object class, e.g. a subclass of
	 * <code>Render2D.display.Sprite</code>. In the sample above, the class "Game" is the
	 * application root. An instance of "Game" will be created as soon as Render2D is
	 * initialized. The second parameter is the conventional (Flash) stage object. Per
	 * default, Render2D will display its contents directly below the stage.
	 * </p>
	 * <p>
	 * It is recommended to store the Render2D instance as a member variable, to make sure
	 * that the Garbage Collector does not destroy it. After creating the Render2D object,
	 * you have to start it up like this:
	 * </p>
	 * 
	 * <pre>Render2D.start();</pre>
	 * <p>
	 * It will now render the contents of the "Game" class in the frame rate that is set
	 * up for the application (as defined in the Flash stage).
	 * </p>
	 * <strong>Accessing the Render2D object</strong>
	 * <p>
	 * From within your application, you can access the current Render2D object anytime
	 * through the static method <code>Render2D.current</code>. It will return the active
	 * Render2D instance (most applications will only have one Render2D object, anyway).
	 * </p>
	 * <strong>Viewport</strong>
	 * <p>
	 * The area the Render2D content is rendered into is, per default, the complete size
	 * of the stage. You can, however, use the "viewPort" property to change it. This can
	 * be useful when you want to render only into a part of the screen, or if the player
	 * size changes. For the latter, you can listen to the RESIZE-event dispatched by the
	 * Render2D stage.
	 * </p>
	 * <strong>Native overlay</strong>
	 * <p>
	 * Sometimes you will want to display native Flash content on top of Render2D. That's
	 * what the <code>nativeOverlay</code> property is for. It returns a Flash Sprite
	 * lying directly on top of the Render2D content. You can add conventional Flash
	 * objects to that overlay.
	 * </p>
	 * <p>
	 * Beware, though, that conventional Flash content on top of 3D content can lead to
	 * performance penalties on some (mobile) platforms. For that reason, always remove
	 * all child objects from the overlay when you don't need them any longer. Render2D
	 * will remove the overlay from the display list when it's empty.
	 * </p>
	 * <strong>Multitouch</strong>
	 * <p>
	 * Render2D supports multitouch input on devices that provide it. During development,
	 * where most of us are working with a conventional mouse and keyboard, Render2D can
	 * simulate multitouch events with the help of the "Shift" and "Ctrl" (Mac: "Cmd")
	 * keys. Activate this feature by enabling the <code>simulateMultitouch</code>
	 * property.
	 * </p>
	 * <strong>Handling a lost render context</strong>
	 * <p>
	 * On some operating systems and under certain conditions (e.g. returning from system
	 * sleep), Render2D's stage3D render context may be lost. Render2D can recover from a
	 * lost context if the class property "handleLostContext" is set to "true". Keep in
	 * mind, however, that this comes at the price of increased memory consumption;
	 * Render2D will cache textures in RAM to be able to restore them when the context is
	 * lost.
	 * </p>
	 * <p>
	 * In case you want to react to a context loss, Render2D dispatches an event with the
	 * type "Event.CONTEXT3D_CREATE" when the context is restored. You can recreate any
	 * invalid resources in a corresponding event listener.
	 * </p>
	 * <strong>Sharing a 3D Context</strong>
	 * <p>
	 * Per default, Render2D handles the Stage3D context independently. If you want to
	 * combine Render2D with another Stage3D engine, however, this may not be what you
	 * want. In this case, you can make use of the <code>shareContext</code> property:
	 * </p>
	 * <ol>
	 * <li>Manually create and configure a context3D object that both frameworks can work
	 * with (through <code>stage3D.requestContext3D</code> and
	 * <code>context.configureBackBuffer</code>).</li>
	 * <li>Initialize Render2D with the stage3D instance that contains that configured
	 * context. This will automatically enable <code>shareContext</code>.</li>
	 * <li>Call <code>start()</code> on your Render2D instance (as usual). This will make
	 * Render2D queue input events (keyboard/mouse/touch).</li>
	 * <li>Create a game loop (e.g. using the native <code>ENTER_FRAME</code> event) and
	 * let it call Render2D's <code>nextFrame</code> as well as the equivalent method of
	 * the other Stage3D engine. Surround those calls with <code>context.clear()</code>
	 * and <code>context.present()</code>.</li>
	 * </ol>
	 */
	public class Render2D extends EventDispatcher2D
	{
		//-----------------------------------------------------------------------------------------
		// Constants
		//-----------------------------------------------------------------------------------------
		
		/** The version of the Render2D framework. */
		public static const VERSION:String = "1.3";
		
		/** The key for the shader programs stored in 'contextData' */
		private static const PROGRAM_DATA_NAME:String = "render2d.programs";
		
		
		//-----------------------------------------------------------------------------------------
		// Properties
		//-----------------------------------------------------------------------------------------
		
		/** @private */
		private var _stage3D:Stage3D;
		/** @private */
		private var _stage2D:Stage2D;
		/** @private */
		private var _context:Context3D;
		
		/** @private */
		private var _stage:Stage;
		/** @private */
		private var _nativeOverlay:Sprite;
		
		/** @private */
		private var _root:Sprite2D;
		
		/** @private */
		private var _juggler:Juggler2D;
		/** @private */
		private var _renderSupport:RenderSupport2D;
		/** @private */
		private var _touchProcessor:TouchProcessor2D;
		/** @private */
		private var _statsDisplay:StatsDisplay2D;
		
		/** @private */
		private var _viewPort:Rectangle;
		/** @private */
		private var _previousViewPort:Rectangle;
		/** @private */
		private var _clippedViewPort:Rectangle;
		
		/** @private */
		private var _profile:String;
		/** @private */
		private var _antiAliasing:int;
		/** @private */
		private var _lastFrameTimestamp:Number;
		
		/** @private */
		private var _started:Boolean;
		/** @private */
		private var _simulateMultitouch:Boolean;
		/** @private */
		private var _enableErrorChecking:Boolean;
		/** @private */
		private var _leftMouseDown:Boolean;
		/** @private */
		private var _shareContext:Boolean;
		
		/** @private */
		private static var _current:Render2D;
		/** @private */
		private static var _contextData:Dictionary;
		/** @private */
		private static var _handleLostContext:Boolean;
		
		
		//-----------------------------------------------------------------------------------------
		// Constructor
		//-----------------------------------------------------------------------------------------
		
		/**
		 * Creates a new Render2D instance.
		 * 
		 * @param rootClass A subclass of a Render2D display object. It will be created as
		 *            soon as initialization is finished and will become the first child of
		 *            the Render2D stage.
		 * @param viewPort A rectangle describing the area into which the content will be
		 *            rendered. @default stage size
		 * @param stage3D The Stage3D object into which the content will be rendered. If it
		 *            already contains a context, <code>sharedContext</code> will be set to
		 *            <code>true</code>. @default the first available Stage3D.
		 * @param renderMode Use this parameter to force "software" rendering.
		 * @param profile The Context3DProfile that should be requested.
		 */
		public function Render2D(root:Sprite2D, viewPort:Rectangle = null,
			stage3D:Stage3D = null, renderMode:String = "auto",
			profile:String = "baselineConstrained")
		{
			_stage = Main.instance.stage;
			
			if (!root) root = new Sprite2D();
			if (!viewPort) viewPort = new Rectangle(0, 0, _stage.stageWidth, _stage.stageHeight);
			if (!stage3D) stage3D = _stage.stage3Ds[0];
			if (!_contextData) _contextData = new Dictionary(true);
			
			makeCurrent();
			
			_root = root;
			_viewPort = viewPort;
			_stage3D = stage3D;
			
			_previousViewPort = new Rectangle();
			_stage2D = new Stage2D(viewPort.width, viewPort.height, _stage.color);
			_touchProcessor = new TouchProcessor2D(_stage2D);
			_juggler = new Juggler2D();
			_renderSupport = new RenderSupport2D();
			
			_nativeOverlay = new Sprite();
			_stage.addChild(_nativeOverlay);
			
			_antiAliasing = 0;
			_simulateMultitouch = false;
			_enableErrorChecking = false;
			_profile = profile;
			_lastFrameTimestamp = getTimer() / 1000.0;
			
			/* For context data, we actually reference by stage3D, since it survives
			 * a context loss. */
			_contextData[stage3D] = new Dictionary();
			_contextData[stage3D][PROGRAM_DATA_NAME] = new Dictionary();
			
			/* Register touch/mouse event handlers. */
			for each (var touchEventType:String in touchEventTypes)
			{
				_stage.addEventListener(touchEventType, onTouch);
			}
			
			/* Register other event handlers. */
			_stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			_stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
			_stage.addEventListener(KeyboardEvent.KEY_UP, onKey);
			_stage.addEventListener(Event.RESIZE, onResize);
			_stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeave);
			
			_stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false, 10);
			_stage3D.addEventListener(ErrorEvent.ERROR, onStage3DError, false, 10);
			
			/* If we already got a context3D and it's not disposed. */
			if (_stage3D.context3D && _stage3D.context3D.driverInfo != "Disposed")
			{
				_shareContext = true;
				/* we don't call it right away, because Render2D should behave the
				 * same way with or without a shared context. */
				setTimeout(initialize, 1);
			}
			else
			{
				_shareContext = false;
				try
				{
					/* "Context3DProfile" is only available starting with Flash Player
					 * 11.4/AIR 3.4. to stay compatible with older versions, we check if
					 * the parameter is available. */
					var requestContext3D:Function = _stage3D.requestContext3D;
					if (requestContext3D.length == 1) requestContext3D(renderMode);
					else requestContext3D(renderMode, profile);
				}
				catch (err:Error)
				{
					showOnScreenError("Context3D error: " + err.message);
				}
			}
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Public Methods
		//-----------------------------------------------------------------------------------------
		
		/**
		 * Disposes all children of the stage and the render context; removes all registered
		 * event listeners.
		 */
		public function dispose():void
		{
			stop();
			
			_stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			_stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
			_stage.removeEventListener(KeyboardEvent.KEY_UP, onKey);
			_stage.removeEventListener(Event.RESIZE, onResize);
			_stage.removeEventListener(Event.MOUSE_LEAVE, onMouseLeave);
			_stage.removeChild(_nativeOverlay);
			
			_stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			_stage3D.removeEventListener(ErrorEvent.ERROR, onStage3DError);
			
			for each (var touchEventType:String in touchEventTypes)
			{
				_stage.removeEventListener(touchEventType, onTouch);
			}
			
			if (_stage2D) _stage2D.dispose();
			if (_renderSupport) _renderSupport.dispose();
			if (_touchProcessor) _touchProcessor.dispose();
			if (_context && !_shareContext) _context.dispose();
			if (_current == this) _current = null;
		}
		
		
		/**
		 * Calls <code>advanceTime()</code> (with the time that has passed since the last
		 * frame) and <code>render()</code>.
		 */
		public function nextFrame():void
		{
			var now:Number = getTimer() / 1000.0;
			var passedTime:Number = now - _lastFrameTimestamp;
			_lastFrameTimestamp = now;
			
			advanceTime(passedTime);
			render();
		}
		
		
		/**
		 * Dispatches ENTER_FRAME events on the display list, advances the Juggler and
		 * processes touches.
		 */
		public function advanceTime(passedTime:Number):void
		{
			makeCurrent();
			_touchProcessor.advanceTime(passedTime);
			_stage2D.advanceTime(passedTime);
			_juggler.advanceTime(passedTime);
		}
		
		
		/**
		 * Renders the complete display list. Before rendering, the context is cleared;
		 * afterwards, it is presented. This can be avoided by enabling
		 * <code>shareContext</code>.
		 */
		public function render():void
		{
			if (!contextValid) return;
			
			makeCurrent();
			updateViewPort();
			updateNativeOverlay();
			_renderSupport.nextFrame();
			
			if (!_shareContext) RenderSupport2D.clear(_stage2D.color, 1.0);
			
			var scaleX:Number = _viewPort.width / _stage2D.stageWidth;
			var scaleY:Number = _viewPort.height / _stage2D.stageHeight;
			
			_context.setDepthTest(false, Context3DCompareMode.ALWAYS);
			_context.setCulling(Context3DTriangleFace.NONE);
			
			_renderSupport.renderTarget = null;
			_renderSupport.setOrthographicProjection(
				_viewPort.x < 0 ? -_viewPort.x / scaleX : 0.0,
				_viewPort.y < 0 ? -_viewPort.y / scaleY : 0.0,
				_clippedViewPort.width / scaleX,
				_clippedViewPort.height / scaleY);
			
			_stage2D.render(_renderSupport, 1.0);
			_renderSupport.finishQuadBatch();
			
			if (_statsDisplay) _statsDisplay.drawCount = _renderSupport.drawCount;
			if (!_shareContext) _context.present();
		}
		
		
		/**
		 * Make this Render2D instance the <code>current</code> one.
		 */
		public function makeCurrent():void
		{
			_current = this;
		}
		
		
		/**
		 * As soon as Render2D is started, it will queue input events (keyboard/mouse/touch);
		 * furthermore, the method <code>nextFrame</code> will be called once per Flash Player
		 * frame. (Except when <code>shareContext</code> is enabled: in that case, you have to
		 * call that method manually.)
		 */
		public function start():void
		{
			_started = true;
			_lastFrameTimestamp = getTimer() / 1000.0;
		}
		
		
		/**
		 * Stops all logic processing and freezes the rendering in its current state. The content
		 * is still being rendered once per frame, though, because otherwise the conventional
		 * display list would no longer be updated.
		 */
		public function stop():void
		{
			_started = false;
		}
		
		
		/**
		 * Registers a vertex- and fragment-program under a certain name. If the name was
		 * already used, the previous program is overwritten.
		 * 
		 * @param name
		 * @param vertexProgram
		 * @param fragmentProgram
		 */
		public function registerProgram(name:String, vertexProgram:ByteArray,
			fragmentProgram:ByteArray):void
		{
			deleteProgram(name);
			
			var program:Program3D = _context.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			programs[name] = program;
		}
		
		
		/**
		 * Deletes the vertex- and fragment-programs of a certain name.
		 * 
		 * @param name
		 */
		public function deleteProgram(name:String):void
		{
			var program:Program3D = getProgram(name);
			if (!program) return;
			program.dispose();
			delete programs[name];
		}
		
		
		/**
		 * Returns the vertex- and fragment-programs registered under a certain name.
		 * 
		 * @param name
		 */
		public function getProgram(name:String):Program3D
		{
			return programs[name];
		}
		
		
		/**
		 * Indicates if a set of vertex- and fragment-programs is registered under a
		 * certain name.
		 * 
		 * @param name
		 */
		public function hasProgram(name:String):Boolean
		{
			return name in programs;
		}
		
		
		/**
		 * Displays the statistics box at a certain position.
		 * 
		 * TODO To be removed! render2D stats should be integrated with Tetragon's Stats Monitor!
		 * 
		 * @param hAlign
		 * @param vAlign
		 * @param scale
		 */
		public function showStatsAt(hAlign:String = "left", vAlign:String = "top",
			scale:Number = 1.0):void
		{
			if (!_context)
			{
				// Render2D is not yet ready - we postpone this until it's initialized.
				addEventListener(Event2D.ROOT_CREATED, onRootCreated);
			}
			else
			{
				if (_statsDisplay == null)
				{
					_statsDisplay = new StatsDisplay2D();
					_statsDisplay.touchable = false;
					_stage2D.addChild(_statsDisplay);
				}

				var stageWidth:int = _stage2D.stageWidth;
				var stageHeight:int = _stage2D.stageHeight;

				_statsDisplay.scaleX = _statsDisplay.scaleY = scale;

				if (hAlign == HAlign.LEFT) _statsDisplay.x = 0;
				else if (hAlign == HAlign.RIGHT) _statsDisplay.x = stageWidth - _statsDisplay.width;
				else _statsDisplay.x = int((stageWidth - _statsDisplay.width) / 2);

				if (vAlign == VAlign.TOP) _statsDisplay.y = 0;
				else if (vAlign == VAlign.BOTTOM) _statsDisplay.y = stageHeight - _statsDisplay.height;
				else _statsDisplay.y = int((stageHeight - _statsDisplay.height) / 2);
			}

			function onRootCreated():void
			{
				showStatsAt(hAlign, vAlign, scale);
				removeEventListener(Event2D.ROOT_CREATED, onRootCreated);
			}
		}
		
		
		/**
		 * Returns a String Representation of the class.
		 * 
		 * @return A String Representation of the class.
		 */
		public function toString():String
		{
			return "Render2D";
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Accessors
		//-----------------------------------------------------------------------------------------
		
		/**
		 * Indicates if a context is available and non-disposed.
		 */
		private function get contextValid():Boolean
		{
			return (_context && _context.driverInfo != "Disposed");
		}


		/**
		 * Indicates if this Render2D instance is started.
		 */
		public function get started():Boolean
		{
			return _started;
		}


		/**
		 * The default juggler of this instance. Will be advanced once per frame.
		 */
		public function get juggler():Juggler2D
		{
			return _juggler;
		}


		/**
		 * The render context of this instance.
		 */
		public function get context():Context3D
		{
			return _context;
		}


		/**
		 * A dictionary that can be used to save custom data related to the current context.
		 * If you need to share data that is bound to a specific stage3D instance (e.g.
		 * textures), use this dictionary instead of creating a static class variable. The
		 * Dictionary is actually bound to the stage3D instance, thus it survives a context
		 * loss.
		 */
		public function get contextData():Dictionary
		{
			return _contextData[_stage3D];
		}


		/**
		 * Indicates if multitouch simulation with "Shift" and "Ctrl"/"Cmd"-keys is enabled.
		 * 
		 * @default false
		 */
		public function get simulateMultitouch():Boolean
		{
			return _simulateMultitouch;
		}
		public function set simulateMultitouch(v:Boolean):void
		{
			_simulateMultitouch = v;
			if (_context) _touchProcessor.simulateMultitouch = v;
		}


		/**
		 * Indicates if Stage3D render methods will report errors. Activate only when needed,
		 * as this has a negative impact on performance.
		 * 
		 * @default false
		 */
		public function get enableErrorChecking():Boolean
		{
			return _enableErrorChecking;
		}
		public function set enableErrorChecking(v:Boolean):void
		{
			_enableErrorChecking = v;
			if (_context) _context.enableErrorChecking = v;
		}
		
		
		/**
		 * The antialiasing level. 0 - no antialasing, 16 - maximum antialiasing.
		 * 
		 * @default 0
		 */
		public function get antiAliasing():int
		{
			return _antiAliasing;
		}
		public function set antiAliasing(v:int):void
		{
			if (_antiAliasing != v)
			{
				_antiAliasing = v;
				if (contextValid) updateViewPort(true);
			}
		}
		
		
		/**
		 * The viewport into which Render2D contents will be rendered.
		 */
		public function get viewPort():Rectangle
		{
			return _viewPort;
		}
		public function set viewPort(v:Rectangle):void
		{
			_viewPort = v.clone();
		}
		
		
		/**
		 * The ratio between viewPort width and stage width. Useful for choosing a different
		 * set of textures depending on the display resolution.
		 */
		public function get contentScaleFactor():Number
		{
			return _viewPort.width / _stage2D.stageWidth;
		}
		
		
		/**
		 * A Flash Sprite placed directly on top of the Render2D content. Use it to display
		 * native Flash components.
		 */
		public function get nativeOverlay():Sprite
		{
			return _nativeOverlay;
		}
		
		
		/**
		 * Indicates if a small statistics box (with FPS, memory usage and draw count)
		 * is displayed.
		 */
		public function get showStats():Boolean
		{
			return _statsDisplay && _statsDisplay.parent;
		}
		public function set showStats(v:Boolean):void
		{
			if (v == showStats) return;
			if (v)
			{
				if (_statsDisplay) _stage2D.addChild(_statsDisplay);
				else showStatsAt();
			}
			else _statsDisplay.removeFromParent();
		}
		
		
		/**
		 * The Render2D stage object, which is the root of the display tree that
		 * is rendered.
		 */
		public function get stage2D():Stage2D
		{
			return _stage2D;
		}
		
		
		/**
		 * The Flash Stage3D object Render2D renders into.
		 */
		public function get stage3D():Stage3D
		{
			return _stage3D;
		}


		/**
		 * The Flash (2D) stage object Render2D renders beneath.
		 */
		public function get stage():Stage
		{
			return _stage;
		}
		
		
		/**
		 * The instance of the root class provided in the constructor. Available as soon as
		 * the event 'ROOT_CREATED' has been dispatched.
		 */
		public function get root():DisplayObject2D
		{
			return _root;
		}
		
		
		/**
		 * Indicates if the Context3D render calls are managed externally to Render2D, to
		 * allow other frameworks to share the Stage3D instance.
		 * 
		 * @default false
		 */
		public function get shareContext():Boolean
		{
			return _shareContext;
		}
		public function set shareContext(v:Boolean):void
		{
			_shareContext = v;
		}
		
		
		/**
		 * The Context3D profile as requested in the constructor. Beware that if you are using
		 * a shared context, this might not be accurate.
		 */
		public function get profile():String
		{
			return _profile;
		}
		
		
		/**
		 * The currently active Render2D instance.
		 */
		public static function get current():Render2D
		{
			return _current;
		}
		
		
		/**
		 * The render context of the currently active Render2D instance.
		 */
		public static function get context():Context3D
		{
			return _current ? _current.context : null;
		}
		
		
		/**
		 * The default juggler of the currently active Render2D instance.
		 */
		public static function get juggler():Juggler2D
		{
			return _current ? _current.juggler : null;
		}
		
		
		/**
		 * The contentScaleFactor of the currently active Render2D instance.
		 */
		public static function get contentScaleFactor():Number
		{
			return _current ? _current.contentScaleFactor : 1.0;
		}
		
		
		/**
		 * Indicates if multitouch input should be supported.
		 */
		public static function get multitouchEnabled():Boolean
		{
			return Multitouch.inputMode == MultitouchInputMode.TOUCH_POINT;
		}
		public static function set multitouchEnabled(v:Boolean):void
		{
			if (_current)
			{
				throw new IllegalOperationError("'multitouchEnabled' must be set before"
					+ " Render2D instance is created.");
			}
			else
			{
				Multitouch.inputMode = v
					? MultitouchInputMode.TOUCH_POINT
					: MultitouchInputMode.NONE;
			}
		}
		
		
		/**
		 * Indicates if Render2D should automatically recover from a lost device context. On
		 * some systems, an upcoming screensaver or entering sleep mode may invalidate the
		 * render context. This setting indicates if Render2D should recover from such
		 * incidents. Beware that this has a huge impact on memory consumption! It is
		 * recommended to enable this setting on Android and Windows, but to deactivate it on
		 * iOS and Mac OS X.
		 * 
		 * @default false
		 */
		public static function get handleLostContext():Boolean
		{
			return _handleLostContext;
		}
		public static function set handleLostContext(v:Boolean):void
		{
			if (_current)
			{
				throw new IllegalOperationError("'handleLostContext' must be set before"
					+ " Render2D instance is created.");
			}
			else
			{
				_handleLostContext = v;
			}
		}
		
		
		/**
		 * @private
		 */
		private function get touchEventTypes():Array
		{
			return Mouse.supportsCursor || !multitouchEnabled
				? [MouseEvent.MOUSE_DOWN, MouseEvent.MOUSE_MOVE, MouseEvent.MOUSE_UP]
				: [TouchEvent.TOUCH_BEGIN, TouchEvent.TOUCH_MOVE, TouchEvent.TOUCH_END];
		}
		
		
		/**
		 * @private
		 */
		private function get programs():Dictionary
		{
			return contextData[PROGRAM_DATA_NAME];
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Callback Handlers
		//-----------------------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		private function onStage3DError(e:ErrorEvent):void
		{
			if (e.errorID == 3702)
			{
				showOnScreenError("This application is not correctly embedded (wrong wmode value)");
			}
			else
			{
				showOnScreenError("Stage3D error: " + e.text);
			}
		}
		
		
		/**
		 * @private
		 */
		private function onContextCreated(e:Event):void
		{
			if (!Render2D.handleLostContext && _context)
			{
				stop();
				e.stopImmediatePropagation();
				showOnScreenError("Fatal error: The application lost the device context!");
				Log.fatal("The device context was lost. Enable Render2D.handleLostContext"
					+ " to avoid this error.", this);
			}
			else
			{
				initialize();
			}
		}
		
		
		/**
		 * @private
		 */
		private function onEnterFrame(e:Event):void
		{
			/* On mobile, the native display list is only updated on stage3D draw calls.
			 * Thus, we render even when Render2D is paused. */
			if (!_shareContext)
			{
				if (_started) nextFrame();
				else render();
			}
		}
		
		
		/**
		 * @private
		 */
		private function onKey(e:KeyboardEvent):void
		{
			if (!_started) return;
			makeCurrent();
			_stage2D.dispatchEvent(new KeyboardEvent2D(e.type, e.charCode, e.keyCode,
				e.keyLocation, e.ctrlKey, e.altKey, e.shiftKey));
		}
		
		
		/**
		 * @private
		 */
		private function onResize(e:Event):void
		{
			var stage:Stage = e.target as Stage;
			_stage2D.dispatchEvent(new ResizeEvent2D(Event.RESIZE, stage.stageWidth,
				stage.stageHeight));
		}
		
		
		/**
		 * @private
		 */
		private function onMouseLeave(e:Event):void
		{
			_touchProcessor.enqueueMouseLeftStage();
		}


		/**
		 * @private
		 */
		private function onTouch(e:Event):void
		{
			if (!_started) return;
			
			var globalX:Number;
			var globalY:Number;
			var touchID:int;
			var phase:String;
			var pressure:Number = 1.0;
			var width:Number = 1.0;
			var height:Number = 1.0;
			
			/* Figure out general touch properties. */
			if (e is MouseEvent)
			{
				var mouseEvent:MouseEvent = e as MouseEvent;
				globalX = mouseEvent.stageX;
				globalY = mouseEvent.stageY;
				touchID = 0;
				
				// MouseEvent.buttonDown returns true for both left and right button (AIR supports
				// the right mouse button). We only want to react on the left button for now,
				// so we have to save the state for the left button manually.
				if (e.type == MouseEvent.MOUSE_DOWN) _leftMouseDown = true;
				else if (e.type == MouseEvent.MOUSE_UP) _leftMouseDown = false;
			}
			else
			{
				var touchEvent:TouchEvent = e as TouchEvent;
				globalX = touchEvent.stageX;
				globalY = touchEvent.stageY;
				touchID = touchEvent.touchPointID;
				pressure = touchEvent.pressure;
				width = touchEvent.sizeX;
				height = touchEvent.sizeY;
			}
			
			/* Figure out touch phase. */
			switch (e.type)
			{
				case TouchEvent.TOUCH_BEGIN:
					phase = TouchPhase2D.BEGAN;
					break;
				case TouchEvent.TOUCH_MOVE:
					phase = TouchPhase2D.MOVED;
					break;
				case TouchEvent.TOUCH_END:
					phase = TouchPhase2D.ENDED;
					break;
				case MouseEvent.MOUSE_DOWN:
					phase = TouchPhase2D.BEGAN;
					break;
				case MouseEvent.MOUSE_UP:
					phase = TouchPhase2D.ENDED;
					break;
				case MouseEvent.MOUSE_MOVE:
					phase = (_leftMouseDown ? TouchPhase2D.MOVED : TouchPhase2D.HOVER);
					break;
			}
			
			/* Move position into viewport bounds. */
			globalX = _stage2D.stageWidth * (globalX - _viewPort.x) / _viewPort.width;
			globalY = _stage2D.stageHeight * (globalY - _viewPort.y) / _viewPort.height;
			
			/* Enqueue touch in touch processor. */
			_touchProcessor.enqueue(touchID, phase, globalX, globalY, pressure, width, height);
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Private Methods
		//-----------------------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		private function initialize():void
		{
			makeCurrent();
			initializeGraphicsAPI();
			initializeRoot();
			
			_touchProcessor.simulateMultitouch = _simulateMultitouch;
			_lastFrameTimestamp = getTimer() / 1000.0;
		}
		
		
		/**
		 * @private
		 */
		private function initializeGraphicsAPI():void
		{
			_context = _stage3D.context3D;
			_context.enableErrorChecking = _enableErrorChecking;
			contextData[PROGRAM_DATA_NAME] = new Dictionary();

			updateViewPort(true);

			Log.verbose("Render2D System v" + VERSION + " - Initialization complete.", this);
			Log.verbose("Display Driver: " + _context.driverInfo, this);
			
			dispatchEventWith(Event2D.CONTEXT3D_CREATE, false, _context);
		}
		
		
		/**
		 * @private
		 */
		private function initializeRoot():void
		{
			_stage2D.addChildAt(_root, 0);
			dispatchEventWith(Event2D.ROOT_CREATED, false, _root);
		}
		
		
		/**
		 * @private
		 */
		private function updateViewPort(updateAliasing:Boolean = false):void
		{
			/* The last set viewport is stored in a variable; that way, people can modify the
			 * viewPort directly (without a copy) and we still know if it has changed. */
			if (updateAliasing
				|| _previousViewPort.width != _viewPort.width
				|| _previousViewPort.height != _viewPort.height
				|| _previousViewPort.x != _viewPort.x
				|| _previousViewPort.y != _viewPort.y)
			{
				_previousViewPort.setTo(_viewPort.x, _viewPort.y, _viewPort.width, _viewPort.height);

				// Constrained mode requires that the viewport is within the native stage bounds;
				// thus, we use a clipped viewport when configuring the back buffer. (In baseline
				// mode, that's not necessary, but it does not hurt either.)
				_clippedViewPort = _viewPort.intersection(new Rectangle(0, 0, _stage.stageWidth,
					_stage.stageHeight));
				
				if (!_shareContext)
				{
					// setting x and y might move the context to invalid bounds (since changing
					// the size happens in a separate operation) -- so we have no choice but to
					// set the backbuffer to a very small size first, to be on the safe side.
					if (_profile == "baselineConstrained")
					{
						_renderSupport.configureBackBuffer(32, 32, _antiAliasing, false);
					}
					
					_stage3D.x = _clippedViewPort.x;
					_stage3D.y = _clippedViewPort.y;
					
					_renderSupport.configureBackBuffer(_clippedViewPort.width,
						_clippedViewPort.height, _antiAliasing, false);
				}
				else
				{
					_renderSupport.backBufferWidth = _clippedViewPort.width;
					_renderSupport.backBufferHeight = _clippedViewPort.height;
				}
			}
		}
		
		
		/**
		 * @private
		 */
		private function updateNativeOverlay():void
		{
			_nativeOverlay.x = _viewPort.x;
			_nativeOverlay.y = _viewPort.y;
			_nativeOverlay.scaleX = _viewPort.width / _stage2D.stageWidth;
			_nativeOverlay.scaleY = _viewPort.height / _stage2D.stageHeight;
		}
		
		
		/**
		 * @private
		 */
		private function showOnScreenError(message:String):void
		{
			var tf:TextField = new TextField();
			var format:TextFormat = new TextFormat("Verdana", 12, 0xFFFFFF);
			format.align = TextFormatAlign.CENTER;
			tf.defaultTextFormat = format;
			tf.wordWrap = true;
			tf.width = _stage2D.stageWidth * 0.75;
			tf.autoSize = TextFieldAutoSize.CENTER;
			tf.text = message;
			tf.x = (_stage2D.stageWidth - tf.width) / 2;
			tf.y = (_stage2D.stageHeight - tf.height) / 2;
			tf.background = true;
			tf.backgroundColor = 0x440000;
			nativeOverlay.addChild(tf);
		}
	}
}
