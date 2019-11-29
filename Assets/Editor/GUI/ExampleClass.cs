using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.AnimatedValues;
using UnityEngine;

public class ExampleClass : EditorWindow
{
    float spaceSize;

    AnimBool m_ShowExtraFields;
    string m_String;
    Color m_Color = Color.white;
    int m_Number = 0;
    [MenuItem("Examples/GUILayout.Space")]
    static void CreateWindow()
    {
        EditorWindow window = GetWindow<ExampleClass>();
        window.Show();
    }
    private void OnEnable()
    {
        m_ShowExtraFields = new AnimBool(true);
        m_ShowExtraFields.valueChanged.AddListener(Repaint);
    }
    private void OnGUI()
    {
        //if (GUILayout.Button("Button1: Move Button2 down by 2 pixels"))
        //{
        //    spaceSize = spaceSize + 2.0f;
        //}
        //GUILayout.Space(spaceSize);
        //if (GUILayout.Button("Button2: Move up by 1 pixel"))
        //{
        //    spaceSize = spaceSize - 1.0f;
        //}
        //Repaint 值改变重绘 ToggleLeft在左边 indentLevel是指水平
        m_ShowExtraFields.target = EditorGUILayout.ToggleLeft("Show extr fields", m_ShowExtraFields.target);
        if (EditorGUILayout.BeginFadeGroup(m_ShowExtraFields.faded))
        {
            EditorGUI.indentLevel++;
            EditorGUILayout.PrefixLabel("Color");
            m_Color = EditorGUILayout.ColorField(m_Color);
            EditorGUILayout.PrefixLabel("Text");
            m_String = EditorGUILayout.TextField(m_String);
            EditorGUILayout.PrefixLabel("Number");
            m_Number = EditorGUILayout.IntSlider(m_Number,0,10);
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndFadeGroup();
    }
}
