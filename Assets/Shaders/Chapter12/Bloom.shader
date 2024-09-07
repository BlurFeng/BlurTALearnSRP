Shader "Custom/Bloom"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Bloom("Bloom (RGB)", 2D) = "black" {}
        _BlurSize("Blur Size", Float) = 1
        _LuminanceThreshold("Luminance Threshold", Float) = 0.5
    }

    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _Bloom;
        float _BlurSize;
        float _LuminanceThreshold;

        //用于提取亮部区域的方法
        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
        };

        v2f vertExtractBright(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }

        //计算亮度值
        fixed luminance(fixed4 color) 
        {
			return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
		}

        fixed4 fragExtractBright(v2f i) : SV_Target
        {
            fixed4 col = tex2D(_MainTex, i.uv);
            //计算亮度值和阈值差，并限制在0-1内
            fixed val = clamp(luminance(col) - _LuminanceThreshold, 0, 1);

            return col * val;
        }

        struct v2fBloom
        {
            float4 pos : SV_POSITION;
            half4 uv : TEXCOORD0;
        };

        v2fBloom vertBloom(appdata_img v)
        {
            v2fBloom o;

            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.texcoord;
            o.uv.zw = v.texcoord;

            #if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y < 0)
                o.uv.w = 1 - o.uv.w;
            #endif

            return o;
        }

        fixed4 fragBloom(v2fBloom i) : SV_Target
        {
            return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
        }

        ENDCG

        ZTest Always Cull Off ZWrite Off

        //提取亮部
        Pass
        {
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright
            ENDCG
        }

        UsePass "Custom/Chapter 12/Gaussian Blur/GAUSSIAN_BLUR_VERTICAL"
        UsePass "Custom/Chapter 12/Gaussian Blur/GAUSSIAN_BLUR_HORIZONTAL"

        //将亮部Bloom应用到原图
        Pass
        {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            ENDCG
        }
    }

    FallBack Off
}
