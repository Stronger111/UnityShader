// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
//使用顶点法线进行环境反射
Shader "Unlit/SkyReflection"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                half3 worldRef1 : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            v2f vert (float4 vertex:POSITION,float3 normal:NORMAL)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(vertex);
                float3 worldPos=mul(unity_ObjectToWorld,vertex).xyz;
                float3 worldViewDir=normalize(UnityWorldSpaceViewDir(worldPos));
                float3 worldNormal=UnityObjectToWorldNormal(normal);
                o.worldRef1=reflect(-worldViewDir,worldNormal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 skyData=UNITY_SAMPLE_TEXCUBE(unity_SpecCube0,i.worldRef1);
                half3 skyColor=DecodeHDR(skyData,unity_SpecCube0_HDR);
                // sample the texture
                fixed4 col =0;
                // apply fog
                col.rgb=skyColor;
                return col;
            }
            ENDCG
        }
    }
}
