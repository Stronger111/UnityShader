using System.Collections;
using System.Collections.Generic;
using UnityEngine;
/// <summary>
/// 深度纹理模拟运动模糊
/// </summary>
public class MotionBlurWithDepthTexture : PostEffectBase
{
    public Shader motionBlurShader;
    private Material motionBlurMaterial = null;
    public Material material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }
    [Range(0.0f, 1.0f)]
    public float blurSize = 0.5f;   //模糊图像的大小

    private Camera myCamera;
    public Camera CameraInScene
    {
        get
        {
            if (myCamera == null)
            {
                myCamera = GetComponent<Camera>();
            }
            return myCamera;
        }
    }
    private Matrix4x4 previousViewProjectionMatrix;    //保存上一帧摄像机的视角*投影矩阵

    private void OnEnable()    //摄像机状态
    {
        CameraInScene.depthTextureMode |= DepthTextureMode.Depth;
    }
    // Use this for initialization
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {

    }
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_BlurSize", blurSize);

            material.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);
            Matrix4x4 currentViewProjectionMatrix = CameraInScene.projectionMatrix * CameraInScene.worldToCameraMatrix;
            Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;  //逆矩阵
            material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);

            previousViewProjectionMatrix = currentViewProjectionMatrix;

            Graphics.Blit(source, destination, material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
