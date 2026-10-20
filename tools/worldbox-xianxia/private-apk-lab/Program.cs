using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Mono.Cecil;
using Mono.Cecil.Cil;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;

// Generic private-file toolkit. Operates on copies of USER-OWNED files only.
// No APK, third-party game DLL or paid features ever uploaded to public GitHub.
class Program {
 static int Main(string[] args) {
  try {
   if(args.Length<2){Console.Error.WriteLine("usage: inspect game.dll | compile source.cs references-dir output.dll | patch game.dll plugin.dll output.dll | verify before.dll after.dll");return 2;}
   switch(args[0]){
    case "inspect": Inspect(args[1]);return 0;
    case "compile":
     if(args.Length<4)throw new ArgumentException("compile source.cs managed-reference-dir output.dll");
     Compile(args[1],args[2],args[3]);return 0;
    case "patch":
     if(args.Length<4)throw new ArgumentException("patch game-Assembly-CSharp.dll original-plugin.dll patched.dll");
     Patch(args[1],args[2],args[3]);return 0;
    case "verify":
     if(args.Length<4)throw new ArgumentException("verify original.dll patched.dll plugin.dll");
     Verify(args[1],args[2],args[3]);return 0;
    default:throw new ArgumentException("bad mode");
   }
  }catch(Exception e){Console.Error.WriteLine("FAIL_PRIVATE_FILE_TOOLKIT: "+e);return 1;}
 }
 static TypeDefinition FindType(AssemblyDefinition a,string name) =>
     a.MainModule.Types.FirstOrDefault(t=>t.Name==name)
       ?? throw new InvalidOperationException("expected type not found: "+name);
 static MethodDefinition FindStartup(AssemblyDefinition a){
   var map=FindType(a,"MapBox");
   foreach(string name in new[]{"Start","Awake"})
   {
      var method=map.Methods.FirstOrDefault(m=>m.Name==name && m.Parameters.Count==0 && m.HasBody && !m.IsStatic);
      if(method!=null)return method;
   }
   throw new InvalidOperationException("MapBox lacks a safe startup method");
 }
 static ReaderParameters Resolved(string path){
   var resolver=new DefaultAssemblyResolver();
   resolver.AddSearchDirectory(Path.GetDirectoryName(Path.GetFullPath(path))!);
   resolver.AddSearchDirectory(AppContext.BaseDirectory);
   var refs=Environment.GetEnvironmentVariable("WORLD_BOX_MONO_REFS");
   if(!string.IsNullOrWhiteSpace(refs)&&Directory.Exists(refs))resolver.AddSearchDirectory(refs);
   return new ReaderParameters{ReadSymbols=false,InMemory=true,AssemblyResolver=resolver};
 }
 static void Inspect(string path){
  using var a=AssemblyDefinition.ReadAssembly(path,Resolved(path));
  Console.WriteLine("ASSEMBLY "+a.Name.FullName);
  foreach(string typeName in new[]{"MapBox","ModLoader","AssetModLoader","World"}){
    var type=a.MainModule.Types.FirstOrDefault(t=>t.Name==typeName);
    if(type==null)continue;
    Console.WriteLine("TYPE "+type.FullName+" base="+type.BaseType?.FullName);
    foreach(var m in type.Methods.Where(m=>new[]{"Awake","Start","OnEnable","LoadMods","loadMods","Update"}.Any(k=>m.Name.Contains(k,StringComparison.OrdinalIgnoreCase)))) {
      Console.WriteLine("  METHOD "+m.Name+" static="+m.IsStatic+" params="+m.Parameters.Count+" hasBody="+m.HasBody);
      if(m.HasBody)foreach(var ins in m.Body.Instructions.Take(25))Console.WriteLine("    "+ins.OpCode+" "+ins.Operand);
    }
  }
  var target=FindStartup(a);
  Console.WriteLine("PATCH_TARGET "+target.DeclaringType.FullName+"."+target.Name);
 }
 static void Compile(string source,string refDir,string output) {
   var files=Directory.GetFiles(refDir,"*.dll",SearchOption.TopDirectoryOnly);
   if(files.Length==0)throw new InvalidOperationException("no private Mono managed references");
   var refs=new List<MetadataReference>();
   foreach(var path in files)try{refs.Add(MetadataReference.CreateFromFile(path));}catch(BadImageFormatException){}
   var syntax=CSharpSyntaxTree.ParseText(File.ReadAllText(source));
   var c=CSharpCompilation.Create("WorldBoxXianxiaMonoBridge",new[]{syntax},refs,
        new CSharpCompilationOptions(OutputKind.DynamicallyLinkedLibrary,optimizationLevel:OptimizationLevel.Release));
   Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(output))!);
   using var stream=File.Create(output);
   var emit=c.Emit(stream);
   foreach(var d in emit.Diagnostics.Where(d=>d.Severity>=DiagnosticSeverity.Warning))Console.WriteLine(d.ToString());
   if(!emit.Success)throw new InvalidOperationException("private original-APK Mono reference compilation failed");
   Console.WriteLine("PASS_MONO_ORIGINAL_REFERENCE_COMPILE "+output);
 }
 static void Patch(string original,string plugin,string output) {
   using var game=AssemblyDefinition.ReadAssembly(original,Resolved(original));
   using var addon=AssemblyDefinition.ReadAssembly(plugin,Resolved(plugin));
   var entry=FindStartup(game);
   var addonEntry=addon.MainModule.Types.FirstOrDefault(t=>t.FullName=="XianxiaMonoBridge.Entry");
   var install=addonEntry?.Methods.FirstOrDefault(m=>m.Name=="Install"&&m.IsStatic&&m.Parameters.Count==0);
   if(install==null||!install.IsPublic)throw new InvalidOperationException("plugin must export XianxiaMonoBridge.Entry.Install()");
   if(entry.Body.Instructions.Any(x=>x.Operand?.ToString()?.Contains("XianxiaMonoBridge")==true))
     throw new InvalidOperationException("already patched");
   var asmref=game.MainModule.AssemblyReferences.FirstOrDefault(x=>x.Name==addon.Name.Name);
   if(asmref==null){
     asmref=new AssemblyNameReference(addon.Name.Name,addon.Name.Version);
     game.MainModule.AssemblyReferences.Add(asmref);
   }
   var t=new TypeReference("XianxiaMonoBridge","Entry",game.MainModule,asmref,false);
   var m=new MethodReference("Install",game.MainModule.TypeSystem.Void,t){HasThis=false};
   var processor=entry.Body.GetILProcessor();
   var first=entry.Body.Instructions.First();
   // Boot is an isolated try/catch inside original-plugin Install. This
   // modifies only the prologue of MapBox.Start and preserves all game IL.
   processor.InsertBefore(first,processor.Create(OpCodes.Call,m));
   game.MainModule.Mvid=Guid.NewGuid();
   Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(output))!);
   game.Write(output,new WriterParameters{WriteSymbols=false});
   Console.WriteLine("PATCHED_MAPBOX_START "+output+" game="+game.Name.Name+" plugin="+addon.Name.Name);
 }
 static void Verify(string original,string patched,string plugin) {
  using var a=AssemblyDefinition.ReadAssembly(original,Resolved(original));
  using var b=AssemblyDefinition.ReadAssembly(patched,Resolved(patched));
  using var p=AssemblyDefinition.ReadAssembly(plugin,Resolved(plugin));
  var aa=FindStartup(a).Body.Instructions.Select(x=>x.OpCode+" "+x.Operand).ToArray();
  var bb=FindStartup(b).Body.Instructions.Select(x=>x.OpCode+" "+x.Operand).ToArray();
  if(bb.Length!=aa.Length+1||!bb[0].Contains("XianxiaMonoBridge.Entry::Install"))throw new InvalidOperationException("patch hook not at startup");
  if(!bb.Skip(1).SequenceEqual(aa))throw new InvalidOperationException("original startup IL changed unexpectedly");
  var ac=a.MainModule.Types.ToDictionary(t=>t.FullName);
  var bc=b.MainModule.Types.ToDictionary(t=>t.FullName);
  if(ac.Count!=bc.Count||ac.Keys.Except(bc.Keys).Any())throw new InvalidOperationException("game type set modified");
  if(!b.MainModule.AssemblyReferences.Any(x=>x.Name==p.Name.Name))throw new InvalidOperationException("plugin ref missing");
  Console.WriteLine("PASS_GAME_IL_PATCH_SCOPE_CHECK mapBox-start-call-only original-inst-count="+aa.Length);
 }
}
