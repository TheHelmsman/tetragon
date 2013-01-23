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
	import tetragon.view.render2d.text.TextField2D;
	import tetragon.view.render2d.display.Quad2D;
	import tetragon.view.render2d.display.Sprite2D;
	import tetragon.view.render2d.events.Event2D;
	
	
	/**
	 * Render2DGameView class
	 *
	 * @author hexagon
	 */
	public class Render2DGameView4 extends Sprite2D
	{
		//-----------------------------------------------------------------------------------------
		// Properties
		//-----------------------------------------------------------------------------------------
		
		private var _quad:Quad2D;
		private var _tf:TextField2D;
		
		
		//-----------------------------------------------------------------------------------------
		// Constructor
		//-----------------------------------------------------------------------------------------
		
		/**
		 * Creates a new instance of the class.
		 */
		public function Render2DGameView4()
		{
			addEventListener(Event2D.ADDED_TO_STAGE, onAddedToStage);
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
		
		private function onAddedToStage(e:Event2D):void
		{
			removeEventListener(Event2D.ADDED_TO_STAGE, onAddedToStage);
			
			stage.color = Math.random() * 0xFFFFFF;
			pivotX = 100;
			pivotY = 100;
			x = 612;
			y = 420;
			
			_quad = new Quad2D(200, 200);
			_quad.setVertexColor(0, Math.random() * 0xFFFFFF);
			_quad.setVertexColor(1, Math.random() * 0xFFFFFF);
			_quad.setVertexColor(2, Math.random() * 0xFFFFFF);
			_quad.setVertexColor(3, Math.random() * 0xFFFFFF);
			addChild(_quad);
			
			_tf = new TextField2D(200, 200, "View4", "Verdana", 28, 0xFFFFFF);
			_tf.border = true;
			addChild(_tf);
			
			addEventListener(Event2D.ENTER_FRAME, onEnterFrame);
		}
		
		
		private function onEnterFrame(e:Event2D):void
		{
			rotation += 0.01;
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Private Methods
		//-----------------------------------------------------------------------------------------
		
	}
}
