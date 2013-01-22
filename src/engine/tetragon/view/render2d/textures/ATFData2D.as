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
    import flash.display3D.Context3DTextureFormat;
    import flash.utils.ByteArray;

    /** A parser for the ATF data format. */
    internal class ATFData2D
    {
        private var mFormat:String;
        private var mWidth:int;
        private var mHeight:int;
        private var mNumTextures:int;
        private var mData:ByteArray;
        
        /** Create a new instance by parsing the given byte array. */
        public function ATFData2D(data:ByteArray)
        {
            var signature:String = String.fromCharCode(data[0], data[1], data[2]);
            if (signature != "ATF") throw new ArgumentError("Invalid ATF data");
            
            switch (data[6])
            {
                case 0:
                case 1: mFormat = Context3DTextureFormat.BGRA; break;
                case 2:
                case 3: mFormat = Context3DTextureFormat.COMPRESSED; break;
                case 4:
                case 5: mFormat = "compressedAlpha"; break; // explicit string to stay compatible 
                                                            // with older versions
                default: throw new Error("Invalid ATF format");
            }
            
            mWidth = Math.pow(2, data[7]); 
            mHeight = Math.pow(2, data[8]);
            mNumTextures = data[9];
            mData = data;
        }
        
        public function get format():String { return mFormat; }
        public function get width():int { return mWidth; }
        public function get height():int { return mHeight; }
        public function get numTextures():int { return mNumTextures; }
        public function get data():ByteArray { return mData; }
    }
}