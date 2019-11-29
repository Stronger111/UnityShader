using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GUIExample : MonoBehaviour
{
    Vector2 scrollPosition;
    string longString = "This is a long-ish string";
    public Texture tex;
    float sliderValue = 1.0f;
    string stringToEdit = "Hello World\nI've got 2 lines...";
    float vSbarValue;

    Rect windowRect = new Rect(20,20,120,50);
    private void OnGUI()
    {
        //1 Begion 
        //GUILayout.BeginHorizontal("box");  //开始一个盒子区域

        //GUILayout.Button("I first Button");
        //GUILayout.Button("I am Secend");

        //GUILayout.EndHorizontal();

        //2  开始绘制区域
        //GUILayout.BeginArea(new Rect(10,10,100,100));
        //GUILayout.Button("单机我");
        //GUILayout.Button("OR Me");
        //GUILayout.EndArea();

        //3: scroll
        //scrollPosition = GUILayout.BeginScrollView(scrollPosition, GUILayout.Width(100), GUILayout.Height(100));
        //GUILayout.Label(longString);
        //if(GUILayout.Button("Clear"))
        //{
        //    longString = "";
        //}
        //GUILayout.EndScrollView();
        //if (GUILayout.Button("Add More Text"))
        //    longString += "\nHere is another line";

        //4 box
        //if (!tex)
        //{
        //    Debug.LogError("Miss Texture");
        //}
        //GUILayout.Box(tex);
        //GUILayout.Label("This is an sized label");

        //5 可以和下面不对其 不去扩展宽度
        //GUILayout.BeginVertical();
        //GUILayout.Button("Short Button", GUILayout.ExpandWidth(false));
        //GUILayout.Button("Very very long Button");
        //GUILayout.EndVertical();

        //6
        //GUILayout.BeginArea(new Rect(0,0,200,60));

        //GUILayout.BeginHorizontal();
        //GUILayout.RepeatButton("A button with\ntwo lines");
        //GUILayout.FlexibleSpace();
        //GUILayout.BeginVertical();
        //GUILayout.Box("Value:"+Mathf.Round(sliderValue));
        //sliderValue = GUILayout.HorizontalSlider(sliderValue, 0.0f, 10f);

        //GUILayout.EndVertical();
        //GUILayout.EndHorizontal();
        //GUILayout.EndArea();

        //7 GUILayout.SelectionGrid
        //GUILayout.BeginVertical("Box");
        //selGridInt = GUILayout.SelectionGrid(selGridInt, selStrings, 1);
        //if (GUILayout.Button("Start"))
        //{
        //    Debug.Log("You chose " + selStrings[selGridInt]);
        //}
        //GUILayout.EndVertical();
        //8  多行
        //stringToEdit = GUILayout.TextArea(stringToEdit,200);
        //9单行
        //stringToEdit = GUILayout.TextField(stringToEdit,50);
        //10
        //vSbarValue = GUILayout.VerticalScrollbar(vSbarValue,1f,10f,0f);
        windowRect = GUILayout.Window(0, windowRect, DoMyWindow, "My Window");
    }

    void DoMyWindow(int windowID)
    {
        if (GUILayout.Button("Hello World"))
        {
            print("Got a click");
        }
    }
}
