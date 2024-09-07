Shader "Custom/CHapter 10/Fresnel"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _FresnelScale("Fresnel Scale", Range(0, 1)) = 0.5
        _Cubemap("Reflection Cubemap", Cube) = "_Skybox" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry"}

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed _FresnelScale;
            samplerCUBE _Cubemap;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                fixed3 worldViewDir : TEXCOORD2;
                fixed3 worldRefl : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

                o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldViewDir = normalize(i.worldViewDir);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT;

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

                fixed3 reflection = texCUBE(_Cubemap, i.worldRefl);

                //使用Schlick菲涅尔近似等式
                fixed3 fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldViewDir, worldNormal), 5);

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                fixed3 color = ambient + lerp(diffuse, reflection, saturate(fresnel)) * atten;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Reflective/VertexLit"
}
