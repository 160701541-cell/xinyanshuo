// Source-only SDK compatibility stubs. NEVER shipped as a real WorldBox mod.
// These validate C# syntax and our assumed signatures, not Android API linkage.
using System;
using System.Collections.Generic;
namespace NeoModLoader.api {
    public class BasicMod<T> {
        protected virtual void OnModLoad() {}
        protected static void Destroy(object o) {}
    }
}
namespace UnityEngine {
    public enum TextureFormat { RGBA32 }
    public enum FilterMode { Point }
    public enum TextureWrapMode { Clamp }
    public struct Color {
        public float r,g,b,a;
        public Color(float r,float g,float b,float a=1) { this.r=r;this.g=g;this.b=b;this.a=a; }
        public static Color white=>new Color(1,1,1);
        public static Color black=>new Color(0,0,0);
        public static Color clear=>new Color(0,0,0,0);
    }
    public struct Vector2 {
        public float x,y;
        public Vector2(float x,float y){this.x=x;this.y=y;}
    }
    public struct Vector3 {
        public float x,y,z;
        public Vector3(float x,float y,float z){this.x=x;this.y=y;this.z=z;}
    }
    public class Transform { public Vector3 position; }
    public class Camera { public Transform transform=new Transform(); }
    public class Texture2D {
        public FilterMode filterMode;
        public TextureWrapMode wrapMode;
        public Texture2D(int x,int y,TextureFormat f,bool mipmap) {}
        public void SetPixel(int x,int y,Color c) {}
        public void Apply(bool mipmap,bool noLongerReadable) {}
        public static Texture2D whiteTexture { get; }=new Texture2D(1,1,TextureFormat.RGBA32,false);
    }
    public struct Rect {
        public Rect(float x,float y,float width,float height) {}
    }
    public static class Screen { public static int width=1280,height=720; }
    public static class Time { public static float unscaledTime; }
    public static class Application { public static string version="0.51.4"; }
    public static class Debug {
        public static void Log(object msg){}
        public static void LogWarning(object msg){}
    }
    public static class GUI {
        public static Color color;
        public static bool Button(Rect r,string text){return false;}
        public static void Box(Rect r,string title){}
        public static void Label(Rect r,string text){}
        public static void DrawTexture(Rect r,Texture2D texture){}
    }
    public static class Mathf {
        public static float Abs(float x)=>Math.Abs(x);
        public static float Min(float x,float y)=>Math.Min(x,y);
        public static float Max(float x,float y)=>Math.Max(x,y);
        public static float Clamp(float x,float a,float b)=>Math.Max(a,Math.Min(x,b));
        public static int Clamp(int x,int a,int b)=>Math.Max(a,Math.Min(x,b));
        public static int RoundToInt(float x)=>(int)Math.Round(x);
    }
}
public class WorldTile {}
public class Actor {
    public UnityEngine.Vector2 current_position;
    public bool isAlive()=>true;
    public string getName()=> "mock";
}
public class UnitContainer {
    public IEnumerable<Actor> getSimpleList()=>Array.Empty<Actor>();
}
public class World {
    public static World world;
    public UnityEngine.Camera camera = new UnityEngine.Camera();
    public UnitContainer units=new UnitContainer();
    public Actor getActorNearCursor()=>null;
    public WorldTile GetTile(int x,int y)=>null;
}
public static class MapBox { public static int width=512,height=512; }
