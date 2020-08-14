using System.Collections.Generic;
using System.Runtime.InteropServices;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

// Preferrably want to have all buffer structs in power of 2...
// 6 * 4 bytes = 24 bytes  //6个 4个bytes
[System.Serializable]
[StructLayout(LayoutKind.Sequential)] //内存布局顺序布局方式
public struct IndirectInstanceCSInput
{
    public Vector3 boundsCenter;  //3  +12
    public Vector3 boundsExtents;  //6 +12
}

// 8 * 4 bytes = 32 bytes
[StructLayout(LayoutKind.Sequential)]
public struct Indirect2x2Matrix
{
    public Vector4 row0;
    public Vector4 row1;  //16+16=32
}

// 2 * 4 bytes = 8 bytes
public class SortingData
{
    public uint drawCallInstanceIndex;  //1
    public float distanceToCam;  //2
}

[System.Serializable]
public class IndirectRenderingMesh
{
    public Mesh mesh;
    public Material material;
    //Lod Shader
    public MaterialPropertyBlock lod00MatPropBlock;
    public MaterialPropertyBlock lod01MatPropBlock;
    public MaterialPropertyBlock lod02MatPropBlock;
    //LOD Shadow
    public MaterialPropertyBlock shadowLod00MatPropBlock;
    public MaterialPropertyBlock shadowLod01MatPropBlock;
    public MaterialPropertyBlock shadowLod02MatPropBlock;
    //Vertices
    public uint numOfVerticesLod00;
    public uint numOfVerticesLod01;
    public uint numOfVerticesLod02;
    //Indices
    public uint numOfIndicesLod00;
    public uint numOfIndicesLod01;
    public uint numOfIndicesLod02;
}
public class IndirectRenderer : MonoBehaviour
{
    #region 变量
    [Header("设置")]
    public bool runCompute = true;
    public bool drawInstance = true;
    public bool enableInstanceShadows = true;
    public bool enableOcclusionCulling = true;
    public bool enableDetailCulling = true;
    public bool enableLOD = true;
    public bool enableOnlyLOD02Shadows = true;
    [Range(00.00f, 00.02f)] public float detailCullingPercentage = 0.005f;  //百分比

    //Debug 变量
    [Header("Debug")]
    public bool debugShowUI;
    public bool debugDrawLOD;
    public bool debugDrawBoundsInSceneView;
    public bool debugDrawHiZ;
    [Range(0, 10)] public int debugHiZLOD;
    public GameObject debugUIPrefab;

    [Header("Data")]
    [ReadOnly] public List<IndirectInstanceCSInput> instancesInputData = new List<IndirectInstanceCSInput>();
    [ReadOnly] public IndirectRenderingMesh[] indirectMeshes;

    [Header("Logging")]
    public bool logInstanceDrawMatrices = false;
    public bool logArgumentsAfterReset = false;
    public bool logSortingData = false;
    public bool logInstancesIsVisibleBuffer = false;
    public bool logScannedPreicates = false;
    public bool logGroupSumArrayBuffer = false;
    public bool logScannedGroupSumsBuffer = false;
    public bool logArgsBufferAfterCopy = false;
    public bool logCulledInstancesDrawMatrices = false;

    [Header("References")]
    public ComputeShader createDrawDataBufferCS;
    public ComputeShader sortingCS;
    public ComputeShader occlusionCS;
    public ComputeShader scanInstancesCS;
    public ComputeShader scanGroupSumsCS;
    public ComputeShader copyInstanceDataCS;
    public HiZBuffer hiZBuffer;
    public Camera mainCamera;
    public Camera debugCamera;

    //Compute Buffers
    private ComputeBuffer m_instancesIsVisibleBuffer;
    private ComputeBuffer m_instancesGroupSumArrayBuffer;
    //Scan
    private ComputeBuffer m_instancesScannedGroupSumBuffer;
    private ComputeBuffer m_instancesScannedPreicates;
    private ComputeBuffer m_instanceDataBuffer;
    //Sort Compute Buffer
    private ComputeBuffer m_instancesSortingData;
    private ComputeBuffer m_instancesSortingDataTemp;
    //矩阵
    private ComputeBuffer m_instancesMatrixRows01;
    private ComputeBuffer m_instancesMatrixRows23;
    private ComputeBuffer m_instancesMatrixRows45;
    //Cull 矩阵
    private ComputeBuffer m_instancesCulledMatrixRow01;
    private ComputeBuffer m_instancesCulledMatrixRows23;
    private ComputeBuffer m_instancesCulledMatrixRows45;
    //Args Buffer
    private ComputeBuffer m_instancesArgsBuffer;
    //Shadow Args
    private ComputeBuffer m_shadowArgsBuffer;
    private ComputeBuffer m_shadowsIsVisibleBuffer;
    //分组 
    private ComputeBuffer m_shadowGroupSumArrayBuffer;
    private ComputeBuffer m_shadowsScannedGroupSumBuffer;
    //Predicates 判断
    private ComputeBuffer m_shadowScannedInstancePredicates;
    //shadow Culled
    private ComputeBuffer m_shadowCulledMatrixRows01;
    private ComputeBuffer m_shadowCulledMatrixRows23;
    private ComputeBuffer m_shadowCulledMatrixRows45;

    //Command Buffer
    private CommandBuffer m_sortingCommandBuffer;

    //Kernel ID s  Compute Shader
    private int m_createDrawDataBufferKernelID;
    #endregion

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
