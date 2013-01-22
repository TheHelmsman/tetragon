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
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	/** A texture atlas is a collection of many smaller textures in one big image. This class
	 *  is used to access textures from such an atlas.
	 *  
	 *  <p>Using a texture atlas for your textures solves two problems:</p>
	 *  
	 *  <ul>
	 *    <li>There is always one texture active at a given moment. Whenever you change the active
	 *        texture, a "texture-switch" has to be executed, and that switch takes time.</li>
	 *    <li>Any Stage3D texture has to have side lengths that are powers of two. Render2D hides 
	 *        this limitation from you, but at the cost of additional graphics memory.</li>
	 *  </ul>
	 *  
	 *  <p>By using a texture atlas, you avoid both texture switches and the power-of-two 
	 *  limitation. All textures are within one big "super-texture", and Render2D takes care that 
	 *  the correct part of this texture is displayed.</p>
	 *  
	 *  <p>There are several ways to create a texture atlas. One is to use the atlas generator 
	 *  script that is bundled with Render2D's sibling, the <a href="http://www.sparrow-framework.org">
	 *  Sparrow framework</a>. It was only tested in Mac OS X, though. A great multi-platform 
	 *  alternative is the commercial tool <a href="http://www.texturepacker.com">
	 *  Texture Packer</a>.</p>
	 *  
	 *  <p>Whatever tool you use, Render2D expects the following file format:</p>
	 * 
	 *  <listing>
	 * 	&lt;TextureAtlas imagePath='atlas.png'&gt;
	 * 	  &lt;SubTexture name='texture_1' x='0'  y='0' width='50' height='50'/&gt;
	 * 	  &lt;SubTexture name='texture_2' x='50' y='0' width='20' height='30'/&gt; 
	 * 	&lt;/TextureAtlas&gt;
	 *  </listing>
	 *  
	 *  <p>If your images have transparent areas at their edges, you can make use of the 
	 *  <code>frame</code> property of the Texture class. Trim the texture by removing the 
	 *  transparent edges and specify the original texture size like this:</p>
	 * 
	 *  <listing>
	 * 	&lt;SubTexture name='trimmed' x='0' y='0' height='10' width='10'
	 * 	    frameX='-10' frameY='-10' frameWidth='30' frameHeight='30'/&gt;
	 *  </listing>
	 */
	public class TextureAtlas2D
	{
		private var mAtlasTexture:Texture2D;
		private var mTextureRegions:Dictionary;
		private var mTextureFrames:Dictionary;
		/** helper objects */
		private var sNames:Vector.<String> = new <String>[];


		/** Create a texture atlas from a texture by parsing the regions from an XML file. */
		public function TextureAtlas2D(texture:Texture2D, atlasXml:XML = null)
		{
			mTextureRegions = new Dictionary();
			mTextureFrames = new Dictionary();
			mAtlasTexture = texture;

			if (atlasXml)
				parseAtlasXml(atlasXml);
		}


		/** Disposes the atlas texture. */
		public function dispose():void
		{
			mAtlasTexture.dispose();
		}


		/** This function is called by the constructor and will parse an XML in Render2D's 
		 *  default atlas file format. Override this method to create custom parsing logic
		 *  (e.g. to support a different file format). */
		protected function parseAtlasXml(atlasXml:XML):void
		{
			var scale:Number = mAtlasTexture.scale;

			for each (var subTexture:XML in atlasXml.SubTexture)
			{
				var name:String = subTexture.attribute("name");
				var x:Number = parseFloat(subTexture.attribute("x")) / scale;
				var y:Number = parseFloat(subTexture.attribute("y")) / scale;
				var width:Number = parseFloat(subTexture.attribute("width")) / scale;
				var height:Number = parseFloat(subTexture.attribute("height")) / scale;
				var frameX:Number = parseFloat(subTexture.attribute("frameX")) / scale;
				var frameY:Number = parseFloat(subTexture.attribute("frameY")) / scale;
				var frameWidth:Number = parseFloat(subTexture.attribute("frameWidth")) / scale;
				var frameHeight:Number = parseFloat(subTexture.attribute("frameHeight")) / scale;

				var region:Rectangle = new Rectangle(x, y, width, height);
				var frame:Rectangle = frameWidth > 0 && frameHeight > 0 ? new Rectangle(frameX, frameY, frameWidth, frameHeight) : null;

				addRegion(name, region, frame);
			}
		}


		/** Retrieves a subtexture by name. Returns <code>null</code> if it is not found. */
		public function getTexture(name:String):Texture2D
		{
			var region:Rectangle = mTextureRegions[name];

			if (region == null) return null;
			else return Texture2D.fromTexture(mAtlasTexture, region, mTextureFrames[name]);
		}


		/** Returns all textures that start with a certain string, sorted alphabetically
		 *  (especially useful for "MovieClip"). */
		public function getTextures(prefix:String = "", result:Vector.<Texture2D>=null):Vector.<Texture2D>
		{
			if (result == null) result = new <Texture2D>[];

			for each (var name:String in getNames(prefix, sNames))
				result.push(getTexture(name));

			sNames.length = 0;
			return result;
		}


		/** Returns all texture names that start with a certain string, sorted alphabetically. */
		public function getNames(prefix:String = "", result:Vector.<String>=null):Vector.<String>
		{
			if (result == null) result = new <String>[];

			for (var name:String in mTextureRegions)
				if (name.indexOf(prefix) == 0)
					result.push(name);

			result.sort(Array.CASEINSENSITIVE);
			return result;
		}


		/** Returns the region rectangle associated with a specific name. */
		public function getRegion(name:String):Rectangle
		{
			return mTextureRegions[name];
		}


		/** Returns the frame rectangle of a specific region, or <code>null</code> if that region 
		 *  has no frame. */
		public function getFrame(name:String):Rectangle
		{
			return mTextureFrames[name];
		}


		/** Adds a named region for a subtexture (described by rectangle with coordinates in 
		 *  pixels) with an optional frame. */
		public function addRegion(name:String, region:Rectangle, frame:Rectangle = null):void
		{
			mTextureRegions[name] = region;
			mTextureFrames[name] = frame;
		}


		/** Removes a region with a certain name. */
		public function removeRegion(name:String):void
		{
			delete mTextureRegions[name];
			delete mTextureFrames[name];
		}
	}
}