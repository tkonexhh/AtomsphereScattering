#pragma once

#include "./ACMath.hlsl"

uniform float2 _DensityScaleHeight;//海平面散射值
uniform float _PlanetRadius;
uniform float _AtmosphereHeight;

uniform float3 _ScatteringR;
uniform float3 _ScatteringM;
uniform float3 _ExtinctionR;
uniform float3 _ExtinctionM;
uniform float _MieG;

uniform float _SunIntensity;
uniform float _SunMieG;

//计算最终Inscattering
//----- Input
// cosAngle			散射角

//----- Output :
// scatterR
// scatterM
void ApplyPhaseFunction(inout float3 scatterR, inout float3 scatterM, float cosAngle)
{
    scatterR *= RayleighPhase(cosAngle);
    scatterM *= MiePhaseHGCS(cosAngle, _MieG);
}

float3 RenderSun(float3 scatterM, float cosAngle)
{
    return scatterM * MiePhaseHG(cosAngle, _SunMieG) * 0.003;
}

// //计算大气强度
// void GetAtmosphereDensity(float3 position, float3 planetCenter, float3 lightDir, out float2 densityAtP, out float2 particleDensityCP)
// {
//     float height = length(position - planetCenter) - _PlanetRadius;
//     densityAtP = ParticleDensity(height, _DensityScaleHeight.xy);

//     float cosAngle = dot(normalize(position - planetCenter), lightDir.xyz);

//     particleDensityCP = SAMPLE_TEXTURE2D_LOD(_IntegralCPDensityLUT, sampler_IntegralCPDensityLUT, float2(cosAngle * 0.5 + 0.5, (height / _AtmosphereHeight)), 0).xy;
// }


//----- Input
// localDensity			rho(h)
// densityPA
// densityCP

//----- Output :
// localInscatterR
// localInscatterM
void ComputeLocalInscattering(float2 densityAtP, float2 particleDensityCP, float2 particleDensityAP, out float3 localInscatterR, out float3 localInscatterM)
{
    float2 particleDensityCPA = particleDensityAP + particleDensityCP;

    float3 Tr = particleDensityCPA.x * _ExtinctionR;
    float3 Tm = particleDensityCPA.y * _ExtinctionM;

    float3 extinction = exp( - (Tr + Tm));

    localInscatterR = densityAtP.x * extinction;
    localInscatterM = densityAtP.y * extinction;
}

//----- Input
// position			视线采样点P // Current point within the atmospheric sphere
// lightDir			光照方向    // Direction towards the sun

//----- Output :
// opticalDepthCP:	dcp
void lightSampling(float3 position, float lightDir, float3 planetCenter, out float2 opticalDepthCP)
{
    opticalDepthCP = 0;

    float3 rayStart = position;
    float3 rayDir = -lightDir;

    float2 intersection = RaySphereIntersection(rayStart, rayDir, planetCenter, _PlanetRadius + _AtmosphereHeight);
    float3 rayEnd = rayStart + rayDir * intersection.y;

    // compute density along the ray
    float stepCount = 50;// 250;
    float3 step = (rayEnd - rayStart) / stepCount;
    float stepSize = length(step);
    float2 density = 0;

    for (float s = 0.5; s < stepCount; s += 1.0)
    {
        float3 position = rayStart + step * s;
        float height = abs(length(position - planetCenter) - _PlanetRadius);//海拔高度
        float2 localDensity = exp( - (height.xx / _DensityScaleHeight));

        density += localDensity * stepSize;
    }

    opticalDepthCP = density;
}

void GetAtmosphereDensityRealTime(float3 position, float3 planetCenter, float3 lightDir, out float2 densityAtP, out float2 particleDensityCP)
{
    float height = length(position - planetCenter) - _PlanetRadius;
    densityAtP = ParticleDensity(height, _DensityScaleHeight.xy);
    lightSampling(position, lightDir, planetCenter, particleDensityCP);
}


//----- Input
// rayStart		视线起点 A
// rayDir		视线方向
// rayLength		AB 长度
// planetCenter		地球中心坐标
// distanceScale	世界坐标的尺寸
// lightdir		太阳光方向
// sampleCount		AB 采样次数

//----- Output :
// extinction       T(PA)
// inscattering:	Inscatering
float3 IntegrateInscattering(float3 rayStart, float3 rayDir, float rayLength, float3 planetCenter, float distanceScale, float3 lightDir, float sampleCount, out float3 extinction, half3 lightColor)
{

    rayLength *= distanceScale;
    float3 step = rayDir * (rayLength / sampleCount);//步长
    float stepSize = length(step) ;//* distanceScale;

    float2 particleDensityAP = 0;
    float3 scatterR = 0;
    float3 scatterM = 0;

    float2 densityAtP;
    float2 particleDensityCP;

    float2 prevDensityAtP;
    float3 prevLocalInscatterR, prevLocalInscatterM;
    GetAtmosphereDensityRealTime(rayStart, planetCenter, lightDir, prevDensityAtP, particleDensityCP);
    // ComputeLocalInscattering(prevDensityAtP, particleDensityCP, particleDensityAP, prevLocalInscatterR, prevLocalInscatterM);

    //TODO loop vs Unroll?
    [loop]
    for (float s = 1.0; s < sampleCount; s += 1)
    {
        float3 p = rayStart + step * s;

        GetAtmosphereDensityRealTime(p, planetCenter, lightDir, densityAtP, particleDensityCP);
        particleDensityAP += (densityAtP + prevDensityAtP) * (stepSize / 2.0);

        prevDensityAtP = densityAtP;

        float3 localInscatterR, localInscatterM;
        ComputeLocalInscattering(densityAtP, particleDensityCP, particleDensityAP, localInscatterR, localInscatterM);

        scatterR += (localInscatterR + prevLocalInscatterR) * (stepSize / 2.0);
        scatterM += (localInscatterM + prevLocalInscatterM) * (stepSize / 2.0);

        prevLocalInscatterR = localInscatterR;
        prevLocalInscatterM = localInscatterM;
    }

    float3 m = scatterR;
    float cosAngle = dot(rayDir, lightDir.xyz);

    ApplyPhaseFunction(scatterR, scatterM, cosAngle);

    float3 lightInscatter = (scatterR * _ScatteringR + scatterM * _ScatteringM) * lightColor.xyz;
    // #if defined(_RENDERSUN)
    lightInscatter += RenderSun(m, cosAngle) * _SunIntensity;
    // #endif

    // // Extinction
    extinction = exp( - (particleDensityAP.x * _ExtinctionR + particleDensityAP.y * _ExtinctionM));

    return lightInscatter.xyz;
}