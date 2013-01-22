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
	import tetragon.view.render2d.core.render2d_internal;
	import tetragon.view.render2d.events.Event2D;
	import tetragon.view.render2d.filters.FragmentFilter2D;
	import tetragon.view.render2d.util.MatrixUtil2D;

	import com.hexagonstar.exception.AbstractClassException;

	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.getQualifiedClassName;

	use namespace render2d_internal;
	/**
	 *  A DisplayObjectContainer represents a collection of display objects.
	 *  It is the base class of all display objects that act as a container for other objects. By 
	 *  maintaining an ordered list of children, it defines the back-to-front positioning of the 
	 *  children within the display tree.
	 *  
	 *  <p>A container does not a have size in itself. The width and height properties represent the 
	 *  extents of its children. Changing those properties will scale all children accordingly.</p>
	 *  
	 *  <p>As this is an abstract class, you can't instantiate it directly, but have to 
	 *  use a subclass instead. The most lightweight container class is "Sprite".</p>
	 *  
	 *  <strong>Adding and removing children</strong>
	 *  
	 *  <p>The class defines methods that allow you to add or remove children. When you add a child, 
	 *  it will be added at the frontmost position, possibly occluding a child that was added 
	 *  before. You can access the children via an index. The first child will have index 0, the 
	 *  second child index 1, etc.</p> 
	 *  
	 *  Adding and removing objects from a container triggers non-bubbling events.
	 *  
	 *  <ul>
	 *   <li><code>Event.ADDED</code>: the object was added to a parent.</li>
	 *   <li><code>Event.ADDED_TO_STAGE</code>: the object was added to a parent that is 
	 *       connected to the stage, thus becoming visible now.</li>
	 *   <li><code>Event.REMOVED</code>: the object was removed from a parent.</li>
	 *   <li><code>Event.REMOVED_FROM_STAGE</code>: the object was removed from a parent that 
	 *       is connected to the stage, thus becoming invisible now.</li>
	 *  </ul>
	 *  
	 *  Especially the <code>ADDED_TO_STAGE</code> event is very helpful, as it allows you to 
	 *  automatically execute some logic (e.g. start an animation) when an object is rendered the 
	 *  first time.
	 *  
	 *  @see Sprite
	 *  @see DisplayObject
	 */
	public class DisplayObjectContainer2D extends DisplayObject2D
	{
		// members
		private var mChildren:Vector.<DisplayObject2D>;
		/** Helper objects. */
		private static var sHelperMatrix:Matrix = new Matrix();
		private static var sHelperPoint:Point = new Point();
		private static var sBroadcastListeners:Vector.<DisplayObject2D> = new <DisplayObject2D>[];


		// construction
		/** @private */
		public function DisplayObjectContainer2D()
		{
			if (Capabilities.isDebugger && getQualifiedClassName(this) == "Render2D.display::DisplayObjectContainer")
			{
				throw new AbstractClassException(this);
			}

			mChildren = new <DisplayObject2D>[];
		}


		/** Disposes the resources of all children. */
		public override function dispose():void
		{
			for (var i:int = mChildren.length - 1; i >= 0; --i)
				mChildren[i].dispose();

			super.dispose();
		}


		// child management
		/** Adds a child to the container. It will be at the frontmost position. */
		public function addChild(child:DisplayObject2D):DisplayObject2D
		{
			addChildAt(child, numChildren);
			return child;
		}


		/** Adds a child to the container at a certain index. */
		public function addChildAt(child:DisplayObject2D, index:int):DisplayObject2D
		{
			var numChildren:int = mChildren.length;

			if (index >= 0 && index <= numChildren)
			{
				child.removeFromParent();

				// 'splice' creates a temporary object, so we avoid it if it's not necessary
				if (index == numChildren) mChildren.push(child);
				else mChildren.splice(index, 0, child);

				child.setParent(this);
				child.dispatchEventWith(Event2D.ADDED, true);

				if (stage)
				{
					var container:DisplayObjectContainer2D = child as DisplayObjectContainer2D;
					if (container) container.broadcastEventWith(Event2D.ADDED_TO_STAGE);
					else child.dispatchEventWith(Event2D.ADDED_TO_STAGE);
				}

				return child;
			}
			else
			{
				throw new RangeError("Invalid child index");
			}
		}


		/** Removes a child from the container. If the object is not a child, nothing happens. 
		 *  If requested, the child will be disposed right away. */
		public function removeChild(child:DisplayObject2D, dispose:Boolean = false):DisplayObject2D
		{
			var childIndex:int = getChildIndex(child);
			if (childIndex != -1) removeChildAt(childIndex, dispose);
			return child;
		}


		/** Removes a child at a certain index. Children above the child will move down. If
		 *  requested, the child will be disposed right away. */
		public function removeChildAt(index:int, dispose:Boolean = false):DisplayObject2D
		{
			if (index >= 0 && index < numChildren)
			{
				var child:DisplayObject2D = mChildren[index];
				child.dispatchEventWith(Event2D.REMOVED, true);

				if (stage)
				{
					var container:DisplayObjectContainer2D = child as DisplayObjectContainer2D;
					if (container) container.broadcastEventWith(Event2D.REMOVED_FROM_STAGE);
					else child.dispatchEventWith(Event2D.REMOVED_FROM_STAGE);
				}

				child.setParent(null);
				index = mChildren.indexOf(child);
				// index might have changed by event handler
				if (index >= 0) mChildren.splice(index, 1);
				if (dispose) child.dispose();

				return child;
			}
			else
			{
				throw new RangeError("Invalid child index");
			}
		}


		/** Removes a range of children from the container (endIndex included). 
		 *  If no arguments are given, all children will be removed. */
		public function removeChildren(beginIndex:int = 0, endIndex:int = -1, dispose:Boolean = false):void
		{
			if (endIndex < 0 || endIndex >= numChildren)
				endIndex = numChildren - 1;

			for (var i:int = beginIndex; i <= endIndex; ++i)
				removeChildAt(beginIndex, dispose);
		}


		/** Returns a child object at a certain index. */
		public function getChildAt(index:int):DisplayObject2D
		{
			if (index >= 0 && index < numChildren)
				return mChildren[index];
			else
				throw new RangeError("Invalid child index");
		}


		/** Returns a child object with a certain name (non-recursively). */
		public function getChildByName(name:String):DisplayObject2D
		{
			var numChildren:int = mChildren.length;
			for (var i:int = 0; i < numChildren; ++i)
				if (mChildren[i].name == name) return mChildren[i];

			return null;
		}


		/** Returns the index of a child within the container, or "-1" if it is not found. */
		public function getChildIndex(child:DisplayObject2D):int
		{
			return mChildren.indexOf(child);
		}


		/** Moves a child to a certain index. Children at and after the replaced position move up.*/
		public function setChildIndex(child:DisplayObject2D, index:int):void
		{
			var oldIndex:int = getChildIndex(child);
			if (oldIndex == -1) throw new ArgumentError("Not a child of this container");
			mChildren.splice(oldIndex, 1);
			mChildren.splice(index, 0, child);
		}


		/** Swaps the indexes of two children. */
		public function swapChildren(child1:DisplayObject2D, child2:DisplayObject2D):void
		{
			var index1:int = getChildIndex(child1);
			var index2:int = getChildIndex(child2);
			if (index1 == -1 || index2 == -1) throw new ArgumentError("Not a child of this container");
			swapChildrenAt(index1, index2);
		}


		/** Swaps the indexes of two children. */
		public function swapChildrenAt(index1:int, index2:int):void
		{
			var child1:DisplayObject2D = getChildAt(index1);
			var child2:DisplayObject2D = getChildAt(index2);
			mChildren[index1] = child2;
			mChildren[index2] = child1;
		}


		/** Sorts the children according to a given function (that works just like the sort function
		 *  of the Vector class). */
		public function sortChildren(compareFunction:Function):void
		{
			mChildren = mChildren.sort(compareFunction);
		}


		/** Determines if a certain object is a child of the container (recursively). */
		public function contains(child:DisplayObject2D):Boolean
		{
			while (child)
			{
				if (child == this) return true;
				else child = child.parent;
			}
			return false;
		}


		/** @inheritDoc */
		public override function getBounds(targetSpace:DisplayObject2D, resultRect:Rectangle = null):Rectangle
		{
			if (resultRect == null) resultRect = new Rectangle();

			var numChildren:int = mChildren.length;

			if (numChildren == 0)
			{
				getTransformationMatrix(targetSpace, sHelperMatrix);
				MatrixUtil2D.transformCoords(sHelperMatrix, 0.0, 0.0, sHelperPoint);
				resultRect.setTo(sHelperPoint.x, sHelperPoint.y, 0, 0);
				return resultRect;
			}
			else if (numChildren == 1)
			{
				return mChildren[0].getBounds(targetSpace, resultRect);
			}
			else
			{
				var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
				var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;

				for (var i:int = 0; i < numChildren; ++i)
				{
					mChildren[i].getBounds(targetSpace, resultRect);
					minX = minX < resultRect.x ? minX : resultRect.x;
					maxX = maxX > resultRect.right ? maxX : resultRect.right;
					minY = minY < resultRect.y ? minY : resultRect.y;
					maxY = maxY > resultRect.bottom ? maxY : resultRect.bottom;
				}

				resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
				return resultRect;
			}
		}


		/** @inheritDoc */
		public override function hitTest(localPoint:Point, forTouch:Boolean = false):DisplayObject2D
		{
			if (forTouch && (!visible || !touchable))
				return null;

			var localX:Number = localPoint.x;
			var localY:Number = localPoint.y;

			var numChildren:int = mChildren.length;
			for (var i:int = numChildren - 1; i >= 0; --i) // front to back!
			{
				var child:DisplayObject2D = mChildren[i];
				getTransformationMatrix(child, sHelperMatrix);

				MatrixUtil2D.transformCoords(sHelperMatrix, localX, localY, sHelperPoint);
				var target:DisplayObject2D = child.hitTest(sHelperPoint, forTouch);

				if (target) return target;
			}

			return null;
		}


		/** @inheritDoc */
		public override function render(support:RenderSupport2D, parentAlpha:Number):void
		{
			var alpha:Number = parentAlpha * this.alpha;
			var numChildren:int = mChildren.length;
			var blendMode:String = support.blendMode;

			for (var i:int = 0; i < numChildren; ++i)
			{
				var child:DisplayObject2D = mChildren[i];

				if (child.hasVisibleArea)
				{
					var filter:FragmentFilter2D = child.filter;

					support.pushMatrix();
					support.transformMatrix(child);
					support.blendMode = child.blendMode;

					if (filter) filter.render(child, support, alpha);
					else child.render(support, alpha);

					support.blendMode = blendMode;
					support.popMatrix();
				}
			}
		}


		/** Dispatches an event on all children (recursively). The event must not bubble. */
		public function broadcastEvent(event:Event2D):void
		{
			if (event.bubbles)
				throw new ArgumentError("Broadcast of bubbling events is prohibited");

			// The event listeners might modify the display tree, which could make the loop crash.
			// Thus, we collect them in a list and iterate over that list instead.
			// And since another listener could call this method internally, we have to take
			// care that the static helper vector does not get currupted.

			var fromIndex:int = sBroadcastListeners.length;
			getChildEventListeners(this, event.type, sBroadcastListeners);
			var toIndex:int = sBroadcastListeners.length;

			for (var i:int = fromIndex; i < toIndex; ++i)
				sBroadcastListeners[i].dispatchEvent(event);

			sBroadcastListeners.length = fromIndex;
		}


		/** Dispatches an event with the given parameters on all children (recursively). 
		 *  The method uses an internal pool of event objects to avoid allocations. */
		public function broadcastEventWith(type:String, data:Object = null):void
		{
			var event:Event2D = Event2D.fromPool(type, false, data);
			broadcastEvent(event);
			Event2D.toPool(event);
		}


		private function getChildEventListeners(object:DisplayObject2D, eventType:String, listeners:Vector.<DisplayObject2D>):void
		{
			var container:DisplayObjectContainer2D = object as DisplayObjectContainer2D;

			if (object.hasEventListener(eventType))
				listeners.push(object);

			if (container)
			{
				var children:Vector.<DisplayObject2D> = container.mChildren;
				var numChildren:int = children.length;

				for (var i:int = 0; i < numChildren; ++i)
					getChildEventListeners(children[i], eventType, listeners);
			}
		}


		/** The number of children of this container. */
		public function get numChildren():int
		{
			return mChildren.length;
		}
	}
}
