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

                //���ȣ�ֱ�ӳ���
                fixed3 col = renderTex.rgb * _Brightness;

                //���Ͷȣ��ȹ���һ�����Ͷ�Ϊ0����ɫֵluminanceCol��Ȼ���ڱ��Ͷ�Ϊ0����ɫ��ԭɫ֮���ֵ
                fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                fixed3 luminanceCol = fixed3(luminance, luminance, luminance);
                col = lerp(luminanceCol, col, _Saturation);

                //�Աȶȣ��ȹ����Աȶ�Ϊ0����ɫ��Ȼ���ֵ
                fixed3 avgCol = fixed3(0.5f, 0.5f, 0.5f);
                col = lerp(avgCol, col, _Contrast);

                return fixed4(col, renderTex.a);
            }

            ENDCG
        }
    }

    FallBack Off
}
