// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/Terrain"
{
    Properties
    {
		_DirtColor("Dirt Color", 2D) = "white" {}
		[NoScaleOffset]
		_DirtNormalmap("Dirt Normal", 2D) = "bump" {}
		[NoScaleOffset]
		_DirtRoughness("Dirt Roughness", 2D) = "white" {}
		[NoScaleOffset]
		_DirtHeight("Dirt Height", 2D) = "black" {}
		_DirtDisplacementScale("Dirt Displacement Scale", float) = 0.06

        _SnowNormalmap ("Snow Normal", 2D) = "bump" {}
		[NoScaleOffset]
        _SnowHeight ("Snow Height", 2D) = "black" {}
		[NoScaleOffset]
        _SnowWeight ("Snow Weight", 2D) = "white" {}
        _SnowNoise ("Snow Noise", 2D) = "black" {}
        _SnowColor ("Snow Color", Color) = (1,1,1,1)
        // [NoScaleOffset]
        // _SnowSpec ("Snow Spec", 2D) = "black" {}
        // [NoScaleOffset]
        // _SnowRough ("Snow Rough", 2D) = "black" {}
		[NoScaleOffset]
        _SnowDiffuse ("Snow Diffuse", 2D) = "bump" {}
        _SnowDisplacementScale ("Snow Displacement Scale", float) = 0.045
        _SnowAOStrength ("Snow AO Strength", Range(0,1)) = 0.5
        _SnowAODeformation ("Snow AO Deformation", Range(0, 1)) = 0.2
        _SnowSubsurfaceColor ("Snow Subsurface Color", Color) = (0, 0.5, 1, 1)

        _TessellationFactor ("Tessellation Factor(OOOI)", Vector) = (3,3,3,3)

        _TrailTex("Trail Tex", 2D) = "black" {}

        _MaskThreshold ("Mask Threshold", Range(0, 1)) = 0.85
        _MaskHardness("Mask Hardness", float) = 20
        _SnowElevation ("Snow Elevation", float) = 0.4

        _SnowRoughness ("Snow Roughness", Range(0, 1)) = 0.2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma hull HS
            #pragma domain DS
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

			float4 _DirtColor_ST;
			sampler2D _DirtColor;
			sampler2D _DirtNormalmap;
			sampler2D _DirtRoughness;
			sampler2D _DirtHeight;
            float _DirtDisplacementScale;

            float4 _SnowNormalmap_ST;
            sampler2D _SnowNormalmap;
            sampler2D _SnowHeight;
            sampler2D _SnowWeight;
            float4 _SnowNoise_ST;
            sampler2D _SnowNoise;
            float4 _SnowColor;
            // sampler2D _SnowSpec;
            // sampler2D _SnowRough;
            sampler2D _SnowDiffuse;
            float _SnowDisplacementScale;
            float _SnowAOStrength;
            float _SnowAODeformation;
            float4 _SnowSubsurfaceColor;

            float4 _TessellationFactor;

            sampler2D _TrailTex;
            float _MaskThreshold;
            float _MaskHardness;
            float _SnowElevation;

            float _SnowRoughness;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct VertOut
            {
                float4 vertex : INTERNALTESSPOS;
                float2 uv : TEXCOORD0;
                float2 uvDirt : TEXCOORD1;
                float2 uvSnow : TEXCOORD2;
                float2 uvNoise : TEXCOORD3;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            VertOut vert (appdata v)
            {
                VertOut o;
                o.uv = v.uv;
                o.uvDirt = TRANSFORM_TEX(v.uv, _DirtColor);
                o.uvSnow = TRANSFORM_TEX(v.uv, _SnowNormalmap);
                o.uvNoise = TRANSFORM_TEX(v.uv, _SnowNoise);
                o.vertex = v.vertex;
                o.normal = v.normal;
                o.tangent = v.tangent;
                return o;
            }

            struct PatchTess
            {
                float EdgeTess[3] : SV_TessFactor;
                float InsideTess : SV_InsideTessFactor;
            };

            PatchTess ConstHS(InputPatch<VertOut, 3> patch, uint patchID : SV_PRIMITIVEID)
            {
                PatchTess pt;
                pt.EdgeTess[0] = _TessellationFactor.x;
                pt.EdgeTess[1] = _TessellationFactor.y;
                pt.EdgeTess[2] = _TessellationFactor.z;
                pt.InsideTess = _TessellationFactor.w;
                return pt;
            }

            struct HullOut
            {
                float4 vertex : INTERNALTESSPOS;
                float2 uv : TEXCOORD0;
                float2 uvDirt : TEXCOORD1;
                float2 uvSnow : TEXCOORD2;
                float2 uvNoise : TEXCOORD3;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            [UNITY_domain("tri")]
            [UNITY_partitioning("integer")]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_patchconstantfunc("ConstHS")]
            HullOut HS(InputPatch<VertOut, 3> p,
            uint i : SV_OutputControlPointID,
            uint patchId : SV_PRIMITIVEID)
            {
                HullOut hout;
                hout.vertex = p[i].vertex;
                hout.uv = p[i].uv;
                hout.uvDirt = p[i].uvDirt;
                hout.uvSnow = p[i].uvSnow;
                hout.uvNoise = p[i].uvNoise;
                hout.normal = p[i].normal;
                hout.tangent = p[i].tangent;
                return hout;
            }

            struct DomainOut
            {
                float4 vertex : POSITION;
                float3 tSpace0 : TEXCOORD0;
                float3 tSpace1 : TEXCOORD1;
                float3 tSpace2 : TEXCOORD2;
                float2 uv : TEXCOORD3;
                float2 uvDirt : TEXCOORD4;
                float2 uvSnow : TEXCOORD5;
                float2 uvNoise : TEXCOORD6;
                float3 worldPos : TEXCOORD7;
                float trailDepth : TEXCOORD8;
            };

            [UNITY_domain("tri")]
            DomainOut DS(PatchTess pt,
            float3 uvw : SV_DomainLocation,
            const OutputPatch<HullOut, 3> tri)
            {
                DomainOut dout;
                dout.uv = tri[0].uv * uvw.x + tri[1].uv * uvw.y + tri[2].uv * uvw.z;
                dout.uvDirt = tri[0].uvDirt * uvw.x + tri[1].uvDirt * uvw.y + tri[2].uvDirt * uvw.z;
                dout.uvSnow = tri[0].uvSnow * uvw.x + tri[1].uvSnow * uvw.y + tri[2].uvSnow * uvw.z;
                dout.uvNoise = tri[0].uvNoise * uvw.x + tri[1].uvNoise * uvw.y + tri[2].uvNoise * uvw.z;
                float3 normal = normalize(tri[0].normal * uvw.x + tri[1].normal * uvw.y + tri[2].normal * uvw.z);
                float3 tangent = normalize((tri[0].tangent * uvw.x + tri[1].tangent * uvw.y + tri[2].tangent * uvw.z).xyz);
                

                float weight = tex2Dlod(_SnowWeight, float4(dout.uv, 0, 0)).r;

				float disp = _DirtDisplacementScale * 2 * tex2Dlod(_DirtHeight, float4(dout.uvDirt, 0, 0)).r - _DirtDisplacementScale;
                float snowHeight = tex2Dlod(_SnowHeight, float4(dout.uvSnow, 0, 0)).r;
                
                float2 worldCenter = float2(0,0);
                float worldSize = 128;

                float3 vertex = tri[0].vertex * uvw.x + tri[1].vertex * uvw.y + tri[2].vertex * uvw.z;
                float4 worldPos = mul(unity_ObjectToWorld, float4(vertex,1));
                float4 uvTrail = float4((worldPos.xz - worldCenter) / worldSize + 0.5, 0, 0);
                float trailDepth = tex2Dlod(_TrailTex, uvTrail).r;
                trailDepth *= 4;
                float blurStep = 1.0/1024;
                trailDepth += tex2Dlod(_TrailTex, uvTrail + float4(1,0,0,0) * blurStep).r * 2;
                trailDepth += tex2Dlod(_TrailTex, uvTrail + float4(0,1,0,0) * blurStep).r * 2;
                trailDepth += tex2Dlod(_TrailTex, uvTrail + float4(-1,0,0,0) * blurStep).r * 2;
                trailDepth += tex2Dlod(_TrailTex, uvTrail + float4(0,-1,0,0) * blurStep).r * 2;
                trailDepth += tex2Dlod(_TrailTex, uvTrail + float4(-1,-1,0,0) * blurStep).r;
                trailDepth += tex2Dlod(_TrailTex, uvTrail + float4(1,1,0,0) * blurStep).r;
                trailDepth += tex2Dlod(_TrailTex, uvTrail + float4(1,-1,0,0) * blurStep).r;
                trailDepth += tex2Dlod(_TrailTex, uvTrail + float4(-1,1,0,0) * blurStep).r;
                trailDepth /= 16;
                snowHeight = lerp(snowHeight, 0.5, trailDepth);
                float snowDisp = _SnowDisplacementScale * 2 * snowHeight - _SnowDisplacementScale;

                // float trailDisp = (1 - trailDepth) * _SnowElevation * weight;
                
                float trailDisp = trailDepth / 0.75 * _SnowElevation * weight;

                disp = lerp(lerp(disp, snowDisp, weight), disp, trailDepth) + trailDisp;

                worldPos.y += disp;
                dout.vertex = mul(UNITY_MATRIX_VP, worldPos);
                dout.worldPos = worldPos;

                dout.trailDepth = trailDepth;

                float uvwStep = 1 / _TessellationFactor.w;
                uvw.x += uvwStep;
                uvw.z -= uvwStep;

                float3 trailStep = float3(0.125, 0, -0.125);
                float s21 = tex2Dlod(_TrailTex, float4((worldPos.xz + trailStep.zy - worldCenter) / worldSize + 0.5, 0, 0)).r;
                float s01 = tex2Dlod(_TrailTex, float4((worldPos.xz + trailStep.xy - worldCenter) / worldSize + 0.5, 0, 0)).r;
                float s12 = tex2Dlod(_TrailTex, float4((worldPos.xz + trailStep.yz - worldCenter) / worldSize + 0.5, 0, 0)).r;
                float s10 = tex2Dlod(_TrailTex, float4((worldPos.xz + trailStep.yx - worldCenter) / worldSize + 0.5, 0, 0)).r;
                float3 va = normalize(float3(trailStep.xy * 2, s01 - s21));
                float3 vb = normalize(float3(trailStep.yx * 2, s10 - s12));
                float3 ad = cross(va, vb);

                float3 worldNormal = UnityObjectToWorldNormal(normal);
                worldNormal = normalize(worldNormal + ad * (dot(worldNormal, ad)));
                float3 worldTangent = UnityObjectToWorldDir(tangent.xyz);
                float3 worldBitangent = cross(worldNormal, worldTangent) * tri[0].tangent.w * unity_WorldTransformParams.w;
                worldTangent = cross(worldNormal, worldBitangent);
                dout.tSpace0 = float3(worldTangent.x, worldBitangent.x, worldNormal.x);
                dout.tSpace1 = float3(worldTangent.y, worldBitangent.y, worldNormal.y);
                dout.tSpace2 = float3(worldTangent.z, worldBitangent.z, worldNormal.z);

                return dout;
            }

            void frag (DomainOut i
            , out half4 outGBuffer0 : SV_TARGET0
            , out half4 outGBuffer1 : SV_TARGET1
            , out half4 outGBuffer2 : SV_TARGET2
            , out half4 outEmission : SV_TARGET3
            #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
            , out half4 outShadowMask : SV_TARGET4
            #endif
            )
            {
                // Dirt
                float3 baseColor = tex2D(_DirtColor, i.uvDirt).rgb;
                float occlusion = 0;
                float roughness = tex2D(_DirtRoughness, i.uvDirt).r;
                float3 normal = UnpackNormal(tex2D(_DirtNormalmap, i.uvDirt)).rgb;
                normal.x = dot(i.tSpace0, normal);
                normal.y = dot(i.tSpace1, normal);
                normal.z = dot(i.tSpace2, normal);
                normal = normalize(normal);
                float4 ssColor = float4(0,0,0,0);

                // trail
                float trailDepth = i.trailDepth;//tex2D(_TrailTex, (i.worldPos.xz - float2(0,0)) / 128 + 0.5).r;

                // Snow
                float3 snowColor = tex2D(_SnowDiffuse, i.uvSnow);//_SnowColor;
                float snowOcclusion = lerp(tex2D(_SnowHeight, i.uvSnow).r, 0.5, 1 - saturate(trailDepth / 0.75)) * _SnowAOStrength + 1 - _SnowAOStrength;
                snowOcclusion *= (1 - _SnowAODeformation) + _SnowAODeformation * saturate(trailDepth / 0.75) * saturate(trailDepth / 0.75);
                
                // float4 snowSpec = tex2D(_SnowSpec, i.uvSnow);
                // float snowRough = tex2D(_SnowRough, i.uvSnow).r;
                float snowRoughness = tex2D(_SnowNoise, i.uvNoise).r;
                snowRoughness *= 1 - _SnowRoughness;
                snowRoughness += _SnowRoughness;
                float3 snowNormal = UnpackNormal(tex2D(_SnowNormalmap, i.uvSnow)).rgb;
                snowNormal.x = dot(i.tSpace0, snowNormal);
                snowNormal.y = dot(i.tSpace1, snowNormal);
                snowNormal.z = dot(i.tSpace2, snowNormal);
                snowNormal = normalize(snowNormal+snowRoughness*float3(0,-0.25,0));
                float4 snowSSColor = _SnowSubsurfaceColor;


                // mask
                float mask = saturate(1 - trailDepth / 0.75) * 0.5;//saturate((trailDepth - _MaskThreshold) * _MaskHardness);


                // lerp
                float weight = tex2D(_SnowWeight, i.uv).r;
                baseColor = lerp(lerp(baseColor, snowColor.rgb, weight), baseColor, mask);
                occlusion = lerp(lerp(occlusion, snowOcclusion, weight), occlusion, mask);
                roughness = lerp(lerp(roughness, snowRoughness, weight), roughness, mask);
                normal = lerp(lerp(normal, snowNormal, weight), normal, mask);
                normal = normalize(normal);
                ssColor = lerp(lerp(ssColor, snowSSColor, weight), ssColor, mask);

                // GBuffer
                // RT0: diffuse color (rgb), occlusion (a) - sRGB rendertarget
                // RT1: spec color (rgb), smoothness (a) - sRGB rendertarget
                // RT2: normal (rgb), --unused, very low precision-- (a)
                outGBuffer0 = float4(baseColor, occlusion);
                outGBuffer1 = float4(occlusion.xxx,_SnowRoughness);//1 - roughness * roughness);
                outGBuffer2 = float4(normal, 0);

				// outGBuffer0 = (float4(i.tSpace0.z, i.tSpace1.z, i.tSpace2.z, 0));
				// outGBuffer1 = float4(0,0,0,0);//1 - roughness * roughness);
				// outGBuffer2 = float4(1,1,1, 0);

                outEmission = float4(1,1,1,1);//float4(0,0,0,1);
    #ifdef _EMISSION
                outEmission = ssColor;
    #endif

                // outGBuffer0 = abs(float4(tex2D(_DirtColor, i.uvDirt).rgb,0));
                // outGBuffer1 = float4(0,0,0,0);
                // outGBuffer2 = float4(0,1,0,0);
                // outEmission = float4(0,0,0,0);

            #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
                outShadowMask = float4(0, 0, 0, 0);
            #endif
            }
            ENDCG
        }
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma hull HS
            #pragma domain DS
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
    #include "UnityStandardCore.cginc"

			float4 _DirtColor_ST;
			sampler2D _DirtColor;
			sampler2D _DirtNormalmap;
			sampler2D _DirtRoughness;
			sampler2D _DirtHeight;
            float _DirtDisplacementScale;

            float4 _SnowNormalmap_ST;
            sampler2D _SnowNormalmap;
            sampler2D _SnowHeight;
            sampler2D _SnowWeight;
            float4 _SnowNoise_ST;
            sampler2D _SnowNoise;
            float4 _SnowColor;
            float _SnowDisplacementScale;
            float _SnowAOStrength;
            float _SnowAODeformation;
            float4 _SnowSubsurfaceColor;

            float4 _TessellationFactor;

            sampler2D _TrailTex;
            float _MaskThreshold;
            float _MaskHardness;
            float _SnowElevation;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct VertOut
            {
                float4 vertex : INTERNALTESSPOS;
                float2 uv : TEXCOORD0;
                float2 uvDirt : TEXCOORD1;
                float2 uvSnow : TEXCOORD2;
                float2 uvNoise : TEXCOORD3;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            VertOut vert (appdata v)
            {
                VertOut o;
                o.uv = v.uv;
                o.uvDirt = TRANSFORM_TEX(v.uv, _DirtColor);
                o.uvSnow = TRANSFORM_TEX(v.uv, _SnowNormalmap);
                o.uvNoise = TRANSFORM_TEX(v.uv, _SnowNoise);
                o.vertex = v.vertex;
                o.normal = v.normal;
                o.tangent = v.tangent;
                return o;
            }

            struct PatchTess
            {
                float EdgeTess[3] : SV_TessFactor;
                float InsideTess : SV_InsideTessFactor;
            };

            PatchTess ConstHS(InputPatch<VertOut, 3> patch, uint patchID : SV_PRIMITIVEID)
            {
                PatchTess pt;
                pt.EdgeTess[0] = _TessellationFactor.x;
                pt.EdgeTess[1] = _TessellationFactor.y;
                pt.EdgeTess[2] = _TessellationFactor.z;
                pt.InsideTess = _TessellationFactor.w;
                return pt;
            }

            struct HullOut
            {
                float4 vertex : INTERNALTESSPOS;
                float2 uv : TEXCOORD0;
                float2 uvDirt : TEXCOORD1;
                float2 uvSnow : TEXCOORD2;
                float2 uvNoise : TEXCOORD3;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            [UNITY_domain("tri")]
            [UNITY_partitioning("integer")]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_patchconstantfunc("ConstHS")]
            HullOut HS(InputPatch<VertOut, 3> p,
            uint i : SV_OutputControlPointID, uint patchID : SV_PRIMITIVEID)
            {
                HullOut hout;
                hout.vertex = p[i].vertex;
                hout.uv = p[i].uv;
                hout.uvDirt = p[i].uvDirt;
                hout.uvSnow = p[i].uvSnow;
                hout.uvNoise = p[i].uvNoise;
                hout.normal = p[i].normal;
                hout.tangent = p[i].tangent;
                return hout;
            }

            struct DomainOut
            {
                float4 vertex : POSITION;
                float3 tSpace0 : TEXCOORD0;
                float3 tSpace1 : TEXCOORD1;
                float3 tSpace2 : TEXCOORD2;
                float2 uv : TEXCOORD3;
                float2 uvDirt : TEXCOORD4;
                float2 uvSnow : TEXCOORD5;
                float2 uvNoise : TEXCOORD6;
                float3 worldPos : TEXCOORD7;
            };

            [UNITY_domain("tri")]
            DomainOut DS(PatchTess pt,
            float3 uvw : SV_DomainLocation,
            const OutputPatch<HullOut, 3> tri)
            {
                DomainOut dout;
                dout.uv = tri[0].uv * uvw.x + tri[1].uv * uvw.y + tri[2].uv * uvw.z;
                dout.uvDirt = tri[0].uvDirt * uvw.x + tri[1].uvDirt * uvw.y + tri[2].uvDirt * uvw.z;
                dout.uvSnow = tri[0].uvSnow * uvw.x + tri[1].uvSnow * uvw.y + tri[2].uvSnow * uvw.z;
                dout.uvNoise = tri[0].uvNoise * uvw.x + tri[1].uvNoise * uvw.y + tri[2].uvNoise * uvw.z;
                float3 normal = normalize(tri[0].normal * uvw.x + tri[1].normal * uvw.y + tri[2].normal * uvw.z);
                float3 tangent = normalize((tri[0].tangent * uvw.x + tri[1].tangent * uvw.y + tri[2].tangent * uvw.z).xyz);
                
                float3 worldNormal = UnityObjectToWorldNormal(normal);
                float3 worldTangent = UnityObjectToWorldDir(tangent.xyz);
                float3 worldBitangent = cross(worldNormal, worldTangent) * tri[0].tangent.w * unity_WorldTransformParams.w;
                //worldTangent = cross(worldNormal, worldBitangent);
                dout.tSpace0 = float3(worldTangent.x, worldBitangent.x, worldNormal.x);
                dout.tSpace1 = float3(worldTangent.y, worldBitangent.y, worldNormal.y);
                dout.tSpace2 = float3(worldTangent.z, worldBitangent.z, worldNormal.z);
                float3 vertex = tri[0].vertex * uvw.x + tri[1].vertex * uvw.y + tri[2].vertex * uvw.z;
                float weight = tex2Dlod(_SnowWeight, float4(dout.uv, 0, 0)).r;

                float4 worldPos = mul(unity_ObjectToWorld, float4(vertex,1));

				float disp = _DirtDisplacementScale * 2 * tex2Dlod(_DirtHeight, float4(dout.uvDirt, 0, 0)).r - _DirtDisplacementScale;
                float snowHeight = tex2Dlod(_SnowHeight, float4(dout.uvSnow, 0, 0)).r;
                float trailDepth = tex2Dlod(_TrailTex, float4((worldPos.xz - float2(0,0)) / 128 + 0.5, 0, 0)).r;
                snowHeight = lerp(snowHeight, 0.5, trailDepth);
                float snowDisp = _SnowDisplacementScale * 2 * snowHeight - _SnowDisplacementScale;

                float trailDisp = (1 - trailDepth) * _SnowElevation * weight;

                disp = lerp(lerp(disp, snowDisp, weight), disp, trailDepth) + trailDisp;

                worldPos.y += disp;
                dout.vertex = mul(UNITY_MATRIX_VP, worldPos);
                dout.worldPos = worldPos;

                return dout;
            }

            fixed4 frag (DomainOut i
            ) : SV_TARGET
            {
                // Dirt
                float3 baseColor = tex2D(_DirtColor, i.uvDirt).rgb;
                float occlusion = 0;
                float roughness = tex2D(_DirtRoughness, i.uvDirt).r;
                float3 normal = UnpackNormal(tex2D(_DirtNormalmap, i.uvDirt)).rgb;
                normal.x = dot(i.tSpace0, normal);
                normal.y = dot(i.tSpace1, normal);
                normal.z = dot(i.tSpace2, normal);
                normal = normalize(normal);
                float4 ssColor = float4(0,0,0,0);

                // trail
                float trailDepth = tex2D(_TrailTex, (i.worldPos.xz - float2(0,0)) / 128 + 0.5).r;

                // Snow
                float3 snowColor = _SnowColor;
                float snowOcclusion = lerp(tex2D(_SnowHeight, i.uvSnow).r, 0.5, trailDepth) * _SnowAOStrength + 1 - _SnowAOStrength;
                snowOcclusion *= 1 - _SnowAODeformation * trailDepth;
                float snowRoughness = tex2D(_SnowNoise, i.uvNoise).r;
                snowRoughness *= 0.9;
                snowRoughness += 0.1;
                float3 snowNormal = UnpackNormal(tex2D(_SnowNormalmap, i.uvSnow)).rgb;
                snowNormal.x = dot(i.tSpace0, snowNormal);
                snowNormal.y = dot(i.tSpace1, snowNormal);
                snowNormal.z = dot(i.tSpace2, snowNormal);
                snowNormal = normalize(snowNormal);
                float4 snowSSColor = _SnowSubsurfaceColor;

                // mask
                float mask = saturate((trailDepth - _MaskThreshold) * _MaskHardness);


                // lerp
                float weight = tex2D(_SnowWeight, i.uv).r;
                baseColor = lerp(lerp(baseColor, snowColor.rgb, weight), baseColor, mask);
                occlusion = lerp(lerp(occlusion, snowOcclusion, weight), occlusion, mask);
                roughness = lerp(lerp(roughness, snowRoughness, weight), roughness, mask);
                normal = lerp(lerp(normal, snowNormal, weight), normal, mask);
                normal = normalize(snowNormal);
                ssColor = lerp(lerp(ssColor, snowSSColor, weight), ssColor, mask);

                half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                // half3 halfDir = normalize(lightDir + viewDir);
                // half diff = max(0, dot(normal, lightDir));
                // half nh = max(0, dot(normal, halfDir));
                // float spec = pow(nh, (1 - roughness * roughness) * 128);
                UnityIndirect ind;
                UNITY_INITIALIZE_OUTPUT(UnityIndirect, ind);
                ind.diffuse = 0;
                ind.specular = 0;
                UnityLight light;
                UNITY_INITIALIZE_OUTPUT(UnityLight, light);
                light.dir = lightDir;
                light.color = _LightColor0;
                half4 res = UNITY_BRDF_PBS (baseColor, occlusion.xxx, 1, 1 - roughness * roughness, normal, -viewDir, light, ind);
                return res;
            }
            ENDCG
        }
    }
}
