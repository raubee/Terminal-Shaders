// From my shadertoy https://www.shadertoy.com/view/wlc3z8 : Glowing tunnel effect

// The terminal graphics as a texture
Texture2D shaderTexture;
SamplerState samplerState;

// Terminal settings such as the resolution of the texture
cbuffer PixelShaderSettings {
  // The number of seconds since the pixel shader was enabled
  float  Time;
  // UI Scale
  float  Scale;
  // Resolution of the shaderTexture
  float2 Resolution;
  // Background color as rgba
  float4 Background;
};

float3 rgb2hsv(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// From iq - https://www.shadertoy.com/view/MsS3Wc
float3 hsv2rgb_smooth( float3 c )
{
  float3 rgb = clamp( abs(fmod(c.x*6.0+float3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	
	return c.z * lerp( float3(1.0,1.0,1.0), rgb, c.y);
}

float tunnel(float3 p)
{
    p.z+=Time;
    p.xy+=sin(p.z)*.5+sin(p.xz*12.)*.05+sin(p.zy*20.)*.025; 
    return 1.-length(p.xy);
}

float map(float3 p)
{
    return tunnel(p);
}

float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
{
    float4 color = shaderTexture.Sample(samplerState, tex);

    tex = 2.*tex - 1.;
    tex.x *= Resolution.x/Resolution.y;
    
    float3 cz = normalize(float3(0.0,0.0,1.0));
    float3 cx = normalize(cross(cz,float3(0.0,1.0,0.0)));
    float3 cy = normalize(cross(cx,cz));

    float3 z = float3(cx*tex.x + cy*tex.y + cz*.15);
    float3 p = float3(0,0,0);
    
    float d = 0.;
    float att = 0.;
    
    for(int i = 0; i < 256; ++i)
    {
        d=map(p);
        if(d < .0001)break;
        if(d > 10000.0)break;
        p+= z * d;
        att+=0.2/(abs(d)+0.2);
    }
    
    float3 rC = rgb2hsv(float3(.75,.2,0.10));
    rC.r=p.z*0.01+sin(-Time*0.05);
    rC = hsv2rgb_smooth(rC);
    
    if(d < 10000.0)
    {
        rC *= 0.3 + att*0.006;
    }
    
    rC*=1.-length(tex*.5);
    color.rgb = max(rC,color.rgb);

    return color;
}