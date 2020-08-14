// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/SkyReflection Per Pixel"
{
    Properties
    {
        _BumpMap ("Normal Map", 2D) = "bump" {}
    }
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
                float3 worldPos:TEXCOORD0;
                half3 tSpace0:TEXCOORD1;
                half3 tSpace1:TEXCOORD2;
                half3 tSpace2:TEXCOORD3;
                float2 uv:TEXCOORD4;
                float4 pos : SV_POSITION;
            };

            v2f vert (float4 vertex:POSITION,float3 normal:NORMAL,float4 tangent:TANGENT,float2 uv:TEXCOORD0)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(vertex);
                o.worldPos = mul(unity_ObjectToWorld,vertex);
                half3 wNormal=UnityObjectToWorldNormal(normal);  //世界空间法线
                half3 wTangent=UnityObjectToWorldDir(tangent);  //世界空间模型切线
                half tangentSign=tangent.w*unity_WorldTransformParams.w;
                half3 wBitangent=cross(wNormal,wTangent)*tangentSign;
                o.tSpace0=half3(wTangent.x,wBitangent.x,wNormal.x);
                o.tSpace1=half3(wTangent.y,wBitangent.y,wNormal.y);
                o.tSpace2=half3(wTangent.z,wBitangent.z,wNormal.z);
                o.uv=uv;
                return o;
            }
            sampler2D _BumpMap;
            fixed4 frag (v2f i) : SV_Target
            {
                half3 tnormal=UnpackNormal(tex2D(_BumpMap,i.uv));

                half3 worldNormal;
                worldNormal.x=dot(i.tSpace0,tnormal);
                worldNormal.y=dot(i.tSpace1,tnormal);
                worldNormal.z=dot(i.tSpace2,tnormal);   //点乘a*b 利用空间进行转换
                half3 worldViewDir=normalize(UnityWorldSpaceViewDir(i.worldPos));
                half3 worldRef1=reflect(-worldViewDir,worldNormal);

                half4 skyData=UNITY_SAMPLE_TEXCUBE(unity_SpecCube0,worldRef1);
                half3 skyColor=DecodeHDR(skyData,unity_SpecCube0_HDR);
                fixed4 col=0;
                col.rgb=skyColor;
                return col;
            }
            ENDCG
        }
    }
}
