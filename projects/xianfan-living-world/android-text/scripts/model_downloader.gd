extends Node
class_name XianfanModelDownloader

# Godot 4.6: HTTPRequest lacks append_to_download_file. Every HTTP 206 chunk
# goes into a separate 8 MiB scratch file, then is validated and appended to
# an ordinary file. A crash never treats an incomplete chunk as complete.
signal progress(bytes_done: int, bytes_total: int, state: String)
signal completed(local_path: String)
signal failed(reason: String)
const STORE := "user://models"
const CHUNK_BYTES := 8*1024*1024
const MAX_RETRIES := 5
const KNOWN_SHA256 := {
    "hf://Qwen/Qwen3-8B-GGUF/Qwen3-8B-Q4_K_M.gguf":"d98cdcbd03e17ce47681435b5150e34c1417f50b5c0019dd560e4882c5745785",
    "hf://Qwen/Qwen3-14B-GGUF/Qwen3-14B-Q4_K_M.gguf":"500a8806e85ee9c83f3ae08420295592451379b4f8cf2d0f41c15dffeb6b81f0"
}
var http: HTTPRequest
var meter: Timer
var active := false
var paused := false
var source := ""
var url := ""
var final_path := ""
var partial_path := ""
var chunk_path := ""
var metadata_path := ""
var total_bytes := 0
var completed_bytes := 0
var expected_etag := ""
var retry_count := 0
var step_generation := 0
var reported_state := "未开始"

static func resolve_source(source_path: String) -> String:
    if source_path.begins_with("https://") and source_path.to_lower().contains(".gguf"):
        return source_path
    if not source_path.begins_with("hf://"): return ""
    var parts:=source_path.trim_prefix("hf://").split("/")
    if parts.size()!=3 or not str(parts[2]).to_lower().ends_with(".gguf"): return ""
    for part in parts:
        if str(part).is_empty() or ".." in str(part) or "?" in str(part) or "#" in str(part): return ""
    return "https://huggingface.co/%s/%s/resolve/main/%s?download=true" % [parts[0],parts[1],parts[2]]

static func parse_content_range(headers: PackedStringArray) -> Dictionary:
    for line in headers:
        if not line.to_lower().begins_with("content-range:"): continue
        var value:=line.substr(line.find(":")+1).strip_edges().trim_prefix("bytes ")
        var halves:=value.split("/")
        if halves.size()!=2 or halves[1]=="*": return {}
        var interval:=str(halves[0]).split("-")
        if interval.size()!=2: return {}
        if not str(interval[0]).is_valid_int() or not str(interval[1]).is_valid_int() or not str(halves[1]).is_valid_int():
            return {}
        var a:=int(interval[0])
        var b:=int(interval[1])
        var size:=int(halves[1])
        if a<0 or b<a or size<=b: return {}
        return {"start":a,"end":b,"total":size}
    return {}

static func header_value(headers: PackedStringArray, name: String) -> String:
    var prefix:=name.to_lower()+":"
    for line in headers:
        if line.to_lower().begins_with(prefix):
            return line.substr(line.find(":")+1).strip_edges()
    return ""

static func progress_percent(bytes_done: int, bytes_total: int) -> float:
    if bytes_total<=0: return -1.0
    return clampf(float(bytes_done)*100.0/float(bytes_total),0.0,100.0)

func _ready() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORE))
    http=HTTPRequest.new()
    http.max_redirects=10
    http.use_threads=true
    http.timeout=100.0
    http.accept_gzip=false
    add_child(http)
    http.request_completed.connect(_on_request_completed)
    meter=Timer.new()
    meter.wait_time=0.3
    meter.timeout.connect(_update_meter)
    add_child(meter)

func _locations(address: String) -> Dictionary:
    var key:=address.sha256_text().substr(0,24)
    return {"final":STORE+"/"+key+".gguf",
        "partial":STORE+"/"+key+".gguf.part",
        "chunk":STORE+"/"+key+".chunk",
        "meta":STORE+"/"+key+".json"}

func cached_path(address: String) -> String:
    var files:=_locations(address)
    var path:=str(files["final"])
    if FileAccess.file_exists(path):
        var f:=FileAccess.open(path,FileAccess.READ)
        if f!=null and f.get_length()>=1024 and f.get_buffer(4).get_string_from_ascii()=="GGUF": return path
    return ""

func pending_bytes(address: String) -> int:
    var files:=_locations(address)
    var sidecar:=str(files["meta"])
    if not FileAccess.file_exists(sidecar): return 0
    var f:=FileAccess.open(sidecar,FileAccess.READ)
    if f==null: return 0
    var parsed: Variant=JSON.parse_string(f.get_as_text())
    if not (parsed is Dictionary) or str(parsed.get("source",""))!=address: return 0
    if not FileAccess.file_exists(str(files["partial"])): return 0
    return int(FileAccess.get_file_as_bytes(str(files["partial"])).size()) if false else _file_size(str(files["partial"]))

func _file_size(path: String) -> int:
    if not FileAccess.file_exists(path): return 0
    var f:=FileAccess.open(path,FileAccess.READ)
    return int(f.get_length()) if f!=null else 0

func _persist_meta() -> void:
    var meta:=FileAccess.open(metadata_path,FileAccess.WRITE)
    if meta!=null:
        meta.store_string(JSON.stringify({"source":source,"url":url,"total":total_bytes,
            "etag":expected_etag,"resume":true}))
        meta.flush()

func _progress(state: String) -> void:
    reported_state=state
    var transferred:=http.get_downloaded_bytes() if active and http!=null else 0
    var done:=completed_bytes+maxi(0,int(transferred))
    progress.emit(done,total_bytes,state)

func _update_meter() -> void:
    if active and http!=null:
        _progress("正在下载")

func begin(address: String) -> bool:
    if active: return false
    var target:=resolve_source(address)
    if target.is_empty():
        failed.emit("仅支持可直接下载GGUF的HTTPS链接，或含GGUF文件名的hf://仓库路径。")
        return false
    source=address
    url=target
    var paths:=_locations(address)
    final_path=str(paths["final"])
    partial_path=str(paths["partial"])
    chunk_path=str(paths["chunk"])
    metadata_path=str(paths["meta"])
    if not cached_path(address).is_empty():
        completed.emit(cached_path(address))
        return true
    var previous: Dictionary={}
    if FileAccess.file_exists(metadata_path):
        var f:=FileAccess.open(metadata_path,FileAccess.READ)
        if f!=null:
            var parsed: Variant=JSON.parse_string(f.get_as_text())
            if parsed is Dictionary: previous=parsed
    if previous.has("source") and str(previous["source"])!=source:
        failed.emit("下载元数据与模型地址不匹配，拒绝混合不同文件。")
        return false
    if not previous.is_empty():
        total_bytes=int(previous.get("total",0))
        expected_etag=str(previous.get("etag",""))
    else:
        if FileAccess.file_exists(partial_path):
            failed.emit("发现无元信息的部分文件，拒绝盲目续传。请清理该模型缓存再重试。")
            return false
        total_bytes=0
        expected_etag=""
        _persist_meta()
    completed_bytes=_file_size(partial_path)
    if total_bytes>0 and completed_bytes>total_bytes:
        failed.emit("缓存文件长度大于服务端总长度，拒绝继续。")
        return false
    if FileAccess.file_exists(chunk_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(chunk_path))
    paused=false
    active=true
    retry_count=0
    step_generation+=1
    meter.start()
    _progress("恢复下载" if completed_bytes>0 else "开始下载")
    if total_bytes>0 and completed_bytes==total_bytes:
        call_deferred("_validate_and_finish")
    else:
        call_deferred("_next_chunk")
    return true

func pause() -> void:
    if not active: return
    paused=true
    active=false
    step_generation+=1
    if http!=null: http.cancel_request()
    meter.stop()
    _persist_meta()
    progress.emit(completed_bytes,total_bytes,"已暂停，断点已保留")

func _retry(reason: String) -> void:
    if not active: return
    retry_count+=1
    if retry_count>MAX_RETRIES:
        active=false
        meter.stop()
        _persist_meta()
        failed.emit("%s；已自动重试%d次，缓存保留。再次点击继续将从已完成位置下载。" % [reason,MAX_RETRIES])
        return
    _progress("连接中断，%d秒后自动续传（第%d/%d次）" % [mini(30,1<<mini(retry_count,4)),retry_count,MAX_RETRIES])
    var snapshot:=step_generation
    await get_tree().create_timer(mini(30,1<<mini(retry_count,4))).timeout
    if active and not paused and snapshot==step_generation: _next_chunk()

func _next_chunk() -> void:
    if not active or paused: return
    var start:=completed_bytes
    if total_bytes>0 and start>=total_bytes:
        _validate_and_finish()
        return
    var last:=start+CHUNK_BYTES-1
    if total_bytes>0: last=mini(last,total_bytes-1)
    if FileAccess.file_exists(chunk_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(chunk_path))
    http.download_file=chunk_path
    var headers:=PackedStringArray([
        "Range: bytes=%d-%d" % [start,last],
        "Accept-Encoding: identity",
        "User-Agent: XianfanCanglan/1.0"
    ])
    if not expected_etag.is_empty() and start>0:
        headers.append("If-Range: "+expected_etag)
    var e:=http.request(url,headers,HTTPClient.METHOD_GET)
    if e!=OK: _retry("启动HTTP请求失败，代码%d" % int(e))

func _on_request_completed(result: int, status: int, headers: PackedStringArray, _body: PackedByteArray) -> void:
    if not active or paused: return
    if result!=HTTPRequest.RESULT_SUCCESS:
        _retry("下载连接失败，网络错误码%d，HTTP %d" % [result,status])
        return
    if status==401 or status==403:
        _retry("模型访问被拒绝HTTP %d，请检查登录/仓库可用性" % status)
        return
    if status!=206:
        # Some sources return full 200 despite Range; never append it, and
        # never silently show 100% for the wrong file.
        _retry("服务器返回HTTP %d，不支持可靠的字节范围下载" % status)
        return
    var range:=parse_content_range(headers)
    if range.is_empty() or int(range["start"])!=completed_bytes:
        _retry("Content-Range起点与本地断点不一致，已拒绝拼接")
        return
    var expected_length:=int(range["end"])-int(range["start"])+1
    var saved_length:=_file_size(chunk_path)
    if expected_length!=saved_length or saved_length>CHUNK_BYTES or saved_length<=0:
        _retry("分块长度不符：应收%d字节，实际%d字节" % [expected_length,saved_length])
        return
    if total_bytes>0 and total_bytes!=int(range["total"]):
        _retry("服务器文件大小变化，不能与旧模型缓存拼接")
        return
    var etag:=header_value(headers,"etag")
    if not expected_etag.is_empty() and not etag.is_empty() and etag!=expected_etag:
        _retry("ETag变化，下载来源版本发生改变")
        return
    if total_bytes==0:
        total_bytes=int(range["total"])
        expected_etag=etag
    # Append at most 8 MiB to disk, without retaining a multi-GB GGUF in RAM.
    var read:=FileAccess.open(chunk_path,FileAccess.READ)
    var target: FileAccess
    if FileAccess.file_exists(partial_path):
        target=FileAccess.open(partial_path,FileAccess.READ_WRITE)
    else:
        target=FileAccess.open(partial_path,FileAccess.WRITE_READ)
    if read==null or target==null:
        _retry("本地存储文件无法打开，检查空间与读写权限")
        return
    target.seek_end()
    var buffer:=read.get_buffer(expected_length)
    target.store_buffer(buffer)
    target.flush()
    target.close()
    read.close()
    if _file_size(partial_path)!=completed_bytes+expected_length:
        active=false
        meter.stop()
        failed.emit("存储写入长度校验失败，已停止以防损坏模型。")
        return
    completed_bytes+=expected_length
    retry_count=0
    _persist_meta()
    DirAccess.remove_absolute(ProjectSettings.globalize_path(chunk_path))
    _progress("分块保存完成")
    if completed_bytes>=total_bytes:
        _validate_and_finish()
    else:
        _next_chunk()

func _validate_and_finish() -> void:
    if not active: return
    meter.stop()
    var f:=FileAccess.open(partial_path,FileAccess.READ)
    if f==null or total_bytes<=0 or f.get_length()!=total_bytes:
        active=false
        failed.emit("文件长度不符，保留断点，但不会加载残缺模型。")
        return
    if f.get_buffer(4).get_string_from_ascii()!="GGUF":
        active=false
        failed.emit("文件头不是GGUF：下载链接可能返回错误页。缓存保留供诊断。")
        return
    f.close()
    # Check official SHA256 for Qwen3 8B/14B. Stream at 1 MiB per step.
    var checksum:=str(KNOWN_SHA256.get(source,""))
    if not checksum.is_empty():
        _progress("下载完成，校验SHA256完整性")
        var ctx:=HashingContext.new()
        ctx.start(HashingContext.HASH_SHA256)
        var stream:=FileAccess.open(partial_path,FileAccess.READ)
        while not stream.eof_reached():
            if paused or not active: return
            var bytes:=stream.get_buffer(1024*1024)
            if bytes.is_empty(): break
            ctx.update(bytes)
            if stream.get_position()%(64*1024*1024)<1024*1024:
                progress.emit(stream.get_position(),total_bytes,"正在校验完整性")
                await get_tree().process_frame
        stream.close()
        if ctx.finish().hex_encode().to_lower()!=checksum:
            active=false
            failed.emit("官方SHA256校验失败！拒绝加载此文件，需清理该模型缓存重新下载。")
            return
    var err:=DirAccess.rename_absolute(ProjectSettings.globalize_path(partial_path),
        ProjectSettings.globalize_path(final_path))
    if err!=OK:
        active=false
        failed.emit("完整模型文件重命名失败，错误码%d" % int(err))
        return
    if FileAccess.file_exists(metadata_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(metadata_path))
    active=false
    completed_bytes=total_bytes
    progress.emit(completed_bytes,total_bytes,"下载和文件校验完成")
    completed.emit(final_path)
