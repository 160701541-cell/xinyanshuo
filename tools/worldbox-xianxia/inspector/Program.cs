// Safe offline metadata reader. Does NOT execute WorldBox, modify APK or publish DLLs.
using System.Reflection.PortableExecutable;
using System.Reflection.Metadata;
using System.Text.Json;
using System.Linq;
using System.Collections.Generic;
using System.IO;
var location = args.Length > 0 ? args[0] : throw new ArgumentException("Pass public WorldBox reference Assembly-CSharp.dll");
using var file=File.OpenRead(location);
using var pe = new PEReader(file);
var md=pe.GetMetadataReader();
var result = new List<object>();
foreach (var h in md.TypeDefinitions) {
    var td=md.GetTypeDefinition(h);
    var name=md.GetString(td.Name);
    if (!new[]{"MapSize","MapGenerator","MapBox","MapSizeAsset","WorldGenerator"}.Any(s=>name.Contains(s,StringComparison.OrdinalIgnoreCase)))continue;
    var methods = td.GetMethods().Select(x=>md.GetString(md.GetMethodDefinition(x).Name)).ToArray();
    var fields = td.GetFields().Select(x=>md.GetString(md.GetFieldDefinition(x).Name)).ToArray();
    var props = td.GetProperties().Select(x=>md.GetString(md.GetPropertyDefinition(x).Name)).ToArray();
    result.Add(new {type=name,namespace_name=md.GetString(td.Namespace),methods,fields,properties=props});
}
Console.WriteLine(JsonSerializer.Serialize(new {source="public WorldBoxOpenMods Android reference assembly",note="metadata names only / not user APK or runtime",types=result},new JsonSerializerOptions{WriteIndented=true}));
