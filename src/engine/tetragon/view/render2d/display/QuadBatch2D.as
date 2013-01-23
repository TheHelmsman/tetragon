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
	import tetragon.view.render2d.core.Render2D;
	import tetragon.view.render2d.core.RenderSupport2D;
	import tetragon.view.render2d.core.VertexData2D;
	import tetragon.view.render2d.events.Event2D;
	import tetragon.view.render2d.filters.FragmentFilter2D;
	import tetragon.view.render2d.filters.FragmentFilterMode2D;
	import tetragon.view.render2d.textures.Texture2D;
	import tetragon.view.render2d.textures.TextureSmoothing2D;

	import com.hexagonstar.exception.MissingContext3DException;
	import com.hexagonstar.util.agal.AGALMiniAssembler;
	import com.hexagonstar.util.geom.MatrixUtil;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	
	/** Optimizes rendering of a number of quads with an identical state.
	 * 
	 *  <p>The majority of all rendered objects in Render2D are quads. In fact, all the default
	 *  leaf nodes of Render2D are quads (the Image and Quad classes). The rendering of those 
	 *  quads can be accelerated by a big factor if all quads with an identical state are sent 
	 *  to the GPU in just one call. That's what the QuadBatch class can do.</p>
	 *  
	 *  <p>The 'flatten' method of the Sprite class uses this class internally to optimize its 
	 *  rendering performance. In most situations, it is recommended to stick with flattened
	 *  sprites, because they are easier to use. Sometimes, however, it makes sense
	 *  to use the QuadBatch class directly: e.g. you can add one quad multiple times to 
	 *  a quad batch, whereas you can only add it once to a sprite. Furthermore, this class
	 *  does not dispatch <code>ADDED</code> or <code>ADDED_TO_STAGE</code> events when a quad
	 *  is added, which makes it more lightweight.</p>
	 *  
	 *  <p>One QuadBatch object is bound to a specific render state. The first object you add to a 
	 *  batch will decide on the QuadBatch's state, that is: its texture, its settings for 
	 *  smoothing and blending, and if it's tinted (colored vertices and/or transparency). 
	 *  When you reset the batch, it will accept a new state on the next added quad.</p> 
	 *  
	 *  <p>The class extends DisplayObject, but you can use it even without adding it to the
	 *  display tree. Just call the 'renderCustom' method from within another render method,
	 *  and pass appropriate values for transformation matrix, alpha and blend mode.</p>
	 *
	 *  @see Sprite  
	 */
	public class QuadBatch2D extends DisplayObject2D
	{
		private static const QUAD_PROGRAM_NAME:String = "QB_q";
		
		private var _numQuads:int;
		private var _syncRequired:Boolean;
		private var _tinted:Boolean;
		private var _texture:Texture2D;
		private var _smoothing:String;
		private var _vertexData:VertexData2D;
		private var _vertexBuffer:VertexBuffer3D;
		private var _indexData:Vector.<uint>;
		private var _indexBuffer:IndexBuffer3D;
		
		/** Helper objects. */
		private static var _helperMatrix:Matrix = new Matrix();
		private static var _renderAlpha:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];
		private static var _renderMatrix:Matrix3D = new Matrix3D();
		private static var _programNameCache:Dictionary = new Dictionary();


		/** Creates a new QuadBatch instance with empty batch data. */
		public function QuadBatch2D()
		{
			_vertexData = new VertexData2D(0, true);
			_indexData = new <uint>[];
			_numQuads = 0;
			_tinted = false;
			_syncRequired = false;

			// Handle lost context. We use the conventional event here (not the one from Render2D)
			// so we're able to create a weak event listener; this avoids memory leaks when people
			// forget to call "dispose" on the QuadBatch.
			Render2D.current.stage3D.addEventListener(Event2D.CONTEXT3D_CREATE, onContextCreated, false, 0, true);
		}


		/** Disposes vertex- and index-buffer. */
		public override function dispose():void
		{
			Render2D.current.stage3D.removeEventListener(Event2D.CONTEXT3D_CREATE, onContextCreated);

			if (_vertexBuffer) _vertexBuffer.dispose();
			if (_indexBuffer) _indexBuffer.dispose();

			super.dispose();
		}


		private function onContextCreated(event:Object):void
		{
			createBuffers();
			registerPrograms();
		}


		/** Creates a duplicate of the QuadBatch object. */
		public function clone():QuadBatch2D
		{
			var clone:QuadBatch2D = new QuadBatch2D();
			clone._vertexData = _vertexData.clone(0, _numQuads * 4);
			clone._indexData = _indexData.slice(0, _numQuads * 6);
			clone._numQuads = _numQuads;
			clone._tinted = _tinted;
			clone._texture = _texture;
			clone._smoothing = _smoothing;
			clone._syncRequired = true;
			clone.blendMode = blendMode;
			clone.alpha = alpha;
			return clone;
		}


		private function expand(newCapacity:int = -1):void
		{
			var oldCapacity:int = capacity;

			if (newCapacity < 0) newCapacity = oldCapacity * 2;
			if (newCapacity == 0) newCapacity = 16;
			if (newCapacity <= oldCapacity) return;

			_vertexData.numVertices = newCapacity * 4;

			for (var i:int = oldCapacity; i < newCapacity; ++i)
			{
				_indexData[int(i * 6)] = i * 4;
				_indexData[int(i * 6 + 1)] = i * 4 + 1;
				_indexData[int(i * 6 + 2)] = i * 4 + 2;
				_indexData[int(i * 6 + 3)] = i * 4 + 1;
				_indexData[int(i * 6 + 4)] = i * 4 + 3;
				_indexData[int(i * 6 + 5)] = i * 4 + 2;
			}

			createBuffers();
			registerPrograms();
		}


		private function createBuffers():void
		{
			var numVertices:int = _vertexData.numVertices;
			var numIndices:int = _indexData.length;
			var context:Context3D = Render2D.context;

			if (_vertexBuffer) _vertexBuffer.dispose();
			if (_indexBuffer) _indexBuffer.dispose();
			if (numVertices == 0) return;
			if (context == null) throw new MissingContext3DException();

			_vertexBuffer = context.createVertexBuffer(numVertices, VertexData2D.ELEMENTS_PER_VERTEX);
			_vertexBuffer.uploadFromVector(_vertexData.rawData, 0, numVertices);

			_indexBuffer = context.createIndexBuffer(numIndices);
			_indexBuffer.uploadFromVector(_indexData, 0, numIndices);

			_syncRequired = false;
		}


		/** Uploads the raw data of all batched quads to the vertex buffer. */
		private function syncBuffers():void
		{
			if (_vertexBuffer == null)
				createBuffers();
			else
			{
				// as 3rd parameter, we could also use 'mNumQuads * 4', but on some GPU hardware (iOS!),
				// this is slower than updating the complete buffer.

				_vertexBuffer.uploadFromVector(_vertexData.rawData, 0, _vertexData.numVertices);
				_syncRequired = false;
			}
		}


		/** Renders the current batch with custom settings for model-view-projection matrix, alpha 
		 *  and blend mode. This makes it possible to render batches that are not part of the 
		 *  display list. */
		public function renderCustom(mvpMatrix:Matrix, parentAlpha:Number = 1.0, blendMode:String = null):void
		{
			if (_numQuads == 0) return;
			if (_syncRequired) syncBuffers();

			var pma:Boolean = _vertexData.premultipliedAlpha;
			var context:Context3D = Render2D.context;
			var tinted:Boolean = _tinted || (parentAlpha != 1.0);
			var programName:String = _texture ? getImageProgramName(tinted, _texture.mipMapping, _texture.repeat, _texture.format, _smoothing) : QUAD_PROGRAM_NAME;

			_renderAlpha[0] = _renderAlpha[1] = _renderAlpha[2] = pma ? parentAlpha : 1.0;
			_renderAlpha[3] = parentAlpha;

			MatrixUtil.convertTo3D(mvpMatrix, _renderMatrix);
			RenderSupport2D.setBlendFactors(pma, blendMode ? blendMode : this.blendMode);

			context.setProgram(Render2D.current.getProgram(programName));
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _renderAlpha, 1);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, _renderMatrix, true);
			context.setVertexBufferAt(0, _vertexBuffer, VertexData2D.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_2);

			if (_texture == null || tinted)
				context.setVertexBufferAt(1, _vertexBuffer, VertexData2D.COLOR_OFFSET, Context3DVertexBufferFormat.FLOAT_4);

			if (_texture)
			{
				context.setTextureAt(0, _texture.base);
				context.setVertexBufferAt(2, _vertexBuffer, VertexData2D.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
			}

			context.drawTriangles(_indexBuffer, 0, _numQuads * 2);

			if (_texture)
			{
				context.setTextureAt(0, null);
				context.setVertexBufferAt(2, null);
			}

			context.setVertexBufferAt(1, null);
			context.setVertexBufferAt(0, null);
		}


		/** Resets the batch. The vertex- and index-buffers remain their size, so that they
		 *  can be reused quickly. */
		public function reset():void
		{
			_numQuads = 0;
			_texture = null;
			_smoothing = null;
			_syncRequired = true;
		}


		/** Adds an image to the batch. This method internally calls 'addQuad' with the correct
		 *  parameters for 'texture' and 'smoothing'. */
		public function addImage(image:Image2D, parentAlpha:Number = 1.0, modelViewMatrix:Matrix = null, blendMode:String = null):void
		{
			addQuad(image, parentAlpha, image.texture, image.smoothing, modelViewMatrix, blendMode);
		}


		/** Adds a quad to the batch. The first quad determines the state of the batch,
		 *  i.e. the values for texture, smoothing and blendmode. When you add additional quads,  
		 *  make sure they share that state (e.g. with the 'isStageChange' method), or reset
		 *  the batch. */
		public function addQuad(quad:Quad2D, parentAlpha:Number = 1.0, texture:Texture2D = null, smoothing:String = null, modelViewMatrix:Matrix = null, blendMode:String = null):void
		{
			if (modelViewMatrix == null)
				modelViewMatrix = quad.transformationMatrix;

			var tinted:Boolean = texture ? (quad.tinted || parentAlpha != 1.0) : false;
			var alpha:Number = parentAlpha * quad.alpha;
			var vertexID:int = _numQuads * 4;

			if (_numQuads + 1 > _vertexData.numVertices / 4) expand();
			if (_numQuads == 0)
			{
				this.blendMode = blendMode ? blendMode : quad.blendMode;
				_texture = texture;
				_tinted = tinted;
				_smoothing = smoothing;
				_vertexData.setPremultipliedAlpha(texture ? texture.premultipliedAlpha : true, false);
			}

			quad.copyVertexDataTo(_vertexData, vertexID);
			_vertexData.transformVertex(vertexID, modelViewMatrix, 4);

			if (alpha != 1.0)
				_vertexData.scaleAlpha(vertexID, alpha, 4);

			_syncRequired = true;
			_numQuads++;
		}


		public function addQuadBatch(quadBatch:QuadBatch2D, parentAlpha:Number = 1.0, modelViewMatrix:Matrix = null, blendMode:String = null):void
		{
			if (modelViewMatrix == null)
				modelViewMatrix = quadBatch.transformationMatrix;

			var tinted:Boolean = quadBatch._tinted || parentAlpha != 1.0;
			var alpha:Number = parentAlpha * quadBatch.alpha;
			var vertexID:int = _numQuads * 4;
			var numQuads:int = quadBatch.numQuads;

			if (_numQuads + numQuads > capacity) expand(_numQuads + numQuads);
			if (_numQuads == 0)
			{
				this.blendMode = blendMode ? blendMode : quadBatch.blendMode;
				_texture = quadBatch._texture;
				_tinted = tinted;
				_smoothing = quadBatch._smoothing;
				_vertexData.setPremultipliedAlpha(quadBatch._vertexData.premultipliedAlpha, false);
			}

			quadBatch._vertexData.copyTo(_vertexData, vertexID, 0, numQuads * 4);
			_vertexData.transformVertex(vertexID, modelViewMatrix, numQuads * 4);

			if (alpha != 1.0)
				_vertexData.scaleAlpha(vertexID, alpha, numQuads * 4);

			_syncRequired = true;
			_numQuads += numQuads;
		}


		/** Indicates if specific quads can be added to the batch without causing a state change. 
		 *  A state change occurs if the quad uses a different base texture, has a different 
		 *  'tinted', 'smoothing', 'repeat' or 'blendMode' setting, or if the batch is full
		 *  (one batch can contain up to 8192 quads). */
		public function isStateChange(tinted:Boolean, parentAlpha:Number, texture:Texture2D, smoothing:String, blendMode:String, numQuads:int = 1):Boolean
		{
			if (_numQuads == 0) return false;
			else if (_numQuads + numQuads > 8192) return true; // maximum buffer size
			else if (_texture == null && texture == null) return false;
			else if (_texture != null && texture != null)
				return _texture.base != texture.base || _texture.repeat != texture.repeat || _smoothing != smoothing || _tinted != (tinted || parentAlpha != 1.0) || this.blendMode != blendMode;
			else return true;
		}


		// display object methods
		/** @inheritDoc */
		public override function getBounds(targetSpace:DisplayObject2D, resultRect:Rectangle = null):Rectangle
		{
			if (resultRect == null) resultRect = new Rectangle();

			var transformationMatrix:Matrix = targetSpace == this ? null : getTransformationMatrix(targetSpace, _helperMatrix);

			return _vertexData.getBounds(transformationMatrix, 0, _numQuads * 4, resultRect);
		}


		/** @inheritDoc */
		public override function render(support:RenderSupport2D, parentAlpha:Number):void
		{
			if (_numQuads)
			{
				support.finishQuadBatch();
				support.raiseDrawCount();
				renderCustom(support.mvpMatrix, alpha * parentAlpha, support.blendMode);
			}
		}


		// compilation (for flattened sprites)
		/** Analyses an object that is made up exclusively of quads (or other containers)
		 *  and creates a vector of QuadBatch objects representing it. This can be
		 *  used to render the container very efficiently. The 'flatten'-method of the Sprite 
		 *  class uses this method internally. */
		public static function compile(object:DisplayObject2D, quadBatches:Vector.<QuadBatch2D>):void
		{
			compileObject(object, quadBatches, -1, new Matrix());
		}


		private static function compileObject(object:DisplayObject2D, quadBatches:Vector.<QuadBatch2D>, quadBatchID:int, transformationMatrix:Matrix, alpha:Number = 1.0, blendMode:String = null, ignoreCurrentFilter:Boolean = false):int
		{
			var i:int;
			var quadBatch:QuadBatch2D;
			var isRootObject:Boolean = false;
			var objectAlpha:Number = object.alpha;

			var container:DisplayObjectContainer2D = object as DisplayObjectContainer2D;
			var quad:Quad2D = object as Quad2D;
			var batch:QuadBatch2D = object as QuadBatch2D;
			var filter:FragmentFilter2D = object.filter;

			if (quadBatchID == -1)
			{
				isRootObject = true;
				quadBatchID = 0;
				objectAlpha = 1.0;
				blendMode = object.blendMode;
				if (quadBatches.length == 0) quadBatches.push(new QuadBatch2D());
				else quadBatches[0].reset();
			}

			if (filter && !ignoreCurrentFilter)
			{
				if (filter.mode == FragmentFilterMode2D.ABOVE)
				{
					quadBatchID = compileObject(object, quadBatches, quadBatchID, transformationMatrix, alpha, blendMode, true);
				}

				quadBatchID = compileObject(filter.compile(object), quadBatches, quadBatchID, transformationMatrix, alpha, blendMode);

				if (filter.mode == FragmentFilterMode2D.BELOW)
				{
					quadBatchID = compileObject(object, quadBatches, quadBatchID, transformationMatrix, alpha, blendMode, true);
				}
			}
			else if (container)
			{
				var numChildren:int = container.numChildren;
				var childMatrix:Matrix = new Matrix();

				for (i = 0; i < numChildren; ++i)
				{
					var child:DisplayObject2D = container.getChildAt(i);
					var childVisible:Boolean = child.alpha != 0.0 && child.visible && child.scaleX != 0.0 && child.scaleY != 0.0;
					if (childVisible)
					{
						var childBlendMode:String = child.blendMode == BlendMode2D.AUTO ? blendMode : child.blendMode;
						childMatrix.copyFrom(transformationMatrix);
						RenderSupport2D.transformMatrixForObject(childMatrix, child);
						quadBatchID = compileObject(child, quadBatches, quadBatchID, childMatrix, alpha * objectAlpha, childBlendMode);
					}
				}
			}
			else if (quad || batch)
			{
				var texture:Texture2D;
				var smoothing:String;
				var tinted:Boolean;
				var numQuads:int;

				if (quad)
				{
					var image:Image2D = quad as Image2D;
					texture = image ? image.texture : null;
					smoothing = image ? image.smoothing : null;
					tinted = quad.tinted;
					numQuads = 1;
				}
				else
				{
					texture = batch._texture;
					smoothing = batch._smoothing;
					tinted = batch._tinted;
					numQuads = batch._numQuads;
				}

				quadBatch = quadBatches[quadBatchID];

				if (quadBatch.isStateChange(tinted, alpha * objectAlpha, texture, smoothing, blendMode, numQuads))
				{
					quadBatchID++;
					if (quadBatches.length <= quadBatchID) quadBatches.push(new QuadBatch2D());
					quadBatch = quadBatches[quadBatchID];
					quadBatch.reset();
				}

				if (quad)
					quadBatch.addQuad(quad, alpha, texture, smoothing, transformationMatrix, blendMode);
				else
					quadBatch.addQuadBatch(batch, alpha, transformationMatrix, blendMode);
			}
			else
			{
				throw new Error("Unsupported display object: " + getQualifiedClassName(object));
			}

			if (isRootObject)
			{
				// remove unused batches
				for (i = quadBatches.length - 1; i > quadBatchID; --i)
				{
					(quadBatches.pop() as QuadBatch2D).dispose();
				}
			}

			return quadBatchID;
		}


		// properties
		public function get numQuads():int
		{
			return _numQuads;
		}


		public function get tinted():Boolean
		{
			return _tinted;
		}


		public function get texture():Texture2D
		{
			return _texture;
		}


		public function get smoothing():String
		{
			return _smoothing;
		}


		private function get capacity():int
		{
			return _vertexData.numVertices / 4;
		}


		// program management
		private static function registerPrograms():void
		{
			var target:Render2D = Render2D.current;
			if (target.hasProgram(QUAD_PROGRAM_NAME)) return;
			// already registered

			var assembler:AGALMiniAssembler = new AGALMiniAssembler();
			var vertexProgramCode:String;
			var fragmentProgramCode:String;

			// this is the input data we'll pass to the shaders:
			//
			// va0 -> position
			// va1 -> color
			// va2 -> texCoords
			// vc0 -> alpha
			// vc1 -> mvpMatrix
			// fs0 -> texture

			// Quad:

			vertexProgramCode = "m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace 
			"mul v0, va1, vc0 \n";
			// multiply alpha (vc0) with color (va1)

			fragmentProgramCode = "mov oc, v0       \n";
			// output color

			target.registerProgram(QUAD_PROGRAM_NAME, assembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode), assembler.assemble(Context3DProgramType.FRAGMENT, fragmentProgramCode));

			// Image:
			// Each combination of tinted/repeat/mipmap/smoothing has its own fragment shader.

			for each (var tinted:Boolean in [true, false])
			{
				vertexProgramCode = tinted ? "m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace 
				"mul v0, va1, vc0 \n" + // multiply alpha (vc0) with color (va1) 
				"mov v1, va2      \n"   // pass texture coordinates to fragment program
				: "m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace 
				"mov v1, va2      \n";
				// pass texture coordinates to fragment program

				fragmentProgramCode = tinted ? "tex ft1,  v1, fs0 <???> \n" + // sample texture 0 
				"mul  oc, ft1,  v0       \n"   // multiply color with texel color
				: "tex  oc,  v1, fs0 <???> \n";
				// sample texture 0

				var smoothingTypes:Array = [TextureSmoothing2D.NONE, TextureSmoothing2D.BILINEAR, TextureSmoothing2D.TRILINEAR];

				var formats:Array = [Context3DTextureFormat.BGRA, Context3DTextureFormat.COMPRESSED, "compressedAlpha"// use explicit string for compatibility
				];

				for each (var repeat:Boolean in [true, false])
				{
					for each (var mipmap:Boolean in [true, false])
					{
						for each (var smoothing:String in smoothingTypes)
						{
							for each (var format:String in formats)
							{
								var options:Array = ["2d", repeat ? "repeat" : "clamp"];

								if (format == Context3DTextureFormat.COMPRESSED)
									options.push("dxt1");
								else if (format == "compressedAlpha")
									options.push("dxt5");

								if (smoothing == TextureSmoothing2D.NONE)
									options.push("nearest", mipmap ? "mipnearest" : "mipnone");
								else if (smoothing == TextureSmoothing2D.BILINEAR)
									options.push("linear", mipmap ? "mipnearest" : "mipnone");
								else
									options.push("linear", mipmap ? "miplinear" : "mipnone");

								target.registerProgram(getImageProgramName(tinted, mipmap, repeat, format, smoothing), assembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode), assembler.assemble(Context3DProgramType.FRAGMENT, fragmentProgramCode.replace("???", options.join())));
							}
						}
					}
				}
			}
		}


		private static function getImageProgramName(tinted:Boolean, mipMap:Boolean = true, repeat:Boolean = false, format:String = "bgra", smoothing:String = "bilinear"):String
		{
			var bitField:uint = 0;

			if (tinted) bitField |= 1;
			if (mipMap) bitField |= 1 << 1;
			if (repeat) bitField |= 1 << 2;

			if (smoothing == TextureSmoothing2D.NONE)
				bitField |= 1 << 3;
			else if (smoothing == TextureSmoothing2D.TRILINEAR)
				bitField |= 1 << 4;

			if (format == Context3DTextureFormat.COMPRESSED)
				bitField |= 1 << 5;
			else if (format == "compressedAlpha")
				bitField |= 1 << 6;

			var name:String = _programNameCache[bitField];

			if (name == null)
			{
				name = "QB_i." + bitField.toString(16);
				_programNameCache[bitField] = name;
			}

			return name;
		}
	}
}
