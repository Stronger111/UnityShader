Shader "Hidden/Culling/UGHiZ"
{
	Properties
	{

	}

	SubShader
	{
		
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			Name "HZB Culling Blit"
			Tags { "LightMode" = "HZB Occlusion Blit" }
			CGPROGRAM

		    sampler2D _SDCameraDepthTexture;
		 
			#pragma target 4.5
			#pragma vertex vert
			#pragma fragment frag

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				float camDepth = tex2D(_SDCameraDepthTexture, i.uv).r;
				return float4(camDepth,0,0,0);
			}
			ENDCG
		}

		pass
		{
			 Name "HZB Culling Reduce"
			 Tags{ "LightMode" = "HZB Occlusion Reduce" }
			 CGPROGRAM
			 //#include "../../ShaderLibrary/API/GLES3.hlsl"
			 Texture2D _Texture;
			 SamplerState sampler_Texture;
			 #pragma target 4.5
			 #pragma vertex vert
			 #pragma fragment frag
           
			 struct appdata
			 {
				 float4 vertex : POSITION;
				 float2 uv : TEXCOORD0;
			 };

			 struct v2f
			 {
				 float2 uv : TEXCOORD0;
				 float4 vertex : SV_POSITION;
			 };

			 v2f vert(appdata v)
			 {
				 v2f o;
				 o.vertex = UnityObjectToClipPos(v.vertex);
				 o.uv = v.uv;
				 return o;
			 }

			 float4 frag(v2f i) : SV_Target
			 {
				 //float4 r = GATHER_RED_TEXTURE2D(_Texture,sampler_Texture,i.uv);
				 float4 r=float4(0,0,0,0);
				 float minimum = min(min(min(r.x, r.y), r.z), r.w);
				 return float4(minimum, minimum, minimum, minimum);
			  }
		     ENDCG
		 }
	}
}
