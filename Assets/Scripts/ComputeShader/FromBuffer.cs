using System.Collections;
using System.Collections.Generic;
using UnityEngine;

struct PBuffer
{
    public float life;
    public Vector3 pos;
    public Vector3 scale;
    public Vector3 eulerAngle;
}
public class FromBuffer : MonoBehaviour
{
    public ComputeShader computeShader;
    public GameObject prefab;
    List<GameObject> pool = new List<GameObject>();
    int count = 16;
    ComputeBuffer buffer;

    private void Start()
    {
        for (int i = 0; i < count; i++)
        {
            GameObject obj = Instantiate(prefab) as GameObject;
            pool.Add(obj);
        }
        CreateBuffer();
    }
    private void Update()
    {
        Dispatch();

        PBuffer[] values = new PBuffer[count];
        buffer.GetData(values);
        bool reborn = false;
        for (int i = 0; i < count; i++)
        {
            if (values[i].life < 0)
            {
                InitStruct(ref values[i]);
                reborn = true;
            }
            else
            {
                pool[i].transform.position = values[i].pos;
                pool[i].transform.localScale = values[i].scale;
                pool[i].transform.eulerAngles = values[i].eulerAngle;
            }
        }
        if (reborn)
            buffer.SetData(values);
    }
    void CreateBuffer()
    {
        buffer = new ComputeBuffer(count, 40);  //40是字节数
        PBuffer[] values = new PBuffer[count];
        for (int i = 0; i < count; i++)
        {
            PBuffer m = new PBuffer();
            InitStruct(ref m);
            values[i] = m;
        }
        buffer.SetData(values);
    }

    void InitStruct(ref PBuffer m)
    {
        m.life = Random.Range(1f, 3f);
        m.pos = Random.insideUnitSphere * 5f;
        m.scale = Vector3.one * Random.Range(0.3f, 1f);
        m.eulerAngle = new Vector3(0, Random.Range(0f, 180f), 0);
    }
    void Dispatch()
    {
        computeShader.SetFloat("deltaTime", Time.deltaTime);
        int kid = computeShader.FindKernel("CSMain");
        computeShader.SetBuffer(kid, "buffer", buffer);
        computeShader.Dispatch(kid, 2, 2, 1);
    }
    void ReleaseBuffer()
    {
        buffer.Release();
    }
    private void OnDisable()
    {
        ReleaseBuffer();
    }
}
