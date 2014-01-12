package away3d.filters.tasks;

	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	
	import flash.display3D.Context3D;
	
	import flash.display3D.Context3DProgramType;
	
	import flash.display3D.textures.Texture;
	
	//use namespace arcane;
	
	class Filter3DRadialBlurTask extends Filter3DTaskBase
	{
		private static var LAYERS:Int = 15;
		
		var _data:Array<Float>;
		
		var _intensity:Float = 1.0;
		var _glowGamma:Float = 1.0;
		var _blurStart:Float = 1.0;
		var _blurWidth:Float = -0.3;
		var _cx:Float = 0.5;
		var _cy:Float = 0.5;
		
		public function new(intensity:Float = 1.0, glowGamma:Float = 1.0, blurStart:Float = 1.0, blurWidth:Float = -0.3, cx:Float = 0.5, cy:Float = 0.5)
		{
			super();
			_intensity = intensity;
			_glowGamma = glowGamma;
			_blurStart = blurStart;
			_blurWidth = blurWidth;
			_cx = cx;
			_cy = cy;
			_data = Array<Float>([0, 0, 0, 0, 0, 0, 0, 0, 0, 1, LAYERS, LAYERS - 1]);
			resetUniforms();
		}
		
		private function resetUniforms():Void
		{
			_data[0] = _intensity;
			_data[1] = _glowGamma;
			_data[2] = _blurStart;
			_data[3] = _blurWidth;
			_data[4] = _cx;
			_data[5] = _cy;
		}
		
		override private function getVertexCode():String
		{
			return "mov op, va0\n" +
				"mov vt0, vc2.xxxy\n" +
				"sub vt0.xy, va1.xy, vc1.xy \n" +
				"mov v0, vt0";
		}
		
		override private function getFragmentCode():String
		{
			var code:String;
			
			code =
				//half4 blurred = 0,0,0,0; = ft1
				"mov ft1, fc2.xxxx \n" +
				// float2 ctrPt = float2(CX,CY); -> ft2
				"mov ft2.xy, fc1.xy \n" +
				// ft3.x -> counter = 0;
				"mov ft3.x, fc2.x \n";
			
			// Y-Axis
			// For loop conversion - 			for (var i:Int = 0; i <= LAYERS; i++)
			var i:Int;
			for (i in 0...LAYERS) {
				// float scale = BlurStart + BlurWidth*(i/(float) (nsamples-1)); -> ft4
				// ft4.x = (i/(float) (nsamples-1))
				code += "div ft4.x, ft3.x, fc2.w\n";
				// ft4.x *= Blurwidth;
				code += "mul ft4.x, ft4.x, fc0.w \n";
				// ft4.x += BlurStart;
				code += "add ft4.x, ft4.x, fc0.z \n";
				// blurred += tex2D(tex, IN.UV.xy*scale + ctrPt );
				code += "mov ft5.xy ,v0.xy\n";
				code += "mul ft5.xy, ft5.xy, ft4.xx \n";
				code += "add ft5.xy, ft5.xy, fc1.xy \n";
				code += "tex ft5, ft5.xy, fs0<2d, clamp, linear>\n";
				code += "add ft1, ft1, ft5 \n";
				// inc counter by one
				code += "add ft3.x, ft3.x, fc2.y \n";
			}
			/*     blurred /= nsamples;
			 blurred.rgb = pow(blurred.rgb,GlowGamma);
			 blurred.rgb *= Intensity;
			 blurred.rgb = saturate(blurred.rgb);
			 */
			code += "div ft1, ft1, fc2.z\n";
			code += "pow ft1.xyz, ft1.xyz, fc0.y\n";
			code += "mul ft1.xyz, ft1.xyz, fc0.x\n";
			code += "sat ft1.xyz, ft1.xyz \n";
			// var origTex = tex2D(tex, IN.UV.xy + ctrPt );
			code += "add ft0.xy, v0.xy, fc1.xy \n";
			code += "tex ft6, ft0.xy, fs0<2d,clamp, linear>\n";
			// var newC = origTex.rgb + blurred.rgb;
			code += "add ft1.xyz, ft1.xyz, ft6.xyz \n";
			// return newC
			code += "mov oc, ft1\n";
			
			//trace(code);
			return code;
		}
		
		public var intensity(get, set) : Float;
		
		public function get_intensity() : Float
		{
			return _intensity;
		}
		
		public function set_intensity(intensity:Float) : Float
		{
			_intensity = intensity;
			resetUniforms();
		}
		
		public var glowGamma(get, set) : Float;
		
		public function get_glowGamma() : Float
		{
			return _glowGamma;
		}
		
		public function set_glowGamma(glowGamma:Float) : Float
		{
			_glowGamma = glowGamma;
			resetUniforms();
		}
		
		public var blurStart(get, set) : Float;
		
		public function get_blurStart() : Float
		{
			return _blurStart;
		}
		
		public function set_blurStart(blurStart:Float) : Float
		{
			_blurStart = blurStart;
			resetUniforms();
		}
		
		public var blurWidth(get, set) : Float;
		
		public function get_blurWidth() : Float
		{
			return _blurWidth;
		}
		
		public function set_blurWidth(blurWidth:Float) : Float
		{
			_blurWidth = blurWidth;
			resetUniforms();
		}
		
		public var cx(get, set) : Float;
		
		public function get_cx() : Float
		{
			return _cx;
		}
		
		public function set_cx(cx:Float) : Float
		{
			_cx = cx;
			resetUniforms();
		}
		
		public var cy(get, set) : Float;
		
		public function get_cy() : Float
		{
			return _cy;
		}
		
		public function set_cy(cy:Float) : Float
		{
			_cy = cy;
			resetUniforms();
		}
		
		override public function activate(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void
		{
			var context:Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _data, 3);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 3);
		}
	}
