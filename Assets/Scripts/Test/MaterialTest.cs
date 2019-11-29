using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MaterialTest : MonoBehaviour
{
    public GameObject go;
    Renderer render;
    // Start is called before the first frame update
    void Start()
    {
        render = go.GetComponent<Renderer>();
    }
    Material material;
    Material mat;
    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.K))
        {
            material = render.material;
            string name = material.name;
            //string name = render.sharedMaterial.name;
            //Texture tex = render.sharedMaterial.mainTexture;
        }
        if (Input.GetKeyDown(KeyCode.L))
        {
            Debug.Log(render.material.name);
            mat = render.material;
            //Object.Destroy(render.sharedMaterial);
            //render.sharedMaterial = null;

        }
    }
}
