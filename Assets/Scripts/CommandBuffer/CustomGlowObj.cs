using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomGlowObj : MonoBehaviour
{
    public Material glowMaterial;
    private void OnEnable()
    {
        CustomGlowSystem.instance.Add(this);
    }
    // Start is called before the first frame update
    void Start()
    {
        CustomGlowSystem.instance.Add(this);
    }

    void OnDisable()
    {
        CustomGlowSystem.instance.Remove(this);
    }
}
