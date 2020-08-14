Shader "Unlit/Art PBR"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Base Color",Color)=(1,1,1,1)
        [Gamma] _Metallic("Metallic",Range(0,1))=0  //金属度经过伽马校正
        _Smoothness("Smoothness",Range(0,1))=0.5
        [Header(LUT)]
        _LUT("Lut",2D)="white"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityStandardBRDF.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal:TEXCOORD1;
                float3 worldPos:TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float _Metallic;
            float _Smoothness;
            float4 _Color;
            sampler2D _LUT;
            float4 _MainTex_ST;

            float3 fresnelSchlickRoughness(float cosTheta,float3 F0,float roughness)
            {
                return F0+(max(float3(1.0-roughness,1.0-roughness,1.0-roughness),F0)-F0)*pow(1.0-cosTheta,5.0);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal=UnityObjectToWorldNormal(v.normal);
                o.normal=normalize(o.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.normal=normalize(i.normal); //归一化法线方向
                float3 lightDir=normalize(_WorldSpaceLightPos0.xyz); //世界空间灯光方向
                float3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);  //视点方向
                float3 lightColor=_LightColor0.rgb; //灯光颜色
                float3 halfVector=normalize(lightDir+viewDir); //半角向量
                float preceptualRoughness=1-_Smoothness;   //粗糙度
                float roughness=preceptualRoughness*preceptualRoughness;
                float squareRoughness=roughness*roughness;
                
                float nl=max(saturate(dot(i.normal,lightDir)), 0.000001);
                float nv=max(saturate(dot(i.normal,viewDir)), 0.000001);
                float vh=max(saturate(dot(viewDir,halfVector)), 0.000001);
                float lh=max(saturate(dot(lightDir,halfVector)), 0.000001);
                float nh=max(saturate(dot(i.normal,halfVector)), 0.000001);

               
                float3 Albedo=_Color*tex2D(_MainTex,i.uv);
                //高光GGX
                float lerpSquareRoughness=pow(lerp(0.002,1,roughness),2);
                //D
                float D=lerpSquareRoughness/(pow((pow(nh,2)*(lerpSquareRoughness-1)+1),2)*UNITY_PI);

                //G
                float kInDirectLight=pow(squareRoughness+1,2)/8;
                float kInIBL=pow(squareRoughness,2)/8;
                float GLeft=nl/lerp(nl,1,kInDirectLight);
                float GRight=nv/lerp(nv,1,kInDirectLight);
                float G=GLeft*GRight;

                //F
                float3 F0=lerp(unity_ColorSpaceDielectricSpec.rgb,Albedo,_Metallic);
                float3 F=F0+(1-F0)*exp2((-5.55473*vh-6.98316)*vh);
                float3 SpecularResult=(D*G*F*0.25)/(nv*nl);
                //漫反射部分
                float kd= (1 - F)*(1 - _Metallic);
                float3 diffColor=kd*Albedo*lightColor*nl;   //漫反射颜色 点乘 法线*灯光方向
                float3 specColor=SpecularResult*lightColor*nl*UNITY_PI;   //高光颜色
                float3 DirectLightResult=diffColor+specColor;   //直接光结果
                //间接光漫反射部分
                half3 ambient_contrib=ShadeSH9(float4(i.normal,1));  //球协光
                float3 ambient=0.03*Albedo;
                float3 iblDiffuse=max(half3(0,0,0),ambient.rgb+ambient_contrib);
                             
               
                //间接光高光部分
                float mip_roughness=preceptualRoughness*(1.7-0.7*preceptualRoughness);
                float3 reflectVec=reflect(-viewDir,i.normal);
                half mip=mip_roughness*UNITY_SPECCUBE_LOD_STEPS;
                half4 rgbm=UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,reflectVec,mip);

                float3 iblSpecular=DecodeHDR(rgbm,unity_SpecCube0_HDR);

                float2 envBRDF=tex2D(_LUT,float2(lerp(0,0.99,nv),lerp(0,0.99,roughness))).rg; //查找表部分 surfaceRedution
                float3 Flast=fresnelSchlickRoughness(max(nv,0.0),F0,roughness);
                float kdLast=(1-Flast)*(1-_Metallic);   
                float3 iblDiffuseResult=iblDiffuse*kdLast*Albedo;  //间接光部分
                float3 iblSpecularResult=iblSpecular*(Flast*envBRDF.r+envBRDF.g);  //间接光高光部分
                float3 IndirectResult=iblDiffuseResult+iblSpecularResult;

                float4 result= float4(DirectLightResult+IndirectResult,1); 

                return result;
            }
            ENDCG
        }
    }
}
