using System;
using System.IO;
using System.Text;
using UnityEngine;

namespace XianxiaMonoBridge {
public static class DiagnosticLog {
    static readonly object Gate=new object();
    static string directory,path;
    static bool installed;
    static int regularCount;
    const long MaximumBytes=1024*1024;
    public static void Install(){
        lock(Gate){
            if(installed)return;
            try{
                directory=Path.Combine(Application.persistentDataPath,"WorldBoxXianxiaLogs");
                Directory.CreateDirectory(directory);
                path=Path.Combine(directory,"session.log");
                string previous=Path.Combine(directory,"previous.log");
                if(File.Exists(path)){
                    if(File.Exists(previous))File.Delete(previous);
                    File.Move(path,previous);
                }
                installed=true;
                Application.logMessageReceivedThreaded+=Receive;
                AppDomain.CurrentDomain.UnhandledException+=Unhandled;
                Write("MONO_DIAGNOSTICS_READY v16 game="+Application.version+
                    " unity="+Application.unityVersion+" model="+SystemInfo.deviceModel+
                    " gpu="+SystemInfo.graphicsDeviceName+" data="+Application.persistentDataPath);
            }catch(Exception){installed=false;}
        }
    }
    static void Unhandled(object sender,UnhandledExceptionEventArgs args){
        Write("MANAGED_UNHANDLED terminating="+args.IsTerminating+"\n"+args.ExceptionObject);
    }
    static void Receive(string message,string stack,LogType kind){
        if(kind==LogType.Log && message.IndexOf("XIANXIA",StringComparison.OrdinalIgnoreCase)<0 &&
           message.IndexOf("NML",StringComparison.OrdinalIgnoreCase)<0 &&
           message.IndexOf("Sakuga",StringComparison.OrdinalIgnoreCase)<0 &&
           message.IndexOf("Frontiers",StringComparison.OrdinalIgnoreCase)<0){
            lock(Gate){if(++regularCount>200)return;}
        }
        Write(kind+" "+message+"\n"+stack);
    }
    public static void Write(string message){
        lock(Gate){
            if(!installed||path==null)return;
            try{
                if(message.Length>16000)message=message.Substring(0,16000)+" [truncated]";
                if(File.Exists(path)&&new FileInfo(path).Length>MaximumBytes){
                    string rotated=Path.Combine(directory,"rotated.log");
                    if(File.Exists(rotated))File.Delete(rotated);
                    File.Move(path,rotated);
                }
                File.AppendAllText(path,DateTime.UtcNow.ToString("o")+" "+message+"\n",Encoding.UTF8);
            }catch(Exception){ }
        }
    }
    public static string Read(){
        lock(Gate){
            try{
                var text=new StringBuilder("WorldBox万界仙侠 v16 MOD整合日志\n");
                foreach(string name in new[]{"previous.log","rotated.log","session.log"}){
                    string file=Path.Combine(directory,name);
                    if(!File.Exists(file))continue;
                    using(var stream=new FileStream(file,FileMode.Open,FileAccess.Read,FileShare.ReadWrite)){
                        if(stream.Length>24000)stream.Seek(-24000,SeekOrigin.End);
                        using(var reader=new StreamReader(stream,Encoding.UTF8))text.Append("\n=== "+name+" ===\n"+reader.ReadToEnd());
                    }
                }
                return text.ToString();
            }catch(Exception e){return "日志读取失败："+e.GetType().Name;}
        }
    }
}
}
