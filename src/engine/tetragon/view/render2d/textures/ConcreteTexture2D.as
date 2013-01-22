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
	import tetragon.view.render2d.core.Render2D;
	import tetragon.view.render2d.events.Event2D;

	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.TextureBase;

	/** A ConcreteTexture wraps a Stage3D texture object, storing the properties of the texture. */
	public class ConcreteTexture2D extends Texture2D
	{
		private var mBase:TextureBase;
		private var mFormat:String;
		private var mWidth:int;
		private var mHeight:int;
		private var mMipMapping:Boolean;
		private var mPremultipliedAlpha:Boolean;
		private var mOptimizedForRenderTexture:Boolean;
		private var mData:Object;
		private var mScale:Number;


		/** Creates a ConcreteTexture object from a TextureBase, storing information about size,
		 *  mip-mapping, and if the channels contain premultiplied alpha values. */
		public function ConcreteTexture2D(base:TextureBase, format:String, width:int, height:int, mipMapping:Boolean, premultipliedAlpha:Boolean, optimizedForRenderTexture:Boolean = false, scale:Number = 1)
		{
			mScale = scale <= 0 ? 1.0 : scale;
			mBase = base;
			mFormat = format;
			mWidth = width;
			mHeight = height;
			mMipMapping = mipMapping;
			mPremultipliedAlpha = premultipliedAlpha;
			mOptimizedForRenderTexture = optimizedForRenderTexture;
		}


		/** Disposes the TextureBase object. */
		public override function dispose():void
		{
			if (mBase) mBase.dispose();
			restoreOnLostContext(null);
			// removes event listener & data reference
			super.dispose();
		}


		// texture backup (context lost)
		/** Instructs this instance to restore its base texture when the context is lost. 'data' 
		 *  can be either BitmapData or a ByteArray with ATF data. */
		public function restoreOnLostContext(data:Object):void
		{
			if (mData == null && data != null)
				Render2D.current.addEventListener(Event2D.CONTEXT3D_CREATE, onContextCreated);
			else if (data == null)
				Render2D.current.removeEventListener(Event2D.CONTEXT3D_CREATE, onContextCreated);

			mData = data;
		}


		private function onContextCreated(event:Event2D):void
		{
			var context:Context3D = Render2D.context;
			var bitmapData:BitmapData = mData as BitmapData;
			var atfData:ATFData2D = mData as ATFData2D;
			var nativeTexture:flash.display3D.textures.Texture;

			if (bitmapData)
			{
				nativeTexture = context.createTexture(mWidth, mHeight, Context3DTextureFormat.BGRA, mOptimizedForRenderTexture);
				Texture2D.uploadBitmapData(nativeTexture, bitmapData, mMipMapping);
			}
			else if (atfData)
			{
				nativeTexture = context.createTexture(atfData.width, atfData.height, atfData.format, mOptimizedForRenderTexture);
				Texture2D.uploadAtfData(nativeTexture, atfData.data);
			}

			mBase = nativeTexture;
		}


		// properties
		/** Indicates if the base texture was optimized for being used in a render texture. */
		public function get optimizedForRenderTexture():Boolean
		{
			return mOptimizedForRenderTexture;
		}


		/** @inheritDoc */
		public override function get base():TextureBase
		{
			return mBase;
		}


		/** @inheritDoc */
		public override function get root():ConcreteTexture2D
		{
			return this;
		}


		/** @inheritDoc */
		public override function get format():String
		{
			return mFormat;
		}


		/** @inheritDoc */
		public override function get width():Number
		{
			return mWidth / mScale;
		}


		/** @inheritDoc */
		public override function get height():Number
		{
			return mHeight / mScale;
		}


		/** @inheritDoc */
		public override function get nativeWidth():Number
		{
			return mWidth;
		}


		/** @inheritDoc */
		public override function get nativeHeight():Number
		{
			return mHeight;
		}


		/** The scale factor, which influences width and height properties. */
		public override function get scale():Number
		{
			return mScale;
		}


		/** @inheritDoc */
		public override function get mipMapping():Boolean
		{
			return mMipMapping;
		}


		/** @inheritDoc */
		public override function get premultipliedAlpha():Boolean
		{
			return mPremultipliedAlpha;
		}
	}
}