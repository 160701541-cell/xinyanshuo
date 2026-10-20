using System;
using UnityEngine;

namespace XianxiaWorldBox
{
    /// <summary>
    /// Only protects OUR optional isometric observer's overhead. Never changes
    /// WorldBox simulation speed, CPU governor, FPS cap, or writes saved worlds.
    /// This is a source/Android-SDK compiled candidate; not real device QA.
    /// </summary>
    public static class ObserverFrameGuardV12
    {
        public const float SuspendBelowFps = 24f;
        public const float RecoverAboveFps = 38f;
        public const float SuspendAfterSeconds = 4f;
        public const float RecoveryAfterSeconds = 6f;

        static float lowSince = -1f;
        static float goodSince = -1f;
        static float nextUiSample;
        public static float SmoothedFps { get; private set; } = 60f;
        public static bool Paused { get; private set; }
        public static bool Enabled { get; private set; } = true;
        public static string Reason { get; private set; } = "观察模式轻量运行";

        public static void Tick()
        {
            if (!Enabled) return;
            float dt = Time.unscaledDeltaTime;
            if (dt <= 0f || dt > 2f) return;
            float raw = Mathf.Clamp(1f / dt, 1f, 240f);
            // Fast enough to react, slow enough to ignore one-frame spikes.
            SmoothedFps = SmoothedFps * 0.92f + raw * 0.08f;
            float now = Time.unscaledTime;

            if (!Paused)
            {
                goodSince = -1f;
                if (SmoothedFps < SuspendBelowFps)
                {
                    if (lowSince < 0f) lowSince = now;
                    else if (now - lowSince >= SuspendAfterSeconds)
                    {
                        Paused = true;
                        lowSince = -1f;
                        Reason = "帧率连续偏低，已暂停附加观察绘制（不暂停WorldBox）";
                        Debug.LogWarning("[XIANXIA-V12] OBSERVER_PERF_SUSPENDED");
                    }
                }
                else lowSince = -1f;
            }
            else
            {
                if (SmoothedFps > RecoverAboveFps)
                {
                    if (goodSince < 0f) goodSince = now;
                    else if (now - goodSince >= RecoveryAfterSeconds)
                    {
                        Paused = false;
                        goodSince = -1f;
                        Reason = "帧率恢复，重新开启观察层";
                        Debug.Log("[XIANXIA-V12] OBSERVER_PERF_RECOVERED");
                    }
                }
                else goodSince = -1f;
            }
        }

        public static float SampleInterval()
        {
            // Larger worlds imply extra work / higher allocation churn.
            // Only change OUR sampling frequency, not main simulation.
            if (Paused) return 5f;
            if (SmoothedFps < 32f) return 3f;
            if (SmoothedFps < 48f) return 1.5f;
            return 0.8f;
        }

        public static int ClampRadius(int requested)
        {
            int safe = Mathf.Clamp(requested, 3, 9);
            if (SmoothedFps < 32f) return Math.Min(safe, 4);
            if (SmoothedFps < 45f) return Math.Min(safe, 6);
            return safe;
        }

        public static bool AcceptLargeMapCandidate(int chunks)
        {
            // Registering candidates (not generating maps) is still opt-in.
            // No proof of RAM/thermal headroom is available from this callback.
            if (chunks <= 12) return true;
            if (Paused || SmoothedFps < 50f) return false;
            return chunks <= 16; // 20x20 requires separate device certification
        }

        public static void Reset()
        {
            Paused = false;
            SmoothedFps = 60f;
            lowSince = -1f;
            goodSince = -1f;
            Reason = "用户重置观察层性能保护";
        }
    }
}
