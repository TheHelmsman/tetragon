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
package tetragon.view.render2d.filters
{
	import tetragon.view.render2d.core.RenderSupport2D;
	import tetragon.view.render2d.core.Render2D;
	import tetragon.view.render2d.core.render2d_internal;
	import tetragon.view.render2d.display.BlendMode2D;
	import tetragon.view.render2d.display.DisplayObject2D;
	import tetragon.view.render2d.display.Image2D;
	import tetragon.view.render2d.display.QuadBatch2D;
	import tetragon.view.render2d.display.Stage2D;
	import tetragon.view.render2d.events.Event2D;
	import tetragon.view.render2d.textures.Texture2D;
	import tetragon.view.render2d.util.MatrixUtil2D;
	import tetragon.view.render2d.util.RectangleUtil2D;
	import tetragon.view.render2d.util.VertexData2D;
	import tetragon.view.render2d.util.getNextPowerOfTwo2D;

	import com.hexagonstar.exception.AbstractClassException;
	import com.hexagonstar.exception.MissingContext3DException;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.errors.IllegalOperationError;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.getQualifiedClassName;

    /** The FragmentFilter class is the base class for all filter effects in Starling.
     *  All other filters of this package extend this class. You can attach them to any display
     *  object through the 'filter' property.
     * 
     *  <p>A fragment filter works in the following way:</p>
     *  <ol>
     *    <li>The object that is filtered is rendered into a texture (in stage coordinates).</li>
     *    <li>That texture is passed to the first filter pass.</li>
     *    <li>Each pass processes the texture using a fragment shader (and optionally a vertex 
     *        shader) to achieve a certain effect.</li>
     *    <li>The output of each pass is used as the input for the next pass; if it's the 
     *        final pass, it will be rendered directly to the back buffer.</li>  
     *  </ol>
     * 
     *  <p>All of this is set up by the abstract FragmentFilter class. Concrete subclasses
     *  just need to override the protected methods 'createPrograms', 'activate' and 
     *  (optionally) 'deactivate' to create and execute its custom shader code. Each filter
     *  can be configured to either replace the original object, or be drawn below or above it.
     *  This can be done through the 'mode' property, which accepts one of the Strings defined
     *  in the 'FragmentFilterMode' class.</p>
     * 
     *  <p>Beware that each filter should be used only on one object at a time. Otherwise, it
     *  will get slower and require more resources; and caching will lead to undefined
     *  results.</p>
     */ 
    public class FragmentFilter2D
    {
        /** All filter processing is expected to be done with premultiplied alpha. */
        protected const PMA:Boolean = true;
        
        /** The standard vertex shader code. It will be used automatically if you don't create
         *  a custom vertex shader yourself. */
        protected const STD_VERTEX_SHADER:String = 
            "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output space
            "mov v0, va1      \n";  // pass texture coordinates to fragment program
        
        /** The standard fragment shader code. It just forwards the texture color to the output. */
        protected const STD_FRAGMENT_SHADER:String =
            "tex oc, v0, fs0 <2d, clamp, linear, mipnone>"; // just forward texture color
        
        private var mVertexPosAtID:int = 0;
        private var mTexCoordsAtID:int = 1;
        private var mBaseTextureID:int = 0;
        private var mMvpConstantID:int = 0;
        
        private var mNumPasses:int;
        private var mPassTextures:Vector.<Texture2D>;

        private var mMode:String;
        private var mResolution:Number;
        private var mMarginX:Number;
        private var mMarginY:Number;
        private var mOffsetX:Number;
        private var mOffsetY:Number;
        
        private var mVertexData:VertexData2D;
        private var mVertexBuffer:VertexBuffer3D;
        private var mIndexData:Vector.<uint>;
        private var mIndexBuffer:IndexBuffer3D;
        
        private var mCacheRequested:Boolean;
        private var mCache:QuadBatch2D;
        
        /** helper objects. */
        private var mProjMatrix:Matrix = new Matrix();
        private static var sBounds:Rectangle  = new Rectangle();
        private static var sStageBounds:Rectangle = new Rectangle();
        private static var sTransformationMatrix:Matrix = new Matrix();
        
        /** Creates a new Fragment filter with the specified number of passes and resolution.
         *  This constructor may only be called by the constructor of a subclass. */
        public function FragmentFilter2D(numPasses:int=1, resolution:Number=1.0)
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "starling.filters::FragmentFilter")
            {
                throw new AbstractClassException(this);
            }
            
            if (numPasses < 1) throw new ArgumentError("At least one pass is required.");
            
            mNumPasses = numPasses;
            mMarginX = mMarginY = 0.0;
            mOffsetX = mOffsetY = 0;
            mResolution = resolution;
            mMode = FragmentFilterMode2D.REPLACE;
            
            mVertexData = new VertexData2D(4);
            mVertexData.setTexCoords(0, 0, 0);
            mVertexData.setTexCoords(1, 1, 0);
            mVertexData.setTexCoords(2, 0, 1);
            mVertexData.setTexCoords(3, 1, 1);
            
            mIndexData = new <uint>[0, 1, 2, 1, 3, 2];
            mIndexData.fixed = true;
            
            createPrograms();
            
            // Handle lost context. By using the conventional event, we can make it weak; this  
            // avoids memory leaks when people forget to call "dispose" on the filter.
            Render2D.current.stage3D.addEventListener(Event2D.CONTEXT3D_CREATE, 
                onContextCreated, false, 0, true);
        }
        
        /** Disposes the filter (programs, buffers, textures). */
        public function dispose():void
        {
            Render2D.current.stage3D.removeEventListener(Event2D.CONTEXT3D_CREATE, onContextCreated);
            if (mVertexBuffer) mVertexBuffer.dispose();
            if (mIndexBuffer)  mIndexBuffer.dispose();
            disposePassTextures();
            disposeCache();
        }
        
        private function onContextCreated(event:Object):void
        {
            mVertexBuffer = null;
            mIndexBuffer  = null;
            mPassTextures = null;
            
            createPrograms();
        }
        
        /** Applies the filter on a certain display object, rendering the output into the current 
         *  render target. This method is called automatically by Starling's rendering system 
         *  for the object the filter is attached to. */
        public function render(object:DisplayObject2D, support:RenderSupport2D, parentAlpha:Number):void
        {
            // bottom layer
            
            if (mode == FragmentFilterMode2D.ABOVE)
                object.render(support, parentAlpha);
            
            // center layer
            
            if (mCacheRequested)
            {
                mCacheRequested = false;
                mCache = renderPasses(object, support, 1.0, true);
                disposePassTextures();
            }
            
            if (mCache)
                mCache.render(support, parentAlpha);
            else
                renderPasses(object, support, parentAlpha, false);
            
            // top layer
            
            if (mode == FragmentFilterMode2D.BELOW)
                object.render(support, parentAlpha);
        }
        
        private function renderPasses(object:DisplayObject2D, support:RenderSupport2D, 
                                      parentAlpha:Number, intoCache:Boolean=false):QuadBatch2D
        {
            var cacheTexture:Texture2D = null;
            var stage:Stage2D = object.stage;
            var context:Context3D = Render2D.context;
            var scale:Number = Render2D.current.contentScaleFactor;
            
            if (stage   == null) throw new Error("Filtered object must be on the stage.");
            if (context == null) throw new MissingContext3DException();
            
            // the bounds of the object in stage coordinates 
            calculateBounds(object, stage, !intoCache, sBounds);
            
            if (sBounds.isEmpty())
            {
                disposePassTextures();
                return intoCache ? new QuadBatch2D() : null; 
            }
            
            updateBuffers(context, sBounds);
            updatePassTextures(sBounds.width, sBounds.height, mResolution * scale);

            support.finishQuadBatch();
            support.raiseDrawCount(mNumPasses);
            support.pushMatrix();
            
            // save original projection matrix and render target
            mProjMatrix.copyFrom(support.projectionMatrix); 
            var previousRenderTarget:Texture2D = support.renderTarget;
            
            if (previousRenderTarget)
                throw new IllegalOperationError(
                    "It's currently not possible to stack filters! " +
                    "This limitation will be removed in a future Stage3D version.");
            
            if (intoCache) 
                cacheTexture = Texture2D.empty(sBounds.width, sBounds.height, PMA, true, 
                                             mResolution * scale);
            
            // draw the original object into a texture
            support.renderTarget = mPassTextures[0];
            support.clear();
            support.blendMode = BlendMode2D.NORMAL;
            support.setOrthographicProjection(sBounds.x, sBounds.y, sBounds.width, sBounds.height);
            object.render(support, parentAlpha);
            support.finishQuadBatch();
            
            // prepare drawing of actual filter passes
            RenderSupport2D.setBlendFactors(PMA);
            support.loadIdentity();  // now we'll draw in stage coordinates!
            
            context.setVertexBufferAt(mVertexPosAtID, mVertexBuffer, VertexData2D.POSITION_OFFSET, 
                                      Context3DVertexBufferFormat.FLOAT_2);
            context.setVertexBufferAt(mTexCoordsAtID, mVertexBuffer, VertexData2D.TEXCOORD_OFFSET,
                                      Context3DVertexBufferFormat.FLOAT_2);
            
            // draw all passes
            for (var i:int=0; i<mNumPasses; ++i)
            {
                if (i < mNumPasses - 1) // intermediate pass  
                {
                    // draw into pass texture
                    support.renderTarget = getPassTexture(i+1);
                    support.clear();
                }
                else // final pass
                {
                    if (intoCache)
                    {
                        // draw into cache texture
                        support.renderTarget = cacheTexture;
                        support.clear();
                    }
                    else
                    {
                        // draw into back buffer, at original (stage) coordinates
                        support.renderTarget = previousRenderTarget;
                        support.projectionMatrix.copyFrom(mProjMatrix); // restore projection matrix
                        support.translateMatrix(mOffsetX, mOffsetY);
                        support.blendMode = object.blendMode;
                        support.applyBlendMode(PMA);
                    }
                }
                
                var passTexture:Texture2D = getPassTexture(i);
                
                context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, mMvpConstantID, 
                                                      support.mvpMatrix3D, true);
                context.setTextureAt(mBaseTextureID, passTexture.base);
                
                activate(i, context, passTexture);
                context.drawTriangles(mIndexBuffer, 0, 2);
                deactivate(i, context, passTexture);
            }
            
            // reset shader attributes
            context.setVertexBufferAt(mVertexPosAtID, null);
            context.setVertexBufferAt(mTexCoordsAtID, null);
            context.setTextureAt(mBaseTextureID, null);
            
            support.popMatrix();
            
            if (intoCache)
            {
                // restore support settings
                support.renderTarget = previousRenderTarget;
                support.projectionMatrix.copyFrom(mProjMatrix);
                
                // Create an image containing the cache. To have a display object that contains
                // the filter output in object coordinates, we wrap it in a QuadBatch: that way,
                // we can modify it with a transformation matrix.
                
                var quadBatch:QuadBatch2D = new QuadBatch2D();
                var image:Image2D = new Image2D(cacheTexture);
                
                stage.getTransformationMatrix(object, sTransformationMatrix);
                MatrixUtil2D.prependTranslation(sTransformationMatrix, 
                                              sBounds.x + mOffsetX, sBounds.y + mOffsetY);
                quadBatch.addImage(image, 1.0, sTransformationMatrix);

                return quadBatch;
            }
            else return null;
        }
        
        // helper methods
        
        private function updateBuffers(context:Context3D, bounds:Rectangle):void
        {
            mVertexData.setPosition(0, bounds.x, bounds.y);
            mVertexData.setPosition(1, bounds.right, bounds.y);
            mVertexData.setPosition(2, bounds.x, bounds.bottom);
            mVertexData.setPosition(3, bounds.right, bounds.bottom);
            
            if (mVertexBuffer == null)
            {
                mVertexBuffer = context.createVertexBuffer(4, VertexData2D.ELEMENTS_PER_VERTEX);
                mIndexBuffer  = context.createIndexBuffer(6);
                mIndexBuffer.uploadFromVector(mIndexData, 0, 6);
            }
            
            mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, 4);
        }
        
        private function updatePassTextures(width:int, height:int, scale:Number):void
        {
            var numPassTextures:int = mNumPasses > 1 ? 2 : 1;
            
            var needsUpdate:Boolean = mPassTextures == null || 
                mPassTextures.length != numPassTextures ||
                mPassTextures[0].width != width || mPassTextures[0].height != height;  
            
            if (needsUpdate)
            {
                if (mPassTextures)
                {
                    for each (var texture:Texture2D in mPassTextures) 
                        texture.dispose();
                    
                    mPassTextures.length = numPassTextures;
                }
                else
                {
                    mPassTextures = new Vector.<Texture2D>(numPassTextures);
                }
                
                for (var i:int=0; i<numPassTextures; ++i)
                    mPassTextures[i] = Texture2D.empty(width, height, PMA, true, scale);
            }
        }
        
        private function getPassTexture(pass:int):Texture2D
        {
            return mPassTextures[pass % 2];
        }
        
        /** Calculates the bounds of the filter in stage coordinates, while making sure that the 
         *  according textures will have powers of two. */
        private function calculateBounds(object:DisplayObject2D, stage:Stage2D, 
                                         intersectWithStage:Boolean, resultRect:Rectangle):void
        {
            // optimize for full-screen effects
            if (object == stage || object == Render2D.current.root)
                resultRect.setTo(0, 0, stage.stageWidth, stage.stageHeight);
            else
                object.getBounds(stage, resultRect);
            
            if (intersectWithStage)
            {
                sStageBounds.setTo(0, 0, stage.stageWidth, stage.stageHeight);
                RectangleUtil2D.intersect(resultRect, sStageBounds, resultRect);
            }
            
            if (!resultRect.isEmpty())
            {    
                // the bounds are a rectangle around the object, in stage coordinates,
                // and with an optional margin. To fit into a POT-texture, it will grow towards
                // the right and bottom.
                var deltaMargin:Number = mResolution == 1.0 ? 0.0 : 1.0 / mResolution; // avoid hard edges
                resultRect.x -= mMarginX + deltaMargin;
                resultRect.y -= mMarginY + deltaMargin;
                resultRect.width  += 2 * (mMarginX + deltaMargin);
                resultRect.height += 2 * (mMarginY + deltaMargin);
                resultRect.width  = getNextPowerOfTwo2D(resultRect.width  * mResolution) / mResolution;
                resultRect.height = getNextPowerOfTwo2D(resultRect.height * mResolution) / mResolution;
            }
        }
        
        private function disposePassTextures():void
        {
            for each (var texture:Texture2D in mPassTextures)
                texture.dispose();
            
            mPassTextures = null;
        }
        
        private function disposeCache():void
        {
            if (mCache)
            {
                if (mCache.texture) mCache.texture.dispose();
                mCache.dispose();
                mCache = null;
            }
        }
        
        // protected methods

        /** Subclasses must override this method and use it to create their 
         *  fragment- and vertex-programs. */
        protected function createPrograms():void
        {
            throw new Error("Method has to be implemented in subclass!");
        }

        /** Subclasses must override this method and use it to activate their fragment- and 
         *  to vertext-programs.
         *  The 'activate' call directly precedes the call to 'context.drawTriangles'. Set up
         *  the context the way your filter needs it. The following constants and attributes 
         *  are set automatically:
         *  
         *  <ul><li>vertex constants 0-3: mvpMatrix (3D)</li>
         *      <li>vertex attribute 0: vertex position (FLOAT_2)</li>
         *      <li>vertex attribute 1: texture coordinates (FLOAT_2)</li>
         *      <li>texture 0: input texture</li>
         *  </ul>
         *  
         *  @param pass: the current render pass, starting with '0'. Multipass filters can
         *               provide different logic for each pass.
         *  @param context: the current context3D (the same as in Starling.context, passed
         *               just for convenience)
         *  @param texture: the input texture, which is already bound to sampler 0. */
        protected function activate(pass:int, context:Context3D, texture:Texture2D):void
        {
            throw new Error("Method has to be implemented in subclass!");
        }
        
        /** This method is called directly after 'context.drawTriangles'. 
         *  If you need to clean up any resources, you can do so in this method. */
        protected function deactivate(pass:int, context:Context3D, texture:Texture2D):void
        {
            // clean up resources
        }
        
        /** Assembles fragment- and vertex-shaders, passed as Strings, to a Program3D. 
         *  If any argument is  null, it is replaced by the class constants STD_FRAGMENT_SHADER or
         *  STD_VERTEX_SHADER, respectively. */
        protected function assembleAgal(fragmentShader:String=null, vertexShader:String=null):Program3D
        {
            if (fragmentShader == null) fragmentShader = STD_FRAGMENT_SHADER;
            if (vertexShader   == null) vertexShader   = STD_VERTEX_SHADER;
            
            return RenderSupport2D.assembleAgal(vertexShader, fragmentShader);
        }
        
        // cache
        
        /** Caches the filter output into a texture. An uncached filter is rendered in every frame;
         *  a cached filter only once. However, if the filtered object or the filter settings
         *  change, it has to be updated manually; to do that, call "cache" again. */
        public function cache():void
        {
            mCacheRequested = true;
            disposeCache();
        }
        
        /** Clears the cached output of the filter. After calling this method, the filter will
         *  be executed once per frame again. */ 
        public function clearCache():void
        {
            mCacheRequested = false;
            disposeCache();
        }
        
        // flattening
        
        /** @private */
        render2d_internal function compile(object:DisplayObject2D):QuadBatch2D
        {
            if (mCache) return mCache;
            else
            {
                var renderSupport:RenderSupport2D;
                var stage:Stage2D = object.stage;
                
                if (stage == null) 
                    throw new Error("Filtered object must be on the stage.");
                
                renderSupport = new RenderSupport2D();
                object.getTransformationMatrix(stage, renderSupport.modelViewMatrix);
                return renderPasses(object, renderSupport, 1.0, true);
            }
        }
        
        // properties
        
        /** Indicates if the filter is cached (via the "cache" method). */
        public function get isCached():Boolean { return (mCache != null) || mCacheRequested; }
        
        /** The resolution of the filter texture. "1" means stage resolution, "0.5" half the
         *  stage resolution. A lower resolution saves memory and execution time (depending on 
         *  the GPU), but results in a lower output quality. Values greater than 1 are allowed;
         *  such values might make sense for a cached filter when it is scaled up. @default 1 */
        public function get resolution():Number { return mResolution; }
        public function set resolution(value:Number):void 
        {
            if (value <= 0) throw new ArgumentError("Resolution must be > 0");
            else mResolution = value; 
        }
        
        /** The filter mode, which is one of the constants defined in the "FragmentFilterMode" 
         *  class. @default "replace" */
        public function get mode():String { return mMode; }
        public function set mode(value:String):void { mMode = value; }
        
        /** Use the x-offset to move the filter output to the right or left. */
        public function get offsetX():Number { return mOffsetX; }
        public function set offsetX(value:Number):void { mOffsetX = value; }
        
        /** Use the y-offset to move the filter output to the top or bottom. */
        public function get offsetY():Number { return mOffsetY; }
        public function set offsetY(value:Number):void { mOffsetY = value; }
        
        /** The x-margin will extend the size of the filter texture along the x-axis.
         *  Useful when the filter will "grow" the rendered object. */
        protected function get marginX():Number { return mMarginX; }
        protected function set marginX(value:Number):void { mMarginX = value; }
        
        /** The y-margin will extend the size of the filter texture along the y-axis.
         *  Useful when the filter will "grow" the rendered object. */
        protected function get marginY():Number { return mMarginY; }
        protected function set marginY(value:Number):void { mMarginY = value; }
        
        /** The number of passes the filter is applied. The "activate" and "deactivate" methods
         *  will be called that often. */
        protected function set numPasses(value:int):void { mNumPasses = value; }
        protected function get numPasses():int { return mNumPasses; }
        
        /** The ID of the vertex buffer attribute that stores the vertex position. */ 
        protected final function get vertexPosAtID():int { return mVertexPosAtID; }
        protected final function set vertexPosAtID(value:int):void { mVertexPosAtID = value; }
        
        /** The ID of the vertex buffer attribute that stores the texture coordinates. */
        protected final function get texCoordsAtID():int { return mTexCoordsAtID; }
        protected final function set texCoordsAtID(value:int):void { mTexCoordsAtID = value; }

        /** The ID (sampler) of the input texture (containing the output of the previous pass). */
        protected final function get baseTextureID():int { return mBaseTextureID; }
        protected final function set baseTextureID(value:int):void { mBaseTextureID = value; }
        
        /** The ID of the first register of the modelview-projection constant (a 4x4 matrix). */
        protected final function get mvpConstantID():int { return mMvpConstantID; }
        protected final function set mvpConstantID(value:int):void { mMvpConstantID = value; }
    }
}