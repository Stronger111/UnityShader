// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Custom/EyeBallsHDPbr" {

	Properties {
		[Header(Colors)]
		_InternalColor ("Internal Color", Color) = (1,1,1,1)
		_EmissionColor ("Emission Color", Color) = (1,1,1,1)
		_EyeColor ("Iris Color", Color) = (0,0,1,0)
		_ScleraColor ("Scolera Color", Color) = (1,1,1,0)
		[Space]
		[HideInInspector]
		_Color("Main Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BumpMap ("Normals", 2D) = "bump" {}
		[HideInInspector]
		_BumpScale ("NormalScale", Range(0,1)) = 1
		_Mask ("(R) Subsurface (G) Spec (B) Iris Mask (A) Height", 2D) = "white" {}
		[Space]
		_SSS("SSS Intensity", Range(0,1)) = 1
		_EyeParallax("Parallax", Range(0,0.3)) = 0
		[Header(Reflection)]
		_Glossiness("Gloss", Range(0,1)) = 0.5
		_Fresnel("Fresnel Value", Float) = 0.028
		_Reflection("Reflection", Range(0,1)) = 0.0
		[Header(AO)]
		_OcclusionMap("AO Texture", 2D) = "white"{}
		_OcclusionStrength("AO Strength", Range(0.0, 1.0)) = 1.0
		_OcclusionColor("AO Color", Color) = (0,0,0,0)
		[Header(Makeup)]
		_IrisScale("Scale Iris", Range(0.25, 2)) = 1
		_IrisSizeAndOffset("Iris Size And Offset In Altas", Vector) = (1,1,0,0)
		[Header(HSV)]
		_EyeColorHSV("Iris Color HSV", Vector) = (0,0,0,0)
		_EmissionColorHSV("Emission Color HSV", Vector) = (0,0,0,0)
		[Header(Adjustment)]
		_IrisSizeAdjust("Iris Size Adjustment", Range(0.1, 1)) = 1
	}

	SubShader{
		Tags { "RenderType" = "Opaque" }
		LOD 200
		Cull Back
		CGINCLUDE
		#include "UnityStandardCore.cginc"

		float _EyeParallax;
		sampler2D _Mask;
		float4 _Mask_TexelSize;
		float _Fresnel;
		float _IrisScale;
		float _IrisSizeAdjust;
		float4 _IrisSizeAndOffset;
		float3 _EyeColor;
		float3 _ScleraColor;
		float3 _InternalColor;
		half _SSS;

		float4 _EyeColorHSV;
		float4 _EmissionColorHSV;

		float3 HSV2RGB(float3 c)
		{
			float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
			float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
			return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
		}

		float2 CalculateUVOffset(float3 viewDir, float2 uv) {

			float limit = (-length(viewDir.xy) / viewDir.z) * _EyeParallax;
			float2 uvDir = normalize(viewDir.xy);
			float2 maxUVOffset = uvDir * limit;

			//choose the amount of steps we need based on angle to surface.
			int maxSteps = lerp(40, 5, viewDir.z);
			float rayStep = 1.0 / (float)maxSteps;

			// dx and dy effectively calculate the UV size of a pixel in the texture.
			// x derivative of mask uv
			float2 dx = ddx(uv);
			// y derivative of mask uv
			float2 dy = ddy(uv);

			float rayHeight = 1.0;
			float2 uvOffset = 0;
			float currentHeight = 1;
			float2 stepLength = rayStep * maxUVOffset;

			int step = 0;
			//search for the occluding uv coord in the heightmap
			while (step < maxSteps && currentHeight <= rayHeight)
			{
				step++;
				currentHeight = tex2Dgrad(_Mask, uv + uvOffset, dx, dy).a;
				rayHeight -= rayStep;
				uvOffset += stepLength;
			}
			return uvOffset;
		}
		float4 ScaleIris(float4 i_tex, float2 scale)
		{
			i_tex.xy = (i_tex.xy - 0.5) / scale + 0.5;
			return i_tex;
		}
		float4 ScaleIrisWhitSizeAndOffset(float4 i_tex, float2 scale, float4 sizeAndOffset)
		{
			float2 center = 0.5 * sizeAndOffset.xy + sizeAndOffset.zw;
			i_tex.xy = (i_tex.xy - center) / scale + center;
			return i_tex;
		}

		// parallax transformed texcoord is used to sample occlusion
		inline FragmentCommonData EyeFragmentSetup(inout float4 i_tex, float3 i_eyeVec, float4 tangentToWorld[3], float3 i_posWorld, float3 specColor, out float reflection)
		{
			FragmentCommonData o = (FragmentCommonData)0;
			o.eyeVec = NormalizePerPixelNormal(i_eyeVec);
			float3x3 t2w;
			t2w[0] = tangentToWorld[0].xyz;
			t2w[1] = tangentToWorld[1].xyz;
			t2w[2] = tangentToWorld[2].xyz;
			float3x3 w2t = transpose(t2w);
			float3 teye = mul(o.eyeVec,w2t);
			float2 uv = i_tex.xy;
			float2 offset = CalculateUVOffset(teye, uv);
			o.specColor = specColor;

			o.posWorld = i_posWorld;

			half oneMinusReflectivity;
			float4 albedoUV = i_tex;
			albedoUV.xy += offset;
			albedoUV.xy = (albedoUV.xy * _IrisSizeAndOffset.xy) + _IrisSizeAndOffset.zw;
			albedoUV = ScaleIrisWhitSizeAndOffset(albedoUV, _IrisSizeAdjust, _IrisSizeAndOffset);
			half3 albedo = Albedo(albedoUV);
			half inArea = step(_IrisSizeAndOffset.z, albedoUV.x) * step(_IrisSizeAndOffset.w, albedoUV.y)
				* step(albedoUV.x, _IrisSizeAndOffset.z + _IrisSizeAndOffset.x)
				* step(albedoUV.y, _IrisSizeAndOffset.w + _IrisSizeAndOffset.y);
			albedo = lerp(1, albedo, inArea);
			half3 diffColor = EnergyConservationBetweenDiffuseAndSpecular(albedo, 0.2, /*out*/ oneMinusReflectivity);

			o.diffColor = diffColor;
			o.oneMinusReflectivity = oneMinusReflectivity;

			o.normalWorld = PerPixelWorldNormal(i_tex, tangentToWorld);
			half NdotV = dot(o.eyeVec, o.normalWorld);
			reflection = (_Fresnel - NdotV * _Fresnel);
			reflection *= reflection;
			o.smoothness = sqrt(_Glossiness);

			return o;
		}
		float3 GetDiffuseColorAndEmission(float3 diffColor, 
			float irisMask, float thickness, 
			float3 eyeVec, float3 lightDir, 
			float3 normalWorld, float atten,
			out float3 emission)
		{
			if (_EyeColorHSV.w == 1)
			{
				_EyeColor = HSV2RGB(_EyeColorHSV.xyz);
			}
			if (_EmissionColorHSV.w == 1)
			{
				_EmissionColor.xyz = HSV2RGB(_EmissionColorHSV.xyz);
			}
			emission = (2 * diffColor * _EmissionColor * irisMask);
			diffColor *= lerp(_ScleraColor, _EyeColor, irisMask);
			float eDotL = saturate(dot(-eyeVec, lightDir));//FIXME:Really needed?
			half diff = saturate(dot(normalWorld, lightDir));
			float3 diffReduction = (1 - _InternalColor) * thickness * eDotL * (diff * atten) * _SSS;
			diffColor -= diffReduction;
			return diffColor;
		}
		ENDCG

		Pass
		{

			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" "Queue" = "Geometry"}


			CGPROGRAM
			#pragma vertex vertForwardBase
			#pragma fragment fragForwardBaseEye
			#pragma multi_compile_fwdbase
			// make fog work
			#pragma multi_compile_fog
			#pragma target 4.0
			#pragma shader_feature _NORMALMAP

			half _Reflection;
			float3 _OcclusionColor;

			half4 fragForwardBaseEye(VertexOutputForwardBase i) : SV_Target
			{
				UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);
		
				float4 scaleUV = ScaleIris(i.tex, _IrisScale);
				fixed4 mask = tex2D(_Mask, scaleUV);
				float reflection;
				FragmentCommonData s = EyeFragmentSetup(scaleUV, i.eyeVec.xyz, i.tangentToWorldAndPackedData, IN_WORLDPOS(i), mask.g, reflection);
				//FRAGMENT_SETUP(s)

				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				UnityLight light = MainLight();
				UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);

				half3 diffuse = s.diffColor;
				half3 emission;
				s.diffColor = GetDiffuseColorAndEmission(diffuse, mask.b, mask.r, s.eyeVec, light.dir, s.normalWorld, atten, emission);

				//TODO: Recompute uv when rotate eye
				half occlusion = Occlusion(i.tex.xy);
				UnityGI gi = FragmentGI(s, 1, i.ambientOrLightmapUV, atten, light, true);
				gi.indirect.diffuse *= lerp(_OcclusionColor, 1, occlusion);
				gi.indirect.specular *= lerp(_OcclusionColor, 1, occlusion);
				gi.indirect.specular *= _Reflection * reflection;
				half4 c = BRDF2_Unity_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
				//c.rgb += Emission(i.tex.xy);
				c.rgb += emission * (1-mask.a);

				UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
				UNITY_APPLY_FOG(_unity_fogCoord, c.rgb);
				return OutputForward(c, s.alpha);
			}
			ENDCG
		}
		Pass
		{

			Name "FORWARD_DELTA"
			Tags{ "LightMode" = "ForwardAdd" "Queue" = "Geometry"}
			Blend One One
			Fog { Color(0,0,0,0) } // in additive pass fog should be black
			ZWrite Off
			ZTest LEqual
			
			CGPROGRAM
			#pragma vertex vertForwardAdd
			#pragma fragment fragForwardAddEye
			#pragma multi_compile_fwdadd
			// make fog work
			#pragma multi_compile_fog
			#pragma target 4.0
			#pragma shader_feature _NORMALMAP

			half4 fragForwardAddEye(VertexOutputForwardAdd i) : SV_Target
			{
				UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				float4 scaleUV = ScaleIris(i.tex, _IrisScale);
				fixed4 mask = tex2D(_Mask, scaleUV);
				float reflection;
				FragmentCommonData s = EyeFragmentSetup(scaleUV, i.eyeVec.xyz, i.tangentToWorldAndLightDir, IN_WORLDPOS_FWDADD(i), mask.b, reflection);
				//FRAGMENT_SETUP_FWDADD(s)

				UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld)
				
				UnityLight light = AdditiveLight(IN_LIGHTDIR_FWDADD(i), atten);
				UnityIndirect noIndirect = ZeroIndirect();
				half3 diffuse = s.diffColor;
				half3 emission;
				s.diffColor = GetDiffuseColorAndEmission(diffuse, mask.b, mask.r, s.eyeVec, light.dir, s.normalWorld, atten, emission);
				half4 c = BRDF2_Unity_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, light, noIndirect);
				
				UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
				UNITY_APPLY_FOG_COLOR(_unity_fogCoord, c.rgb, half4(0,0,0,0)); // fog towards black in additive pass
				return OutputForward(c, s.alpha);
			}
			ENDCG
		}
	}
	FallBack "Standard"
}
