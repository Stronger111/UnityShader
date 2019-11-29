Shader "GEffect/BD_Skin_EA_PBR"
{
	Properties
	{
		_Color("Main Color (Use alpha to blend)", Color) = (1,1,1,1)
		_MainTex("Diffuse", 2D) = "white" {}
		_BumpMap("Normal", 2D) = "normal" {}
		_BumpScale ("Normal Scale", float) = 1

		_SpecColor("Specular", Color) = (0.2,0.2,0.2)
			[HideInInspector]
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_SmoothnessOffset("Smoothness Offset", Range(-1.0, 1.0)) = 0.5

		_OcclusionMap("AO Texture", 2D) = "white"{}
		_OcclusionStrength ("AO Strength", float) = 1

		//_DetailNormalTex("DetailNormal", 2D) = "normal"{}
		//_DetailNormalTile("DetailNormalTile", Float) = 1.0
		//_DetailNormalWeight("DetailNormalWeight" ,Range(0,10)) = 1

		_MaterialTex("Smooth(G)", 2D) = "normal"{}

		_SSSWeight ("SSS Weight", Range(0, 1)) = 1
		_GlobalSSSWeight("Global SSS Weight", Range(0, 1)) = 1
		_LookupDiffuseSpec("SSS Lut", 2D) = "gray" {}
		_BumpinessDR("Diffuse Bumpiness R", Range(0,1)) = 0.1
		_BumpinessDG("Diffuse Bumpiness G", Range(0,1)) = 0.6
		_BumpinessDB("Diffuse Bumpiness B", Range(0,1)) = 0.7
		_SSSOffset ("SSS Offset", Range(-1, 1)) = 0
		_SSSColor ("SSS Color", Color) = (0,0,0,0)

		[Header(Decal)]
		_DecalTex ("Decal Tex", 2D) = "black" {}
		[Header(BrowL)]
		_BrowLMakeupColor ("BrowL Makeup Color", Color) = (1,1,1,1)
		_BrowLMakeupAlpha ("BrowL Makeup Alpha", Range(0, 1)) = 0
		_BrowLMakeupScale ("BrowL Makeup Scale", Vector) = (1,1,1,1)
		_BrowLMakeupSmoothness ("BrowL Makeup Smoothness", Range(0, 1)) = 0
		_BrowLMakeupMetallic ("BrowL Makeup Metallic", Range(0, 1)) = 0
		_BrowLMakeupPos ("BrowL Makeup Pos", Vector) = (0,0,0,0)
		_BrowLMakeupSizeAndOffset ("BrowL Makeup SizeAndOffset", Vector) = (1,1,0,0)
		_BrowLMakeupHSV ("BrowL Makeup HSV", Vector) = (0,0,0,0)
		[Header(BrowR)]
		_BrowRMakeupColor ("BrowR Makeup Color", Color) = (1,1,1,1)
		_BrowRMakeupAlpha ("BrowR Makeup Alpha", Range(0, 1)) = 0
		_BrowRMakeupScale ("BrowR Makeup Scale", Vector) = (1,1,1,1)
		_BrowRMakeupSmoothness ("BrowR Makeup Smoothness", Range(0, 1)) = 0
		_BrowRMakeupMetallic ("BrowR Makeup Metallic", Range(0, 1)) = 0
		_BrowRMakeupPos ("BrowR Makeup Pos", Vector) = (0,0,0,0)
		_BrowRMakeupSizeAndOffset ("BrowR Makeup SizeAndOffset", Vector) = (1,1,0,0)
		_BrowRMakeupHSV ("BrowR Makeup HSV", Vector) = (0,0,0,0)
		[Header(EyeL)]
		_EyeLMakeupColor ("EyeL Makeup Color", Color) = (1,1,1,1)
		_EyeLMakeupAlpha ("EyeL Makeup Alpha", Range(0, 1)) = 0
		_EyeLMakeupScale ("EyeL Makeup Scale", Vector) = (1,1,1,1)
		_EyeLMakeupSmoothness ("EyeL Makeup Smoothness", Range(0, 1)) = 0
		_EyeLMakeupMetallic ("EyeL Makeup Metallic", Range(0, 1)) = 0
		_EyeLMakeupPos ("EyeL Makeup Pos", Vector) = (0,0,0,0)
		_EyeLMakeupSizeAndOffset ("EyeL Makeup SizeAndOffset", Vector) = (1,1,0,0)
		_EyeLMakeupHSV ("EyeL Makeup HSV", Vector) = (0,0,0,0)
		[Header(EyeR)]
		_EyeRMakeupColor ("EyeR Makeup Color", Color) = (1,1,1,1)
		_EyeRMakeupAlpha ("EyeR Makeup Alpha", Range(0, 1)) = 0
		_EyeRMakeupScale ("EyeR Makeup Scale", Vector) = (1,1,1,1)
		_EyeRMakeupSmoothness ("EyeR Makeup Smoothness", Range(0, 1)) = 0
		_EyeRMakeupMetallic ("EyeR Makeup Metallic", Range(0, 1)) = 0
		_EyeRMakeupPos ("EyeR Makeup Pos", Vector) = (0,0,0,0)
		_EyeRMakeupSizeAndOffset ("EyeR Makeup SizeAndOffset", Vector) = (1,1,0,0)
		_EyeRMakeupHSV ("EyeR Makeup HSV", Vector) = (0,0,0,0)
		[Header(Lip)]
		_LipMakeupColor ("Lip Makeup Color", Color) = (1,1,1,1)
		_LipMakeupAlpha ("Lip Makeup Alpha", Range(0, 1)) = 0
		_LipMakeupScale ("Lip Makeup Scale", Vector) = (1,1,1,1)
		_LipMakeupSmoothness ("Lip Makeup Smoothness", Range(0, 1)) = 0
		_LipMakeupMetallic ("Lip Makeup Metallic", Range(0, 1)) = 0
		_LipMakeupPos ("Lip Makeup Pos", Vector) = (0,0,0,0)
		_LipMakeupSizeAndOffset ("Lip Makeup SizeAndOffset", Vector) = (1,1,0,0)
		_LipMakeupHSV ("Lip Makeup HSV", Vector) = (0,0,0,0)
		[Header(DecalL)]
		_DecalLMakeupColor ("DecalL Makeup Color", Color) = (1,1,1,1)
		_DecalLMakeupAlpha ("DecalL Makeup Alpha", Range(0, 1)) = 0
		_DecalLMakeupScale ("DecalL Makeup Scale", Vector) = (1,1,1,1)
		_DecalLMakeupSmoothness ("DecalL Makeup Smoothness", Range(0, 1)) = 0
		_DecalLMakeupMetallic ("DecalL Makeup Metallic", Range(0, 1)) = 0
		_DecalLMakeupPos ("DecalL Makeup Pos", Vector) = (0,0,0,0)
		_DecalLMakeupSizeAndOffset ("DecalL Makeup SizeAndOffset", Vector) = (1,1,0,0)
		_DecalLMakeupHSV ("DecalL Makeup HSV", Vector) = (0,0,0,0)
		[Header(DecalR)]
		_DecalRMakeupColor ("DecalR Makeup Color", Color) = (1,1,1,1)
		_DecalRMakeupAlpha ("DecalR Makeup Alpha", Range(0, 1)) = 0
		_DecalRMakeupScale ("DecalR Makeup Scale", Vector) = (1,1,1,1)
		_DecalRMakeupSmoothness ("DecalR Makeup Smoothness", Range(0, 1)) = 0
		_DecalRMakeupMetallic ("DecalR Makeup Metallic", Range(0, 1)) = 0
		_DecalRMakeupPos ("DecalR Makeup Pos", Vector) = (0,0,0,0)
		_DecalRMakeupSizeAndOffset ("DecalR Makeup SizeAndOffset", Vector) = (1,1,0,0)
		_DecalRMakeupHSV ("DecalR Makeup HSV", Vector) = (0,0,0,0)

	}
	CGINCLUDE

	#define EPSILON 1.0e-4

	float3 RGB2HSV(float3 c)
	{
		float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
		float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
		float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
		float d = q.x - min(q.w, q.y);
		float e = 1.0e-4;
		return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
	}

	float3 HSV2RGB(float3 c)
	{
		float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
		float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
		return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
	}

#define DECLARE_DECAL_PROPERTIES(n) \
    float2 n##Scale; \
    float2 n##Pos; \
    float4 n##SizeAndOffset; \
    float3 n##Color; \
    float n##Alpha; \
    float4 n##HSV; \
    float n##Smoothness; \
    float n##Metallic;


#define CAL_FRAG_DECAL_UV_RGB(n, c, texuv, smoothness, metallic) \
    { \
        float4 uv##n; \
        uv##n.zw=(texuv-n##Pos)/n##Scale/n##SizeAndOffset.xy + float2(0.5, 0.5); \
        uv##n.xy=uv##n.zw*n##SizeAndOffset.xy+n##SizeAndOffset.zw; \
        half4 d##n=tex2D(_DecalTex,uv##n); \
        half3 decal##n=d##n.rgb*n##Color; \
        if (n##HSV.w == 1) \
        { \
            float3 hsv=RGB2HSV(decal##n); \
            hsv+=n##HSV.xyz; \
            decal##n=HSV2RGB(hsv); \
        } \
        half inArea##n=step(0,uv##n.z)*step(0,uv##n.w)*step(uv##n.z,1)*step(uv##n.w,1); \
        half alpha=n##Alpha*inArea##n; \
        alpha*=d##n.a; \
        c.rgb=lerp(c.rgb,decal##n,alpha); \
        smoothness=max(smoothness,n##Smoothness*inArea##n*step(0.01,d##n.a)); \
        metallic=max(metallic,n##Metallic*alpha); \
        c.a=max(c.a,alpha); \
    }

	float _SSSWeight;
	float _GlobalSSSWeight;

	sampler2D _LookupDiffuseSpec;
	uniform float _BumpinessDR;
	uniform float _BumpinessDG;
	uniform float _BumpinessDB;
	float _SSSOffset;
	float3 _SSSColor;

	#include "UnityStandardCore.cginc"	
	float3 PreintegratedSSS(sampler2D _BumpMap,
		float2 uv, float4 tangent2World[3],
		float3 normalWorld, float3 eyeVec,
		UnityLight light, UnityIndirect gi,
		float thick, out float3 transmission)
	{

		float3 texNormalLow = UnpackNormal(tex2Dbias(_BumpMap, half4(uv, 0, 3)));
		float3 wNormalLow = texNormalLow.x * tangent2World[0].xyz
			+ texNormalLow.y * tangent2World[1]
			+ texNormalLow.z * tangent2World[2];
		float3 NormalR = normalize(lerp(wNormalLow, normalWorld, _BumpinessDR));
		float3 NormalG = normalize(lerp(wNormalLow, normalWorld, _BumpinessDG));
		float3 NormalB = normalize(lerp(wNormalLow, normalWorld, _BumpinessDB));


		//float perceptualRoughness = 1;
		//float3 halfDir = Unity_SafeNormalize(float3(light.dir) + eyeVec);
		//float nv = saturate(dot(normalWorld, eyeVec));
		//float nl = saturate(dot(normalWorld, light.dir));
		//half lh = saturate(dot(light.dir, halfDir));
		//half diffuseTerm = DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;
		//float diff = gi.diffuse + light.color * diffuseTerm;

		float3 lightDir = light.dir;
		float3 diffNdotL = 0.5 + 0.5 * half3(
			dot(NormalR, lightDir),
			dot(NormalG, lightDir),
			dot(NormalB, lightDir));
		float scattering = saturate((1 - thick + _SSSOffset));

		half3 preintegrate = half3(
			tex2D(_LookupDiffuseSpec, half2(diffNdotL.r, scattering)).r,
			tex2D(_LookupDiffuseSpec, half2(diffNdotL.g, scattering)).g,
			tex2D(_LookupDiffuseSpec, half2(diffNdotL.b, scattering)).b);
		//half3 preintegrate = tex2D(_LookupDiffuseSpec, half2(diff.r, scattering));
		preintegrate *= 2;

		thick = 1 - thick;
		float tt = -thick * thick;
		half NdotL = dot(normalWorld, lightDir);
		float halfLambert = NdotL * 0.5 + 0.5;
		half3 translucencyProfile =
			float3(0.233, 0.455, 0.649) * exp(tt / 0.0064) +
			float3(0.100, 0.336, 0.344) * exp(tt / 0.0484) +
			float3(0.118, 0.198, 0.000) * exp(tt / 0.1870) +
			float3(0.113, 0.007, 0.007) * exp(tt / 0.5670) +
			float3(0.358, 0.004, 0.000) * exp(tt / 1.9900) +
			float3(0.078, 0.000, 0.000) * exp(tt / 7.4100);
		float3 translucency = saturate((1 - NdotL)*halfLambert*thick) * translucencyProfile;
		//preintegrate = lerp(1, preintegrate, thick);


		translucency *= 2 * _GlobalSSSWeight;
		transmission = translucency;
		float3 col = lerp(1, saturate(preintegrate), _SSSWeight);
		return col;
	}

	half4 BRDF1_Unity_PBS_Skin(half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
		float3 normal, float3 viewDir,
		UnityLight light, UnityIndirect gi,
		float3 sss, float3 transmission)
	{
		float perceptualRoughness = SmoothnessToPerceptualRoughness(smoothness);
		float3 halfDir = Unity_SafeNormalize(float3(light.dir) + viewDir);

		// NdotV should not be negative for visible pixels, but it can happen due to perspective projection and normal mapping
		// In this case normal should be modified to become valid (i.e facing camera) and not cause weird artifacts.
		// but this operation adds few ALU and users may not want it. Alternative is to simply take the abs of NdotV (less correct but works too).
		// Following define allow to control this. Set it to 0 if ALU is critical on your platform.
		// This correction is interesting for GGX with SmithJoint visibility function because artifacts are more visible in this case due to highlight edge of rough surface
		// Edit: Disable this code by default for now as it is not compatible with two sided lighting used in SpeedTree.
#define UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV 0

#if UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV
	// The amount we shift the normal toward the view vector is defined by the dot product.
		half shiftAmount = dot(normal, viewDir);
		normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f) : normal;
		// A re-normalization should be applied here but as the shift is small we don't do it to save ALU.
		//normal = normalize(normal);

		float nv = saturate(dot(normal, viewDir)); // TODO: this saturate should no be necessary here
#else
		half nv = abs(dot(normal, viewDir));    // This abs allow to limit artifact
#endif

		float nl = saturate(dot(normal, light.dir));
		float nh = saturate(dot(normal, halfDir));

		half lv = saturate(dot(light.dir, viewDir));
		half lh = saturate(dot(light.dir, halfDir));

		// Diffuse term
		half diffuseTerm = DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;

		// Specular term
		// HACK: theoretically we should divide diffuseTerm by Pi and not multiply specularTerm!
		// BUT 1) that will make shader look significantly darker than Legacy ones
		// and 2) on engine side "Non-important" lights have to be divided by Pi too in cases when they are injected into ambient SH
		float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
#if UNITY_BRDF_GGX
		// GGX with roughtness to 0 would mean no specular at all, using max(roughness, 0.002) here to match HDrenderloop roughtness remapping.
		roughness = max(roughness, 0.002);
		float V = SmithJointGGXVisibilityTerm(nl, nv, roughness);
		float D = GGXTerm(nh, roughness);
#else
		// Legacy
		half V = SmithBeckmannVisibilityTerm(nl, nv, roughness);
		half D = NDFBlinnPhongNormalizedTerm(nh, PerceptualRoughnessToSpecPower(perceptualRoughness));
#endif

		float specularTerm = V * D * UNITY_PI; // Torrance-Sparrow model, Fresnel is applied later

#   ifdef UNITY_COLORSPACE_GAMMA
		specularTerm = sqrt(max(1e-4h, specularTerm));
#   endif

		// specularTerm * nl can be NaN on Metal in some cases, use max() to make sure it's a sane value
		specularTerm = max(0, specularTerm * nl);
#if defined(_SPECULARHIGHLIGHTS_OFF)
		specularTerm = 0.0;
#endif

		// surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(roughness^2+1)
		half surfaceReduction;
#   ifdef UNITY_COLORSPACE_GAMMA
		surfaceReduction = 1.0 - 0.28*roughness*perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
#   else
		surfaceReduction = 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]
#   endif

	// To provide true Lambert lighting, we need to be able to kill specular completely.
		specularTerm *= any(specColor) ? 1.0 : 0.0;

		half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));
		half3 color = diffColor * (gi.diffuse + diffuseTerm * light.color * sss + transmission * light.color)
			+ specularTerm * light.color * FresnelTerm(specColor, lh)
			+ surfaceReduction * gi.specular * FresnelLerp(specColor, grazingTerm, nv);

		return half4(color, 1);
	}
	ENDCG
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100
		
		Pass
		{

			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" "Queue" = "Geometry"}


			CGPROGRAM
			#pragma vertex vertForwardBase
			#pragma fragment fragForwardBaseSkin
			#pragma multi_compile_fwdbase
			// make fog work
			#pragma multi_compile_fog
			#pragma target 3.0
			#pragma shader_feature _NORMALMAP

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
#include "UnityStandardConfig.cginc"
			//#include "BD_FunctionLibrary.cginc"

			sampler2D _MaterialTex;
			float _SmoothnessOffset;

			sampler2D _DecalTex;
			float4 _DecalTex_ST;
			DECLARE_DECAL_PROPERTIES(_DecalLMakeup)
			DECLARE_DECAL_PROPERTIES(_DecalRMakeup)
			DECLARE_DECAL_PROPERTIES(_LipMakeup)
			DECLARE_DECAL_PROPERTIES(_EyeLMakeup)
			DECLARE_DECAL_PROPERTIES(_EyeRMakeup)
			DECLARE_DECAL_PROPERTIES(_BrowLMakeup)
			DECLARE_DECAL_PROPERTIES(_BrowRMakeup)

			half4 fragForwardBaseSkin(VertexOutputForwardBase i) : SV_Target
			{
				UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

				FRAGMENT_SETUP(s)
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				UnityLight light = MainLight();
				UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);

				float4 misc = tex2D(_MaterialTex, i.tex.xy);
				s.smoothness = saturate(misc.g * misc.g * 2 * _Glossiness + _SmoothnessOffset);

				half occlusion = Occlusion(i.tex.xy);
				UnityGI gi = FragmentGI(s, occlusion, i.ambientOrLightmapUV, atten, light, false);

				float3 trm = 1;
				float3 sss = PreintegratedSSS(_BumpMap, 
					i.tex.xy, i.tangentToWorldAndPackedData, 
					s.normalWorld, s.eyeVec, 
					light, gi.indirect, 
					1 - misc.r, trm);


				half4 c = BRDF1_Unity_PBS_Skin(s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect, sss, trm);
				
				float partSmoothness = _SmoothnessOffset;
				float metallic = 0;
				float4 partBase = float4(0, 0, 0, 0);

				CAL_FRAG_DECAL_UV_RGB(_DecalLMakeup, partBase, i.tex.xy, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_DecalRMakeup, partBase, i.tex.xy, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_LipMakeup, partBase, i.tex.xy, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_EyeLMakeup, partBase, i.tex.xy, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_EyeRMakeup, partBase, i.tex.xy, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_BrowRMakeup, partBase, i.tex.xy, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_BrowLMakeup, partBase, i.tex.xy, partSmoothness, metallic);

				s.smoothness = partSmoothness;
				UnityIndirect noIndirect = ZeroIndirect();
				half4 pc = BRDF1_Unity_PBS(partBase, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
				s.specColor = 0.98;
				half4 mc = BRDF1_Unity_PBS(partBase, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
				pc = lerp(pc, mc, metallic);

				c.rgb += Emission(i.tex.xy);

				c.rgb = lerp(c.rgb, pc, partBase.a);

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
			#pragma fragment fragForwardAddSkin
			#pragma multi_compile_fwdadd
			// make fog work
			#pragma multi_compile_fog
			#pragma target 3.0
			#pragma shader_feature _NORMALMAP

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			//#include "BD_FunctionLibrary.cginc"

			sampler2D _MaterialTex;
			float _SmoothnessOffset;

			sampler2D _DecalTex;
			float4 _DecalTex_ST;
			DECLARE_DECAL_PROPERTIES(_DecalLMakeup)
			DECLARE_DECAL_PROPERTIES(_DecalRMakeup)
			DECLARE_DECAL_PROPERTIES(_LipMakeup)
			DECLARE_DECAL_PROPERTIES(_EyeLMakeup)
			DECLARE_DECAL_PROPERTIES(_EyeRMakeup)
			DECLARE_DECAL_PROPERTIES(_BrowLMakeup)
			DECLARE_DECAL_PROPERTIES(_BrowRMakeup)

			half4 fragForwardAddSkin(VertexOutputForwardAdd i) : SV_Target
			{
				UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				FRAGMENT_SETUP_FWDADD(s)

				UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld)
				UnityLight light = AdditiveLight(IN_LIGHTDIR_FWDADD(i), atten);
				UnityIndirect noIndirect = ZeroIndirect();

				float4 misc = tex2D(_MaterialTex, i.tex.xy);
				s.smoothness = saturate(misc.g * misc.g * 2 * _Glossiness + _SmoothnessOffset);

				float3 trm = 1;
				float3 sss = PreintegratedSSS(_BumpMap,
					i.tex.xy, i.tangentToWorldAndLightDir,
					s.normalWorld, s.eyeVec,
					light, noIndirect,
					1 - misc.r, trm);

				half4 c = BRDF1_Unity_PBS_Skin(s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, light, noIndirect, sss, trm);


				float partSmoothness = _SmoothnessOffset;
				float metallic = 0;
				float4 partBase = float4(0, 0, 0, 0);

				CAL_FRAG_DECAL_UV_RGB(_DecalLMakeup, partBase, i.tex.xy, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_DecalRMakeup, partBase, i.tex.xy, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_LipMakeup, partBase, i.tex.xy, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_EyeLMakeup, partBase, i.tex.xy, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_EyeRMakeup, partBase, i.tex.xy, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_BrowRMakeup, partBase, i.tex.xy, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_BrowLMakeup, partBase, i.tex.xy, partSmoothness, metallic);

				s.smoothness = partSmoothness;
				half4 pc = BRDF1_Unity_PBS(partBase, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, light, noIndirect);
				s.specColor = 0.98;
				half4 mc = BRDF1_Unity_PBS(partBase, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, light, noIndirect);
				pc = lerp(pc, mc, metallic);

				c.rgb += Emission(i.tex.xy);

				c.rgb = lerp(c.rgb, pc, partBase.a);

				UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
				UNITY_APPLY_FOG_COLOR(_unity_fogCoord, c.rgb, half4(0, 0, 0, 0)); // fog towards black in additive pass
				return OutputForward(c, s.alpha);
				//UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

				//FRAGMENT_SETUP_FWDADD(s)
				//UNITY_SETUP_INSTANCE_ID(i);
				//UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				//UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);
				//UnityLight light = AdditiveLight(IN_LIGHTDIR_FWDADD(i), 1);

				//float4 misc = tex2D(_MaterialTex, i.tex.xy);
				//s.smoothness = misc.g * _SkinSmoothness;
				//s.specColor = _SkinF0;

				//half occlusion = Occlusion(i.tex.xy);
				//UnityGI gi = FragmentGI(s, occlusion, 0, atten, light);

				//half4 c = UNITY_BRDF_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
				//c.rgb += Emission(i.tex.xy);
				//c.rgb = PreintegratedSSS(_BumpMap,
				//	i.tex.xy, i.tangentToWorldAndLightDir,
				//	s.normalWorld, s.eyeVec,
				//	c.rgb,
				//	light,
				//	1 - misc.r);

				//UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
				//UNITY_APPLY_FOG(_unity_fogCoord, c.rgb);
				//return OutputForward(c, s.alpha);
			}

			ENDCG
		}

	}
		Fallback "VertexLit"
}
