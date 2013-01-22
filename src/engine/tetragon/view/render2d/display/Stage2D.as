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
	import tetragon.view.render2d.core.starling_internal;
	import tetragon.view.render2d.events.EnterFrameEvent2D;
	import tetragon.view.render2d.events.Event2D;

	import flash.errors.IllegalOperationError;
	import flash.geom.Point;
    
    use namespace starling_internal;
    
    /** Dispatched when the Flash container is resized. */
    [Event(name="resize", type="tetragon.view.render2d.events.ResizeEvent2D")]
    
    /** Dispatched when a key on the keyboard is released. */
    [Event(name="keyUp", type="tetragon.view.render2d.events.KeyboardEvent2D")]
    
    /** Dispatched when a key on the keyboard is pressed. */
    [Event(name="keyDown", type="tetragon.view.render2d.events.KeyboardEvent2D")]
    
    /** A Stage represents the root of the display tree.  
     *  Only objects that are direct or indirect children of the stage will be rendered.
     * 
     *  <p>This class represents the Starling version of the stage. Don't confuse it with its 
     *  Flash equivalent: while the latter contains objects of the type 
     *  <code>flash.display.DisplayObject</code>, the Starling stage contains only objects of the
     *  type <code>starling.display.DisplayObject</code>. Those classes are not compatible, and 
     *  you cannot exchange one type with the other.</p>
     * 
     *  <p>A stage object is created automatically by the <code>Starling</code> class. Don't
     *  create a Stage instance manually.</p>
     * 
     *  <strong>Keyboard Events</strong>
     * 
     *  <p>In Starling, keyboard events are only dispatched at the stage. Add an event listener
     *  directly to the stage to be notified of keyboard events.</p>
     * 
     *  <strong>Resize Events</strong>
     * 
     *  <p>When the Flash player is resized, the stage dispatches a <code>ResizeEvent</code>. The 
     *  event contains properties containing the updated width and height of the Flash player.</p>
     *
     *  @see starling.events.KeyboardEvent
     *  @see starling.events.ResizeEvent  
     * 
     * */
    public class Stage2D extends DisplayObjectContainer2D
    {
        private var mWidth:int;
        private var mHeight:int;
        private var mColor:uint;
        private var mEnterFrameEvent:EnterFrameEvent2D = new EnterFrameEvent2D(Event2D.ENTER_FRAME, 0.0);
        
        /** @private */
        public function Stage2D(width:int, height:int, color:uint=0)
        {
            mWidth = width;
            mHeight = height;
            mColor = color;
        }
        
        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void
        {
            mEnterFrameEvent.reset(Event2D.ENTER_FRAME, false, passedTime);
            broadcastEvent(mEnterFrameEvent);
        }

        /** Returns the object that is found topmost beneath a point in stage coordinates, or  
         *  the stage itself if nothing else is found. */
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject2D
        {
            if (forTouch && (!visible || !touchable))
                return null;
            
            // locations outside of the stage area shouldn't be accepted
            if (localPoint.x < 0 || localPoint.x > mWidth ||
                localPoint.y < 0 || localPoint.y > mHeight)
                return null;
            
            // if nothing else is hit, the stage returns itself as target
            var target:DisplayObject2D = super.hitTest(localPoint, forTouch);
            if (target == null) target = this;
            return target;
        }
        
        /** @private */
        public override function set width(value:Number):void 
        { 
            throw new IllegalOperationError("Cannot set width of stage");
        }
        
        /** @private */
        public override function set height(value:Number):void
        {
            throw new IllegalOperationError("Cannot set height of stage");
        }
        
        /** @private */
        public override function set x(value:Number):void
        {
            throw new IllegalOperationError("Cannot set x-coordinate of stage");
        }
        
        /** @private */
        public override function set y(value:Number):void
        {
            throw new IllegalOperationError("Cannot set y-coordinate of stage");
        }
        
        /** @private */
        public override function set scaleX(value:Number):void
        {
            throw new IllegalOperationError("Cannot scale stage");
        }

        /** @private */
        public override function set scaleY(value:Number):void
        {
            throw new IllegalOperationError("Cannot scale stage");
        }
        
        /** @private */
        public override function set rotation(value:Number):void
        {
            throw new IllegalOperationError("Cannot rotate stage");
        }
        
        /** The background color of the stage. */
        public function get color():uint { return mColor; }
        public function set color(value:uint):void { mColor = value; }
        
        /** The width of the stage coordinate system. Change it to scale its contents relative
         *  to the <code>viewPort</code> property of the Starling object. */ 
        public function get stageWidth():int { return mWidth; }
        public function set stageWidth(value:int):void { mWidth = value; }
        
        /** The height of the stage coordinate system. Change it to scale its contents relative
         *  to the <code>viewPort</code> property of the Starling object. */
        public function get stageHeight():int { return mHeight; }
        public function set stageHeight(value:int):void { mHeight = value; }
    }
}