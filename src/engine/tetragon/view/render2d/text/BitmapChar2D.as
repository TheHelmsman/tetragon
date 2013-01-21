// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================
package tetragon.view.render2d.text
{
	import tetragon.view.render2d.display.Image2D;
	import tetragon.view.render2d.textures.Texture2D;

	import flash.utils.Dictionary;

    /** A BitmapChar contains the information about one char of a bitmap font.  
     *  <em>You don't have to use this class directly in most cases. 
     *  The TextField class contains methods that handle bitmap fonts for you.</em>    
     */ 
    public class BitmapChar2D
    {
        private var mTexture:Texture2D;
        private var mCharID:int;
        private var mXOffset:Number;
        private var mYOffset:Number;
        private var mXAdvance:Number;
        private var mKernings:Dictionary;
        
        /** Creates a char with a texture and its properties. */
        public function BitmapChar2D(id:int, texture:Texture2D, 
                                   xOffset:Number, yOffset:Number, xAdvance:Number)
        {
            mCharID = id;
            mTexture = texture;
            mXOffset = xOffset;
            mYOffset = yOffset;
            mXAdvance = xAdvance;
            mKernings = null;
        }
        
        /** Adds kerning information relative to a specific other character ID. */
        public function addKerning(charID:int, amount:Number):void
        {
            if (mKernings == null)
                mKernings = new Dictionary();
            
            mKernings[charID] = amount;
        }
        
        /** Retrieve kerning information relative to the given character ID. */
        public function getKerning(charID:int):Number
        {
            if (mKernings == null || mKernings[charID] == undefined) return 0.0;
            else return mKernings[charID];
        }
        
        /** Creates an image of the char. */
        public function createImage():Image2D
        {
            return new Image2D(mTexture);
        }
        
        /** The unicode ID of the char. */
        public function get charID():int { return mCharID; }
        
        /** The number of points to move the char in x direction on character arrangement. */
        public function get xOffset():Number { return mXOffset; }
        
        /** The number of points to move the char in y direction on character arrangement. */
        public function get yOffset():Number { return mYOffset; }
        
        /** The number of points the cursor has to be moved to the right for the next char. */
        public function get xAdvance():Number { return mXAdvance; }
        
        /** The texture of the character. */
        public function get texture():Texture2D { return mTexture; }
        
        /** The width of the character in points. */
        public function get width():Number { return mTexture.width; }
        
        /** The height of the character in points. */
        public function get height():Number { return mTexture.height; }
    }
}