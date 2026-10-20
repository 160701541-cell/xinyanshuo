using System;
using System.Reflection;
using UnityEngine;
namespace XianxiaWorldBox {
    public static class PixelFrameV30 {
        static Texture2D buttonFace;
        static Texture2D Face() {
            if(buttonFace!=null)return buttonFace;
            buttonFace=new Texture2D(8,8,TextureFormat.RGBA32,false);
            buttonFace.filterMode=FilterMode.Point;buttonFace.wrapMode=TextureWrapMode.Clamp;
            for(int y=0;y<8;y++)for(int x=0;x<8;x++){
                Color c=new Color(.23f,.27f,.23f,1f);
                if(x==0||y==0||x==7||y==7)c=new Color(.08f,.10f,.08f,1f);
                else if(x==1||y==6)c=new Color(.52f,.54f,.42f,1f);
                buttonFace.SetPixel(x,y,c);
            }
            buttonFace.Apply(false,true);return buttonFace;
        }
        // Only call on owned GUIStyle copies.
        public static void Button(GUIStyle style) {
            foreach(string key in new[]{"normal","hover","active","focused"}){
                var stateProp=style.GetType().GetProperty(key);
                object state=stateProp==null?null:stateProp.GetValue(style,null);
                if(state==null)continue;
                var background=state.GetType().GetProperty("background");
                if(background!=null&&background.CanWrite)background.SetValue(state,Face(),null);
            }
        }
        public static void Draw(Rect r) {
            Color before=GUI.color;
            try {
                GUI.color=new Color(.08f,.10f,.08f,1f);
                GUI.DrawTexture(r,Texture2D.whiteTexture);
                GUI.color=new Color(.48f,.50f,.38f,1f);
                GUI.DrawTexture(new Rect(r.x+3,r.y+3,r.width-6,r.height-6),Texture2D.whiteTexture);
                GUI.color=new Color(.15f,.19f,.15f,1f);
                GUI.DrawTexture(new Rect(r.x+6,r.y+6,r.width-12,r.height-12),Texture2D.whiteTexture);
            } finally {GUI.color=before;}
        }
    }
}
