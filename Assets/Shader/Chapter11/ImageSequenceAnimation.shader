Shader "Unity Shaders Book/Chapter11/ImageSequenceAnimation" {
	Properties {
		_Color ("Color Tint", Color) = (1,1,1,1)
		_MainTex ("Image Sequence", 2D) = "white" {}
		_HorizontalAmount("HorizontalAmount",Float)=4
		_VerticalAmount("VerticalAmount",Float)=4
		_Speed("Speed",Range(1,100))=30
	}
	SubShader {
		Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True"}
		pass{
			Tags{"LightMode"="ForwardBase"}

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _HorizontalAmount;
			float _VerticalAmount;
			fixed _Speed;

			struct a2v{
              float4 vertex:POSITION;
			  float2 texcoord:TEXCOORD0;
			};
			struct v2f{
              float4 pos:SV_POSITION;
			  float2 uv:TEXCOORD0;
			};

			v2f vert(a2v v){
              v2f o;
              o.pos=UnityObjectToClipPos(v.vertex);
			  o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
			  return o;
			}
            fixed4 frag(v2f i):SV_TARGET{
               float time=floor(_Time.y*_Speed);
			   float row=floor(time/_HorizontalAmount);
			   float column=time-row*_HorizontalAmount;

			   half2 uv=i.uv+half2(column,-row);
			   uv.x/=_HorizontalAmount;
			   uv.y/=_VerticalAmount;

			   fixed4 c=tex2D(_MainTex,uv);
			   c.rgb*=_Color;
			   return c;
			}
			ENDCG
		}
	}
	FallBack "Transparent/VertexLit"
}
