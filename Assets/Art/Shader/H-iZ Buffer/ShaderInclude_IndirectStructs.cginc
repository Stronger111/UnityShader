#ifndef __INDIRECT_INCLUDE__
#define __INDIRECT_INCLUDE__

struct InstanceData
{
	float3 boundsCenter;
	float3 boundsExtents;
};

struct Indirect2x2Matrix
{
	float4 row0; 
	float4 row1;
};

struct SortingData
{
	uint drawCallInstanceIndex;
	float distanceToCam;
};
#endif