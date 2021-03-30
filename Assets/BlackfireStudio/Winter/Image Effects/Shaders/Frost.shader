// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Blackfire Studio
// Matthieu Ostertag

Shader "Blackfire Studio/Image Effects/Frost"
{
	Properties {
		_MainTex		("Base (RGB)", 2D)					= "white" {}
		_DiffuseTex		("Diffuse (RGBA)", 2D)				= "white" {}
		_BumpTex		("Normal (RGB)", 2D)				= "bump" {}
		_CoverageTex	("Coverage (R)", 2D)				= "white" {}
		
		_Transparency	("Transparency", Range(0.0, 1.0))	= 0.0
		_Refraction		("Refraction", Range(0.0, 2.0))		= 0.0
		_Coverage		("Coverage", Range(0.0, 1.0))		= 0.0
		_Smooth			("Spread", Range(0.0, 1.0))			= 0.0
		
		_Color			("Color", Color)	= (1, 1, 1, 1)
	}
	
	SubShader {
		Pass {
			
			ZTest Always Cull Off ZWrite Off
			Fog { Mode off }
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			
			#include "UnityCG.cginc"
			#include "../../Shaders/Snow/SnowCore.cginc"

			uniform sampler2D	_MainTex;
			uniform	float4		_MainTex_TexelSize;
			uniform sampler2D	_DiffuseTex;
			uniform sampler2D	_BumpTex;
			uniform sampler2D	_CoverageTex;
			
			uniform	fixed		_Transparency;
			uniform	fixed		_Refraction;
			uniform	fixed		_Coverage;
			uniform	fixed		_Smooth;
			
			fixed4				_Color;
			
			struct appdata
			{
				float4	vertex : POSITION;
				half2	texcoord : TEXCOORD0;
			};
				
			struct v2f
			{
				float4	pos : SV_POSITION;
				half2	uv[2] : TEXCOORD0;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				half2 uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, v.texcoord);
				o.uv[0] = uv;
				#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0)
					{ uv.y = 1 - uv.y; }
				#endif
				o.uv[1] = uv;
				return o;
			} 
			
			fixed4	frag(v2f i) : COLOR
			{
				half4 diffuse = tex2D(_DiffuseTex, i.uv[1]);
				diffuse.rgb *= _Color.rgb;
				
				half2 normal = UnpackNormal(tex2D(_BumpTex, i.uv[1])).xy;
				
				half transparency = lerp(1, 0, diffuse.a * _Transparency);
				
				//Coverage
				half coverage = tex2D(_CoverageTex, i.uv[1]).r;
				coverage = coverage - lerp(1, -1, _Coverage * transparency);
				coverage = saturate(coverage / _Smooth);
				
				//Refraction
				half3 screen = tex2D(_MainTex, i.uv[0] + normal * _Refraction * coverage).rgb;
				
				// Screen Blend Mode
				half3 blendScreen = Screen(screen, diffuse.rgb);
				blendScreen = lerp(blendScreen, diffuse.rgb, _Color.a);
				
				fixed4 color = fixed4(1, 1, 1, 1);
				color.rgb = lerp(screen, blendScreen, coverage);
				return color;
			}
			
			ENDCG
		}
	} 
	FallBack off
}
