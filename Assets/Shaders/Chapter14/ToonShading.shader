Shader "Custom/Chapter 14/Toon Shading"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Ramp ("Ramp Tex", 2D) = "white" {}
        _Outline ("Outline", Range(0, 1)) = 0.02
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _SpecularScale ("Specular Scale", Range(0, 0.1)) = 0.01
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry"}

        //渲染描边Pass，只处理背面三角面片。通过将背面外扩大于正面形成描边
        Pass
        {
            NAME "Outline"
            Cull Front

            CGPROGRAM

            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            float _Outline;
            fixed4 _OutlineColor;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert(a2v v)
            {
                v2f o;

                //计算在视野空间下的位置和法线
                float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
                float3 normal = mul((float3x3)UNITY_MATRIX_MV, v.normal);

                //视野空间下的z代表距离视觉点的远近，值越小越远。通过调整法线的z值使背面不容易挡住正面
                normal.z = -0.5;

                //顶点向法线方向扩张
                pos = pos + float4(normalize(normal), 0) * _Outline;
                o.pos = mul(UNITY_MATRIX_P, pos);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return float4(_OutlineColor.rgb, 1);
            }

            ENDCG
        }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            Cull Back

            CGPROGRAM

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityShaderVariables.cginc"

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
            fixed4 _Specular;
            fixed _SpecularScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                //反射率
                fixed3 albedo =  tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //阴影
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                //通过diff对_Ramp采样获得漫反射颜色
                fixed diff = (dot(worldNormal, worldLightDir) * 0.5 + 0.5) * atten;
                fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff, diff)).rgb;

                //高光
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);
                fixed spec = dot(worldNormal, worldHalfDir);
                //领域像素之间的近似导数值，当差距越大w值越大，那么高光过度部分越多
                fixed w = fwidth(spec) * 2;
                //这里spec的值在[-1,1]，减1后为[-2,0]，_SpecularScale值实际上就是向正数偏移的部分
                //然后-w和w框定了高光渐变的最外环区域
                fixed3 specular = _Specular.rgb * smoothstep(-w, w, spec - 1 + _SpecularScale) * step(0.0001, _SpecularScale);

                return fixed4(ambient + diffuse + specular, 1);
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}
