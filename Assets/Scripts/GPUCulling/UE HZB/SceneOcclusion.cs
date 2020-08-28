using System.Collections;
using System.Collections.Generic;
using UnityEngine;
/// <summary>
/// OC Culling
/// </summary>
public class SceneOcclusion
{
    public List<UGOcclusionPrimitive> Primitives;

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
