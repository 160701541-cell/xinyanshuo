// Metadata-only inspection of public AndroidModLoader reference files.
// No APK, save or third-party DLL is copied to the public repository.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection.Metadata;
using System.Reflection.PortableExecutable;
using System.Text.Json;

if(args.Length!=2)throw new ArgumentException("Usage: LocaleTypes <public Assembly-CSharp.dll> <public NML mobile DLL>");
var results=new List<object>();
foreach(var filename in args)
{
    using var input=File.OpenRead(filename);
    using var pe=new PEReader(input);
    if(!pe.HasMetadata)throw new InvalidDataException("No .NET metadata in public reference "+Path.GetFileName(filename));
    var md=pe.GetMetadataReader();
    foreach(var h in md.TypeDefinitions)
    {
        var def=md.GetTypeDefinition(h);
        var full=(md.GetString(def.Namespace)+"."+md.GetString(def.Name)).Trim('.');
        bool relevant=full=="LocalizedTextManager"||
            full=="NeoModLoader.General.LM"||
            full.EndsWith(".LocalizedTextManager",StringComparison.Ordinal)||
            full.EndsWith(".LocalizedText",StringComparison.Ordinal);
        if(!relevant)continue;
        var methods=def.GetMethods().Select(v=>md.GetString(md.GetMethodDefinition(v).Name)).Distinct().Order().ToArray();
        var fields=def.GetFields().Select(v=>md.GetString(md.GetFieldDefinition(v).Name)).Order().ToArray();
        var properties=def.GetProperties().Select(v=>md.GetString(md.GetPropertyDefinition(v).Name)).Order().ToArray();
        results.Add(new {assembly=Path.GetFileName(filename),type=full,methods,fields,properties});
    }
}
Console.WriteLine(JsonSerializer.Serialize(new {
 source="public AndroidModLoader SDK reference metadata only",
 note="Source API shape only; not the user-owned WorldBox 0.51.4 APK or a runtime test.",
 items=results
},new JsonSerializerOptions{WriteIndented=true}));
