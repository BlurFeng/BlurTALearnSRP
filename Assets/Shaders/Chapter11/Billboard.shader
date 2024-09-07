Shader "Custom/Chapter 11/Billboard"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        _Color("Color", Color) = (1, 1, 1, 1)
        _VerBillboard("Vertical Restraints", Range(0, 1)) = 1
        _CenterOffSet("Center Offset", Vector) = (0, 0, 0, 0)
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "DisableBatching" = "True"
        }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            CGPROGRAM

            #pragma vertex vert 
            #pragma fragment frag 

            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed _VerBillboard;
            fixed4 _CenterOffSet;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;

                //假设在模型空间中中心点固定为零点
                float3 center = float3(0, 0, 0) + _CenterOffSet;
                //获取相机在模型空间下的位置
                float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));

                //目标法线指向观察者
                float3 normalDir = viewer - center;

                //_VerBillboard为1时，法线方向固定为视线方向
                //当_VerBillboard为0时，向上方向固定为(0,1,0)
                //及Pitch俯仰角固定，Yaw偏航变化面向摄像机
                normalDir.y *= _VerBillboard;
                normalDir = normalize(normalDir);

                //这里构建一个upDir用来求rightDir，此时upDir和normalDir不是垂直的
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                float3 rightDir = normalize(cross(upDir, normalDir));
                //获得了rightDir后，使用normalDir和rightDir叉乘来获得正交的upDir
                upDir = normalize(cross(normalDir, rightDir));

                //根据原始位置相对锚点的偏移量，和三个正交基适量，计算新的位置
                float3 centerOffs = v.vertex.xyz - center;
                float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;

                o.pos = UnityObjectToClipPos(float4(localPos, 1));
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb *= _Color.rgb;

                return col;
            }

            ENDCG
        }
    }

    FallBack "Transparent/VertexLit"
}
