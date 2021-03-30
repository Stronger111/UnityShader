// Blackfire Studio
// Matthieu Ostertag

//#ifndef SNOW_INPUTS_CGINC
//#define SNOW_INPUTS_CGINC

	half 		_RampPower;
	half		_Glitter;
	half		_Aniso;
	half		_Shininess;
	half		_Specular;
	float		_Depth;
	#ifdef SNOW_BLEND_ADVANCED
		half4		_Direction;
		half		_Coverage;
	#endif
	#ifdef SNOW_BLEND_HEIGHT
		half		_Height;
	#endif
	#if defined(SNOW_BLEND_ADVANCED) || defined(SNOW_BLEND_TEXTURE) || defined(SNOW_BLEND_HEIGHT)
		half		_Spread;
		half		_Smooth;
		half		_Transition;
		half		_TransitionSmooth;
	#endif
	#ifdef SNOW_REFLECTION
		half		_Reflection;
		half		_Falloff;
	#endif
	#ifdef SNOW_GLITTER
		half4		_SpecularColor;
		half		_Speed;
		half		_Density;
		half		_DensityStatic;
		half		_Power;
	#endif

	sampler2D	_Ramp;
	sampler2D	_MainTex;
	sampler2D	_BumpTex;
	sampler2D	_DepthTex;
	#if defined(SNOW_BLEND_ADVANCED) || defined(SNOW_BLEND_TEXTURE) || defined(SNOW_BLEND_HEIGHT)
		sampler2D	_SubNormal;
	#endif
	sampler2D	_GlitterTex;
	#ifdef SNOW_REFLECTION
		samplerCUBE	_Cube;
	#endif
	
	struct Input
	{
		float2	uv_MainTex;
		//// This might cause problems for marmoset, rtp, terrain or lightmap integration just use uv_MainTex
		float2	uv_BumpTex;
		float2	uv_GlitterTex;
		////
		#if defined(SNOW_BLEND_ADVANCED) || defined(SNOW_BLEND_TEXTURE) || defined(SNOW_BLEND_HEIGHT)
			float2	uv_SubNormal;
	        float3	worldNormal;
		#endif
		#ifdef SNOW_REFLECTION
			float3 worldRefl;
			float3 viewDir;
		#endif
        INTERNAL_DATA
	};
	
	struct SnowOutput
	{
	    half3 	Albedo;
	    half3	Normal;
	    half3 	Emission;
	    half3	Specular;
	    half 	Alpha;
	    half	Depth;
	};

//#endif