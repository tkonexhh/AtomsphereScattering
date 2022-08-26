using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class RuntimeSkyboxSetting : MonoBehaviour
{
    [Min(0f)]
    public float planetRadius = 6357000.0f;//星球半径
    [Min(0f)]
    public float atmosphereHeight = 12000f;//大气层厚度
    [Range(0.0f, 0.999f)]
    public float MieG = 0.76f;
    [Range(0, 10.0f)]
    public float RayleighScatterCoef = 1;
    [Range(0, 10.0f)]
    public float RayleighExtinctionCoef = 1;
    [Range(0, 10.0f)]
    public float MieScatterCoef = 1;
    [Range(0, 10.0f)]
    public float MieExtinctionCoef = 1;

    // [Header("Particles")]
    // public float RayleighDensityScale = 7994.0f;
    // public float MieDensityScale = 1200;

    [Header("Sun Disk")]
    [Range(0, 3)] public float sunIntensity = 0.75f;

    [Range(-1, 1)] public float sunMieG = 0.98f;

    private readonly Vector4 DensityScaleHeight = new Vector4(7994.0f, 1200.0f, 0, 0);//瑞利散射 米氏散射 的海平面散射值
    private readonly Vector4 RayleighSct = new Vector4(5.8f, 13.5f, 33.1f, 0.0f) * 0.000001f;
    private readonly Vector4 MieSct = new Vector4(2.0f, 2.0f, 2.0f, 0.0f) * 0.00001f;

    internal class ShaderIDs
    {
        public static readonly int DensityScaleHeight = Shader.PropertyToID("_DensityScaleHeight");
        public static readonly int PlanetRadius = Shader.PropertyToID("_PlanetRadius");
        public static readonly int AtmosphereHeight = Shader.PropertyToID("_AtmosphereHeight");
        public static readonly int ScatteringR = Shader.PropertyToID("_ScatteringR");
        public static readonly int ScatteringM = Shader.PropertyToID("_ScatteringM");
        public static readonly int ExtinctionR = Shader.PropertyToID("_ExtinctionR");
        public static readonly int ExtinctionM = Shader.PropertyToID("_ExtinctionM");
        public static readonly int MieG = Shader.PropertyToID("_MieG");

        public static readonly int SunIntensity = Shader.PropertyToID("_SunIntensity");
        public static readonly int SunMieG = Shader.PropertyToID("_SunMieG");
    }

    private void Start()
    {
        SetCommonParams();
    }

    // Update is called once per frame
    void Update()
    {
        SetCommonParams();
    }

    void SetCommonParams()
    {
        Shader.SetGlobalFloat(ShaderIDs.PlanetRadius, planetRadius);
        Shader.SetGlobalFloat(ShaderIDs.AtmosphereHeight, atmosphereHeight);
        // Shader.SetGlobalVector(ShaderIDs.DensityScaleHeight, new Vector4(RayleighDensityScale, MieDensityScale, 0, 0));
        Shader.SetGlobalVector(ShaderIDs.DensityScaleHeight, DensityScaleHeight);
        Shader.SetGlobalVector(ShaderIDs.ScatteringR, RayleighSct * RayleighScatterCoef);
        Shader.SetGlobalVector(ShaderIDs.ScatteringM, MieSct * MieScatterCoef);
        Shader.SetGlobalVector(ShaderIDs.ExtinctionR, RayleighSct * RayleighExtinctionCoef);
        Shader.SetGlobalVector(ShaderIDs.ExtinctionM, MieSct * MieExtinctionCoef);
        Shader.SetGlobalFloat(ShaderIDs.MieG, MieG);

        Shader.SetGlobalFloat(ShaderIDs.SunIntensity, sunIntensity);
        Shader.SetGlobalFloat(ShaderIDs.SunMieG, sunMieG);
    }
}
