Shader "Custom/Chapter 11/ImageSequenceAnimation"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("Main Tex", 2D) = "white" {}
        _HorAmount("Horizontal Amount", Float) = 4
        _VerAmount("Vertical Amount", Float) = 4
        _Speed("Speed", Range(1, 100)) = 30
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
        }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            float _HorAmount;
            float _VerAmount;
            float _Speed;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert( a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //此算法要求材质的wrapMode为Repeat
                //列的位置从左往右依次播放，达到最大时重置为0
                //行的位置实际上是从负数开始，无限变小

                //总时间乘速度作为时刻值，_Time是场景加载后开始计时
                float time = floor(_Time.y * _Speed);
                //时刻值除以行数的商作为行索引，余数作为列索引
                //row会无限增大，我们将初始row从1开始，这样才能从材质的第一行（最上面）开始
                float row = floor(time / _HorAmount) + 1;
                //column在超过_HorAmount值后会从0重新开始
                float column = time - row * _HorAmount;

                //将uv值映射到（正常情况下是缩小）等分后小区域内
                //比如uv为(1, 1)，行列都为8。实际上一张材质被等分成了64个小区域，每个区域内是一帧的图像
                //映射后的位置实际上是最左下角区域的右上角的一个点
                // half2 uv = float2(i.uv.x / _HorAmount, i.uv.y / _VerAmount);

                //将uv.x坐标按照当前列位置进行偏移，比如column为1，实际上就是向右偏移了一个区域（一帧）
                // uv.x += column / _HorAmount;
                //注意因为美术制作的材质中帧动画顺序是从上到下的，而uv值是从下到上从0到1的
                //我们使用减法向下偏移，因为wrapMode为Repeat，就是从上到下的顺序
                //将uv.y坐标按照当前行位置进行偏移，比如row为2，实际上就是向下偏移了两个区域（两帧数）
                // uv.y -= row / _VerAmount;

                //简化算法，先将uv位置偏移，然后再映射到一帧的大小范围
                half2 uv = i.uv + half2(column, -row);
				uv.x /=  _HorAmount;
				uv.y /= _VerAmount;

                fixed4 color = tex2D(_MainTex, uv) * _Color;

                return color;
                //return fixed4(-uv.y, 0, 0, 1);
            }

            ENDCG
        }
    }

    FallBack "Transparent/VertexLit"
}
