// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Custom/EyeBallsHD" {

	Properties {
		//
		_InternalColor ("Internal Color", Color) = (1,1,1,1)
		_EmissionColor ("Emission Color", Color) = (1,1,1,1)
		//虹膜颜色
		_EyeColor ("Iris Color", Color) = (0,0,1,0)
		_ScleraColor ("Scolera Color", Color) = (1,1,1,0)
		[Space]
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BumpMap ("Normals", 2D) = "bump" {}
		_NormalScale ("NormalScale", Range(0,1)) = 1
		_Mask ("(R) Subsurface (G) Spec (B) Iris Mask (A) Height", 2D) = "white" {}
		[Space]
 		_SSS ("SSS Intensity", Range(0,1)) = 1
		_Glossiness ("Gloss", Range(0,1)) = 0.5
		_Reflection ("Reflection", Range(0,1)) = 0.0
		_Parallax ("Parallax", Range(0,0.3)) = 0
		_Fresnel ("Fresnel Value", Float) = 0.028
	}

	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull Back
		
		CGPROGRAM
		
		#pragma surface surf SimpleSpecular vertex:vert addshadow
		
		#pragma target 4.0
        //
		#include "UnityPBSLighting.cginc"
        //主纹理
		sampler2D _MainTex;
		//法线纹理
		sampler2D _BumpMap;
		//??? Mask纹理
		sampler2D _Mask;

		struct Input {
			//主纹理
			float2 uv_MainTex : TEXCOORD0;
			//虹膜贴图
			float3 eye : TEXCOORD1;
			//bump法线贴图
			float3 normal : TEXCOORD2;
			//灯光颜色
			float3 light : COLOR;
			//视野方向
			float3 viewDir;
        };

		struct SurfaceOutputSSS {
			//反射率
			float3 Albedo;
			//光 热
			float3 Emission;
			//法线
			float3 Normal;
			//平滑度
			float Smoothness;
			//高光
			float Specular;
			//厚度
			float Thickness;
			//透明度
			float Alpha;
		};
		//光泽度
		half _Glossiness;
		//反射
		half _Reflection;
		//_ScleraColor虹膜颜色
		fixed4 _Color, _EmissionColor, _InternalColor, _EyeColor, _ScleraColor;
		half _SSS;
		//视差
		half _Parallax;
		//菲涅尔项
		float _Fresnel;
		//法线缩放？？
		float _NormalScale;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		//GPU Instance项 
		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

		half4 LightingSimpleSpecular (SurfaceOutputSSS s, half3 lightDir, half3 viewDir, half atten) {
			//saturate限制【0，1】
			half diff = saturate(dot(s.Normal, lightDir));
			
			half3 h = normalize (normalize(lightDir) + normalize(viewDir));
			float nh = saturate(dot (s.Normal, h));
			float spec = pow (nh, s.Specular * 128.0) * _Glossiness;
			
			//reflection
			float4 refColor = 1.0;
			float3 refDir = reflect(-viewDir, s.Normal);
    		float4 reflection = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, refDir);
    		refColor.rgb = DecodeHDR(reflection, unity_SpecCube0_HDR);
    		refColor.a = 1.0;
			//sss
			//differnce of eye to incoming light
			float eDotL = saturate(dot(viewDir, lightDir));
			//thickness estimate
			fixed3 albedo = s.Albedo;
			albedo -= (1-_InternalColor) * s.Thickness * eDotL * (diff * atten) * _SSS;
			//spec
			half4 c;
			c.rgb = (albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec) * atten;
			c.a = 1;
        	return c + (refColor * s.Smoothness * _Reflection);
    	}
		//
		float2 CalculateUVOffset(float3 lightDir, float3 viewDir, float3 normal, float2 uv) {
			//Length 向量长度的模
			float limit = (-length(viewDir.xy) / viewDir.z) * _Parallax;
			//
			float2 uvDir = normalize(viewDir.xy);

			float2 maxUVOffset = uvDir * limit;

			//choose the amount of steps we need based on angle to surface.
			int maxSteps = lerp(40, 5, dot(viewDir, normal));
			//
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

		void vert (inout appdata_full v, out Input o) 
		{   
			//初始化参数
			UNITY_INITIALIZE_OUTPUT(Input,o);
			float3x3 t2w;
			float3 P = mul(unity_ObjectToWorld, v.vertex).xyz;
			float3 N = UnityObjectToWorldNormal(v.normal);
			float3 E = -UnityWorldSpaceViewDir(P);

			float3 L = UnityWorldSpaceLightDir(P);
			float3 binormal = cross(v.normal, v.tangent.xyz) * v.tangent.w;
			t2w[0] = UnityObjectToWorldNormal(v.tangent);
			t2w[1] = UnityObjectToWorldNormal(binormal);
			t2w[2] = UnityObjectToWorldNormal(v.normal);
			//transpose计算转置矩阵 行和列
			float3x3 w2t = transpose(t2w);
			o.eye = mul(E, w2t);
			o.normal = mul(N, w2t);
			o.light = mul(L, w2t);
		}
     
		void surf (Input IN, inout SurfaceOutputSSS o) {
			fixed4 mask = tex2D(_Mask, IN.uv_MainTex);
			float2 offset = CalculateUVOffset(IN.light, IN.eye, IN.normal, IN.uv_MainTex);
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex+offset);
			o.Normal = UnpackScaleNormal (tex2D (_BumpMap, IN.uv_MainTex), _NormalScale);
			half f = dot(normalize(IN.viewDir), o.Normal);
			o.Albedo = ((c.rgb * _EyeColor) * mask.b) + ((c.rgb * _ScleraColor) * (1-mask.b));
			o.Specular = mask.b;
			o.Smoothness = (_Fresnel-f*_Fresnel);
			o.Thickness = mask.r;
			o.Emission = (2 * c.rgb * _EmissionColor * mask.b);
			o.Alpha = 1;
		}
		ENDCG
	}
	FallBack "Standard"
}
