using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BrightnessSaturationAndContrast : PostEffectsBase
{
    public Shader briSatConShader;
    private Material briSatConMaterial;
    public Material Material
    {
        get
        {
            briSatConMaterial = CheckShaderAndCreateMaterial(briSatConShader, briSatConMaterial);
            return briSatConMaterial;
        }
    }

    [Range(0f, 3f), Tooltip("亮度")]
    public float brightness = 1f;

    [Range(0f, 3f), Tooltip("饱和度")]
    public float saturation = 1f;

    [Range(0f, 3f), Tooltip("对比度")]
    public float contrast = 1f;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(Material == null)
        {
            Graphics.Blit(source, destination);
            return;
        }

        Material.SetFloat("_Brightness", brightness);
        Material.SetFloat("_Saturation", saturation);
        Material.SetFloat("_Contrast", contrast);

        Graphics.Blit(source, destination, Material);
    }
}
