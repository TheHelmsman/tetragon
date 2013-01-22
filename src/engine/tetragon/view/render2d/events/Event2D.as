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
package tetragon.view.render2d.events
{
	import tetragon.view.render2d.core.render2d_internal;

	import com.hexagonstar.util.string.formatString;

	import flash.utils.getQualifiedClassName;

	use namespace render2d_internal;
	/** Event objects are passed as parameters to event listeners when an event occurs.  
	 *  This is Render2D's version of the Flash Event class. 
	 *
	 *  <p>EventDispatchers create instances of this class and send them to registered listeners. 
	 *  An event object contains information that characterizes an event, most importantly the 
	 *  event type and if the event bubbles. The target of an event is the object that 
	 *  dispatched it.</p>
	 * 
	 *  <p>For some event types, this information is sufficient; other events may need additional 
	 *  information to be carried to the listener. In that case, you can subclass "Event" and add 
	 *  properties with all the information you require. The "EnterFrameEvent" is an example for 
	 *  this practice; it adds a property about the time that has passed since the last frame.</p>
	 * 
	 *  <p>Furthermore, the event class contains methods that can stop the event from being 
	 *  processed by other listeners - either completely or at the next bubble stage.</p>
	 * 
	 *  @see EventDispatcher
	 */
	public class Event2D
	{
		/** Event type for a display object that is added to a parent. */
		public static const ADDED:String = "added";
		/** Event type for a display object that is added to the stage */
		public static const ADDED_TO_STAGE:String = "addedToStage";
		/** Event type for a display object that is entering a new frame. */
		public static const ENTER_FRAME:String = "enterFrame";
		/** Event type for a display object that is removed from its parent. */
		public static const REMOVED:String = "removed";
		/** Event type for a display object that is removed from the stage. */
		public static const REMOVED_FROM_STAGE:String = "removedFromStage";
		/** Event type for a triggered button. */
		public static const TRIGGERED:String = "triggered";
		/** Event type for a display object that is being flattened. */
		public static const FLATTEN:String = "flatten";
		/** Event type for a resized Flash Player. */
		public static const RESIZE:String = "resize";
		/** Event type that may be used whenever something finishes. */
		public static const COMPLETE:String = "complete";
		/** Event type for a (re)created stage3D rendering context. */
		public static const CONTEXT3D_CREATE:String = "context3DCreate";
		/** Event type that indicates that the root DisplayObject has been created. */
		public static const ROOT_CREATED:String = "rootCreated";
		/** Event type for an animated object that requests to be removed from the juggler. */
		public static const REMOVE_FROM_JUGGLER:String = "removeFromJuggler";
		/** An event type to be utilized in custom events. Not used by Render2D right now. */
		public static const CHANGE:String = "change";
		/** An event type to be utilized in custom events. Not used by Render2D right now. */
		public static const CANCEL:String = "cancel";
		/** An event type to be utilized in custom events. Not used by Render2D right now. */
		public static const SCROLL:String = "scroll";
		/** An event type to be utilized in custom events. Not used by Render2D right now. */
		public static const OPEN:String = "open";
		/** An event type to be utilized in custom events. Not used by Render2D right now. */
		public static const CLOSE:String = "close";
		/** An event type to be utilized in custom events. Not used by Render2D right now. */
		public static const SELECT:String = "select";
		private static var sEventPool:Vector.<Event2D> = new <Event2D>[];
		private var mTarget:EventDispatcher2D;
		private var mCurrentTarget:EventDispatcher2D;
		private var mType:String;
		private var mBubbles:Boolean;
		private var mStopsPropagation:Boolean;
		private var mStopsImmediatePropagation:Boolean;
		private var mData:Object;


		/** Creates an event object that can be passed to listeners. */
		public function Event2D(type:String, bubbles:Boolean = false, data:Object = null)
		{
			mType = type;
			mBubbles = bubbles;
			mData = data;
		}


		/** Prevents listeners at the next bubble stage from receiving the event. */
		public function stopPropagation():void
		{
			mStopsPropagation = true;
		}


		/** Prevents any other listeners from receiving the event. */
		public function stopImmediatePropagation():void
		{
			mStopsPropagation = mStopsImmediatePropagation = true;
		}


		/** Returns a description of the event, containing type and bubble information. */
		public function toString():String
		{
			return formatString("[{0} type=\"{1}\" bubbles={2}]", getQualifiedClassName(this).split("::").pop(), mType, mBubbles);
		}


		/** Indicates if event will bubble. */
		public function get bubbles():Boolean
		{
			return mBubbles;
		}


		/** The object that dispatched the event. */
		public function get target():EventDispatcher2D
		{
			return mTarget;
		}


		/** The object the event is currently bubbling at. */
		public function get currentTarget():EventDispatcher2D
		{
			return mCurrentTarget;
		}


		/** A string that identifies the event. */
		public function get type():String
		{
			return mType;
		}


		/** Arbitrary data that is attached to the event. */
		public function get data():Object
		{
			return mData;
		}


		// properties for internal use
		/** @private */
		internal function setTarget(value:EventDispatcher2D):void
		{
			mTarget = value;
		}


		/** @private */
		internal function setCurrentTarget(value:EventDispatcher2D):void
		{
			mCurrentTarget = value;
		}


		/** @private */
		internal function setData(value:Object):void
		{
			mData = value;
		}


		/** @private */
		internal function get stopsPropagation():Boolean
		{
			return mStopsPropagation;
		}


		/** @private */
		internal function get stopsImmediatePropagation():Boolean
		{
			return mStopsImmediatePropagation;
		}


		// event pooling
		/** @private */
		render2d_internal static function fromPool(type:String, bubbles:Boolean = false, data:Object = null):Event2D
		{
			if (sEventPool.length) return (sEventPool.pop() as Event2D).reset(type, bubbles, data);
			else return new Event2D(type, bubbles, data);
		}


		/** @private */
		render2d_internal static function toPool(event:Event2D):void
		{
			event.mData = event.mTarget = event.mCurrentTarget = null;
			sEventPool.push(event);
		}


		/** @private */
		render2d_internal function reset(type:String, bubbles:Boolean = false, data:Object = null):Event2D
		{
			mType = type;
			mBubbles = bubbles;
			mData = data;
			mTarget = mCurrentTarget = null;
			mStopsPropagation = mStopsImmediatePropagation = false;
			return this;
		}
	}
}