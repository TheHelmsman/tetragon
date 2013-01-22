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
		
		private var _render2D:Render2D;
		
		
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
			_render2D = new Render2D(Render2DGameView, main.stage);
			_render2D.antiAliasing = 1;
			_render2D.start();
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
