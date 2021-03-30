// Blackfire Studio
// Matthieu Ostertag

#ifndef SNOW_LIGHTING_CGINC
#define SNOW_LIGHTING_CGINC
	
	// forward rendering
	inline half4 LightingSnow (SnowOutput s, half3 lightDir, half3 viewDir, half atten)
	{
		half3 H	= normalize(lightDir + viewDir);
		half NdotH = max(0, dot(s.Normal, H));
		half NdotL = dot(s.Normal, lightDir);
		half NdotV = dot(s.Normal, viewDir);
		
		#if defined(SNOW_BLEND_ADVANCED) || defined(SNOW_BLEND_TEXTURE) || defined(SNOW_BLEND_HEIGHT)
			float3 shadow = atten * _LightColor0.rgb * s.Alpha;
		#else
			float3 shadow = atten * _LightColor0.rgb;
		#endif
		
		half3 albedo = s.Albedo * _LightColor0.rgb;
		float y = NdotL * shadow;
		half2 uv_Ramp = half2(_RampPower * NdotV, y);
		half3 ramp = tex2D(_Ramp, uv_Ramp.xy);
		
		half ssatten = 1.0;
		
		if (0.0 != _WorldSpaceLightPos0.w) {
			half depth		= clamp(s.Depth + _Depth, -1, 1);
			half ssdepth	= lerp(NdotL, 1, depth + saturate(dot(s.Normal, -NdotL)));
			#if defined(SNOW_BLEND_ADVANCED) || defined(SNOW_BLEND_TEXTURE) || defined(SNOW_BLEND_HEIGHT)
				ssatten = atten * ssdepth * s.Alpha;
			#else
				ssatten = atten * ssdepth;
			#endif
			ramp = ramp * ssatten;
		}
		
		#ifdef SNOW_GLITTER
			half3 view			= mul((float3x3)UNITY_MATRIX_V, s.Normal);
			half3 glitter		= frac(0.7 * s.Normal + 9 * s.Specular + _Speed * viewDir * lightDir * view);
			glitter 			*= (_Density - glitter);
			glitter 			= saturate(1 - _DensityStatic * (glitter.x + glitter.y + glitter.z));
			glitter				= (glitter * _SpecularColor.rgb) * _SpecularColor.a + half3(Overlay(glitter, s.Specular.rgb * _Power)) * (1 - _SpecularColor.a);
			
			half3 specular		= saturate(pow(NdotH, _Shininess * 128.0) * _Specular * glitter);
			
			half3 anisotropic	= max(0, sin(radians((NdotH + _Aniso) * 180))) * ssatten;
			anisotropic			= saturate(glitter * anisotropic * _Glitter);
		#else
			half3 specular 		= saturate(pow(NdotH, _Shininess * 128.0) * _Specular * s.Specular.rgb);
			half3 anisotropic	= max(0, sin(radians((NdotH + _Aniso) * 180))) * ssatten;
			anisotropic			= saturate(s.Specular.rgb * anisotropic * _Glitter);
		#endif
		
		half4 c = half4(1, 1, 1, 1);
		#ifdef SNOW_REFLECTION
			c.rgb	= ramp * albedo + (anisotropic + specular + s.Emission) * shadow;
		#else
			c.rgb	= ramp * albedo + (anisotropic + specular) * shadow;
		#endif
		#if defined(SNOW_BLEND_ADVANCED) || defined(SNOW_BLEND_TEXTURE) || defined(SNOW_BLEND_HEIGHT)
			c.a		= s.Alpha;
		#endif
		return c;
	}

#endif