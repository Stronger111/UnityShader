using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;
using UnityEngine.UI;

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
public struct SortingData
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
    public bool drawInstanceShadows = true;
    public bool enableFrustumCulling = true;
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
    public bool logArgumentsAfterOcclusion = false;
    public bool logInstancesIsVisibleBuffer = false;
    public bool logScannedPredicates = false;
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
    private ComputeBuffer m_instancesScannedPredicates;
    private ComputeBuffer m_instanceDataBuffer;
    //Sort Compute Buffer
    private ComputeBuffer m_instancesSortingData;
    private ComputeBuffer m_instancesSortingDataTemp;
    //矩阵
    private ComputeBuffer m_instancesMatrixRows01;
    private ComputeBuffer m_instancesMatrixRows23;
    private ComputeBuffer m_instancesMatrixRows45;
    //Cull 矩阵
    private ComputeBuffer m_instancesCulledMatrixRows01;
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
    private int m_sortingCSKernelID;
    private int m_sortingTransposeKernelID;
    private int m_occlusionKernelID;
    private int m_scanInstancesKernelID;
    private int m_scanGroupSumsKernelID;
    private int m_copyInstanceDataKernelID;
    private bool m_isInitialized;

    // Other
    private int m_numberOfInstanceTypes;
    private int m_numberOfInstances;
    private int m_occlusionGroupX;
    private int m_scanInstancesGroupX;
    private int m_scanThreadGroupsGroupX;
    private int m_copyInstanceDataGroupX;

    private bool m_debugLastDrawLOD = false;
    private bool m_isEnabled;
    private uint[] m_args;
    private Bounds m_bounds;
    private Vector3 m_camPosition = Vector3.one;
    private Vector3 m_lastCamPosition = Vector3.zero;
    private Matrix4x4 m_MVP;

    // Debug
    private AsyncGPUReadbackRequest m_debugGPUArgsRequest;
    private AsyncGPUReadbackRequest m_debugGPUShadowArgsRequest;
    private StringBuilder m_debugUIText = new StringBuilder(1000);
    private Text m_uiText;
    private GameObject m_uiObj;

    // Constants
    private const int NUMBER_OF_DRAW_CALLS = 3; // (LOD00 + LOD01 + LOD02)
    private const int NUMBER_OF_ARGS_PER_DRAW = 5;// (indexCount, instanceCount, startIndex, baseVertex, startInstance)
    private const int NUMBER_OF_ARGS_PER_INSTANCE_TYPE = NUMBER_OF_DRAW_CALLS * NUMBER_OF_ARGS_PER_DRAW;// 3draws * 5args = 15args
    private const int ARGS_BYTE_SIZE_PER_DRAW_CALL = NUMBER_OF_ARGS_PER_DRAW * sizeof(uint); // 5args * 4bytes = 20 bytes
    private const int ARGS_BYTE_SIZE_PER_INSTANCE_TYPE = NUMBER_OF_ARGS_PER_INSTANCE_TYPE * sizeof(uint); // 15args * 4bytes = 60bytes
    //线程组数
    private const int SCAN_THREAD_GROUP_SIZE = 64;
    private const string DEBUG_UI_RED_COLOR = "<color=#ff6666>";
    private const string DEBUG_UI_WHITE_COLOR = "<color=#ffffff>";
    private const string DEBUG_SHADER_LOD_KEYWORD = "INDIRECT_DEBUG_LOD";

    // Shader Property ID's
    private static readonly int _Data = Shader.PropertyToID("_Data");
    private static readonly int _Input = Shader.PropertyToID("_Input");

    //bool Cull 是否启用对应的功能
    private static readonly int _ShouldFrustumCull = Shader.PropertyToID("_ShouldFrustumCull");
    private static readonly int _ShouldOcclusionCull = Shader.PropertyToID("_ShouldOcclusionCull");
    private static readonly int _ShouldLOD = Shader.PropertyToID("_ShouldLOD");
    private static readonly int _ShouldDetailCull = Shader.PropertyToID("_ShouldDetailCull");
    private static readonly int _ShouldOnlyUseLOD02Shadows = Shader.PropertyToID("_ShouldOnlyUseLOD02Shadows");

    private static readonly int _UNITY_MATRIX_MVP = Shader.PropertyToID("_UNITY_MATRIX_MVP");
    private static readonly int _CamPosition = Shader.PropertyToID("_CamPosition");
    private static readonly int _HiZTextureSize = Shader.PropertyToID("_HiZTextureSize");
    private static readonly int _Level = Shader.PropertyToID("_Level");
    private static readonly int _LevelMask = Shader.PropertyToID("_LevelMask");

    private static readonly int _Width = Shader.PropertyToID("_Width");
    private static readonly int _Height = Shader.PropertyToID("_Height");
    private static readonly int _ShadowDistance = Shader.PropertyToID("_ShadowDistance");

    private static readonly int _DetailCullingScreenPercentage = Shader.PropertyToID("_DetailCullingScreenPercentage");
    private static readonly int _HiZMap = Shader.PropertyToID("_HiZMap");
    private static readonly int _NumOfGroups = Shader.PropertyToID("_NumOfGroups");
    private static readonly int _NumOfDrawcalls = Shader.PropertyToID("_NumOfDrawcalls");
    private static readonly int _ArgsOffset = Shader.PropertyToID("_ArgsOffset");

    private static readonly int _Positions = Shader.PropertyToID("_Position");
    private static readonly int _Scales = Shader.PropertyToID("_Scales");
    private static readonly int _Rotations = Shader.PropertyToID("_Rotation");

    private static readonly int _ArgsBuffer = Shader.PropertyToID("_ArgsBuffer");
    private static readonly int _ShadowArgsBuffer = Shader.PropertyToID("_ShadowArgsBuffer");

    private static readonly int _IsVisibleBuffer = Shader.PropertyToID("_IsVisibleBuffer");
    private static readonly int _ShadowIsVisibleBuffer = Shader.PropertyToID("_ShadowIsVisibleBuffer");

    private static readonly int _GroupSumArray = Shader.PropertyToID("_GroupSumArray");
    private static readonly int _ScannedInstancePredicates = Shader.PropertyToID("_ScannedInstancePredicates");

    private static readonly int _GroupSumArrayIn = Shader.PropertyToID("_GroupSumArrayIn");
    private static readonly int _GroupSumArrayOut = Shader.PropertyToID("_GroupSumArrayOut");

    private static readonly int _DrawcallDataOut = Shader.PropertyToID("_DrawcallDataOut");
    private static readonly int _SortingData = Shader.PropertyToID("_SortingData");

    private static readonly int _InstanceDataBuffer = Shader.PropertyToID("_InstanceDataBuffer");
    private static readonly int _InstancePredicatesIn = Shader.PropertyToID("_InstancePredicatesIn");

    private static readonly int _InstancesDrawMatrixRows01 = Shader.PropertyToID("_InstancesDrawMatrixRows01");
    private static readonly int _InstancesDrawMatrixRows23 = Shader.PropertyToID("_InstancesDrawMatrixRows23");
    private static readonly int _InstancesDrawMatrixRows45 = Shader.PropertyToID("_InstancesDrawMatrixRows45");

    private static readonly int _InstancesCulledMatrixRows01 = Shader.PropertyToID("_InstancesCulledMatrixRows01");
    private static readonly int _InstancesCulledMatrixRows23 = Shader.PropertyToID("_InstancesCulledMatrixRows23");
    private static readonly int _InstancesCulledMatrixRows45 = Shader.PropertyToID("_InstancesCulledMatrixRows45");
    #endregion

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        if (m_isEnabled)
        {
            UpdateDebug();
        }
    }
    /// <summary>
    /// 在剔除之前执行
    /// </summary>
    private void OnPreCull()
    {
        if (!m_isEnabled
          || indirectMeshes == null
          || indirectMeshes.Length == 0
          || hiZBuffer.Texture == null
          )
        {
            return;
        }

        UpdateDebug();

        if (runCompute)
        {
            Profiler.BeginSample("CalculateVisibleInstances()");
            CalculateVisibleInstances();
            Profiler.EndSample();
        }

        if (drawInstance)
        {
            Profiler.BeginSample("DrawInstances()");
            DrawInstances();
            Profiler.EndSample();
        }

        if (drawInstanceShadows)
        {
            Profiler.BeginSample("DrawInstanceShadows()");
            DrawInstanceShadows();
            Profiler.EndSample();
        }

        if(debugDrawHiZ)
        {
            Vector3 pos = transform.position;
            pos.y = debugCamera.transform.position.y;
            debugCamera.transform.position = pos;
            debugCamera.Render();
        }
    }

    private void OnDestroy()
    {
        ReleaseBuffers();
        if(debugDrawLOD)
        {
            for(int MeshIndex=0;MeshIndex<indirectMeshes.Length;MeshIndex++)
            {
                indirectMeshes[MeshIndex].material.DisableKeyword(DEBUG_SHADER_LOD_KEYWORD);
            }
        }
    }
    private void OnDrawGizmos()
    {
        if (!Application.isPlaying)
            return;

        if(debugDrawBoundsInSceneView)
        {
            Gizmos.color = new Color(1f,0.0f,0.0f,0.333f);
            for(int InputDataIndex=0;InputDataIndex<instancesInputData.Count; InputDataIndex++)
            {
                Gizmos.DrawWireCube(instancesInputData[InputDataIndex].boundsCenter, instancesInputData[InputDataIndex].boundsExtents*2f);
            }
        }
    }

    private void UpdateDebug()
    {

    }

    public void StartDrawing()
    {
        if(!m_isInitialized)
        {
            Debug.LogError("IndirectRenderer: Unable to start drawing because it's not initialized");
            return;
        }
        m_isEnabled = true;
    }

    public void StopDrawing(bool shouldReleaseBuffers = false)
    {
        m_isEnabled = false;
        if (shouldReleaseBuffers)
        {
            ReleaseBuffers();
            m_isInitialized = false;
            hiZBuffer.enabled = false;
        }
    }

    private void DrawInstances()
    {
        for(int MeshIndex=0;MeshIndex<indirectMeshes.Length;MeshIndex++)
        {
            int argsIndex = MeshIndex * ARGS_BYTE_SIZE_PER_INSTANCE_TYPE;
            IndirectRenderingMesh irm = indirectMeshes[MeshIndex];

            if(enableLOD)
            {
                Graphics.DrawMeshInstancedIndirect(irm.mesh,0,irm.material,m_bounds,m_instancesArgsBuffer, argsIndex+ ARGS_BYTE_SIZE_PER_DRAW_CALL*0,irm.lod00MatPropBlock, ShadowCastingMode.Off);
                Graphics.DrawMeshInstancedIndirect(irm.mesh, 0, irm.material, m_bounds, m_instancesArgsBuffer, argsIndex + ARGS_BYTE_SIZE_PER_DRAW_CALL * 1, irm.lod01MatPropBlock, ShadowCastingMode.Off);
            }
            Graphics.DrawMeshInstancedIndirect(irm.mesh, 0, irm.material, m_bounds, m_instancesArgsBuffer, argsIndex + ARGS_BYTE_SIZE_PER_DRAW_CALL * 2, irm.lod02MatPropBlock, ShadowCastingMode.Off);
        }
    }

    private void DrawInstanceShadows()
    {
        for (int i = 0; i < indirectMeshes.Length; i++)
        {
            int argsIndex = i * ARGS_BYTE_SIZE_PER_INSTANCE_TYPE;
            IndirectRenderingMesh irm = indirectMeshes[i];

            if (!enableOnlyLOD02Shadows)
            {
                Graphics.DrawMeshInstancedIndirect(irm.mesh, 0, irm.material, m_bounds, m_shadowArgsBuffer, argsIndex + ARGS_BYTE_SIZE_PER_DRAW_CALL * 0, irm.shadowLod00MatPropBlock, ShadowCastingMode.ShadowsOnly);
                Graphics.DrawMeshInstancedIndirect(irm.mesh, 0, irm.material, m_bounds, m_shadowArgsBuffer, argsIndex + ARGS_BYTE_SIZE_PER_DRAW_CALL * 1, irm.shadowLod01MatPropBlock, ShadowCastingMode.ShadowsOnly);
            }
            Graphics.DrawMeshInstancedIndirect(irm.mesh, 0, irm.material, m_bounds, m_shadowArgsBuffer, argsIndex + ARGS_BYTE_SIZE_PER_DRAW_CALL * 2, irm.shadowLod02MatPropBlock, ShadowCastingMode.ShadowsOnly);

        }
    }
    public void Initialize(ref IndirectInstanceData[] _instances)
    {
        if (!m_isInitialized)
        {
            InitializeRenderer(ref _instances);
        }
    }

    private bool InitializeRenderer(ref IndirectInstanceData[] _instances)
    {
        //查找Compute Shader Kernel 是否存在
        if (!TryGetKernels())
        {
            return false;
        }

        ReleaseBuffers();
        //输入数据
        instancesInputData.Clear();
        m_numberOfInstanceTypes = _instances.Length;
        m_numberOfInstances = 0;

        m_camPosition = mainCamera.transform.position;
        m_bounds.center = m_camPosition;
        m_bounds.extents = Vector3.one * 10000;

        hiZBuffer.enabled = true;
        hiZBuffer.InitializeTexture();
        //初始化IndirectMesh数量
        indirectMeshes = new IndirectRenderingMesh[m_numberOfInstanceTypes];
        m_args = new uint[m_numberOfInstanceTypes* NUMBER_OF_ARGS_PER_INSTANCE_TYPE];  
        m_args = new uint[m_numberOfInstanceTypes* NUMBER_OF_ARGS_PER_INSTANCE_TYPE];  //***15

        List<Vector3> positions = new List<Vector3>();
        List<Vector3> scales = new List<Vector3>();
        List<Vector3> rotations = new List<Vector3>();

        List<SortingData> sortingData = new List<SortingData>();

        for(int InstanceIndex=0;InstanceIndex< m_numberOfInstanceTypes; InstanceIndex++)
        {
            IndirectRenderingMesh irm = new IndirectRenderingMesh();
            IndirectInstanceData iid = _instances[InstanceIndex];

            // Initialize Mesh
            irm.numOfVerticesLod00 = (uint)iid.lod00Mesh.vertexCount;
            irm.numOfVerticesLod01 = (uint)iid.lod01Mesh.vertexCount;
            irm.numOfVerticesLod02 = (uint)iid.lod02Mesh.vertexCount;

            irm.numOfIndicesLod00 = iid.lod00Mesh.GetIndexCount(0);
            irm.numOfIndicesLod01 = iid.lod01Mesh.GetIndexCount(0);
            irm.numOfIndicesLod02 = iid.lod02Mesh.GetIndexCount(0);

            irm.mesh = new Mesh();
            irm.mesh.name = iid.prefab.name;
            irm.mesh.CombineMeshes(new CombineInstance[] {  new CombineInstance() { mesh = iid.lod00Mesh},
                    new CombineInstance() { mesh = iid.lod01Mesh},
                    new CombineInstance() { mesh = iid.lod02Mesh}},true,false,false);

            // Arguments 索引位置
            int argsIndex = InstanceIndex * NUMBER_OF_ARGS_PER_INSTANCE_TYPE;

            // Buffer with arguments has to have five integer numbers
            // LOD00
            m_args[argsIndex + 0] = irm.numOfIndicesLod00;                          // 0 - index count per instance, 
            m_args[argsIndex + 1] = 0;                                              // 1 - instance count
            m_args[argsIndex + 2] = 0;                                              // 2 - start index location
            m_args[argsIndex + 3] = 0;                                              // 3 - base vertex location
            m_args[argsIndex + 4] = 0;                                              // 4 - start instance location

            // LOD01
            m_args[argsIndex + 5] = irm.numOfIndicesLod01;                          // 0 - index count per instance, 
            m_args[argsIndex + 6] = 0;                                              // 1 - instance count
            m_args[argsIndex + 7] = m_args[argsIndex + 0] + m_args[argsIndex + 2];  // 2 - start index location
            m_args[argsIndex + 8] = 0;                                              // 3 - base vertex location
            m_args[argsIndex + 9] = 0;

            // LOD02
            m_args[argsIndex + 10] = irm.numOfIndicesLod02;                         // 0 - index count per instance, 
            m_args[argsIndex + 11] = 0;                                             // 1 - instance count
            m_args[argsIndex + 12] = m_args[argsIndex + 5] + m_args[argsIndex + 7]; // 2 - start index location
            m_args[argsIndex + 13] = 0;                                             // 3 - base vertex location
            m_args[argsIndex + 14] = 0;

            // Materials
            irm.material = iid.indirectMaterial;
            Bounds originalBounds = CalculateBounds(iid.prefab);

            // Add the instance data (positions, rotations, scaling, bounds...)
            for(int PositionIndex=0;PositionIndex<iid.positions.Length;PositionIndex++)
            {
                positions.Add(iid.positions[PositionIndex]);
                rotations.Add(iid.rotations[PositionIndex]);
                scales.Add(iid.scales[PositionIndex]);

                sortingData.Add(new SortingData() {
                    drawCallInstanceIndex = ((((uint)PositionIndex * NUMBER_OF_ARGS_PER_INSTANCE_TYPE) << 16) + ((uint)m_numberOfInstances)),
                    distanceToCam = Vector3.Distance(iid.positions[PositionIndex], m_camPosition)
                });

                // Calculate the renderer bounds
                Bounds b = new Bounds();
                b.center= iid.positions[PositionIndex];
                Vector3 s = originalBounds.size;
                s.Scale(iid.scales[PositionIndex]);
                b.size = s;

                instancesInputData.Add(new IndirectInstanceCSInput() { boundsCenter=b.center, boundsExtents =b.extents});

                m_numberOfInstances++;

            }
            // Add the data to the renderer list
            indirectMeshes[InstanceIndex] = irm;
        }

        int computeShaderInputSize = Marshal.SizeOf(typeof(IndirectInstanceCSInput));
        int computeShaderDrawMatrixSize = Marshal.SizeOf(typeof(Indirect2x2Matrix));
        int computeSortingDataSize = Marshal.SizeOf(typeof(SortingData));

        m_instancesArgsBuffer = new ComputeBuffer(m_numberOfInstanceTypes* NUMBER_OF_ARGS_PER_INSTANCE_TYPE, sizeof(uint), ComputeBufferType.IndirectArguments);
        m_instanceDataBuffer = new ComputeBuffer(m_numberOfInstances, computeShaderInputSize, ComputeBufferType.Default);
        m_instancesSortingData = new ComputeBuffer(m_numberOfInstances, computeSortingDataSize, ComputeBufferType.Default);
        m_instancesSortingDataTemp = new ComputeBuffer(m_numberOfInstances, computeSortingDataSize, ComputeBufferType.Default);

        m_instancesMatrixRows01 = new ComputeBuffer(m_numberOfInstances, computeShaderDrawMatrixSize, ComputeBufferType.Default);
        m_instancesMatrixRows23 = new ComputeBuffer(m_numberOfInstances, computeShaderDrawMatrixSize, ComputeBufferType.Default);
        m_instancesMatrixRows45 = new ComputeBuffer(m_numberOfInstances, computeShaderDrawMatrixSize, ComputeBufferType.Default);
        m_instancesCulledMatrixRows01 = new ComputeBuffer(m_numberOfInstances, computeShaderDrawMatrixSize, ComputeBufferType.Default);
        m_instancesCulledMatrixRows23 = new ComputeBuffer(m_numberOfInstances, computeShaderDrawMatrixSize, ComputeBufferType.Default);
        m_instancesCulledMatrixRows45 = new ComputeBuffer(m_numberOfInstances, computeShaderDrawMatrixSize, ComputeBufferType.Default);

        m_instancesIsVisibleBuffer = new ComputeBuffer(m_numberOfInstances, sizeof(uint), ComputeBufferType.Default);
        m_instancesScannedPredicates = new ComputeBuffer(m_numberOfInstances, sizeof(uint), ComputeBufferType.Default);
        m_instancesGroupSumArrayBuffer = new ComputeBuffer(m_numberOfInstances, sizeof(uint), ComputeBufferType.Default);
        m_instancesScannedGroupSumBuffer = new ComputeBuffer(m_numberOfInstances, sizeof(uint), ComputeBufferType.Default);

        m_shadowArgsBuffer = new ComputeBuffer(m_numberOfInstanceTypes * NUMBER_OF_ARGS_PER_INSTANCE_TYPE, sizeof(uint), ComputeBufferType.IndirectArguments);
        m_shadowCulledMatrixRows01 = new ComputeBuffer(m_numberOfInstances, computeShaderDrawMatrixSize, ComputeBufferType.Default);
        m_shadowCulledMatrixRows23 = new ComputeBuffer(m_numberOfInstances, computeShaderDrawMatrixSize, ComputeBufferType.Default);
        m_shadowCulledMatrixRows45 = new ComputeBuffer(m_numberOfInstances, computeShaderDrawMatrixSize, ComputeBufferType.Default);
        m_shadowsIsVisibleBuffer = new ComputeBuffer(m_numberOfInstances, sizeof(uint), ComputeBufferType.Default);
        m_shadowScannedInstancePredicates = new ComputeBuffer(m_numberOfInstances, sizeof(uint), ComputeBufferType.Default);
        m_shadowGroupSumArrayBuffer = new ComputeBuffer(m_numberOfInstances, sizeof(uint), ComputeBufferType.Default);
        m_shadowsScannedGroupSumBuffer = new ComputeBuffer(m_numberOfInstances, sizeof(uint), ComputeBufferType.Default);

        m_instancesArgsBuffer.SetData(m_args);
        m_shadowArgsBuffer.SetData(m_args);
        m_instancesSortingData.SetData(sortingData);
        m_instancesSortingDataTemp.SetData(sortingData);

        // Setup the Material Property blocks for our meshes...
        int _Whatever = Shader.PropertyToID("_Whatever");
        int _DebugLODEnabled = Shader.PropertyToID("_DebugLODEnabled");
        for(int MeshIndex=0;MeshIndex< indirectMeshes.Length; MeshIndex++)
        {
            IndirectRenderingMesh irm = indirectMeshes[MeshIndex];
            int argsIndex = MeshIndex * NUMBER_OF_ARGS_PER_INSTANCE_TYPE;

            irm.lod00MatPropBlock = new MaterialPropertyBlock();
            irm.lod01MatPropBlock = new MaterialPropertyBlock();
            irm.lod02MatPropBlock = new MaterialPropertyBlock();
            irm.shadowLod00MatPropBlock = new MaterialPropertyBlock();
            irm.shadowLod01MatPropBlock = new MaterialPropertyBlock();
            irm.shadowLod02MatPropBlock = new MaterialPropertyBlock();

            irm.lod00MatPropBlock.SetInt(_ArgsOffset, argsIndex + 4);
            irm.lod01MatPropBlock.SetInt(_ArgsOffset, argsIndex + 9);
            irm.lod02MatPropBlock.SetInt(_ArgsOffset, argsIndex + 14);

            irm.shadowLod00MatPropBlock.SetInt(_ArgsOffset, argsIndex + 4);
            irm.shadowLod01MatPropBlock.SetInt(_ArgsOffset, argsIndex + 9);
            irm.shadowLod02MatPropBlock.SetInt(_ArgsOffset, argsIndex + 14);
            //传入 _ArgsBuffer
            irm.lod00MatPropBlock.SetBuffer(_ArgsBuffer, m_instancesArgsBuffer);
            irm.lod01MatPropBlock.SetBuffer(_ArgsBuffer, m_instancesArgsBuffer);
            irm.lod02MatPropBlock.SetBuffer(_ArgsBuffer, m_instancesArgsBuffer);

            irm.shadowLod00MatPropBlock.SetBuffer(_ArgsBuffer, m_shadowArgsBuffer);
            irm.shadowLod01MatPropBlock.SetBuffer(_ArgsBuffer, m_shadowArgsBuffer);
            irm.shadowLod02MatPropBlock.SetBuffer(_ArgsBuffer, m_shadowArgsBuffer);
            //Noraml 正常的
            irm.lod00MatPropBlock.SetBuffer(_InstancesDrawMatrixRows01, m_instancesCulledMatrixRows01);
            irm.lod01MatPropBlock.SetBuffer(_InstancesDrawMatrixRows01, m_instancesCulledMatrixRows01);
            irm.lod02MatPropBlock.SetBuffer(_InstancesDrawMatrixRows01, m_instancesCulledMatrixRows01);

            irm.lod00MatPropBlock.SetBuffer(_InstancesDrawMatrixRows23, m_instancesCulledMatrixRows23);
            irm.lod01MatPropBlock.SetBuffer(_InstancesDrawMatrixRows23, m_instancesCulledMatrixRows23);
            irm.lod02MatPropBlock.SetBuffer(_InstancesDrawMatrixRows23, m_instancesCulledMatrixRows23);

            irm.lod00MatPropBlock.SetBuffer(_InstancesDrawMatrixRows45, m_instancesCulledMatrixRows45);
            irm.lod01MatPropBlock.SetBuffer(_InstancesDrawMatrixRows45, m_instancesCulledMatrixRows45);
            irm.lod02MatPropBlock.SetBuffer(_InstancesDrawMatrixRows45, m_instancesCulledMatrixRows45);
            // shadow  阴影
            irm.shadowLod00MatPropBlock.SetBuffer(_InstancesDrawMatrixRows01, m_shadowCulledMatrixRows01);
            irm.shadowLod01MatPropBlock.SetBuffer(_InstancesDrawMatrixRows01, m_shadowCulledMatrixRows01);
            irm.shadowLod02MatPropBlock.SetBuffer(_InstancesDrawMatrixRows01, m_shadowCulledMatrixRows01);

            irm.shadowLod00MatPropBlock.SetBuffer(_InstancesDrawMatrixRows23, m_shadowCulledMatrixRows23);
            irm.shadowLod01MatPropBlock.SetBuffer(_InstancesDrawMatrixRows23, m_shadowCulledMatrixRows23);
            irm.shadowLod02MatPropBlock.SetBuffer(_InstancesDrawMatrixRows23, m_shadowCulledMatrixRows23);

            irm.shadowLod00MatPropBlock.SetBuffer(_InstancesDrawMatrixRows45, m_shadowCulledMatrixRows45);
            irm.shadowLod01MatPropBlock.SetBuffer(_InstancesDrawMatrixRows45, m_shadowCulledMatrixRows45);
            irm.shadowLod02MatPropBlock.SetBuffer(_InstancesDrawMatrixRows45, m_shadowCulledMatrixRows45);

        }
        //-----------------------------------
        // InitializeDrawData
        //-----------------------------------
        // Create the buffer containing draw data for all instances
        ComputeBuffer positionsBuffer = new ComputeBuffer(m_numberOfInstances,Marshal.SizeOf(typeof(Vector3)),ComputeBufferType.Default);
        ComputeBuffer scaleBuffer = new ComputeBuffer(m_numberOfInstances, Marshal.SizeOf(typeof(Vector3)), ComputeBufferType.Default);
        ComputeBuffer rotationBuffer = new ComputeBuffer(m_numberOfInstances, Marshal.SizeOf(typeof(Vector3)), ComputeBufferType.Default);
        //设置数据
        positionsBuffer.SetData(positions);
        scaleBuffer.SetData(scales);
        rotationBuffer.SetData(rotations);

        createDrawDataBufferCS.SetBuffer(m_createDrawDataBufferKernelID,_Positions,positionsBuffer);
        createDrawDataBufferCS.SetBuffer(m_createDrawDataBufferKernelID, _Scales, scaleBuffer);
        createDrawDataBufferCS.SetBuffer(m_createDrawDataBufferKernelID, _Rotations, rotationBuffer);
        createDrawDataBufferCS.SetBuffer(m_createDrawDataBufferKernelID, _InstancesDrawMatrixRows01, m_instancesMatrixRows01);
        createDrawDataBufferCS.SetBuffer(m_createDrawDataBufferKernelID, _InstancesDrawMatrixRows23, m_instancesMatrixRows23);
        createDrawDataBufferCS.SetBuffer(m_createDrawDataBufferKernelID, _InstancesDrawMatrixRows45, m_instancesMatrixRows45);

        int groupX = Mathf.Max(1, m_numberOfInstances/(2*SCAN_THREAD_GROUP_SIZE));
        createDrawDataBufferCS.Dispatch(m_createDrawDataBufferKernelID, groupX,1,1);

        ReleaseComputeBuffer(ref positionsBuffer);
        ReleaseComputeBuffer(ref scaleBuffer);
        ReleaseComputeBuffer(ref rotationBuffer);
        //-----------------------------------
        // InitConstantComputeVariables
        //-----------------------------------
        m_occlusionGroupX = Mathf.Max(1, m_numberOfInstances/64);
        m_scanInstancesGroupX = Mathf.Max(1, m_numberOfInstances / (2 * SCAN_THREAD_GROUP_SIZE));
        m_scanThreadGroupsGroupX = 1;
        m_copyInstanceDataGroupX = Mathf.Max(1, m_numberOfInstances / (2 * SCAN_THREAD_GROUP_SIZE));

        occlusionCS.SetInt(_ShouldFrustumCull, enableFrustumCulling ? 1 : 0);
        occlusionCS.SetInt(_ShouldOcclusionCull, enableOcclusionCulling ? 1 : 0);
        occlusionCS.SetInt(_ShouldDetailCull, enableDetailCulling ? 1 : 0);
        occlusionCS.SetInt(_ShouldLOD, enableLOD ? 1 : 0);
        occlusionCS.SetInt(_ShouldOnlyUseLOD02Shadows, enableOnlyLOD02Shadows ? 1 : 0);
        //阴影距离
        occlusionCS.SetFloat(_ShadowDistance, QualitySettings.shadowDistance);
        //细节百分比
        occlusionCS.SetFloat(_DetailCullingScreenPercentage, detailCullingPercentage);
        //Hi-Z Texture Size
        occlusionCS.SetVector(_HiZTextureSize, hiZBuffer.TextureSize);

        occlusionCS.SetBuffer(m_occlusionKernelID, _InstanceDataBuffer, m_instanceDataBuffer);
        occlusionCS.SetBuffer(m_occlusionKernelID, _ArgsBuffer, m_instancesArgsBuffer);
        occlusionCS.SetBuffer(m_occlusionKernelID, _ShadowArgsBuffer, m_shadowArgsBuffer);
        occlusionCS.SetBuffer(m_occlusionKernelID, _IsVisibleBuffer, m_instancesIsVisibleBuffer);
        occlusionCS.SetBuffer(m_occlusionKernelID, _ShadowIsVisibleBuffer, m_shadowsIsVisibleBuffer);
        occlusionCS.SetTexture(m_occlusionKernelID, _HiZMap, hiZBuffer.Texture);
        occlusionCS.SetBuffer(m_occlusionKernelID, _SortingData, m_instancesSortingData);

        scanGroupSumsCS.SetInt(_NumOfGroups, m_numberOfInstances / (2 * SCAN_THREAD_GROUP_SIZE));

        copyInstanceDataCS.SetInt(_NumOfDrawcalls, m_numberOfInstanceTypes * NUMBER_OF_DRAW_CALLS);
        copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _InstanceDataBuffer, m_instanceDataBuffer);
        copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _InstancesDrawMatrixRows01, m_instancesMatrixRows01);
        copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _InstancesDrawMatrixRows23, m_instancesMatrixRows23);
        copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _InstancesDrawMatrixRows45, m_instancesMatrixRows45);
        copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _SortingData, m_instancesSortingData);
        //排序 Sort Buffer
        CreateCommandBuffers();
        return true;
    }

    private void CreateCommandBuffers()
    {
        CreateSortingCommandBuffer();
    }

    private void CreateSortingCommandBuffer()
    {
        uint BITONIC_BLOCK_SIZE = 256;
        uint TRANSPOSE_BLOCK_SIZE = 8;

        // Determine parameters
        uint NUM_ELEMENTS = (uint)m_numberOfInstances;
        uint MATRIX_WIDTH = BITONIC_BLOCK_SIZE;
        uint MATRIX_HEIGHT = NUM_ELEMENTS / BITONIC_BLOCK_SIZE;

        m_sortingCommandBuffer = new CommandBuffer { name = "AsyncGPUSorting" };

        // Sort the data
        // First sort the rows for the levels <= to the block size
        for (uint level = 2; level < BITONIC_BLOCK_SIZE; level <<= 1)
        {
            SetGPUSortConstants(ref m_sortingCommandBuffer, ref sortingCS, ref level, ref level, ref MATRIX_HEIGHT, ref MATRIX_WIDTH);

            // Sort the row data
            m_sortingCommandBuffer.SetComputeBufferParam(sortingCS, m_sortingCSKernelID, _Data, m_instancesSortingData);
            m_sortingCommandBuffer.DispatchCompute(sortingCS, m_sortingCSKernelID, (int)(NUM_ELEMENTS / BITONIC_BLOCK_SIZE), 1, 1);
        }
        // Then sort the rows and columns for the levels > than the block size
        // Transpose. Sort the Columns. Transpose. Sort the Rows.
        for (uint level = (BITONIC_BLOCK_SIZE << 1); level <= NUM_ELEMENTS; level <<= 1)
        {
            // Transpose the data from buffer 1 into buffer 2
            uint l = (level/ BITONIC_BLOCK_SIZE);
            uint lm = (level & ~NUM_ELEMENTS) / BITONIC_BLOCK_SIZE;
            SetGPUSortConstants(ref m_sortingCommandBuffer, ref sortingCS, ref l, ref lm, ref MATRIX_WIDTH, ref MATRIX_HEIGHT);
            m_sortingCommandBuffer.SetComputeBufferParam(sortingCS, m_sortingTransposeKernelID, _Input, m_instancesSortingData);
            m_sortingCommandBuffer.SetComputeBufferParam(sortingCS, m_sortingTransposeKernelID, _Data, m_instancesSortingDataTemp);
            m_sortingCommandBuffer.DispatchCompute(sortingCS, m_sortingTransposeKernelID, (int)(MATRIX_WIDTH / TRANSPOSE_BLOCK_SIZE), (int)(MATRIX_HEIGHT / TRANSPOSE_BLOCK_SIZE), 1);

            // Sort the transposed column data
            m_sortingCommandBuffer.SetComputeBufferParam(sortingCS, m_sortingCSKernelID, _Data, m_instancesSortingDataTemp);
            m_sortingCommandBuffer.DispatchCompute(sortingCS, m_sortingCSKernelID, (int)(NUM_ELEMENTS / BITONIC_BLOCK_SIZE), 1, 1);


            // Transpose the data from buffer 2 back into buffer 1
            SetGPUSortConstants(ref m_sortingCommandBuffer, ref sortingCS, ref BITONIC_BLOCK_SIZE, ref level, ref MATRIX_HEIGHT, ref MATRIX_WIDTH);
            m_sortingCommandBuffer.SetComputeBufferParam(sortingCS, m_sortingTransposeKernelID, _Input, m_instancesSortingDataTemp);
            m_sortingCommandBuffer.SetComputeBufferParam(sortingCS, m_sortingTransposeKernelID, _Data, m_instancesSortingData);
            m_sortingCommandBuffer.DispatchCompute(sortingCS, m_sortingTransposeKernelID, (int)(MATRIX_HEIGHT / TRANSPOSE_BLOCK_SIZE), (int)(MATRIX_WIDTH / TRANSPOSE_BLOCK_SIZE), 1);

            // Sort the row data
            m_sortingCommandBuffer.SetComputeBufferParam(sortingCS, m_sortingCSKernelID, _Data, m_instancesSortingData);
            m_sortingCommandBuffer.DispatchCompute(sortingCS, m_sortingCSKernelID, (int)(NUM_ELEMENTS / BITONIC_BLOCK_SIZE), 1, 1);
        }
    }
    private void SetGPUSortConstants(ref CommandBuffer commandBuffer,ref ComputeShader cs,ref uint level,ref uint levelMask,ref uint width,ref uint height)
    {
        commandBuffer.SetComputeIntParam(cs, _Level, (int)level);
        commandBuffer.SetComputeIntParam(cs, _LevelMask, (int)levelMask);
        commandBuffer.SetComputeIntParam(cs, _Width, (int)width);
        commandBuffer.SetComputeIntParam(cs, _Height, (int)height);
    }
    private Bounds CalculateBounds(GameObject _prefab)
    {
        GameObject obj = Instantiate(_prefab);
        obj.transform.position = Vector3.zero;
        obj.transform.rotation = Quaternion.Euler(Vector3.zero);
        obj.transform.localScale = Vector3.one;

        Renderer[] rends = obj.GetComponentsInChildren<Renderer>();
        Bounds b = new Bounds();
        if(rends.Length>0)
        {
            b = new Bounds(rends[0].bounds.center, rends[0].bounds.size);
            for(int r = 1; r < rends.Length; r++)
            {
                b.Encapsulate(rends[r].bounds);
            }
        }
        b.center = Vector3.zero;
        DestroyImmediate(obj);
        return b;
    }

    private bool TryGetKernels()
    {
        return TryGetKernel("CSMain", ref createDrawDataBufferCS, ref m_createDrawDataBufferKernelID)
            && TryGetKernel("BitonicSort", ref sortingCS, ref m_sortingCSKernelID)
            && TryGetKernel("MatrixTranspose", ref sortingCS, ref m_sortingTransposeKernelID)
            && TryGetKernel("CSMain", ref occlusionCS, ref m_occlusionKernelID)
            && TryGetKernel("CSMain", ref scanInstancesCS, ref m_scanInstancesKernelID)
            && TryGetKernel("CSMain", ref scanGroupSumsCS, ref m_scanGroupSumsKernelID)
            && TryGetKernel("CSMain", ref copyInstanceDataCS, ref m_copyInstanceDataKernelID)
        ;
    }


    private static bool TryGetKernel(string kernelName, ref ComputeShader cs, ref int kernelID)
    {
        if (!cs.HasKernel(kernelName))
        {
            Debug.LogError(kernelName + " kernel not found in " + cs.name + "!");
            return false;
        }

        cs.FindKernel(kernelName);
        return true;
    }
    private void CalculateVisibleInstances()
    {
        // Global data
        m_camPosition = mainCamera.transform.position;
        //包围盒中心是摄像机位置
        m_bounds.center = m_camPosition;

        Matrix4x4 v = mainCamera.worldToCameraMatrix;
        Matrix4x4 p = mainCamera.projectionMatrix;

        m_MVP = p * v;

        if (logInstanceDrawMatrices)
        {
            logInstanceDrawMatrices = false;
            LogInstanceDrawMatrices("LogInstanceDrawMatrices()");
        }

        //////////////////////////////////////////////////////
        // Reset the arguments buffer
        //////////////////////////////////////////////////////
        Profiler.BeginSample("Resetting args buffer");
        {
            m_instancesArgsBuffer.SetData(m_args);
            m_shadowArgsBuffer.SetData(m_args);

            if (logArgumentsAfterReset)
            {
                logArgumentsAfterReset = false;
                LogArgsBuffers("LogArgsBuffers() - Instances After Reset", "LogArgsBuffers() - Shadows After Reset");
            }
        }
        Profiler.EndSample();

        //////////////////////////////////////////////////////
        // Set up compute shader to perform the occlusion culling
        //////////////////////////////////////////////////////
        Profiler.BeginSample("02 Occlusion");
        {
            // Input
            occlusionCS.SetFloat(_ShadowDistance, QualitySettings.shadowDistance);
            occlusionCS.SetMatrix(_UNITY_MATRIX_MVP, m_MVP);
            occlusionCS.SetVector(_CamPosition, m_camPosition);

            // Dispatch
            occlusionCS.Dispatch(m_occlusionKernelID, m_occlusionGroupX, 1, 1);

            if (logArgumentsAfterOcclusion)
            {
                logArgumentsAfterOcclusion = false;
                LogArgsBuffers("LogArgsBuffers() - Instances After Occlusion", "LogArgsBuffers() - Shadows After Occlusion");
            }

            if (logInstancesIsVisibleBuffer)
            {
                logInstancesIsVisibleBuffer = false;
                LogInstancesIsVisibleBuffers("LogInstancesIsVisibleBuffers() - Instances", "LogInstancesIsVisibleBuffers() - Shadows");
            }
        }
        Profiler.EndSample();

        //////////////////////////////////////////////////////
        // Perform scan of instance predicates
        //////////////////////////////////////////////////////
        Profiler.BeginSample("03 Scan Instances");
        {
            //Normal
            scanInstancesCS.SetBuffer(m_scanInstancesKernelID, _InstancePredicatesIn, m_instancesIsVisibleBuffer);
            scanInstancesCS.SetBuffer(m_scanInstancesKernelID, _GroupSumArray, m_instancesGroupSumArrayBuffer);
            scanInstancesCS.SetBuffer(m_scanInstancesKernelID, _ScannedInstancePredicates, m_instancesScannedPredicates);
            scanInstancesCS.Dispatch(m_scanInstancesKernelID, m_scanInstancesGroupX, 1, 1);

            // Shadows
            scanInstancesCS.SetBuffer(m_scanInstancesKernelID, _InstancePredicatesIn, m_shadowsIsVisibleBuffer);
            scanInstancesCS.SetBuffer(m_scanInstancesKernelID, _GroupSumArray, m_shadowGroupSumArrayBuffer);
            scanInstancesCS.SetBuffer(m_scanInstancesKernelID, _ScannedInstancePredicates, m_shadowScannedInstancePredicates);
            scanInstancesCS.Dispatch(m_scanInstancesKernelID, m_scanInstancesGroupX, 1, 1);


            if (logGroupSumArrayBuffer)
            {
                logGroupSumArrayBuffer = false;
                LogGroupSumArrayBuffer("LogGroupSumArrayBuffer() - Instances", "LogGroupSumArrayBuffer() - Shadows");
            }

            if (logScannedPredicates)
            {
                logScannedPredicates = false;
                LogScannedPredicates("LogScannedPredicates() - Instances", "LogScannedPredicates() - Shadows");
            }
        }
        Profiler.EndSample();

        //////////////////////////////////////////////////////
        // Perform scan of group sums
        //////////////////////////////////////////////////////
        Profiler.BeginSample("Scan Thread Groups");
        {
            // Normal
            scanGroupSumsCS.SetBuffer(m_scanGroupSumsKernelID, _GroupSumArrayIn, m_instancesGroupSumArrayBuffer);
            scanGroupSumsCS.SetBuffer(m_scanGroupSumsKernelID, _GroupSumArrayOut, m_instancesScannedGroupSumBuffer);
            scanGroupSumsCS.Dispatch(m_scanGroupSumsKernelID, m_scanThreadGroupsGroupX, 1, 1);

            // Shadows
            scanGroupSumsCS.SetBuffer(m_scanGroupSumsKernelID, _GroupSumArrayIn, m_shadowGroupSumArrayBuffer);
            scanGroupSumsCS.SetBuffer(m_scanGroupSumsKernelID, _GroupSumArrayOut, m_shadowsScannedGroupSumBuffer);
            scanGroupSumsCS.Dispatch(m_scanGroupSumsKernelID, m_scanThreadGroupsGroupX, 1, 1);

            if (logScannedGroupSumsBuffer)
            {
                logScannedGroupSumsBuffer = false;
                LogScannedGroupSumBuffer("LogScannedGroupSumBuffer() - Instances", "LogScannedGroupSumBuffer() - Shadows");
            }
        }
        Profiler.EndSample();

        //////////////////////////////////////////////////////
        // Perform stream compaction 
        // Calculate instance offsets and store in drawcall arguments buffer
        //////////////////////////////////////////////////////
        Profiler.BeginSample("Copy Instance Data");
        {
            // Normal
            copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _InstancePredicatesIn, m_instancesIsVisibleBuffer);
            copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _GroupSumArray, m_instancesScannedGroupSumBuffer);
            copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _ScannedInstancePredicates, m_instancesScannedPredicates);
            copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _InstancesCulledMatrixRows01, m_instancesCulledMatrixRows01);
            copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _InstancesCulledMatrixRows23, m_instancesCulledMatrixRows23);
            copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _InstancesCulledMatrixRows45, m_instancesCulledMatrixRows45);
            copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _DrawcallDataOut, m_instancesArgsBuffer);
            copyInstanceDataCS.Dispatch(m_copyInstanceDataKernelID, m_copyInstanceDataGroupX, 1, 1);

            // Shadows
            copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _InstancePredicatesIn, m_shadowsIsVisibleBuffer);
            copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _GroupSumArray, m_shadowsScannedGroupSumBuffer);
            copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _ScannedInstancePredicates, m_shadowScannedInstancePredicates);
            copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _InstancesCulledMatrixRows01, m_shadowCulledMatrixRows01);
            copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _InstancesCulledMatrixRows23, m_shadowCulledMatrixRows23);
            copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _InstancesCulledMatrixRows45, m_shadowCulledMatrixRows45);
            copyInstanceDataCS.SetBuffer(m_copyInstanceDataKernelID, _DrawcallDataOut, m_shadowArgsBuffer);
            copyInstanceDataCS.Dispatch(m_copyInstanceDataKernelID, m_copyInstanceDataGroupX, 1, 1);

            if (logCulledInstancesDrawMatrices)
            {
                logCulledInstancesDrawMatrices = false;
                LogCulledInstancesDrawMatrices("LogCulledInstancesDrawMatrices() - Instances", "LogCulledInstancesDrawMatrices() - Shadows");
            }

            if (logArgsBufferAfterCopy)
            {
                logArgsBufferAfterCopy = false;
                LogArgsBuffers("LogArgsBuffers() - Instances After Copy", "LogArgsBuffers() - Shadows After Copy");
            }
        }
        Profiler.EndSample();

        //////////////////////////////////////////////////////
        // Sort the position buffer based on distance from camera
        //////////////////////////////////////////////////////
        Profiler.BeginSample("LOD Sorting");
        {
            m_lastCamPosition = m_camPosition;
            Graphics.ExecuteCommandBufferAsync(m_sortingCommandBuffer, ComputeQueueType.Background);
        }
        Profiler.EndSample();

        if (logSortingData)
        {
            logSortingData = false;
            LogSortingData("LogSortingData())");
        }
    }

    private void LogInstanceDrawMatrices(string prefix = "")
    {

    }

    private void LogArgsBuffers(string instancePrefix = "", string shadowPrefix = "")
    {

    }

    private void LogInstancesIsVisibleBuffers(string instancePrefix = "", string shadowPrefix = "")
    {

    }
    private void LogGroupSumArrayBuffer(string instancePrefix = "", string shadowPrefix = "")
    {
    }

    private void LogScannedPredicates(string instancePrefix = "", string shadowPrefix = "")
    {
    }
    private void LogScannedGroupSumBuffer(string instancePrefix = "", string shadowPrefix = "")
    {
    }
    private void LogCulledInstancesDrawMatrices(string instancePrefix = "", string shadowPrefix = "")
    {

    }

    private void LogSortingData(string prefix = "")
    {

    }

    private void ReleaseBuffers()
    {
        ReleaseCommandBuffer(ref m_sortingCommandBuffer);

        ReleaseComputeBuffer(ref m_instancesIsVisibleBuffer);
        ReleaseComputeBuffer(ref m_instancesGroupSumArrayBuffer);
        ReleaseComputeBuffer(ref m_instancesScannedGroupSumBuffer);
        ReleaseComputeBuffer(ref m_instancesScannedPredicates);
        ReleaseComputeBuffer(ref m_instanceDataBuffer);
        ReleaseComputeBuffer(ref m_instancesSortingData);
        ReleaseComputeBuffer(ref m_instancesSortingDataTemp);
        ReleaseComputeBuffer(ref m_instancesMatrixRows01);
        ReleaseComputeBuffer(ref m_instancesMatrixRows23);
        ReleaseComputeBuffer(ref m_instancesMatrixRows45);
        ReleaseComputeBuffer(ref m_instancesCulledMatrixRows01);
        ReleaseComputeBuffer(ref m_instancesCulledMatrixRows23);
        ReleaseComputeBuffer(ref m_instancesCulledMatrixRows45);
        ReleaseComputeBuffer(ref m_instancesArgsBuffer);

        ReleaseComputeBuffer(ref m_shadowArgsBuffer);
        ReleaseComputeBuffer(ref m_shadowsIsVisibleBuffer);
        ReleaseComputeBuffer(ref m_shadowGroupSumArrayBuffer);
        ReleaseComputeBuffer(ref m_shadowsScannedGroupSumBuffer);
        ReleaseComputeBuffer(ref m_shadowScannedInstancePredicates);
        ReleaseComputeBuffer(ref m_shadowCulledMatrixRows01);
        ReleaseComputeBuffer(ref m_shadowCulledMatrixRows23);
        ReleaseComputeBuffer(ref m_shadowCulledMatrixRows45);
    }

    private static void ReleaseComputeBuffer(ref ComputeBuffer _buffer)
    {
        if (_buffer == null)
        {
            return;
        }

        _buffer.Release();
        _buffer = null;
    }


    private static void ReleaseCommandBuffer(ref CommandBuffer _buffer)
    {
        if (_buffer == null)
            return;

        _buffer.Release();
        _buffer = null;
    }
}
