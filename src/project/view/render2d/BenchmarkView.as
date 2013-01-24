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
	import tetragon.Main;
	import tetragon.debug.Log;
	import tetragon.view.render2d.core.Render2D;
	import tetragon.view.render2d.display.Image2D;
	import tetragon.view.render2d.display.View2D;
	import tetragon.view.render2d.events.EnterFrameEvent2D;
	import tetragon.view.render2d.events.Event2D;
	import tetragon.view.render2d.textures.Texture2D;

	import flash.system.System;
	
	
	/**
	 * BenchmarkView class
	 *
	 * @author hexagon
	 */
	public class BenchmarkView extends View2D
	{
		//-----------------------------------------------------------------------------------------
		// Properties
		//-----------------------------------------------------------------------------------------
		
		private var _texture:Texture2D;
        private var mFrameCount:int;
        private var mElapsed:Number;
        private var mFailCount:int;
        private var mWaitFrames:int;
		
		
		//-----------------------------------------------------------------------------------------
		// Constructor
		//-----------------------------------------------------------------------------------------
		
		/**
		 * Creates a new instance of the class.
		 */
		public function BenchmarkView()
		{
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Public Methods
		//-----------------------------------------------------------------------------------------
		
		
		//-----------------------------------------------------------------------------------------
		// Accessors
		//-----------------------------------------------------------------------------------------
		
		
		//-----------------------------------------------------------------------------------------
		// Callback Handlers
		//-----------------------------------------------------------------------------------------
		
		override protected function onAddedToStage(e:Event2D):void
		{
			super.onAddedToStage(e);
			
			_texture = Texture2D.fromBitmapData(Main.instance.resourceManager.resourceIndex.getImage("123"));
			
			mFailCount = 0;
			mWaitFrames = 2;
			mFrameCount = 0;
			
			addEventListener(EnterFrameEvent2D.ENTER_FRAME, onEnterFrame);
		}
		
		
		private function onEnterFrame(e:EnterFrameEvent2D):void
		{
			mElapsed += e.passedTime;
			mFrameCount++;
			
			if (mFrameCount % mWaitFrames == 0)
			{
				var fps:Number = mWaitFrames / mElapsed;
				var targetFps:int = Render2D.current.stage.frameRate;
				
				if (Math.ceil(fps) >= targetFps)
				{
					mFailCount = 0;
					addTestObjects();
				}
				else
				{
					mFailCount++;

					if (mFailCount > 20)
						mWaitFrames = 5;
					// slow down creation process to be more exact
					if (mFailCount > 30)
						mWaitFrames = 10;
					if (mFailCount == 40)
						benchmarkComplete();
					// target fps not reached for a while
				}

				mElapsed = mFrameCount = 0;
			}

			var numObjects:int = numChildren;
			var passedTime:Number = e.passedTime;

			for (var i:int = 0; i < numObjects; ++i)
			{
				getChildAt(i).rotation += Math.PI / 2 * passedTime;
			}
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Private Methods
		//-----------------------------------------------------------------------------------------
		
		private function addTestObjects():void
		{
			var padding:int = 15;
			var numObjects:int = mFailCount > 20 ? 2 : 10;
			
			for (var i:int = 0; i < numObjects; ++i)
			{
				var img:Image2D = new Image2D(_texture);
				//var q:Quad2D = new Quad2D(40, 40, Math.random() * 0xFFFFFF);
				img.x = padding + Math.random() * (_frameWidth - 2 * padding);
				img.y = padding + Math.random() * (_frameHeight - 2 * padding);
				addChild(img);
			}
		}


		private function benchmarkComplete():void
		{
			removeEventListener(EnterFrameEvent2D.ENTER_FRAME, onEnterFrame);
			
			var fps:int = Render2D.current.stage.frameRate;

			Log.trace("Benchmark complete!");
			Log.trace("FPS: " + fps);
			Log.trace("Number of objects: " + numChildren);
			
			System.pauseForGCIfCollectionImminent();
		}
	}
}
