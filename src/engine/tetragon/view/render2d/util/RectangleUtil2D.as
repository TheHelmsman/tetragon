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
package tetragon.view.render2d.util
{
	import com.hexagonstar.exception.AbstractClassException;

	import flash.geom.Rectangle;

	/** A utility class containing methods related to the Rectangle class. */
	public class RectangleUtil2D
	{
		/** @private */
		public function RectangleUtil2D()
		{
			throw new AbstractClassException(this);
		}


		/** Calculates the intersection between two Rectangles. If the rectangles do not intersect,
		 *  this method returns an empty Rectangle object with its properties set to 0. */
		public static function intersect(rect1:Rectangle, rect2:Rectangle, resultRect:Rectangle = null):Rectangle
		{
			if (resultRect == null) resultRect = new Rectangle();

			var left:Number = Math.max(rect1.x, rect2.x);
			var right:Number = Math.min(rect1.x + rect1.width, rect2.x + rect2.width);
			var top:Number = Math.max(rect1.y, rect2.y);
			var bottom:Number = Math.min(rect1.y + rect1.height, rect2.y + rect2.height);

			if (left > right || top > bottom)
				resultRect.setEmpty();
			else
				resultRect.setTo(left, top, right - left, bottom - top);

			return resultRect;
		}


		/** Calculates a rectangle with the same aspect ratio as the given 'rectangle',
		 *  centered within 'into'.  
		 * 
		 *  <p>This method is useful for calculating the optimal viewPort for a certain display 
		 *  size. You can use different scale modes to specify how the result should be calculated;
		 *  furthermore, you can avoid pixel alignment errors by only allowing whole-number  
		 *  multipliers/divisors (e.g. 3, 2, 1, 1/2, 1/3).</p>
		 *  
		 *  @see Render2D.utils.ScaleMode
		 */
		public static function fit(rectangle:Rectangle, into:Rectangle, scaleMode:String = "showAll", pixelPerfect:Boolean = false, resultRect:Rectangle = null):Rectangle
		{
			if (!ScaleMode2D.isValid(scaleMode)) throw new ArgumentError("Invalid scaleMode: " + scaleMode);
			if (resultRect == null) resultRect = new Rectangle();

			var width:Number = rectangle.width;
			var height:Number = rectangle.height;
			var factorX:Number = into.width / width;
			var factorY:Number = into.height / height;
			var factor:Number = 1.0;

			if (scaleMode == ScaleMode2D.SHOW_ALL)
			{
				factor = factorX < factorY ? factorX : factorY;
				if (pixelPerfect) factor = nextSuitableScaleFactor(factor, false);
			}
			else if (scaleMode == ScaleMode2D.NO_BORDER)
			{
				factor = factorX > factorY ? factorX : factorY;
				if (pixelPerfect) factor = nextSuitableScaleFactor(factor, true);
			}

			width *= factor;
			height *= factor;

			resultRect.setTo(into.x + (into.width - width) / 2, into.y + (into.height - height) / 2, width, height);

			return resultRect;
		}


		/** Calculates the next whole-number multiplier or divisor, moving either up or down. */
		private static function nextSuitableScaleFactor(factor:Number, up:Boolean):Number
		{
			var divisor:Number = 1.0;

			if (up)
			{
				if (factor >= 0.5) return Math.ceil(factor);
				else
				{
					while (1.0 / (divisor + 1) > factor)
						++divisor;
				}
			}
			else
			{
				if (factor >= 1.0) return Math.floor(factor);
				else
				{
					while (1.0 / divisor > factor)
						++divisor;
				}
			}

			return 1.0 / divisor;
		}
	}
}