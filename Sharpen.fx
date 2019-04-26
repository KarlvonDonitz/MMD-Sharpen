//edit by KarlVonDonitz
float Extent
<
   string UIName = "Extent";
   string UIWidget = "Slider";
   bool UIVisible =  true;
   float UIMin = 0.00;
   float UIMax = 0.01;
> = float( 0.007 );

float4 ClearColor
<
   string UIName = "ClearColor";
   string UIWidget = "Color";
   bool UIVisible =  true;
> = float4(0,0,0,0);

float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;

float time :TIME;
float4 MaterialDiffuse : DIFFUSE  < string Object = "Geometry"; >;
static float alpha1 = MaterialDiffuse.a;

float Intensity : CONTROLOBJECT < string name = "(self)"; string item = "Si";>;
float XIntensity : CONTROLOBJECT < string name = "(self)"; string item = "X";>;
float YIntensity : CONTROLOBJECT < string name = "(self)"; string item = "Y";>;
float Flag : CONTROLOBJECT < string name = "(self)"; string item = "Rx";>;
float2 ViewportSize : VIEWPORTPIXELSIZE;

static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);

float ClearDepth  = 1.0;


texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    string Format = "D24S8";
>;


texture2D ScnMap : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1,1};
    int MipLevels = 1;
    string Format = "A8R8G8B8" ;
>;
sampler2D ScnSamp = sampler_state {
    texture = <ScnMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};


struct VS_OUTPUT {
    float4 Pos            : POSITION;
    float2 Tex            : TEXCOORD0;
};

VS_OUTPUT VS_main( float4 Pos : POSITION, float2 Tex : TEXCOORD0 ) {
  
	VS_OUTPUT Out = (VS_OUTPUT)0; 
    Out.Pos = Pos;
    Out.Tex = Tex + ViewportOffset;
    return Out;
}

float4 PS_Effect( float2 Tex: TEXCOORD0 ) : COLOR {   
	float2  intXY = float2(Tex.x * ViewportSize.x , Tex.y * ViewportSize.y);   
	float3x3 Filter = float3x3 (-1,-1,-1 ,
	                            -1, 9,-1,
	                            -1,-1,-1);
	float2 filter_pos_delta[3][3] ={   
{ float2(-1.0 , -1.0) , float2(0,-1.0), float2(1.0 , -1.0) },  
{ float2( 0.0 , -1.0) , float2(0, 0.0), float2(1.0 ,  0.0) }, 
{ float2( 1.0 , -1.0) , float2(0, 1.0), float2(1.0 ,  1.0) },
};   
	float4 Color = 0;
	for(int i = 0 ; i < 3 ; i ++ )  {    
        for(int j = 0 ; j < 3 ; j ++) {
            float2 Final_XY = float2(intXY.x + filter_pos_delta[i][j].x , intXY.y +filter_pos_delta[i][j].y);
            float2 Final_UV = float2(Final_XY.x/ViewportSize.x ,Final_XY.y/ViewportSize.y);
            Color += tex2D(ScnSamp, Final_UV ) * Filter[i][j];
        }
    }
	return Color;
	}

technique Effect <
    string Script = 
        
        "RenderColorTarget0=ScnMap;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "ScriptExternal=Color;"
        
        "RenderColorTarget0=;"
        "RenderDepthStencilTarget=;"
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "Pass=EffectPass;"
    ;
    
> {
    pass EffectPass < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 VS_main();
        PixelShader  = compile ps_3_0 PS_Effect();
    }
}
