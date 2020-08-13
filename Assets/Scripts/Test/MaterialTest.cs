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
            material = render.sharedMaterial;
            string name = material.name;
            Debug.Log(name);
            //string name = render.sharedMaterial.name;
            //Texture tex = render.sharedMaterial.mainTexture;
        }
        if (Input.GetKeyDown(KeyCode.L))
        {
            Debug.Log(render.sharedMaterial.name);
            mat = render.material;
            //Object.Destroy(render.sharedMaterial);
            //render.sharedMaterial = null;

        }
    }
}
