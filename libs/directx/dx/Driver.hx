package dx;

typedef DriverInstance = hl.Abstract<"dx_driver">;

abstract Shader(hl.Abstract<"dx_shader">) {
	@:hlNative("directx", "release_shader") public function release() {
	}
}

abstract Layout(hl.Abstract<"dx_layout">) {
	@:hlNative("directx", "release_layout") public function release() {
	}
}

abstract RasterState(hl.Abstract<"dx_raster">) {
	@:hlNative("directx", "release_raster") public function release() {
	}
}

abstract RenderTargetView(hl.Abstract<"dx_render_target">) {
	@:hlNative("directx", "release_render_target") public function release() {
	}
}

abstract DepthStencilView(hl.Abstract<"dx_depth_stencil">) {
	@:hlNative("directx", "release_depth_stencil") public function release() {
	}
}

@:enum abstract DriverInitFlags(Int) {
	var None = 0;
	var SingleThread = 1;
	var DebugLayer = 2;
	var SwitchToRef = 4;
	var PreventInternalThreadingOptimizations = 8;
	var BgraSupport = 32;
	var Debuggable = 64;
	var PreventAlteringLayerSettingsFromRegistry = 128;
	var DisableGpuTimeout = 256;
	var VideoSupport = 2048;
	@:op(a | b) static function or(a:DriverInitFlags, b:DriverInitFlags) : DriverInitFlags;
}

@:enum abstract ShaderFlags(Int) {
	var None = 0;
	var Debug = 0x1;
	var SkipValidation = 0x2;
	var SkipOptimization = 0x4;
	var PackMatrixRowMajor = 0x8;
	var PackMatrixColumnMajor = 0x10;
	var PartialPrecision = 0x20;
	var ForceVSSoftwareNoOpt = 0x40;
	var ForcePSSoftwareNoOpt = 0x80;
	var NoPreshader = 0x100;
	var AvoidFlowControl = 0x200;
	var PreferFlowControl = 0x400;
	var EnableStrictness = 0x800;
	var EnableBackwardsCompatibility = 0x1000;
	var IEEEStrictness = 0x2000;
	var OptimizationLevel0 = 0x4000;
	var OptimizationLevel1 = 0; // default
	var OptimizationLevel2 = 0x4000 | 0x8000;
	var OptimizationLevel3 = 0x8000;
	var WarningsAreErrors = 0x40000;
	var ResourcesMayAlias = 0x80000;
	var EnableUnboundedDescriptorTables = 0x100000;
	var AllResourcesBound = 0x200000;
	@:op(a | b) static function or(a:ShaderFlags, b:ShaderFlags) : ShaderFlags;
}

@:enum abstract PrimitiveTopology(Int) {
	var Undefined = 0;
	var PointList = 1;
	var LineList = 2;
	var LineStrip = 3;
	var TriangleList = 4;
	var TriangleStrip = 5;
	var LineListAdj = 10;
	var TriangleListAdj = 12;
	var TriangleStripAdj = 13;
	static inline function controlPointPatchList(count:Int) : PrimitiveTopology return cast (count + 32);
}

@:enum abstract DisassembleFlags(Int) {
	var None = 0;
	var EnableColorCode = 1;
	var EnableDefaultValuePrints = 2;
	var EnableInstructionNumbering = 4;
	var EnableInsructionCycle = 8;
	var DisableDebugInfo = 0x10;
	var EnableInstructionOffset = 0x20;
	var InstructionOnly = 0x40;
	var PrintHexLiterals = 0x80;
	@:op(a | b) static function or(a:DisassembleFlags, b:DisassembleFlags) : DisassembleFlags;
}

@:enum abstract LayoutClassification(Int) {
	var PerVertexData = 0;
	var PerInstanceData = 0;
}


class LayoutElement {
	public var semanticName : hl.Bytes;
	public var semanticIndex : Int;
	public var format : Format;
	public var inputSlot : Int;
	public var alignedByteOffset : Int;
	public var inputSlotClass : LayoutClassification;
	public var instanceDataStepRate : Int;
	public function new() {
	}
}

@:enum abstract RenderViewDimension(Int) {
	var Unknown = 0;
	var Buffer = 1;
	var Texture1D = 2;
	var Texture1DArray = 3;
	var Texture2D = 4;
	var Texture2DArray = 5;
	var Texture2DMS = 6;
	var Texture2DMSArray = 7;
	var Texture3D = 8;
}

class RenderTargetDesc {
	public var format : Format;
	public var dimension : RenderViewDimension;
	public var mipMap : Int;
	public var firstSlice : Int;
	public var sliceCount : Int;

	// for buffer
	public var firstElement(get, set) : Int;
	public var elementCount(get, set) : Int;

	public function new(format, dimension = Unknown) {
		this.format = format;
		this.dimension = dimension;
	}

	inline function get_firstElement() return mipMap;
	inline function set_firstElement(m) return mipMap = m;
	inline function get_elementCount() return firstSlice;
	inline function set_elementCount(m) return firstSlice = m;
}

@:enum abstract FillMode(Int) {
	public var WireFrame = 2;
	public var Solid = 3;
}

@:enum abstract CullMode(Int) {
	public var None = 1;
	public var Front = 2;
	public var Back = 3;
}

class RasterizerStateDesc {
	public var fillMode : FillMode;
	public var cullMode : CullMode;
	public var frontCounterClockwise : Bool;
	public var depthBias : Int;
	public var depthBiasClamp : hl.F32;
	public var slopeScaledDepthBias : hl.F32;
	public var depthClipEnable : Bool;
	public var scissorEnable : Bool;
	public var multisampleEnable : Bool;
	public var antialiasedLineEnable : Bool;
	public function new() {
	}
}

@:hlNative("directx")
class Driver {

	public static function create( win : Window, flags : DriverInitFlags = None ) {
		return dxCreate(@:privateAccess win.win, flags);
	}

	public static function getBackBuffer() : Resource {
		return null;
	}

	public static function createRenderTargetView( r : Resource, ?desc : RenderTargetDesc ) : RenderTargetView {
		return dxCreateRenderTargetView(r,desc);
	}

	public static function omSetRenderTargets( count : Int, arr : hl.NativeArray<RenderTargetView>, ?depth : DepthStencilView ) {
	}

	public static function createRasterizerState( desc : RasterizerStateDesc ) : RasterState {
		return dxCreateRasterizerState(desc);
	}

	public static function rsSetState( r : RasterState ) {
	}

	public static function rsSetViewports( count : Int, bytes : hl.BytesAccess<hl.F32> ) {
	}

	public static function clearColor( rt : RenderTargetView, r : Float, g : Float, b : Float, a : Float ) {
	}

	public static function present() {
	}

	public static function getDeviceName() {
		return @:privateAccess String.fromUCS2(dxGetDeviceName());
	}

	public static function getScreenWidth() {
		return 0;
	}

	public static function getScreenHeight() {
		return 0;
	}

	public static function getSupportedVersion() : Float {
		return 0.;
	}

	public static function compileShader( data : String, source : String, entryPoint : String, target : String, flags : ShaderFlags ) : haxe.io.Bytes @:privateAccess {
		var isError = false, size = 0;
		var out = dxCompileShader(data.toUtf8(), data.length, source.toUtf8(), entryPoint.toUtf8(), target.toUtf8(), flags, isError, size);
		if( isError )
			throw String.fromUTF8(out);
		return out.toBytes(size);
	}

	public static function disassembleShader( data : haxe.io.Bytes, flags : DisassembleFlags, ?comments : String ) : String {
		var size = 0;
		var out = dxDisassembleShader(data, data.length, flags, comments == null ? null : @:privateAccess comments.toUtf8(), size);
		if( out == null )
			throw "Could not disassemble shader";
		return @:privateAccess String.fromUTF8(out);
	}

	public static function createVertexShader( bytes : haxe.io.Bytes ) {
		return dxCreateVertexShader(bytes, bytes.length);
	}

	public static function createPixelShader( bytes : haxe.io.Bytes ) {
		return dxCreatePixelShader(bytes, bytes.length);
	}

	public static function drawIndexed( indexCount : Int, startIndex : Int, baseVertex : Int ) : Void {
	}

	public static function vsSetShader( shader : Shader ) : Void {
	}

	public static function vsSetConstantBuffers( start : Int, count : Int, buffers : hl.NativeArray<Resource> ) : Void {
	}

	public static function psSetShader( shader : Shader ) : Void {
	}

	public static function psSetConstantBuffers( start : Int, count : Int, buffers : hl.NativeArray<Resource> ) : Void {
	}

	public static function iaSetPrimitiveTopology( topology : PrimitiveTopology ) : Void {
	}

	public static function iaSetIndexBuffer( buffer : Resource, is32Bits : Bool, offset : Int ) : Void {
	}

	public static function iaSetVertexBuffers( start : Int, count : Int, buffers : hl.NativeArray<Resource>, strides : hl.BytesAccess<Int>, offsets : hl.BytesAccess<Int> ) : Void {
	}

	public static function iaSetInputLayout( layout : Layout ) : Void {
	}

	public static function createInputLayout( elements : hl.NativeArray<LayoutElement>, shaderBytes : hl.Bytes, shaderSize : Int ) : Layout {
		return null;
	}

	@:hlNative("directx", "create_rasterizer_state")
	static function dxCreateRasterizerState( desc : Dynamic ) : RasterState {
		return null;
	}

	@:hlNative("directx", "create_render_target_view")
	static function dxCreateRenderTargetView( r : Resource, desc : Dynamic ) : RenderTargetView {
		return null;
	}

	@:hlNative("directx","create")
	static function dxCreate( win : hl.Abstract < "dx_window" > , flags : DriverInitFlags ) : DriverInstance { return null; }

	@:hlNative("directx","get_device_name")
	static function dxGetDeviceName() : hl.Bytes { return null; }

	@:hlNative("directx","compile_shader")
	static function dxCompileShader( data : hl.Bytes, size : Int, source : hl.Bytes, entry : hl.Bytes, target : hl.Bytes, flags : ShaderFlags, error : hl.Ref<Bool>, outSize : hl.Ref<Int> ) : hl.Bytes {
		return null;
	}

	@:hlNative("directx", "disassemble_shader")
	static function dxDisassembleShader( data : hl.Bytes, size : Int, flags : DisassembleFlags, comments : hl.Bytes, outSize : hl.Ref<Int> ) : hl.Bytes {
		return null;
	}

	@:hlNative("directx","create_vertex_shader")
	static function dxCreateVertexShader( data : hl.Bytes, size : Int ) : Shader {
		return null;
	}

	@:hlNative("directx","create_pixel_shader")
	static function dxCreatePixelShader( data : hl.Bytes, size : Int ) : Shader {
		return null;
	}

}