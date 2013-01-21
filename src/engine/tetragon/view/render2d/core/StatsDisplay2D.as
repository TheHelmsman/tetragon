// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================
package tetragon.view.render2d.core
{
	import tetragon.view.render2d.display.BlendMode2D;
	import tetragon.view.render2d.display.Quad2D;
	import tetragon.view.render2d.display.Sprite2D;
	import tetragon.view.render2d.events.EnterFrameEvent2D;
	import tetragon.view.render2d.events.Event2D;
	import tetragon.view.render2d.text.BitmapFont2D;
	import tetragon.view.render2d.text.TextField2D;

	import com.hexagonstar.constants.HAlign;
	import com.hexagonstar.constants.VAlign;

	import flash.system.System;
    
    /** A small, lightweight box that displays the current framerate, memory consumption and
     *  the number of draw calls per frame. */
    internal class StatsDisplay2D extends Sprite2D
    {
        private var mBackground:Quad2D;
        private var mTextField:TextField2D;
        
        private var mFrameCount:int = 0;
        private var mDrawCount:int  = 0;
        private var mTotalTime:Number = 0;
        
        /** Creates a new Statistics Box. */
        public function StatsDisplay2D()
        {
            mBackground = new Quad2D(50, 25, 0x0);
            mTextField = new TextField2D(48, 25, "", BitmapFont2D.MINI, BitmapFont2D.NATIVE_SIZE, 0xffffff);
            mTextField.x = 2;
            mTextField.hAlign = HAlign.LEFT;
            mTextField.vAlign = VAlign.TOP;
            
            addChild(mBackground);
            addChild(mTextField);
            
            addEventListener(Event2D.ENTER_FRAME, onEnterFrame);
            updateText(0, getMemory(), 0);
            blendMode = BlendMode2D.NONE;
        }
        
        private function updateText(fps:Number, memory:Number, drawCount:int):void
        {
            mTextField.text = "FPS: " + fps.toFixed(fps < 100 ? 1 : 0) + 
                            "\nMEM: " + memory.toFixed(memory < 100 ? 1 : 0) +
                            "\nDRW: " + drawCount; 
        }
        
        private function getMemory():Number
        {
            return System.totalMemory * 0.000000954; // 1 / (1024*1024) to convert to MB
        }
        
        private function onEnterFrame(event:EnterFrameEvent2D):void
        {
            mTotalTime += event.passedTime;
            mFrameCount++;
            
            if (mTotalTime > 1.0)
            {
                updateText(mFrameCount / mTotalTime, getMemory(), mDrawCount-2); // DRW: ignore self
                mFrameCount = mTotalTime = 0;
            }
        }
        
        /** The number of Stage3D draw calls per second. */
        public function get drawCount():int { return mDrawCount; }
        public function set drawCount(value:int):void { mDrawCount = value; }
    }
}