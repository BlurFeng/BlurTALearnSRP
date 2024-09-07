Shader "Custom/Chapter 8/AlphaBlend"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("Main Tex", 2D) = "white" {}
        _AlphaScale("Alpha Scale", Range(0, 1)) = 1
    }

    SubShader
    {
        //透明度混合需要设置的Tag
        Tags 
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
        }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            //关闭深度写入
            ZWrite Off
            //设置混合模式
            //此模式保证源颜色（片元输出颜色）和目标颜色（已经在缓存中的颜色）的透明度比例总值为1
            // DstColor = SrcAlpha x ScrColor + (1 - ScrAlpha) x DstColor
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

            #pragma vertex vert 
            #pragma fragment frag 

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex, i.uv);
                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                //将纹理采样的a通道值（不透明度）和设置的_AlphaScale值设置到输出颜色的a
                return fixed4(diffuse + ambient, texColor.a * _AlphaScale);
            }

            ENDCG
        }
    }

    Fallback "Transparent/VertexLit"
}
