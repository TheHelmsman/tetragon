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
package view.render2d
{
	import tetragon.view.obsolete.Screen;
	import tetragon.view.render2d.core.Render2D;

	import flash.display.Stage3D;
	import flash.events.Event;
	import flash.system.Capabilities;
	
	/**
	 * @author hexagon
	 */
	public class Render2DTestScreen extends Screen
	{
		//-----------------------------------------------------------------------------------------
		// Constants
		//-----------------------------------------------------------------------------------------
		
		public static const ID:String = "render2DTestScreen";
		
		
		//-----------------------------------------------------------------------------------------
		// Properties
		//-----------------------------------------------------------------------------------------
		
		private var _stage3D:Stage3D;
		private var _render2D1:Render2D;
		private var _render2D2:Render2D;
		private var _render2D3:Render2D;
		private var _render2D4:Render2D;

		
		//-----------------------------------------------------------------------------------------
		// Signals
		//-----------------------------------------------------------------------------------------
		
		
		//-----------------------------------------------------------------------------------------
		// Public Methods
		//-----------------------------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		override public function start():void
		{
			super.start();
			main.statsMonitor.toggle();
		}
		
		
		/**
		 * @inheritDoc
		 */
		override public function update():void
		{
			super.update();
		}
		
		
		/**
		 * @inheritDoc
		 */
		override public function reset():void
		{
			super.reset();
		}
		
		
		/**
		 * @inheritDoc
		 */
		override public function stop():void
		{
			super.stop();
		}
		
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			super.dispose();
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Accessors
		//-----------------------------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		override protected function get unload():Boolean
		{
			return true;
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Callback Handlers
		//-----------------------------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		override protected function onStageResize():void
		{
			super.onStageResize();
		}
		
		
		private function onContext3DCreated(e:Event):void
		{
			// Manually configure the context. Important: if you use a different
			// size than "stage.stageWidth x stage.stageHeight", you have to update
			// Starling's viewPort property accordingly.
			_stage3D.context3D.configureBackBuffer(main.stage.stageWidth, main.stage.stageHeight, 2, false);

			// Create our two Starling instances with the preconfigured stage3D.
			// Starling will recognize that the context is being shared, and
			// will not modify it.
			if (!_render2D1)
			{
				_render2D1 = new Render2D(Render2DGameView, null, _stage3D);
				_render2D1.enableErrorChecking = true;
				_render2D1.simulateMultitouch = true;
				_render2D1.antiAliasing = 2;
				_render2D1.start();

				_render2D2 = new Render2D(Render2DGameView2, null, _stage3D);
				_render2D2.enableErrorChecking = true;
				_render2D2.simulateMultitouch = true;
				_render2D2.antiAliasing = 2;
				_render2D2.start();

				_render2D3 = new Render2D(Render2DGameView3, null, _stage3D);
				_render2D3.enableErrorChecking = true;
				_render2D3.simulateMultitouch = true;
				_render2D3.antiAliasing = 2;
				_render2D3.start();
				
				_render2D4 = new Render2D(Render2DGameView4, null, _stage3D);
				_render2D4.enableErrorChecking = true;
				_render2D4.simulateMultitouch = true;
				_render2D4.antiAliasing = 2;
				_render2D4.start();
				
				addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
		}


		private function onEnterFrame(event:Event):void
		{
			// The back buffer needs to be cleared once per frame
			_stage3D.context3D.clear();

			// Advance both Starling instances
			_render2D1.nextFrame();
			_render2D2.nextFrame();
			_render2D3.nextFrame();
			_render2D4.nextFrame();

			// This moves the active back buffer into the foreground.
			_stage3D.context3D.present();
		}		
		
		
		//-----------------------------------------------------------------------------------------
		// Private Methods
		//-----------------------------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		override protected function setup():void
		{
			super.setup();
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function registerResources():void
		{
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function createChildren():void
		{
			var isApple:Boolean = Capabilities.manufacturer.match(/(iOS)|(Macintosh)/) != null;
			Render2D.handleLostContext = !isApple; // not required on Apple devices			
			
			_stage3D = main.stage.stage3Ds[0];
			_stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreated);
			_stage3D.requestContext3D();
			
//			var render2D1:Render2D = new Render2D(Render2DGameView, new Rectangle(0, 0, 512, 320), main.stage.stage3Ds[0]);
//			render2D1.antiAliasing = 1;
//			render2D1.simulateMultitouch = true;
//			render2D1.start();
//
//			var render2D2:Render2D = new Render2D(Render2DGameView, new Rectangle(512, 0, 512, 320), main.stage.stage3Ds[1]);
//			render2D2.antiAliasing = 1;
//			render2D2.simulateMultitouch = true;
//			render2D2.start();
//			
//			var render2D3:Render2D = new Render2D(Render2DGameView, new Rectangle(0, 320, 512, 320), main.stage.stage3Ds[2]);
//			render2D3.antiAliasing = 1;
//			render2D3.simulateMultitouch = true;
//			render2D3.start();
//			
//			var render2D4:Render2D = new Render2D(Render2DGameView, new Rectangle(512, 320, 512, 320), main.stage.stage3Ds[3]);
//			render2D4.antiAliasing = 1;
//			render2D4.simulateMultitouch = true;
//			render2D4.start();
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function registerChildren():void
		{
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function addChildren():void
		{
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function addListeners():void
		{
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function removeListeners():void
		{
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function executeBeforeStart():void
		{
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function updateDisplayText():void
		{
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function layoutChildren():void
		{
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function enableChildren():void
		{
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function disableChildren():void
		{
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function pauseChildren():void
		{
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function unpauseChildren():void
		{
		}
	}
}
