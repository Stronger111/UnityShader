using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Test : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        //值类型
        AAA aAA = new AAA();
        aAA.aaa = 1;
        BBB bBB = new BBB();
        bBB.aa = aAA;
        Debug.Log("aAA.aaa" + aAA.aaa + "bBB.aa" + bBB.aa.aaa);
        aAA.aaa = 3;
        Debug.Log("有一次赋值  aAA.aaa" + aAA.aaa + "bBB.aa" + bBB.aa.aaa);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
public struct AAA
{
    public int aaa;
}

public class BBB
{
    public AAA aa;
}