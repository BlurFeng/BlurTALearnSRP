using System.Collections;
using System.Collections.Generic;
using System.Diagnostics.Contracts;
using UnityEngine;

public class EdgeDetection : PostEffectsBase
{
    public Shader edgeDetectionShader;
    private Material edgeDetectionMaterial;
    public Material Material
    {
        get
        {
            edgeDetectionMaterial = CheckShaderAndCreateMaterial(edgeDetectionShader, edgeDetectionMaterial);
            return edgeDetectionMaterial;
        }
    }

    [Range(0f, 1f), Tooltip("是否只显示边缘，为0时边缘会叠加在原图上，为1时只显示边缘。")]
    public float edgeOnly = 0f;

    [Range(0f, 1f), Tooltip("边缘强度")]
    public float intensity = 1f;

    [Tooltip("边缘颜色。")]
    public Color edgeColor = Color.black;

    [Tooltip("背景颜色，当edgeOnly为1时，没有描边的位置完全显示此颜色。")]
    public Color backgroundColor = Color.white;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (Material == null)
        {
            Graphics.Blit(source, destination);
            return;
        }

        Material.SetFloat("_EdgeOnly", edgeOnly);
        Material.SetFloat("_Intensity", intensity);
        Material.SetColor("_EdgeColor", edgeColor);
        Material.SetColor("_BackgroundColor", backgroundColor);

        Graphics.Blit(source, destination, Material);
    }
}
