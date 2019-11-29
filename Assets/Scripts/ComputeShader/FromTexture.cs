using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FromTexture : MonoBehaviour
{
    public Material Mat;

    public ComputeShader Shader;
    // Start is called before the first frame update
    void Start()
    {
        RunShader();
    }
    void RunShader()
    {
        RenderTexture rT = new RenderTexture(256,256,24);
        rT.enableRandomWrite = true;
        rT.Create();
        Mat.SetTexture("_MainTex", rT);

        int kernelHandle = Shader.FindKernel("CSMain");

        Shader.SetTexture(kernelHandle,"Result",rT);
        Shader.Dispatch(kernelHandle,256/8,256/8,1);
    }
    // Update is called once per frame
    void Update()
    {
      
    }
}
