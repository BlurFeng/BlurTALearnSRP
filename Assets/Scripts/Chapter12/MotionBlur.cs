using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlur : PostEffectsBase
{
    public Shader motionBlurShader;
    private Material motionBlurMaterial;
    public Material Material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    [Range(0f, 0.9f), Tooltip("运动模糊强度，此值越大，运动时拖尾效果越明显。")]
    public float blurAmount = 0.5f;

    private RenderTexture accTrxture;

    private void OnDisable()
    {
        DestroyImmediate(accTrxture);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (Material == null)
        {
            Graphics.Blit(source, destination);
            return;
        }

        //当accTrxture为空或和当前原图片尺寸不符时，实例化新的accTrxture
        if (accTrxture == null || accTrxture.width != source.width || accTrxture.height != source.height)
        {
            DestroyImmediate(accTrxture);
            accTrxture = new RenderTexture(source.width, source.height, 0);
            accTrxture.hideFlags = HideFlags.HideAndDontSave;
            Graphics.Blit(source, accTrxture);
        }

        accTrxture.MarkRestoreExpected();

        Material.SetFloat("_BlurAmount", 1f - blurAmount);
        Graphics.Blit(source, accTrxture, Material);
        Graphics.Blit(accTrxture, destination);
    }
}
