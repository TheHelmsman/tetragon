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
package tetragon.view.render2d.display
{
	import tetragon.Main;
	import tetragon.debug.Log;
	import tetragon.view.IView;
	import tetragon.view.render2d.core.Render2D;
	import tetragon.view.render2d.core.RenderSupport2D;
	import tetragon.view.render2d.events.EnterFrameEvent2D;
	import tetragon.view.render2d.events.Event2D;
	import tetragon.view.render2d.textures.Texture2D;

	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	
	
	/**
	 * View2D class
	 *
	 * @author hexagon
	 */
	public class View2D extends DisplayObjectContainer2D implements IView
	{
		// -----------------------------------------------------------------------------------------
		// Properties
		// -----------------------------------------------------------------------------------------
		
		private var _clipRect:Rectangle;
		private var _clipped:Boolean;
		
		protected var _viewWidth:int;
		protected var _viewHeight:int;
		protected var _backgroundColor:uint;
		protected var _background:Quad2D;
		
		protected var _container:Sprite2D;
		
		private var _texture:Texture2D;
        private var mFrameCount:int;
        private var mElapsed:Number;
        private var mFailCount:int;
        private var mWaitFrames:int;
		
		
		// -----------------------------------------------------------------------------------------
		// Constructor
		// -----------------------------------------------------------------------------------------
		
		/**
		 * Creates a new instance of the class.
		 */
		public function View2D(width:int, height:int, backgroundColor:uint, clipped:Boolean = true)
		{
			_viewWidth = width;
			_viewHeight = height;
			_backgroundColor = backgroundColor;
			_clipped = clipped;
			
			super();
			setup();
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Public Methods
		// -----------------------------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		public override function render(support:RenderSupport2D, alpha:Number):void
		{
			if (!_clipped)
			{
				super.render(support, alpha);
			}
			else
			{
				support.finishQuadBatch();
				support.scissorRectangle = _clipRect;
				
				super.render(support, alpha);
				
				support.finishQuadBatch();
				support.scissorRectangle = null;
			}
		}
		
		
		/**
		 * @inheritDoc
		 */
		public override function hitTest(localPoint:Point, forTouch:Boolean = false):DisplayObject2D
		{
			// without a clip rect, the sprite should behave just like before
			if (!_clipped) return super.hitTest(localPoint, forTouch);
			
			// on a touch test, invisible or untouchable objects cause the test to fail
			if (forTouch && (!visible || !touchable)) return null;
			
			if (_clipRect.containsPoint(localToGlobal(localPoint)))
			{
				return super.hitTest(localPoint, forTouch);
			}
			else
			{
				return null;
			}
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Accessors
		// -----------------------------------------------------------------------------------------
		
		override public function set x(v:Number):void
		{
			super.x = v;
			if (_clipRect) _clipRect.x = v;
		}
		
		
		override public function set y(v:Number):void
		{
			super.y = v;
			if (_clipRect) _clipRect.y = v;
		}
		
		
		public function get clipRect():Rectangle
		{
			return _clipRect;
		}
		public function set clipRect(v:Rectangle):void
		{
			if (v)
			{
				if (!_clipRect) _clipRect = v.clone();
				else _clipRect.setTo(v.x, v.y, v.width, v.height);
			}
			else
			{
				_clipRect = null;
			}
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Callback Handlers
		// -----------------------------------------------------------------------------------------
		
		protected function onAddedToStage(e:Event2D):void
		{
			removeEventListener(Event2D.ADDED_TO_STAGE, onAddedToStage);
			
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

			var numObjects:int = _container.numChildren;
			var passedTime:Number = e.passedTime;

			for (var i:int = 0; i < numObjects; ++i)
			{
				_container.getChildAt(i).rotation += Math.PI / 2 * passedTime;
			}
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Private Methods
		// -----------------------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		protected function setup():void
		{
			if (_clipped)
			{
				_clipRect = new Rectangle(0, 0, _viewWidth, _viewHeight);
			}
			
			_background = new Quad2D(_viewWidth, _viewHeight);
			_background.color = _backgroundColor;
			addChild(_background);
			
			_container = new Sprite2D();
			addChild(_container);
			
			addEventListener(Event2D.ADDED_TO_STAGE, onAddedToStage);
		}
		
		
		private function addTestObjects():void
		{
			var padding:int = 15;
			var numObjects:int = mFailCount > 20 ? 2 : 10;
			
			for (var i:int = 0; i < numObjects; ++i)
			{
				var img:Image2D = new Image2D(_texture);
				//var q:Quad2D = new Quad2D(40, 40, Math.random() * 0xFFFFFF);
				img.x = padding + Math.random() * (_viewWidth - 2 * padding);
				img.y = padding + Math.random() * (_viewHeight - 2 * padding);
				_container.addChild(img);
			}
		}


		private function benchmarkComplete():void
		{
			removeEventListener(EnterFrameEvent2D.ENTER_FRAME, onEnterFrame);
			
			var fps:int = Render2D.current.stage.frameRate;

			Log.trace("Benchmark complete!");
			Log.trace("FPS: " + fps);
			Log.trace("Number of objects: " + _container.numChildren);
			
			System.pauseForGCIfCollectionImminent();
		}
	}
}
