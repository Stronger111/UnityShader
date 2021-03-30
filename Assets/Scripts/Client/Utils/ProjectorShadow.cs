using UnityEngine;
using UnityEngine.Rendering;

public class ProjectorShadow : MonoBehaviour
{
    public float mProjectorSize = 23;

    public LayerMask mLayerCaster;

    public LayerMask mLayerIgnoreReceiver;

    private bool mUseCommandBuf = false;

    private Projector mProjector;

    private Camera mShadowCam;

    private RenderTexture mShadowRT;

    private CommandBuffer mCommandBuf;

    private Material mReplaceMat;

    #region 内置函数

    // Use this for initialization
    void Start()
    {
        // 创建render texture
        mShadowRT = new RenderTexture(2048, 2048, 0, RenderTextureFormat.R8);
        mShadowRT.name = "ShadowRT";
        mShadowRT.antiAliasing = 1;
        mShadowRT.filterMode = FilterMode.Bilinear;
        mShadowRT.wrapMode = TextureWrapMode.Clamp;

        //projector初始化
        mProjector = GetComponent<Projector>();
        mProjector.orthographic = true;
        mProjector.orthographicSize = mProjectorSize;
        mProjector.ignoreLayers = mLayerIgnoreReceiver;
        mProjector.material.SetTexture("_ShadowTex", mShadowRT);

        //camera初始化
        if (mShadowCam == null)
            mShadowCam = gameObject.AddComponent<Camera>();
        mShadowCam.clearFlags = CameraClearFlags.Color;
        mShadowCam.backgroundColor = Color.black;
        mShadowCam.orthographic = true;
        mShadowCam.orthographicSize = mProjectorSize;
        mShadowCam.depth = -100.0f;
        mShadowCam.nearClipPlane = mProjector.nearClipPlane;
        mShadowCam.farClipPlane = mProjector.farClipPlane;
        mShadowCam.targetTexture = mShadowRT;

        SwitchCommandBuffer();
    }

    /// <summary>
    /// 
    /// </summary>
    //private void OnEnable()
    //{
    //    mShadowRT = new RenderTexture(2048, 2048, 0, RenderTextureFormat.R8);
    //    mShadowRT.name = "ShadowRT";
    //    mShadowRT.antiAliasing = 1;
    //    mShadowRT.filterMode = FilterMode.Bilinear;
    //    mShadowRT.wrapMode = TextureWrapMode.Clamp;

    //    //projector初始化
    //    mProjector = GetComponent<Projector>();
    //    mProjector.orthographic = true;
    //    mProjector.orthographicSize = mProjectorSize;
    //    mProjector.ignoreLayers = mLayerIgnoreReceiver;
    //    mProjector.material.SetTexture("_ShadowTex", mShadowRT);

    //    //camera初始化
    //    if (mShadowCam == null)
    //        mShadowCam = gameObject.AddComponent<Camera>();
    //    mShadowCam.clearFlags = CameraClearFlags.Color;
    //    mShadowCam.backgroundColor = Color.black;
    //    mShadowCam.orthographic = true;
    //    mShadowCam.orthographicSize = mProjectorSize;
    //    mShadowCam.depth = -100.0f;
    //    mShadowCam.nearClipPlane = mProjector.nearClipPlane;
    //    mShadowCam.farClipPlane = mProjector.farClipPlane;
    //    mShadowCam.targetTexture = mShadowRT;

    //    SwitchCommandBuffer();
    //}

    // Update is called once per frame
    void Update()
    {
        // 测试Commander Buffer
        if (Input.GetKeyDown(KeyCode.Space))
        {
            mUseCommandBuf = !mUseCommandBuf;
            SwitchCommandBuffer();
        }

        // 填充Commander Buffer
        if (mUseCommandBuf)
        {
            FillCommandBuffer();
        }
    }

    #endregion

    #region 函数

    private void SwitchCommandBuffer()
    {
        Shader replaceshader = Shader.Find("ProjectorShadow/ShadowCaster");

        if (!mUseCommandBuf)
        {
            mShadowCam.cullingMask = mLayerCaster;
            //ProjectorShadow
            mShadowCam.SetReplacementShader(replaceshader, "ProjectShadow");
        }
        else
        {
            mShadowCam.cullingMask = 0;

            mShadowCam.RemoveAllCommandBuffers();
            if (mCommandBuf != null)
            {
                mCommandBuf.Dispose();
                mCommandBuf = null;
            }

            mCommandBuf = new CommandBuffer();
            mShadowCam.AddCommandBuffer(CameraEvent.BeforeImageEffectsOpaque, mCommandBuf);

            if (mReplaceMat == null)
            {
                mReplaceMat = new Material(replaceshader);
                mReplaceMat.hideFlags = HideFlags.HideAndDontSave;
            }
        }
    }

    private void FillCommandBuffer()
    {
        //mCommandBuf.Clear();

        //Plane[] camfrustum = GeometryUtility.CalculateFrustumPlanes(mShadowCam);

        //List<GameObject> listgo = UnitManager.Instance.UnitList;
        //foreach (var go in listgo)
        //{
        //    if (go == null)
        //        continue;

        //    Collider collider = go.GetComponentInChildren<Collider>();
        //    if (collider == null)
        //        continue;

        //    bool bound = GeometryUtility.TestPlanesAABB(camfrustum, collider.bounds);
        //    if (!bound)
        //        continue;

        //    Renderer[] renderlist = go.GetComponentsInChildren<Renderer>();
        //    if (renderlist.Length <= 0)
        //        continue;

        //    // 是否有可见的render
        //    // 有可见的则整个GameObject都渲染
        //    bool hasvis = false;
        //    foreach (var render in renderlist)
        //    {
        //        if (render == null)
        //            continue;

        //        RenderVis rendervis = render.GetComponent<RenderVis>();
        //        if (rendervis == null)
        //            continue;

        //        if (rendervis.IsVisible)
        //        {
        //            hasvis = true;
        //            break;
        //        }
        //    }

        //    foreach (var render in renderlist)
        //    {
        //        if (render == null)
        //            continue;

        //        mCommandBuf.DrawRenderer(render, mReplaceMat);
        //    }
        //}
    }

    #endregion
}
