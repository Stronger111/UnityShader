using System.Collections;
using System.Collections.Generic;
using UnityEngine;
/// <summary>
/// OC Culling
/// </summary>
public class SceneOcclusion
{
    /// <summary>
    /// 支持的纹理图
    /// </summary>
    public const int SizeX = 256;
    public const int SizeY = 256;
    public List<UGOcclusionPrimitive> Primitives;
    public Texture2D BoundsCenterTexture;
    public Texture2D BoundsExtentTexture;
    /// <summary>
    /// 添加包围盒信息 查询使用
    /// </summary>
    /// <param name="BoundsCenter"></param>
    /// <param name="BoundsExtent"></param>
    /// <returns></returns>
    public int AddBounds(Vector4 BoundsCenter,Vector4 BoundsExtent)
    {
        if (Primitives == null)
            Primitives = new List<UGOcclusionPrimitive>();
        UGOcclusionPrimitive primitive = new UGOcclusionPrimitive() { Center= BoundsCenter ,Extent= BoundsExtent};
        Primitives.Add(primitive);
        return Primitives.Count;
    }

    public void Sumit()
    {
        BoundsCenterTexture = new Texture2D(SizeX, SizeY);
        BoundsExtentTexture = new Texture2D(SizeX, SizeY);
        const int BlockSize = 8;
        const int SizeInBlocksX = SizeX / BlockSize; //32
        const int SizeInBlocksY = SizeY / BlockSize; //32
        const int BlockStride = BlockSize * 4 * sizeof(float);

        Color[] CenterBuffer = new Color[BlockSize* BlockSize];
        Color[] ExtentBuffer = new Color[BlockSize* BlockSize];

        int NumPrimitives = Primitives.Count;
        for(int i=0;i< NumPrimitives;i+= BlockSize* BlockSize)//+=64
        {
            //NumPrimitives >64 为64 否则为NumPrimitives-i  BlockEnd<=64
            int BlockEnd = Mathf.Min(BlockSize* BlockSize,NumPrimitives-i);
            for (int b = 0; b < BlockEnd; b++)
            {
                UGOcclusionPrimitive primitive = Primitives[i + b];
                CenterBuffer[b].r = primitive.Center.x;
                CenterBuffer[b].g = primitive.Center.y;
                CenterBuffer[b].b = primitive.Center.z;
                CenterBuffer[b].a = 0.0f;

                ExtentBuffer[b].r = primitive.Extent.x;
                ExtentBuffer[b].g = primitive.Extent.y;
                ExtentBuffer[b].b = primitive.Extent.z;
                ExtentBuffer[b].a = 1.0f;

                //清除 剩下的Block
                if(BlockEnd< BlockSize* BlockSize)
                {

                }
            }
            int BlockIndex = i / (BlockSize*BlockSize);
            int BlockX = BlockIndex % SizeInBlocksX;
            int BlockY = BlockIndex / SizeInBlocksY;
            //创建两张纹理数据
            BoundsCenterTexture.SetPixels(BlockX, BlockY, BlockSize, BlockSize, CenterBuffer);
            BoundsExtentTexture.SetPixels(BlockX, BlockY, BlockSize, BlockSize, ExtentBuffer);
        }
    }
}
/// <summary>
/// 一个分批处理的 遮挡单元
/// </summary>
public struct UGOcclusionPrimitive
{
    /// <summary>
    /// 物体包围盒中心
    /// </summary>
    public Vector4 Center;
    /// <summary>
    /// 包围盒大小
    /// </summary>
    public Vector4 Extent;
}
