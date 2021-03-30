using UnityEngine;
using System.Collections;

namespace BlackfireStudio
{
	[ExecuteInEditMode]
	[RequireComponent(typeof(Camera))]
	[AddComponentMenu("Image Effects/Blackfire Studio/Frost")]
	public class Frost : MonoBehaviour
	{
		public Shader       shader;
		public Color        color;
		public Texture2D    diffuseTex;
		public Texture2D    bumpTex;
		public Texture2D    coverageTex;
		public float        transparency;
		public float        refraction;
		public float        coverage;
		public float        smooth;

		private Material    frostMaterial;
		protected Material material
		{
			get
			{
				if (frostMaterial == null)
				{
					frostMaterial = new Material(shader);
					frostMaterial.hideFlags = HideFlags.HideAndDontSave;
				}
				return frostMaterial;
			}
		}

		private void OnRenderImage(RenderTexture sourceTexture, RenderTexture destTexture)
		{
			if (shader != null)
			{
				material.SetColor("_Color", color);
				material.SetFloat("_Transparency", transparency);
				material.SetFloat("_Refraction", refraction);
				material.SetFloat("_Coverage", coverage);
				material.SetFloat("_Smooth", smooth);
				if (diffuseTex != null) { material.SetTexture("_DiffuseTex", diffuseTex); } else { material.SetTexture("_DiffuseTex", null); }
				if (bumpTex != null) { material.SetTexture("_BumpTex", bumpTex); } else { material.SetTexture("_BumpTex", null); }
				if (coverageTex != null) { material.SetTexture("_CoverageTex", coverageTex); } else { material.SetTexture("_CoverageTex", null); }
				Graphics.Blit(sourceTexture, destTexture, material);
			}
			else
			{
				Graphics.Blit(sourceTexture, destTexture);
			}
		}
	}
}