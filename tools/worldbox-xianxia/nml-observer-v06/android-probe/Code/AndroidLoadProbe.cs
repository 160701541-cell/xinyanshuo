using System;
using NeoModLoader.api;
using UnityEngine;

namespace XianxiaWorldBox
{
    /// <summary>
    /// Minimal P0 mobile loader probe. Read-only, never patches save/terrain/actor.
    /// This verifies Android NML source compilation, UI dispatch and genuine
    /// World.world tile reads before loading the larger private observer candidate.
    /// </summary>
    public sealed class AndroidLoadProbe : BasicMod<AndroidLoadProbe>
    {
        private bool _visible;
        private string _status = "尚未采样";
        private float _nextTick;
        private int _sampleCount;
        protected override void OnModLoad()
        {
            Debug.Log("[XIANXIA-PROBE] ON_LOAD version=" + Application.version);
            if (!Application.version.StartsWith("0.51.", StringComparison.Ordinal))
                _status = "版本未验收 / unsupported";
        }
        private void Update()
        {
            if (!_visible || Time.unscaledTime < _nextTick) return;
            _nextTick = Time.unscaledTime + 1f;
            try
            {
                if (World.world == null || World.world.camera == null)
                {
                    _status = "没有打开WorldBox世界";
                    return;
                }
                Vector3 center = World.world.camera.transform.position;
                int x = Mathf.RoundToInt(center.x);
                int y = Mathf.RoundToInt(center.y);
                WorldTile tile = World.world.GetTile(x, y);
                _status = tile == null ? "中心超出地图" : "真实地图 " + x + "," + y;
                if (tile != null && _sampleCount++ == 0)
                    Debug.Log("[XIANXIA-PROBE] REAL_WORLD_TILE " + x + "," + y);
            }
            catch (Exception ex)
            {
                _status = "读取失败: " + ex.GetType().Name;
                Debug.LogWarning("[XIANXIA-PROBE] exception: " + ex);
            }
        }
        private void OnGUI()
        {
            try
            {
                var rect = new Rect(Screen.width - 168, 72, 158, 46);
                if (GUI.Button(rect, _visible ? "收起万界观测" : "万界观测"))
                {
                    _visible = !_visible;
                    _nextTick = 0f;
                    Debug.Log("[XIANXIA-PROBE] GUI_" + (_visible ? "OPEN" : "CLOSED"));
                }
                if (_visible)
                    GUI.Box(new Rect(Screen.width - 250, 125, 240, 80),
                            "世界盒子 0.51.x 只读探针\n" + _status);
            }
            catch (Exception ex) { Debug.LogWarning("[XIANXIA-PROBE] GUI: " + ex.GetType().Name); }
        }
    }
}
