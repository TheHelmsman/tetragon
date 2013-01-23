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
	import tetragon.view.render2d.core.RenderSupport2D;
	import tetragon.view.render2d.core.VertexData2D;

	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;


	/** A Quad represents a rectangle with a uniform color or a color gradient.
	 *  
	 *  <p>You can set one color per vertex. The colors will smoothly fade into each other over the area
	 *  of the quad. To display a simple linear color gradient, assign one color to vertices 0 and 1 and 
	 *  another color to vertices 2 and 3. </p> 
	 *
	 *  <p>The indices of the vertices are arranged like this:</p>
	 *  
	 *  <pre>
	 *  0 - 1
	 *  | / |
	 *  2 - 3
	 *  </pre>
	 * 
	 *  @see Image
	 */
	public class Quad2D extends DisplayObject2D
	{
		private var _tinted:Boolean;
		/** The raw vertex data of the quad. */
		protected var _vertexData:VertexData2D;
		
		/** Helper objects. */
		private static var _helperPoint:Point = new Point();
		private static var _helperMatrix:Matrix = new Matrix();


		/** Creates a quad with a certain size and color. The last parameter controls if the 
		 *  alpha value should be premultiplied into the color values on rendering, which can
		 *  influence blending output. You can use the default value in most cases.  */
		public function Quad2D(width:Number, height:Number, color:uint = 0xffffff, premultipliedAlpha:Boolean = true)
		{
			_tinted = color != 0xffffff;

			_vertexData = new VertexData2D(4, premultipliedAlpha);
			_vertexData.setPosition(0, 0.0, 0.0);
			_vertexData.setPosition(1, width, 0.0);
			_vertexData.setPosition(2, 0.0, height);
			_vertexData.setPosition(3, width, height);
			_vertexData.setUniformColor(color);

			onVertexDataChanged();
		}


		/** Call this method after manually changing the contents of 'mVertexData'. */
		protected function onVertexDataChanged():void
		{
			// override in subclasses, if necessary
		}


		/** @inheritDoc */
		public override function getBounds(targetSpace:DisplayObject2D, resultRect:Rectangle = null):Rectangle
		{
			if (resultRect == null) resultRect = new Rectangle();

			if (targetSpace == this) // optimization
			{
				_vertexData.getPosition(3, _helperPoint);
				resultRect.setTo(0.0, 0.0, _helperPoint.x, _helperPoint.y);
			}
			else if (targetSpace == parent && rotation == 0.0) // optimization
			{
				var scaleX:Number = this.scaleX;
				var scaleY:Number = this.scaleY;
				_vertexData.getPosition(3, _helperPoint);
				resultRect.setTo(x - pivotX * scaleX, y - pivotY * scaleY, _helperPoint.x * scaleX, _helperPoint.y * scaleY);
				if (scaleX < 0)
				{
					resultRect.width *= -1;
					resultRect.x -= resultRect.width;
				}
				if (scaleY < 0)
				{
					resultRect.height *= -1;
					resultRect.y -= resultRect.height;
				}
			}
			else
			{
				getTransformationMatrix(targetSpace, _helperMatrix);
				_vertexData.getBounds(_helperMatrix, 0, 4, resultRect);
			}

			return resultRect;
		}


		/** Returns the color of a vertex at a certain index. */
		public function getVertexColor(vertexID:int):uint
		{
			return _vertexData.getColor(vertexID);
		}


		/** Sets the color of a vertex at a certain index. */
		public function setVertexColor(vertexID:int, color:uint):void
		{
			_vertexData.setColor(vertexID, color);
			onVertexDataChanged();

			if (color != 0xffffff) _tinted = true;
			else _tinted = _vertexData.tinted;
		}


		/** Returns the alpha value of a vertex at a certain index. */
		public function getVertexAlpha(vertexID:int):Number
		{
			return _vertexData.getAlpha(vertexID);
		}


		/** Sets the alpha value of a vertex at a certain index. */
		public function setVertexAlpha(vertexID:int, alpha:Number):void
		{
			_vertexData.setAlpha(vertexID, alpha);
			onVertexDataChanged();

			if (alpha != 1.0) _tinted = true;
			else _tinted = _vertexData.tinted;
		}


		/** Returns the color of the quad, or of vertex 0 if vertices have different colors. */
		public function get color():uint
		{
			return _vertexData.getColor(0);
		}


		/** Sets the colors of all vertices to a certain value. */
		public function set color(value:uint):void
		{
			for (var i:int = 0; i < 4; ++i)
				setVertexColor(i, value);

			if (value != 0xffffff || alpha != 1.0) _tinted = true;
			else _tinted = _vertexData.tinted;
		}


		/** @inheritDoc **/
		public override function set alpha(value:Number):void
		{
			super.alpha = value;

			if (value < 1.0) _tinted = true;
			else _tinted = _vertexData.tinted;
		}


		/** Copies the raw vertex data to a VertexData instance. */
		public function copyVertexDataTo(targetData:VertexData2D, targetVertexID:int = 0):void
		{
			_vertexData.copyTo(targetData, targetVertexID);
		}


		/** @inheritDoc */
		public override function render(support:RenderSupport2D, parentAlpha:Number):void
		{
			support.batchQuad(this, parentAlpha);
		}


		/** Returns true if the quad (or any of its vertices) is non-white or non-opaque. */
		public function get tinted():Boolean
		{
			return _tinted;
		}
	}
}
