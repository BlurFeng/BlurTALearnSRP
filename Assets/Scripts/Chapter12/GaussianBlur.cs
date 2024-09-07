using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GaussianBlur : PostEffectsBase
{
    public Shader gaussianBlurShader;
    private Material gaussianBlurMaterial;
    public Material Material
    {
        get
        {
            gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
            return gaussianBlurMaterial;
        }
    }

    [Range(0, 4), Tooltip("迭代次数。")]
    public int iterations = 3;

    [Range(0.2f, 3f), Tooltip("此值越大模糊程度越高，但过大可能导致虚影。")]
    public float blurSpread = 0.6f;

    [Range(1, 8), Tooltip("低采样率，此值越大需要处理的纹素越少，但过大会导致画面像素化。")]
    public int downSample = 2;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (Material == null)
        {
            Graphics.Blit(source, destination);
            return;
        }

        //实际进行采样的尺寸
        int rtW = source.width/downSample;
        int rtH = source.height/downSample;

        //声明临时缓存区用于缓存处理过的图像
        RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
        buffer0.filterMode = FilterMode.Bilinear;

        Graphics.Blit(source, buffer0);

        for (int i = 0; i < iterations; i++)
        {
            Material.SetFloat("_BlurSize", 1f + i * blurSpread);

            RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

            //将buffer0进行垂直高斯模糊处理，并缓存到buffer1
            Graphics.Blit(buffer0, buffer1, Material, 0);

            RenderTexture.ReleaseTemporary(buffer0);
            buffer0 = buffer1;
            buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

            //进行水平高斯模糊处理
            Graphics.Blit(buffer0, buffer1, Material, 1);

            RenderTexture.ReleaseTemporary(buffer0);
            buffer0 = buffer1;
        }

        Graphics.Blit(buffer0, destination);
        RenderTexture.ReleaseTemporary(buffer0);
    }
}
