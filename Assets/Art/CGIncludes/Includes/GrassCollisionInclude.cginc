sampler3D _GrassTrailTex;
float _HeightRestriction;
float _GrassCollisionIntensity;
float _WindIntensity;
sampler3D _WindVolumeTex;
float4 _HeroPos;
float3 _StaticWindVector;
float2 _UVOffset;

sampler3D _WindNoise;

float GetWindFromTexture(float2 pos,float2 size,float offs,float2 dir)
{
   float2 movement=offs;
   return tex2Dlod(_WindNoise,float4((pos.x+movement.x)*size.x+dir.x*_Time.y/5,(pos.y+movement.y)*size.y+dir.y*_Time.y/5,0,0)).r*_WindIntensity*0.5;
}

//外部传入位移UV
float GetWindFromTextureStatic(float2 pos,float2 size,float offs,float2 uv)
{
   float2 movement=offs;
   return tex2Dlod(_WindNoise,float4((pos.x+movement.x)*size.x+uv.x,(pos.y+movement.y)*size.y+uv.y,0,0)).r*_WindIntensity*0.5;
}

float Deg2Rad(float deg)
{
   return deg*3.141593/180;
}

float Rad2Deg(float rad)
{
   return rad*180/3.141593;
}

float3 RotateVec(float vec,float angle)
{
   float rad=Deg2Rad(angle);
   float cs=cos(rad);
   float sn=sin(rad);
   float3 side=float3(0,0,0);
   side.x=vec.x*cs-vec.z*sn;
   side.z=vec.x*sn+vec.z*cs;
   return side;
}

float3 GetWind(float3 p0,float offs,float3 objSpaceStaticWindVector)
{
   float4 wp=mul(unity_ObjectToWorld,float4(p0,1));
   float3 ret=float4(0,0,0,0);
   //局部风
   float4 volume=tex3Dlod(_WindVolumeTex,float4((wp.xyz-_HeroPos.xyz+float3(16,16,16))/32,0));
   //srgb
   volume=pow(volume,1/2.24);
   //法线解码
   volume.xyz=volume.xyz*2-1;
   volume.xyz*=volume.w*10;
   float3 objSpaceDynamicWindVector=mul(unity_ObjectToWorld,float4(volume.xyz,0)).xyz;

   ret+=GetWindFromTextureStatic(wp.xz,0.08,offs,_UVOffset)*objSpaceDynamicWindVector;
   ret+=GetWindFromTexture(wp.xz,0.08,offs,objSpaceDynamicWindVector.xz)*objSpaceDynamicWindVector;
   return ret;
}

float3 GetWindStatic(float3 p0,float offs,float3 objSpaceStaticWindVector)
{
   float4 wp=mul(unity_ObjectToWorld,float4(p0,1));
   float3 ret=GetWindFromTextureStatic(wp.xz,offs,_UVOffset)*objSpaceStaticWindVector;
   return ret;
}

//风吹效果
void BlowWind(inout float4 vertex,float4 color)
{
    float3 worldPos=mul(unity_ObjectToWorld,vertex).xyz;
    float hardness=sin(min(vertex.y/4,1.5));
    float3 objSpaceStaticWindVector=mul(unity_WorldToObject,float4(_StaticWindVector.xyz,0)).xyz;
    float3 p0=vertex.xyz;
    float3 p1=p0;
    p1=p0+GetWindStatic(p0,0,objSpaceStaticWindVector)*hardness;
    p1+=GetWindStatic(p1,0.5,objSpaceStaticWindVector)*hardness;

    //草被风吹歪高度降低
    float cosTheta=abs(dot(normalize(p1.xz),normalize(p0.xz)));
    float temp1=length(p1.xz);
    float temp0=length(p0.xz);
    //弯曲效果
    float temp=(temp1-temp0)*cosTheta;
    p1.y-=temp*0.5;
    float2 offset=p1.xz-vertex.xz;
    offset=clamp(offset,-1,1);
    p1.xz=vertex.xz+offset;

    float isLeaf=color.r;
    vertex.xyz=lerp(vertex.xyz,p1,vertex.y*isLeaf);
}

//踩草效果
void GrassGeom(inout float4 vertex,float4 color)
{
    float3 worldPos=mul(unity_ObjectToWorld,vertex).xyz;
    if(distance(worldPos,_HeroPos)>0)
    return;
    float3 offset=float3(0,0.1,0.2);

    float4 grass=tex2Dlod(_GrassTrailTex,float4((worldPos.xz-_HeroPos.xz+float2(16.0,16.0))/32.0,0,0));

    grass=saturate(grass);
    grass.xz=grass.xz*2-1;
    grass*=grass.w;
    grass.y=-grass.w*7;

    grass.xyz=mul(unity_WorldToObject,float4(grass.xyz,0));

    float yParam=min(1,vertex.y/5);
    //防止踩树
    //todo 花的顶点高度过高,比树还高,需要美术更改
    yParam*=step(0,_HeightRestriction-vertex.y);

    grass*=80;
    float grassIntensity=saturate(length(grass));
    grass=clamp(grass,-2,2);
    float3 offsetXYZ=float3(yParam*(grass.x)*_GrassCollisionIntensity*2,
        yParam*(grass.y)*_GrassCollisionIntensity*2,
        yParam*(grass.z)*_GrassCollisionIntensity*2);
     offsetXYZ=lerp(0,offsetXYZ,grassIntensity);
     offsetXYZ=min(2,offsetXYZ);

     float isLeaf=color.r;
     float3 vTemp=offsetXYZ*isLeaf+vertex.xyz;
     vertex.xyz=vTemp;
}
float4 _SphereInfo;

float3 GetFootStep(float2 volumeSpacePos)
{
   _SphereInfo.z=0.001*6;
   _SphereInfo.z=min(1,_SphereInfo.z);

   float3 grass=0;

   float2 _SpherePos0=0.5;
   float2 _SpherePos1=0.5+_SphereInfo.xy*10;

   float2 dirWakeXZ0=normalize(volumeSpacePos-_SpherePos0.xy);
   float3 dirTemp0=float3(dirWakeXZ0.x,0,_SpherePos0.xy);
   float dist0=distance(volumeSpacePos,_SpherePos0.xy);
   dirTemp0.y=-saturate(1-dist0);
   grass+=lerp(dirTemp0,0,smoothstep(-0.4,0.02,(dist0-_SphereInfo.w)))*_SphereInfo.z;

   float weight=0.01;
   float2 dirWakeXZ1=normalize(volumeSpacePos-_SpherePos1.xy);
   float3 dirTemp1=float3(dirWakeXZ1.x,0,dirWakeXZ1.y);
   float dist1=distance(volumeSpacePos,_SpherePos1.xy);
   dirTemp1.y=-saturate(1-dist1);
   grass+=(lerp(dirTemp1,0,smoothstep(-0.4,0.02,(dist1-_SphereInfo.w))))*_SphereInfo.z)*weight;
   
   return grass;
}

//踩草效果低配版
void GrassGeomLow(inout float4 vertex,float4 color)
{
   float3 worldPos=mul(unity_ObjectToWorld,vertex).xyz;
   if(distance(worldPos,_HeroPos)>10)
     return;

    float3 offset=float3(0,0.1,0.2);
    float2 volumeSpacePos=(worldPos.xz-_HeroPos.xz+float2(16.0,16.0))/32.0;
    float3 grass=GetFootStep(volumeSpacePos);

    grass.xyz=mul(unity_WorldToObject,float4(grass.xyz,0));

    
    float yParam=min(1,vertex.y/5);
    //防止踩树
    //todo 花的顶点高度过高,比树还高,需要美术更改
    yParam*=step(0,_HeightRestriction-vertex.y);

    grass*=200;
    float grassIntensity=saturate(length(grass));
    grass=clamp(grass,-2,2);
    float3 offsetXYZ=float3(yParam*(grass.x)*_GrassCollisionIntensity*2,
        yParam*(grass.y)*_GrassCollisionIntensity*2,
        yParam*(grass.z)*_GrassCollisionIntensity*2);
     offsetXYZ=lerp(0,offsetXYZ,grassIntensity);
     offsetXYZ=min(2,offsetXYZ);

     float isLeaf=color.r;
     float3 vTemp=offsetXYZ*isLeaf+vertex.xyz;
     vertex.xyz=vTemp;
}
