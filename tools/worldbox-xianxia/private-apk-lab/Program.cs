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
    case "audit-mod-api":
     if(args.Length<3)throw new ArgumentException("audit-mod-api mod.dll exact-reference-dir");
     AuditModApi(args[1],args[2]);return 0;
    case "publicize-reference":
     if(args.Length<3)throw new ArgumentException("publicize-reference input.dll reference-only.dll");
     PublicizeReference(args[1],args[2]);return 0;
    case "compile-tree":
     if(args.Length<4)throw new ArgumentException("compile-tree source-dir references-dir output.dll");
     CompileTree(args[1],args[2],args[3]);return 0;
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
 static void PublicizeReference(string source,string output){
   if(Path.GetFullPath(source)==Path.GetFullPath(output))throw new ArgumentException("Never replace input");
   using var module=dnlib.DotNet.ModuleDefMD.Load(source);
   foreach(var t in module.GetTypes()){
     if(t.Name=="<Module>")continue;
     t.Attributes=(t.Attributes & ~dnlib.DotNet.TypeAttributes.VisibilityMask) |
       (t.IsNested?dnlib.DotNet.TypeAttributes.NestedPublic:dnlib.DotNet.TypeAttributes.Public);
     foreach(var f in t.Fields)
       f.Attributes=(f.Attributes & ~dnlib.DotNet.FieldAttributes.FieldAccessMask)|dnlib.DotNet.FieldAttributes.Public;
     foreach(var m in t.Methods)
       m.Attributes=(m.Attributes & ~dnlib.DotNet.MethodAttributes.MemberAccessMask)|dnlib.DotNet.MethodAttributes.Public;
   }
   module.Write(output);
   Console.WriteLine("REFERENCE_ONLY_PUBLICIZED; never ship as original game "+output);
 }
 static void CompileTree(string sourceDir,string refDir,string output){
   var paths=Directory.GetFiles(sourceDir,"*.cs",SearchOption.AllDirectories).OrderBy(x=>x).ToArray();
   if(paths.Length==0)throw new InvalidOperationException("No C# sources");
   var parse=new CSharpParseOptions(LanguageVersion.Preview,preprocessorSymbols:new[]{"NML_ANDROID"});
   var trees=paths.Select(p=>CSharpSyntaxTree.ParseText(File.ReadAllText(p),parse,p));
   var refs=new List<MetadataReference>();
   foreach(var p in Directory.GetFiles(refDir,"*.dll"))
     try{refs.Add(MetadataReference.CreateFromFile(p));}catch(BadImageFormatException){}
   var c=CSharpCompilation.Create(Path.GetFileNameWithoutExtension(output),trees,refs,
     new CSharpCompilationOptions(OutputKind.DynamicallyLinkedLibrary,optimizationLevel:OptimizationLevel.Release,
        allowUnsafe:true,deterministic:true));
   using var stream=File.Create(output);var emit=c.Emit(stream);
   foreach(var d in emit.Diagnostics.Where(d=>d.Severity==DiagnosticSeverity.Error))Console.WriteLine(d);
   if(!emit.Success)throw new InvalidOperationException("Exact reference MOD compile failed");
   Console.WriteLine("PASS_EXACT_REFERENCE_MOD_COMPILE files="+paths.Length+" "+output);
 }
 static void AuditModApi(string path,string refDir){
   var resolver=new dnlib.DotNet.AssemblyResolver();
   resolver.PreSearchPaths.Add(Path.GetFullPath(refDir));
   var context=new dnlib.DotNet.ModuleContext(resolver);
   resolver.DefaultModuleContext=context;
   using var module=dnlib.DotNet.ModuleDefMD.Load(path,context);
   int checkedMembers=0;var missing=new List<string>();
   foreach(var member in module.GetMemberRefs()){
     string scope=member.DeclaringType.Scope?.ToString()??"";
     if(!scope.StartsWith("Assembly-CSharp,")&&!scope.StartsWith("NeoModLoader,"))continue;
     checkedMembers++;
     try{
       bool resolved=member.IsMethodRef?member.ResolveMethod()!=null:member.ResolveField()!=null;
       if(!resolved)missing.Add(member.FullName);
     }catch(Exception e){missing.Add(member.FullName+" "+e.GetType().Name);}
   }
   foreach(var value in missing)Console.WriteLine("MISSING_API "+value);
   Console.WriteLine("MOD_API_AUDIT checked="+checkedMembers+" missing="+missing.Count);
   if(missing.Count!=0)throw new InvalidOperationException("Mod references unavailable exact-game APIs");
 }
 static void Patch(string original,string plugin,string output) {
    var mod=dnlib.DotNet.ModuleDefMD.Load(original);
    var addon=dnlib.DotNet.ModuleDefMD.Load(plugin);
    var target=mod.Types.FirstOrDefault(x=>x.Name=="MapBox")??
        throw new InvalidOperationException("No MapBox in original");
    var start=target.Methods.FirstOrDefault(x=>x.Name=="Start" &&
        x.MethodSig.Params.Count==0 && !x.IsStatic && x.HasBody) ??
        throw new InvalidOperationException("No MapBox.Start()");
    if(start.Body.Instructions.Any(x=>x.Operand?.ToString()?.Contains("XianxiaMonoBridge")==true))
        throw new InvalidOperationException("Already injected");
    var entry=addon.Types.FirstOrDefault(x=>x.FullName=="XianxiaMonoBridge.Entry");
    if(entry?.Methods.FirstOrDefault(x=>x.Name=="Install"&&x.IsPublic&&x.IsStatic)==null)
        throw new InvalidOperationException("Missing public original Mono overlay bootstrap");
    var reference=new dnlib.DotNet.AssemblyRefUser(addon.Assembly);
    // dnlib emits the assembly reference through the reachable TypeRef below.
    // ModuleDefMD exposes GetAssemblyRefs(), not a mutable AssemblyRefs list.
    var typeRef=new dnlib.DotNet.TypeRefUser(mod,"XianxiaMonoBridge","Entry",reference);
    var methodRef=new dnlib.DotNet.MemberRefUser(mod,"Install",
        dnlib.DotNet.MethodSig.CreateStatic(mod.CorLibTypes.Void),typeRef);
    start.Body.Instructions.Insert(0,
        dnlib.DotNet.Emit.Instruction.Create(dnlib.DotNet.Emit.OpCodes.Call,methodRef));
    // Discord's desktop SDK is absent on Android. Keep the original method and
    // exception regions intact; only add a platform guard before its first IL.
    var discord=mod.Types.Single(x=>x.Name=="DiscordTracker").Methods.Single(x=>
        x.Name=="Start"&&!x.IsStatic&&x.MethodSig.Params.Count==0&&x.HasBody);
    var guard=new dnlib.DotNet.MemberRefUser(mod,"SkipDesktopDiscord",
        dnlib.DotNet.MethodSig.CreateStatic(mod.CorLibTypes.Boolean),typeRef);
    var originalFirst=discord.Body.Instructions[0];
    discord.Body.Instructions.Insert(0,dnlib.DotNet.Emit.Instruction.Create(dnlib.DotNet.Emit.OpCodes.Call,guard));
    discord.Body.Instructions.Insert(1,dnlib.DotNet.Emit.Instruction.Create(dnlib.DotNet.Emit.OpCodes.Brfalse,originalFirst));
    discord.Body.Instructions.Insert(2,dnlib.DotNet.Emit.Instruction.Create(dnlib.DotNet.Emit.OpCodes.Ret));
    // dnlib writes without Cecil resolving netstandard forwarded type constants.
    mod.Write(output);
    Console.WriteLine("PASS_MONO_PATCHED MapBox.Start bootstrap + DiscordTracker.Start Android guard "+output);
 }
 static void Verify(string original,string patched,string plugin) {
    var a=dnlib.DotNet.ModuleDefMD.Load(original);
    var b=dnlib.DotNet.ModuleDefMD.Load(patched);
    var p=dnlib.DotNet.ModuleDefMD.Load(plugin);
    var aa=a.Types.First(x=>x.Name=="MapBox").Methods.First(x=>x.Name=="Start").Body.Instructions;
    var bb=b.Types.First(x=>x.Name=="MapBox").Methods.First(x=>x.Name=="Start").Body.Instructions;
    if(bb.Count!=aa.Count+1 ||
       bb[0].OpCode!=dnlib.DotNet.Emit.OpCodes.Call ||
       !bb[0].Operand.ToString().Contains("XianxiaMonoBridge.Entry::Install"))
       throw new InvalidOperationException("Bootstrap IL not isolated at MapBox.Start prologue");
    // Branch operands print byte offsets, which shift after inserting the call.
    // Compare branch targets by instruction index and audit every original body.
    var at=a.GetTypes().ToArray(); var bt=b.GetTypes().ToArray();
    if(at.Length!=bt.Length)throw new InvalidOperationException("Original classes changed");
    int checkedMethods=0;
    for(int ti=0;ti<at.Length;ti++){
      if(at[ti].FullName!=bt[ti].FullName || at[ti].Methods.Count!=bt[ti].Methods.Count)
        throw new InvalidOperationException("Original type/method set changed");
      for(int mi=0;mi<at[ti].Methods.Count;mi++){
        var am=at[ti].Methods[mi];var bm=bt[ti].Methods[mi];
        if(am.FullName!=bm.FullName || am.HasBody!=bm.HasBody)
          throw new InvalidOperationException("Original method signature changed");
        if(!am.HasBody)continue;
        int skip=am.DeclaringType.Name=="MapBox"&&am.Name=="Start"&&am.MethodSig.Params.Count==0?1:0;
        if(am.DeclaringType.Name=="DiscordTracker"&&am.Name=="Start"&&am.MethodSig.Params.Count==0){
          var di=bm.Body.Instructions;
          if(di.Count!=am.Body.Instructions.Count+3 || di[0].OpCode!=dnlib.DotNet.Emit.OpCodes.Call ||
             !di[0].Operand.ToString().Contains("XianxiaMonoBridge.Entry::SkipDesktopDiscord") ||
             di[1].OpCode!=dnlib.DotNet.Emit.OpCodes.Brfalse || di[1].Operand!=di[3] ||
             di[2].OpCode!=dnlib.DotNet.Emit.OpCodes.Ret)
            throw new InvalidOperationException("Invalid Android Discord guard");
          skip=3;
        }
        if(!CanonicalBody(am,0).SequenceEqual(CanonicalBody(bm,skip)))
          throw new InvalidOperationException("Original IL or exception regions diverged: "+am.FullName);
        checkedMethods++;
      }
    }
    if(!b.GetAssemblyRefs().Any(x=>x.Name==p.Assembly.Name))
        throw new InvalidOperationException("Companion Mono assembly ref missing");
    Console.WriteLine("PASS_ONLY_BOOTSTRAP_AND_ANDROID_DISCORD_GUARD auditedMethodBodies="+checkedMethods+" startupInstructions="+aa.Count);
 }
 static IEnumerable<string> CanonicalBody(dnlib.DotNet.MethodDef method,int skip){
    var body=method.Body;var ins=body.Instructions;
    int Index(dnlib.DotNet.Emit.Instruction i)=>i==null?-1:ins.IndexOf(i)-skip;
    string Operand(object o)=>o switch {
      dnlib.DotNet.Emit.Instruction i=>"target:"+Index(i),
      IList<dnlib.DotNet.Emit.Instruction> targets=>"targets:"+string.Join(",",targets.Select(Index)),
      _=>o?.ToString()??""
    };
    yield return "initLocals:"+body.InitLocals;
    foreach(var local in body.Variables)yield return "local:"+local.Type.FullName;
    foreach(var i in ins.Skip(skip))yield return i.OpCode+" "+Operand(i.Operand);
    foreach(var eh in body.ExceptionHandlers)
      yield return "handler:"+eh.HandlerType+":"+Index(eh.TryStart)+":"+Index(eh.TryEnd)+":"+
        Index(eh.HandlerStart)+":"+Index(eh.HandlerEnd)+":"+Index(eh.FilterStart)+":"+eh.CatchType?.FullName;
 }
 static void CecilPatch(string original,string plugin,string output) {
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
 static void CecilVerify(string original,string patched,string plugin) {
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
