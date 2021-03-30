using BlackfireStudio;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace BlackfireStudioEditor
{
	[CustomEditor(typeof(Frost))]
	public class FrostEditor : Editor
	{

		private SerializedObject    serializedObj;
		private SerializedProperty  serializedShader;
		private SerializedProperty  serializedColor;
		private SerializedProperty  serializedDiffuseTex;
		private SerializedProperty  serializedBumpTex;
		private SerializedProperty  serializedCoverageTex;
		private SerializedProperty  serializedTransparency;
		private SerializedProperty  serializedRefraction;
		private SerializedProperty  serializedCoverage;
		private SerializedProperty  serializedSmooth;

		private Shader              shaders;

		private List<string>        properties = new List<string>();

		public void OnEnable()
		{
			serializedObj = new SerializedObject(target);
			serializedShader = serializedObj.FindProperty("shader");
			serializedColor = serializedObj.FindProperty("color");
			serializedDiffuseTex = serializedObj.FindProperty("diffuseTex");
			serializedBumpTex = serializedObj.FindProperty("bumpTex");
			serializedCoverageTex = serializedObj.FindProperty("coverageTex");
			serializedTransparency = serializedObj.FindProperty("transparency");
			serializedRefraction = serializedObj.FindProperty("refraction");
			serializedCoverage = serializedObj.FindProperty("coverage");
			serializedSmooth = serializedObj.FindProperty("smooth");

			shaders = serializedShader.objectReferenceValue as Shader;

			RegisterShaderProperties(shaders);
			serializedObj.ApplyModifiedProperties();
		}

		private void RegisterShaderProperties(Shader s)
		{
			for (int i = 0; i < ShaderUtil.GetPropertyCount(s); ++i)
			{
				properties.Add(ShaderUtil.GetPropertyName(s, i));
			}
		}

		private void GUIShaderRange(string item, SerializedProperty serializedProperty)
		{
			float leftValue     = ShaderUtil.GetRangeLimits(shaders, properties.IndexOf(item), 1);
			float rightValue    = ShaderUtil.GetRangeLimits(shaders, properties.IndexOf(item), 2);

			EditorGUILayout.Slider(serializedProperty, leftValue, rightValue);
		}

		public override void OnInspectorGUI()
		{
			serializedObject.Update();

			EditorGUIUtility.LookLikeControls();

			EditorGUILayout.PropertyField(serializedShader, new GUIContent("Shader"));
			EditorGUILayout.PropertyField(serializedColor, new GUIContent("Color (RGB) Screen (A)"));
			EditorGUILayout.PropertyField(serializedDiffuseTex, new GUIContent("Diffuse (RGBA)"));
			EditorGUILayout.PropertyField(serializedBumpTex, new GUIContent("Normal (RGB)"));
			EditorGUILayout.PropertyField(serializedCoverageTex, new GUIContent("Coverage (R)"));

			GUIShaderRange("_Transparency", serializedTransparency);
			GUIShaderRange("_Refraction", serializedRefraction);
			GUIShaderRange("_Coverage", serializedCoverage);
			GUIShaderRange("_Smooth", serializedSmooth);

			serializedObj.ApplyModifiedProperties();

			serializedObj.UpdateIfDirtyOrScript();
        }
	}
}