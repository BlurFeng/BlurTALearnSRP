Shader "Custom/Chapter 12/BrightnessSaturationAndContrast"
{
    Properties
    {
        _MainTex("Base (RGB)", 2D) = "white" {}
        _Brightness("Brightness", Float) = 1
        _Saturation("Saturation", Float) = 1
        _Contrast("Contrast", Float) = 1
    }

    SubShader
    {
        Pass
        {
            ZTest Always
            Cull Off
            ZWrite Off

            CGPROGRAM

            #pragma vertex vert 
            #pragma fragment frag 

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            half _Brightness;
            half _Saturation;
            half _Contrast;

            struct v2f
            {
                float4 pos : POSITION;
                half2 uv : TEXCOORD0;
            };

            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 renderTex = tex2D(_MainTex, i.uv);

                //亮度，直接乘以
                fixed3 col = renderTex.rgb * _Brightness;

                //饱和度，先构建一个饱和度为0的颜色值luminanceCol，然后在饱和度为0的颜色和原色之间插值
                fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                fixed3 luminanceCol = fixed3(luminance, luminance, luminance);
                col = lerp(luminanceCol, col, _Saturation);

                //对比度，先构建对比度为0的颜色，然后插值
                fixed3 avgCol = fixed3(0.5f, 0.5f, 0.5f);
                col = lerp(avgCol, col, _Contrast);

                return fixed4(col, renderTex.a);
            }

            ENDCG
        }
    }

    FallBack Off
}
