// Blackfire Studio
// Matthieu Ostertag

#ifndef SNOW_SURFACE_CGINC
#define SNOW_SURFACE_CGINC

	void SnowSurface(Input IN, inout SnowOutput o)
	{
		half3 normal	= UnpackNormal(tex2D(_BumpTex, IN.uv_BumpTex));	// Base Normal map
		half4 albedo	= tex2D(_MainTex, IN.uv_MainTex);
		
		#if defined(SNOW_BLEND_ADVANCED) || defined(SNOW_BLEND_TEXTURE) || defined(SNOW_BLEND_HEIGHT)
			half3 depth		= tex2D(_DepthTex, IN.uv_SubNormal);
		#else
			half3 depth		= tex2D(_DepthTex, IN.uv_MainTex);
		#endif
		
		#if defined(SNOW_BLEND_ADVANCED) || defined(SNOW_BLEND_TEXTURE) || defined(SNOW_BLEND_HEIGHT)
			// Sub-Normal map (you don't need to convert texture to Normal because of the * 2 - 1 trick. Then you can use alpha)
			half3 subnormal		= UnpackNormal(tex2D(_SubNormal, IN.uv_SubNormal));
			#if defined(SNOW_BLEND_ADVANCED)
				float3 NdotD	= dot(WorldNormalVector(IN, float3(0, 0, 1)), normalize(_Direction.xyz));	// Cross product for WorldNormal and Direction
				half coverage	= NdotD - lerp(1, -1, _Coverage);											// Blending for general coverage
				coverage		= saturate(coverage / _Spread);
				half subheightcoverage	= depth.g - lerp(1, -1, coverage);									// Blending for Sub-Height
				half subnormalcoverage	= NdotD - lerp(1, -1, subheightcoverage + _Transition);				// Blending for Sub-Normal
			#elif defined(SNOW_BLEND_TEXTURE)
				half coverage			= albedo.a;
				coverage				= saturate(coverage / _Spread);
				half subheightcoverage	= depth.g - lerp(1, -1, coverage);
				half subnormalcoverage	= 1 - lerp(1, -1, subheightcoverage + _Transition);
			#elif defined(SNOW_BLEND_HEIGHT)
				half coverage	= lerp(-1, 1 + _Height, albedo.a);
				coverage		= saturate(coverage / _Spread);
				half subheightcoverage	= depth.g - lerp(1, -1, coverage);
				half subnormalcoverage	= 1 - lerp(1, -1, subheightcoverage + _Transition);
			#endif
			subnormalcoverage = saturate(subnormalcoverage / _TransitionSmooth);
			subheightcoverage = saturate(subheightcoverage / _Smooth);
		#endif
		
		o.Albedo = albedo.rgb;
		
		#if defined(SNOW_BLEND_ADVANCED) || defined(SNOW_BLEND_TEXTURE) || defined(SNOW_BLEND_HEIGHT)
			o.Normal		= lerp(subnormal, normal, subnormalcoverage);
		#else
			o.Normal		= normal;
		#endif
		
		#ifndef SNOW_GLITTER
			o.Specular		= tex2D(_GlitterTex, IN.uv_GlitterTex);
		#else
			o.Specular		= UnpackNormal(tex2D(_GlitterTex, IN.uv_GlitterTex));
		#endif
		
		#ifdef SNOW_BLEND_ADVANCED
			o.Alpha		= subheightcoverage * (_Coverage <= 0.0 ? 0 : 1);		// Avoids antialias glitch on low coverage value
		#elif defined(SNOW_BLEND_TEXTURE) || defined(SNOW_BLEND_HEIGHT)
			o.Alpha		= subheightcoverage;
		#endif
		
		o.Depth		= depth.r;
		
		#ifdef SNOW_REFLECTION
			half falloff = 1.0 - saturate(dot(o.Normal, normalize(IN.viewDir)));
			falloff = pow(falloff, _Falloff);
			o.Emission = (texCUBE(_Cube, WorldReflectionVector(IN, o.Normal)).rgb * _Reflection) * falloff;
		#endif
	}

#endif