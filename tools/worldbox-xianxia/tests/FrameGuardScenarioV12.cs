using System;
using UnityEngine;
using XianxiaWorldBox;

static class FrameGuardScenarioV12
{
    static void Assert(bool p, string message)
    {
        if (!p) throw new Exception("FRAME_GUARD_TEST_FAILED: "+message);
    }
    static void Simulate(int frames, float delta)
    {
        Time.unscaledDeltaTime = delta;
        for (int i=0;i<frames;i++)
        {
            Time.unscaledTime += delta;
            ObserverFrameGuardV12.Tick();
        }
    }
    static int Main()
    {
        ObserverFrameGuardV12.Reset();
        Time.unscaledTime = 0f;
        Assert(!ObserverFrameGuardV12.Paused, "initially active");
        Assert(ObserverFrameGuardV12.SampleInterval()<=1.0f, "fast sample when healthy");
        Simulate(80, .1f);
        Assert(ObserverFrameGuardV12.Paused, "sustained <=10 FPS must suspend rendering");
        Assert(ObserverFrameGuardV12.SampleInterval()>=4f, "suspended sample interval");
        Assert(ObserverFrameGuardV12.ClampRadius(9)==4, "low FPS radius reduction");
        Assert(!ObserverFrameGuardV12.AcceptLargeMapCandidate(16),"no large world at low FPS");
        Assert(!ObserverFrameGuardV12.AcceptLargeMapCandidate(20),"20x20 is disabled");
        Assert(ObserverFrameGuardV12.AcceptLargeMapCandidate(12),"12x12 still candidate at registration");
        Simulate(900, .01f);
        Assert(!ObserverFrameGuardV12.Paused, "sustained >=100 FPS should recover");
        Assert(ObserverFrameGuardV12.AcceptLargeMapCandidate(16),"16x16 can be attempted after recovered high FPS");
        Assert(!ObserverFrameGuardV12.AcceptLargeMapCandidate(20),"20x20 never auto-enabled before device QA");
        Console.WriteLine("PASS_FRAME_GUARD_V12: low-FPS suspension, auto recovery, map-size safety");
        return 0;
    }
}
