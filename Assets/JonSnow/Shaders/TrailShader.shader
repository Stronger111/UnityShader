Shader "Hidden/TrailShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
		// Clear
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(0.75,0.75,0.75,0.75);
            }
            ENDCG
        }
		// Draw
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

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

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;// 1/width, 1/height, width, height
			float2 _TrailCenter;
			float _TrailRadius;
			float _TrailHardness;

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				float2 delta = (i.uv - 0.5) * 128 - _TrailCenter;
				float len = length(delta);
				if (len < _TrailRadius * 1.5)
				{
					//float fade = 1-saturate(len / _TrailRadius * len / _TrailRadius);
					float x = len / _TrailRadius;
					float fade0 = 0.75 - (_TrailHardness * 0.75 - 0.25) * (1 - x);// * (1 - x);
					float fade1 = _TrailHardness * 0.25 + 0.75 - _TrailHardness * 4 * (x - 1.25) * (x - 1.25);
					float fade = lerp(fade0, fade1, step(1.0, x));
					col *= (fade / 0.75);
					//col += (1 - col) * _TrailHardness * fade;
				}
				return col;
			}
			ENDCG
		}
    }
}
