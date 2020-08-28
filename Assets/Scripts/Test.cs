using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public class Test : MonoBehaviour
{
    /// <summary>
    /// 测试attribute
    /// </summary>
    public enum Properties
    {
        [ProperticesDesc("血量")]
        PH=1,
        [ProperticesDesc("物理攻击")]
        PhyAtk =2
    }
    Properties CC = Properties.PhyAtk;
    // Start is called before the first frame update
    void Start()
    {
        //值类型
        //AAA aAA = new AAA();
        //aAA.aaa = 1;
        //BBB bBB = new BBB();
        //bBB.aa = aAA;
        //Debug.Log("aAA.aaa" + aAA.aaa + "bBB.aa" + bBB.aa.aaa);
        //aAA.aaa = 3;
        //Debug.Log("有一次赋值  aAA.aaa" + aAA.aaa + "bBB.aa" + bBB.aa.aaa);
        Type type = CC.GetType();
        FieldInfo[] fieldInfos = type.GetFields();
        foreach(FieldInfo field in fieldInfos)
        {
            if(field.Name.Equals(CC.ToString()))
            {
                object[] objs = field.GetCustomAttributes(typeof(ProperticesDesc), true);//是否继承
                if (objs != null && objs.Length > 0)
                {
                    Debug.Log(((ProperticesDesc)objs[0]).Desc);
                }
            }
        }
        //比 3.56更大的数字
        Debug.Log(Mathf.CeilToInt(3.56f));
        //Debug.Log(Mathf.Log(1024,2));
        Debug.Log(Mathf.NextPowerOfTwo(1024));
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

[System.AttributeUsage(System.AttributeTargets.Field | System.AttributeTargets.Enum)]
public class ProperticesDesc:System.Attribute
{
    public string Desc { get; private set;}

    public ProperticesDesc(string value)
    {
        Desc = value;
    }
}