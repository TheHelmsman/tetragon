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
package tetragon.view.render2d.core
{
	import tetragon.view.render2d.display.Stage2D;
	import tetragon.view.render2d.events.KeyboardEvent2D;
	import tetragon.view.render2d.events.Touch2D;
	import tetragon.view.render2d.events.TouchEvent2D;
	import tetragon.view.render2d.events.TouchPhase2D;

	import flash.geom.Point;
	import flash.utils.getDefinitionByName;

	use namespace render2d_internal;
	/** @private
	 *  The TouchProcessor is used internally to convert mouse and touch events of the conventional
	 *  Flash stage to Render2D's TouchEvents. */
	internal class TouchProcessor2D
	{
		private static const MULTITAP_TIME:Number = 0.3;
		private static const MULTITAP_DISTANCE:Number = 25;
		private var mStage:Stage2D;
		private var mElapsedTime:Number;
		private var mTouchMarker:TouchMarker2D;
		private var mCurrentTouches:Vector.<Touch2D>;
		private var mQueue:Vector.<Array>;
		private var mLastTaps:Vector.<Touch2D>;
		private var mShiftDown:Boolean = false;
		private var mCtrlDown:Boolean = false;
		/** Helper objects. */
		private static var sProcessedTouchIDs:Vector.<int> = new <int>[];
		private static var sHoveringTouchData:Vector.<Object> = new <Object>[];


		public function TouchProcessor2D(stage:Stage2D)
		{
			mStage = stage;
			mElapsedTime = 0.0;
			mCurrentTouches = new <Touch2D>[];
			mQueue = new <Array>[];
			mLastTaps = new <Touch2D>[];

			mStage.addEventListener(KeyboardEvent2D.KEY_DOWN, onKey);
			mStage.addEventListener(KeyboardEvent2D.KEY_UP, onKey);
			monitorInterruptions(true);
		}


		public function dispose():void
		{
			monitorInterruptions(false);
			mStage.removeEventListener(KeyboardEvent2D.KEY_DOWN, onKey);
			mStage.removeEventListener(KeyboardEvent2D.KEY_UP, onKey);
			if (mTouchMarker) mTouchMarker.dispose();
		}


		public function advanceTime(passedTime:Number):void
		{
			var i:int;
			var touchID:int;
			var touch:Touch2D;

			mElapsedTime += passedTime;

			// remove old taps
			if (mLastTaps.length > 0)
			{
				for (i = mLastTaps.length - 1; i >= 0; --i)
					if (mElapsedTime - mLastTaps[i].timestamp > MULTITAP_TIME)
						mLastTaps.splice(i, 1);
			}

			while (mQueue.length > 0)
			{
				sProcessedTouchIDs.length = sHoveringTouchData.length = 0;

				// set touches that were new or moving to phase 'stationary'
				for each (touch in mCurrentTouches)
					if (touch.phase == TouchPhase2D.BEGAN || touch.phase == TouchPhase2D.MOVED)
						touch.setPhase(TouchPhase2D.STATIONARY);

				// process new touches, but each ID only once
				while (mQueue.length > 0 && sProcessedTouchIDs.indexOf(mQueue[mQueue.length - 1][0]) == -1)
				{
					var touchArgs:Array = mQueue.pop();
					touchID = touchArgs[0] as int;
					touch = getCurrentTouch(touchID);

					// hovering touches need special handling (see below)
					if (touch && touch.phase == TouchPhase2D.HOVER && touch.target)
						sHoveringTouchData.push({touch:touch, target:touch.target, bubbleChain:touch.bubbleChain});

					processTouch.apply(this, touchArgs);
					sProcessedTouchIDs.push(touchID);
				}

				// the same touch event will be dispatched to all targets;
				// the 'dispatch' method will make sure each bubble target is visited only once.
				var touchEvent:TouchEvent2D = new TouchEvent2D(TouchEvent2D.TOUCH, mCurrentTouches, mShiftDown, mCtrlDown);

				// if the target of a hovering touch changed, we dispatch the event to the previous
				// target to notify it that it's no longer being hovered over.
				for each (var touchData:Object in sHoveringTouchData)
					if (touchData.touch.target != touchData.target)
						touchEvent.dispatch(touchData.bubbleChain);

				// dispatch events
				for each (touchID in sProcessedTouchIDs)
					getCurrentTouch(touchID).dispatchEvent(touchEvent);

				// remove ended touches
				for (i = mCurrentTouches.length - 1; i >= 0; --i)
					if (mCurrentTouches[i].phase == TouchPhase2D.ENDED)
						mCurrentTouches.splice(i, 1);
			}
		}


		public function enqueue(touchID:int, phase:String, globalX:Number, globalY:Number, pressure:Number = 1.0, width:Number = 1.0, height:Number = 1.0):void
		{
			mQueue.unshift(arguments);

			// multitouch simulation (only with mouse)
			if (mCtrlDown && simulateMultitouch && touchID == 0)
			{
				mTouchMarker.moveMarker(globalX, globalY, mShiftDown);
				mQueue.unshift([1, phase, mTouchMarker.mockX, mTouchMarker.mockY]);
			}
		}


		public function enqueueMouseLeftStage():void
		{
			var mouse:Touch2D = getCurrentTouch(0);
			if (mouse == null || mouse.phase != TouchPhase2D.HOVER) return;

			// On OS X, we get mouse events from outside the stage; on Windows, we do not.
			// This method enqueues an artifial hover point that is just outside the stage.
			// That way, objects listening for HOVERs over them will get notified everywhere.

			var offset:int = 1;
			var exitX:Number = mouse.globalX;
			var exitY:Number = mouse.globalY;
			var distLeft:Number = mouse.globalX;
			var distRight:Number = mStage.stageWidth - distLeft;
			var distTop:Number = mouse.globalY;
			var distBottom:Number = mStage.stageHeight - distTop;
			var minDist:Number = Math.min(distLeft, distRight, distTop, distBottom);

			// the new hover point should be just outside the stage, near the point where
			// the mouse point was last to be seen.

			if (minDist == distLeft) exitX = -offset;
			else if (minDist == distRight) exitX = mStage.stageWidth + offset;
			else if (minDist == distTop) exitY = -offset;
			else exitY = mStage.stageHeight + offset;

			enqueue(0, TouchPhase2D.HOVER, exitX, exitY);
		}


		private function processTouch(touchID:int, phase:String, globalX:Number, globalY:Number, pressure:Number = 1.0, width:Number = 1.0, height:Number = 1.0):void
		{
			var position:Point = new Point(globalX, globalY);
			var touch:Touch2D = getCurrentTouch(touchID);

			if (touch == null)
			{
				touch = new Touch2D(touchID, globalX, globalY, phase, null);
				addCurrentTouch(touch);
			}

			touch.setPosition(globalX, globalY);
			touch.setPhase(phase);
			touch.setTimestamp(mElapsedTime);
			touch.setPressure(pressure);
			touch.setSize(width, height);

			if (phase == TouchPhase2D.HOVER || phase == TouchPhase2D.BEGAN)
				touch.setTarget(mStage.hitTest(position, true));

			if (phase == TouchPhase2D.BEGAN)
				processTap(touch);
		}


		private function onKey(event:KeyboardEvent2D):void
		{
			if (event.keyCode == 17 || event.keyCode == 15) // ctrl or cmd key
			{
				var wasCtrlDown:Boolean = mCtrlDown;
				mCtrlDown = event.type == KeyboardEvent2D.KEY_DOWN;

				if (simulateMultitouch && wasCtrlDown != mCtrlDown)
				{
					mTouchMarker.visible = mCtrlDown;
					mTouchMarker.moveCenter(mStage.stageWidth / 2, mStage.stageHeight / 2);

					var mouseTouch:Touch2D = getCurrentTouch(0);
					var mockedTouch:Touch2D = getCurrentTouch(1);

					if (mouseTouch)
						mTouchMarker.moveMarker(mouseTouch.globalX, mouseTouch.globalY);

					// end active touch ...
					if (wasCtrlDown && mockedTouch && mockedTouch.phase != TouchPhase2D.ENDED)
						mQueue.unshift([1, TouchPhase2D.ENDED, mockedTouch.globalX, mockedTouch.globalY]);
					// ... or start new one
					else if (mCtrlDown && mouseTouch)
					{
						if (mouseTouch.phase == TouchPhase2D.HOVER || mouseTouch.phase == TouchPhase2D.ENDED)
							mQueue.unshift([1, TouchPhase2D.HOVER, mTouchMarker.mockX, mTouchMarker.mockY]);
						else
							mQueue.unshift([1, TouchPhase2D.BEGAN, mTouchMarker.mockX, mTouchMarker.mockY]);
					}
				}
			}
			else if (event.keyCode == 16) // shift key
			{
				mShiftDown = event.type == KeyboardEvent2D.KEY_DOWN;
			}
		}


		private function processTap(touch:Touch2D):void
		{
			var nearbyTap:Touch2D = null;
			var minSqDist:Number = MULTITAP_DISTANCE * MULTITAP_DISTANCE;

			for each (var tap:Touch2D in mLastTaps)
			{
				var sqDist:Number = Math.pow(tap.globalX - touch.globalX, 2) + Math.pow(tap.globalY - touch.globalY, 2);
				if (sqDist <= minSqDist)
				{
					nearbyTap = tap;
					break;
				}
			}

			if (nearbyTap)
			{
				touch.setTapCount(nearbyTap.tapCount + 1);
				mLastTaps.splice(mLastTaps.indexOf(nearbyTap), 1);
			}
			else
			{
				touch.setTapCount(1);
			}

			mLastTaps.push(touch.clone());
		}


		private function addCurrentTouch(touch:Touch2D):void
		{
			for (var i:int = mCurrentTouches.length - 1; i >= 0; --i)
				if (mCurrentTouches[i].id == touch.id)
					mCurrentTouches.splice(i, 1);

			mCurrentTouches.push(touch);
		}


		private function getCurrentTouch(touchID:int):Touch2D
		{
			for each (var touch:Touch2D in mCurrentTouches)
				if (touch.id == touchID) return touch;
			return null;
		}


		public function get simulateMultitouch():Boolean
		{
			return mTouchMarker != null;
		}


		public function set simulateMultitouch(value:Boolean):void
		{
			if (simulateMultitouch == value) return;
			// no change
			if (value)
			{
				mTouchMarker = new TouchMarker2D();
				mTouchMarker.visible = false;
				mStage.addChild(mTouchMarker);
			}
			else
			{
				mTouchMarker.removeFromParent(true);
				mTouchMarker = null;
			}
		}


		// interruption handling
		private function monitorInterruptions(enable:Boolean):void
		{
			// if the application moves into the background or is interrupted (e.g. through
			// an incoming phone call), we need to abort all touches.

			try
			{
				var nativeAppClass:Object = getDefinitionByName("flash.desktop::NativeApplication");
				var nativeApp:Object = nativeAppClass["nativeApplication"];

				if (enable)
					nativeApp.addEventListener("deactivate", onInterruption, false, 0, true);
				else
					nativeApp.removeEventListener("activate", onInterruption);
			}
			catch (e:Error)
			{
			}
			// we're not running in AIR
		}


		private function onInterruption(event:Object):void
		{
			var touch:Touch2D;

			// abort touches
			for each (touch in mCurrentTouches)
			{
				if (touch.phase == TouchPhase2D.BEGAN || touch.phase == TouchPhase2D.MOVED || touch.phase == TouchPhase2D.STATIONARY)
				{
					touch.setPhase(TouchPhase2D.ENDED);
				}
			}

			// dispatch events
			var touchEvent:TouchEvent2D = new TouchEvent2D(TouchEvent2D.TOUCH, mCurrentTouches, mShiftDown, mCtrlDown);

			for each (touch in mCurrentTouches)
				touch.dispatchEvent(touchEvent);

			// purge touches
			mCurrentTouches.length = 0;
		}
	}
}
