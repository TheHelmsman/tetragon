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
package tetragon.view.render2d.textures
{
	import tetragon.view.render2d.util.VertexData2D;

	import flash.display3D.textures.TextureBase;
	import flash.geom.Point;
	import flash.geom.Rectangle;

    /** A SubTexture represents a section of another texture. This is achieved solely by 
     *  manipulation of texture coordinates, making the class very efficient. 
     *
     *  <p><em>Note that it is OK to create subtextures of subtextures.</em></p>
     */ 
    public class SubTexture2D extends Texture2D
    {
        private var mParent:Texture2D;
        private var mClipping:Rectangle;
        private var mRootClipping:Rectangle;
        private var mOwnsParent:Boolean;
        
        /** Helper object. */
        private static var sTexCoords:Point = new Point();
        
        /** Creates a new subtexture containing the specified region (in points) of a parent 
         *  texture. If 'ownsParent' is true, the parent texture will be disposed automatically
         *  when the subtexture is disposed. */
        public function SubTexture2D(parentTexture:Texture2D, region:Rectangle,
                                   ownsParent:Boolean=false)
        {
            mParent = parentTexture;
            mOwnsParent = ownsParent;
            
            if (region == null) setClipping(new Rectangle(0, 0, 1, 1));
            else setClipping(new Rectangle(region.x / parentTexture.width,
                                           region.y / parentTexture.height,
                                           region.width / parentTexture.width,
                                           region.height / parentTexture.height));
        }
        
        /** Disposes the parent texture if this texture owns it. */
        public override function dispose():void
        {
            if (mOwnsParent) mParent.dispose();
            super.dispose();
        }
        
        private function setClipping(value:Rectangle):void
        {
            mClipping = value;
            mRootClipping = value.clone();
            
            var parentTexture:SubTexture2D = mParent as SubTexture2D;
            while (parentTexture)
            {
                var parentClipping:Rectangle = parentTexture.mClipping;
                mRootClipping.x = parentClipping.x + mRootClipping.x * parentClipping.width;
                mRootClipping.y = parentClipping.y + mRootClipping.y * parentClipping.height;
                mRootClipping.width  *= parentClipping.width;
                mRootClipping.height *= parentClipping.height;
                parentTexture = parentTexture.mParent as SubTexture2D;
            }
        }
        
        /** @inheritDoc */
        public override function adjustVertexData(vertexData:VertexData2D, vertexID:int, count:int):void
        {
            super.adjustVertexData(vertexData, vertexID, count);
            
            var clipX:Number = mRootClipping.x;
            var clipY:Number = mRootClipping.y;
            var clipWidth:Number  = mRootClipping.width;
            var clipHeight:Number = mRootClipping.height;
            var endIndex:int = vertexID + count;
            
            for (var i:int=vertexID; i<endIndex; ++i)
            {
                vertexData.getTexCoords(i, sTexCoords);
                vertexData.setTexCoords(i, clipX + sTexCoords.x * clipWidth,
                                           clipY + sTexCoords.y * clipHeight);
            }
        }
        
        /** The texture which the subtexture is based on. */ 
        public function get parent():Texture2D { return mParent; }
        
        /** Indicates if the parent texture is disposed when this object is disposed. */
        public function get ownsParent():Boolean { return mOwnsParent; }
        
        /** The clipping rectangle, which is the region provided on initialization 
         *  scaled into [0.0, 1.0]. */
        public function get clipping():Rectangle { return mClipping.clone(); }
        
        /** @inheritDoc */
        public override function get base():TextureBase { return mParent.base; }
        
        /** @inheritDoc */
        public override function get root():ConcreteTexture2D { return mParent.root; }
        
        /** @inheritDoc */
        public override function get format():String { return mParent.format; }
        
        /** @inheritDoc */
        public override function get width():Number { return mParent.width * mClipping.width; }
        
        /** @inheritDoc */
        public override function get height():Number { return mParent.height * mClipping.height; }
        
        /** @inheritDoc */
        public override function get nativeWidth():Number { return mParent.nativeWidth * mClipping.width; }
        
        /** @inheritDoc */
        public override function get nativeHeight():Number { return mParent.nativeHeight * mClipping.height; }
        
        /** @inheritDoc */
        public override function get mipMapping():Boolean { return mParent.mipMapping; }
        
        /** @inheritDoc */
        public override function get premultipliedAlpha():Boolean { return mParent.premultipliedAlpha; }
        
        /** @inheritDoc */
        public override function get scale():Number { return mParent.scale; } 
        
    }
}