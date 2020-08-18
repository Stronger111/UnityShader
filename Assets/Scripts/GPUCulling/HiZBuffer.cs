using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[RequireComponent(typeof(Camera))]
public class HiZBuffer : MonoBehaviour
{
    #region Variables
    [Header("Reference")]
    //todo 这张RT作用
    public RenderTexture topDownView = null;
    public IndirectRenderer m_IndirectRenderer;
    public Camera mainCamera = null;
    public Light light = null;
    //Shader ?
    public Shader generateBufferShader = null;
    public Shader debugShader = null;

    // private
    private int m_LODCount = 0;
    private int[] m_Temporaries = null;
    //反射之后？
    private CameraEvent m_CameraEvent = CameraEvent.AfterReflections;
    /// <summary>
    /// 纹理大小
    /// </summary>
    private Vector2 m_textureSize;
    private Material m_generateBufferMaterial = null;
    private Material m_debugMaterial = null;
    /// <summary>
    /// HZB 深度图
    /// </summary>
    private RenderTexture m_HiZDepthTexture = null;
    private CommandBuffer m_CommandBuffer = null;
    private CameraEvent m_lastCameraEvent = CameraEvent.AfterReflections;
    private RenderTexture m_ShadowmapCopy = null;
    private RenderTargetIdentifier m_Shadowmap;
    private CommandBuffer m_lightShadowCommandBuffer;

    public Vector2 TextureSize { get { return m_textureSize; } }
    public RenderTexture Texture { get { return m_HiZDepthTexture; } }

    private const int MAXIMUM_BUFFER_SIZE = 1024;

    private enum Pass
    {
        Blit,
        Reduce
    }
    #endregion
    private void Awake()
    {
        m_generateBufferMaterial = new Material(generateBufferShader);
        m_debugMaterial = new Material(debugShader);
        mainCamera.depthTextureMode = DepthTextureMode.Depth;
    }
    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {

    }

    private void OnDisable()
    {
        if (mainCamera != null)
        {
            if (m_CommandBuffer != null)
            {
                mainCamera.RemoveCommandBuffer(m_CameraEvent, m_CommandBuffer);
                m_CommandBuffer = null;
            }
        }
        if (m_HiZDepthTexture != null)
        {
            m_HiZDepthTexture.Release();
            m_HiZDepthTexture = null;
        }
    }

    public void InitializeTexture()
    {
        if (m_HiZDepthTexture != null)
            m_HiZDepthTexture.Release();

        int size = Mathf.Max(mainCamera.pixelWidth, mainCamera.pixelHeight);
        size = Mathf.Min(Mathf.NextPowerOfTwo(size), MAXIMUM_BUFFER_SIZE);
        m_textureSize.x = size;
        m_textureSize.y = size;
        //深度是线性 的 
        m_HiZDepthTexture = new RenderTexture(size, size, 0, RenderTextureFormat.RGHalf, RenderTextureReadWrite.Linear);
        m_HiZDepthTexture.filterMode = FilterMode.Point;
        m_HiZDepthTexture.useMipMap = true;
        m_HiZDepthTexture.autoGenerateMips = false;
        bool isCreate = m_HiZDepthTexture.Create();
        if (isCreate)
            m_HiZDepthTexture.hideFlags = HideFlags.HideAndDontSave;
        else
            Debug.LogError(string.Format("创建m_HiZDepthTexture失败{0}", 33));
    }
    /// <summary>
    /// 在渲染场景之前进行调用
    /// </summary>
    private void OnPreRender()
    {
        int size = Mathf.Max(mainCamera.pixelWidth, mainCamera.pixelHeight);
        size = Mathf.Min(Mathf.NextPowerOfTwo(size), MAXIMUM_BUFFER_SIZE);
        m_textureSize.x = size;
        m_textureSize.y = size;

        m_LODCount = Mathf.FloorToInt(Mathf.Log(size, 2f));

        if (m_LODCount == 0)
            return;
       // else
            //Debug.Log(string.Format("LOD Count-----{0}", m_LODCount));

        bool isCommandBufferInvalid = false;
        if (m_HiZDepthTexture == null || (m_HiZDepthTexture.width != size || m_HiZDepthTexture.height != size) || m_lastCameraEvent != m_CameraEvent)
        {
            InitializeTexture();
            m_lastCameraEvent = m_CameraEvent;
            isCommandBufferInvalid = true;
        }

        if (m_CommandBuffer == null || isCommandBufferInvalid)
        {
            m_Temporaries = new int[m_LODCount];

            if (m_CommandBuffer != null)
                mainCamera.RemoveCommandBuffer(m_CameraEvent, m_CommandBuffer);

            m_CommandBuffer = new CommandBuffer();
            m_CommandBuffer.name = "Hi-Z Buffer";

            RenderTargetIdentifier RenderTargetID = new RenderTargetIdentifier(m_HiZDepthTexture);
            m_CommandBuffer.SetGlobalTexture("_LightTexture", m_ShadowmapCopy);
            m_CommandBuffer.Blit(null, RenderTargetID, m_generateBufferMaterial, (int)Pass.Blit);

            for (int LODIndex = 0; LODIndex < m_LODCount; LODIndex++)
            {
                m_Temporaries[LODIndex] = Shader.PropertyToID("_0965d57_Temporaries" + LODIndex.ToString());
                //除 2操作
                size >>= 1;
                size = Mathf.Max(size, 1);
                //
                m_CommandBuffer.GetTemporaryRT(m_Temporaries[LODIndex], size, size, 0, FilterMode.Point, RenderTextureFormat.RGHalf, RenderTextureReadWrite.Linear);

                if (LODIndex == 0)
                    m_CommandBuffer.Blit(RenderTargetID, m_Temporaries[0], m_generateBufferMaterial, (int)Pass.Reduce);
                else
                    m_CommandBuffer.Blit(m_Temporaries[LODIndex - 1], m_Temporaries[LODIndex], m_generateBufferMaterial, (int)Pass.Reduce);
                //到最后是RenderTargetID 是一张降采样的图
                m_CommandBuffer.CopyTexture(m_Temporaries[LODIndex], 0, 0, RenderTargetID, 0, LODIndex + 1);

                if (LODIndex >= 1)
                    m_CommandBuffer.ReleaseTemporaryRT(m_Temporaries[LODIndex - 1]);
            }

            m_CommandBuffer.ReleaseTemporaryRT(m_Temporaries[m_LODCount - 1]);
            mainCamera.AddCommandBuffer(m_CameraEvent, m_CommandBuffer);
        }
    }

    /// <summary>
    /// 在渲染完所有场景后进行调用
    /// </summary>
    /// <param name="source"></param>
    /// <param name="destination"></param>
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        //Debug
        //if()
        //{

        //}
        Graphics.Blit(source,destination);
    }
}
