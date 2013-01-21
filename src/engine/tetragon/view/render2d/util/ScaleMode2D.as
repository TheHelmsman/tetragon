package tetragon.view.render2d.util
{
	import com.hexagonstar.exception.AbstractClassException;

    /** A class that provides constant values for the 'RectangleUtil.fit' method. */
    public class ScaleMode2D
    {
        /** @private */
        public function ScaleMode2D() { throw new AbstractClassException(this); }
        
        /** Specifies that the rectangle is not scaled, but simply centered within the 
         *  specified area. */
        public static const NONE:String = "none";
        
        /** Specifies that the rectangle fills the specified area without distortion 
         *  but possibly with some cropping, while maintaining the original aspect ratio. */
        public static const NO_BORDER:String = "noBorder";
        
        /** Specifies that the entire rectangle will be scaled to fit into the specified 
         *  area, while maintaining the original aspect ratio. This might leave empty bars at
         *  either the top and bottom, or left and right. */
        public static const SHOW_ALL:String = "showAll";
        
        /** Indicates whether the given scale mode string is valid. */
        public static function isValid(scaleMode:String):Boolean
        {
            return scaleMode == NONE || scaleMode == NO_BORDER || scaleMode == SHOW_ALL;
        }
    }
}