Shader "Custom/Chapter 10/GlassRefraction"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bunp" {}
        _Cubemap("Environment Cubemap", Cube) = "_Skybox" {}
        _Distortion("Distortion", Range(0, 100)) = 10
        _RefractAmount("Refract Amount", Range(0.0, 1.0)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Transparent" }

        GrabPass { "_RefractionTex" }

        Pass
        {
            CGPROGRAM

            #pragma vertex vert 
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            samplerCUBE _Cubemap;
            float _Distortion;
            fixed _RefractAmount;
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 scrPos :TEXCOORD0;
                float4 uv : TEXCOORD1;
                float4 TtoW0 : TEXCOORD2;
                float4 TtoW1 : TEXCOORD3;
                float4 TtoW2 : TEXCOORD4;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.scrPos = ComputeGrabScreenPos(o.pos);

                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                //构造切线空间转世界空间矩阵
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                //采样获取切线空间下法线
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));

                //采样折射颜色，内部物体通过折射后的颜色
                //通过GrabPass抓取的_RefractionTex_TexelSize和_Distortion扭曲强度来计算偏移量
                float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                //根据偏移量调整xy坐标
                i.scrPos.xy = i.scrPos.xy + offset;
                //采样折射贴图
                fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;

                //将法线从切线空间转换到世界空间
                bump = normalize(half3(dot(bump, i.TtoW0.xyz), dot(bump, i.TtoW1.xyz), dot(bump, i.TtoW2.xyz)));
                fixed3 reflDir = reflect(-worldViewDir, bump);
                fixed4 texCol = tex2D(_MainTex, i.uv.xy);
                //采样反射颜色，环境在表面的反射
                fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texCol.rgb;

                fixed3 color = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
}
