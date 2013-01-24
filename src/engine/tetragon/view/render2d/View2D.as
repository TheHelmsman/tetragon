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
package tetragon.view.render2d
{
	import tetragon.view.render2d.events.Event2D;
	import tetragon.view.IView;
	import tetragon.view.render2d.display.Quad2D;
	import tetragon.view.render2d.display.Sprite2D;

	import flash.geom.Rectangle;
	
	
	/**
	 * View2D class
	 *
	 * @author hexagon
	 */
	public class View2D extends Sprite2D implements IView
	{
		// -----------------------------------------------------------------------------------------
		// Properties
		// -----------------------------------------------------------------------------------------
		
		protected var _backgroundColor:uint;
		protected var _background:Quad2D;
		protected var _viewPort:Rectangle;
		
		
		// -----------------------------------------------------------------------------------------
		// Constructor
		// -----------------------------------------------------------------------------------------
		
		/**
		 * Creates a new instance of the class.
		 */
		public function View2D(x:int, y:int, w:int, h:int, backgroundColor:uint)
		{
			_viewPort = new Rectangle(x, y, w, h);
			_backgroundColor = backgroundColor;
			
			super();
			setup();
			
			addEventListener(Event2D.ADDED_TO_STAGE, onAddedToStage);
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Public Methods
		// -----------------------------------------------------------------------------------------
		
		
		// -----------------------------------------------------------------------------------------
		// Accessors
		// -----------------------------------------------------------------------------------------
		
		public function get viewPort():Rectangle
		{
			return _viewPort;
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Callback Handlers
		// -----------------------------------------------------------------------------------------
		
		protected function onAddedToStage(e:Event2D):void
		{
			removeEventListener(Event2D.ADDED_TO_STAGE, onAddedToStage);
			
			/* Test Code */
			for (var i:uint = 0; i < 100; i++)
			{
				var q:Quad2D = new Quad2D(40, 40, Math.random() * 0xFFFFFF);
				q.x = Math.random() * _viewPort.width;
				q.y = Math.random() * _viewPort.height;
				addChild(q);
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
			x = _viewPort.x;
			y = _viewPort.y;
			
			_background = new Quad2D(_viewPort.width, _viewPort.height);
			_background.color = _backgroundColor;
			addChild(_background);
		}
	}
}
