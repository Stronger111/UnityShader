#ifndef SNOWCORE_CGINC
#define SNOWCORE_CGINC

inline float3 Overlay(float3 m, float3 color)
{
	color = saturate(color);
	float3 check = step(float3(0.5,0.5,0.5), color.rgb);
	float3 result = check * (float3(1,1,1) - ((float3(1,1,1) - 2*(color.rgb-0.5)) * (1-m.rgb))); 
	result += (1-check) * (2*color.rgb) * m.rgb;
	return result;
}

inline float3 Screen(float3 base, float3 blend)
{
	return (1.0 - ((1.0 - base) * (1.0 - blend)));
}

#endif