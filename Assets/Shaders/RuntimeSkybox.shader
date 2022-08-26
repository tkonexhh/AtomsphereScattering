Shader "AtomsphereScattering/RuntimeSkybox"
{
    SubShader
    {
        Tags { "Queue" = "Background" "RenderType" = "Background" "RenderPipeline" = "UniversalPipeline" "PreviewType" = "Skybox" }
        Pass
        {
            Cull Off

            ZWrite Off
            ZTest LEqual       // Don't draw to bepth buffer
            LOD 100
            HLSLPROGRAM

            #pragma target 5.0

            #pragma vertex vert
            #pragma fragment frag


            #define SAMPLECOUNT_KSYBOX 64

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./ShaderLibrary/InScattering.hlsl"

            struct Attributes
            {
                float4 positionOS: POSITION;
            };

            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionOS: TEXCOORD0;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionOS = input.positionOS;
                return output;
            }

            half4 frag(Varyings input): SV_Target
            {
                float3 rayStart = _WorldSpaceCameraPos.xyz;
                float3 rayDir = normalize(TransformObjectToWorld(input.positionOS));
                float3 planetCenter = float3(0, -_PlanetRadius, 0);

                Light mainLight = GetMainLight();
                float3 lightDir = mainLight.direction;

                //把星球看成一个球体 大气厚度为 星球半径+大气层高度
                float2 intersection = RaySphereIntersection(rayStart, rayDir, planetCenter, _PlanetRadius + _AtmosphereHeight);//与大气层的交点

                float rayLength = intersection.y;
                intersection = RaySphereIntersection(rayStart, rayDir, planetCenter, _PlanetRadius);//与地面的交点
                if (intersection.x >= 0)
                    rayLength = min(rayLength, intersection.x);
                //得到散射长度
                return rayLength;
                float3 extinction;
                //IntegrateInscattering(float3 rayStart, float3 rayDir, float rayLength, float3 planetCenter, float distanceScale, float3 lightDir, float sampleCount, out float3 extinction)
                // float3 inscattering = IntegrateInscattering(rayStart, rayDir, rayLength, planetCenter, 1, lightDir, SAMPLECOUNT_KSYBOX, extinction);
                // return half4(inscattering, 1);

            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}