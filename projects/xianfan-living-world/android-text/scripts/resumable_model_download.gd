extends Node
class_name XianfanResumableModelDownload

# Direct HTTPS streaming to a disk .part file. Unlike native hf:// loading,
# the downloader exposes real byte progress and retries partial downloads.
# A previous manifest grants consent to resume across app restarts.
signal progress(state: Dictionary)
signal completed(result: Dictionary)
const DIRECTORY := "user://gguf_cache"
const MAX_RETRIES := 5
const MAX_REDIRECTS := 8
const CONNECT_TIMEOUT_MS := 25000
const STALL_TIMEOUT_MS := 45000
const DISPLAY_INTERVAL_MS := 500
var active := false
var paused := false
var cancelled := false
var pending_source := ""
var last_progress: Dictionary={}
var _http: HTTPClient
var _started_ms := 0
var _last_tick_ms := 0
var _bytes_at_tick := 0
var _attempt := 0

static func source_url(src: String) -> String:
    if src.begins_with("https://"): return src
    if src.begins_with("hf://"):
        var tail:=src.trim_prefix("hf://")
        var paths:=tail.split("/",false)
        if paths.size()<3: return ""
        return "https://huggingface.co/%s/%s/resolve/main/%s?download=true" % [
            paths[0],paths[1],"/".join(Array(paths).slice(2))]
    return ""

static func range_start(header: String) -> int:
    # Parse Content-Range: bytes 1048576-2097151/5030000000.
    var text:=header.strip_edges()
    if not text.begins_with("bytes "): return -1
    var pieces:=text.trim_prefix("bytes ").split("-",false)
    if pieces.size()!=2: return -1
    if not pieces[0].is_valid_int(): return -1
    return int(pieces[0])

static func range_total(header: String) -> int:
    var pieces:=header.split("/",false)
    if pieces.size()!=2 or not pieces[1].is_valid_int(): return -1
    return int(pieces[1])

static func _headers_lower(headers: Dictionary) -> Dictionary:
    var lowered: Dictionary={}
    for key in headers:
        lowered[str(key).to_lower()]=str(headers[key])
    return lowered

func _name(source: String) -> String:
    return source.sha256_text().substr(0,24)

func final_path(source: String) -> String:
    return DIRECTORY+"/"+_name(source)+".gguf"

func partial_path(source: String) -> String:
    return final_path(source)+".part"

func manifest_path(source: String) -> String:
    return DIRECTORY+"/"+_name(source)+".json"

func _setup() -> bool:
    return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIRECTORY))==OK

func _manifest(source: String) -> Dictionary:
    var path:=manifest_path(source)
    if not FileAccess.file_exists(path): return {}
    var f:=FileAccess.open(path,FileAccess.READ)
    if f==null: return {}
    var json: Variant=JSON.parse_string(f.get_as_text())
    if json is Dictionary and str(json.get("source",""))==source: return json
    return {}

func _save_manifest(source: String, expected: int, state: String) -> void:
    if not _setup(): return
    var m: Dictionary={"source":source,"expected":expected,
        "bytes":current_bytes(source),"state":state,
        "date":Time.get_datetime_string_from_system(),"retry":_attempt}
    var f:=FileAccess.open(manifest_path(source),FileAccess.WRITE)
    if f!=null:
        f.store_string(JSON.stringify(m))

func current_bytes(source: String) -> int:
    var path:=partial_path(source)
    if not FileAccess.file_exists(path): return 0
    var f:=FileAccess.open(path,FileAccess.READ)
    if f==null: return 0
    return f.get_length()

func is_pending(source: String) -> bool:
    if source_url(source).is_empty(): return false
    var m:=_manifest(source)
    return not m.is_empty() and str(m.get("state","")) in ["downloading","paused","retrying","failed"] and current_bytes(source)>0

func _publish(source: String, bytes: int, expected: int, phase: String, error: String="") -> void:
    var now:=Time.get_ticks_msec()
    var elapsed:=maxf(0.001,float(now-_started_ms)/1000.0)
    var speed:=maxf(0.0,float(bytes-_bytes_at_tick)/maxf(0.1,float(now-_last_tick_ms)/1000.0))
    if now-_last_tick_ms>=DISPLAY_INTERVAL_MS:
        _last_tick_ms=now
        _bytes_at_tick=bytes
    last_progress={"source":source,"bytes":bytes,"total":expected,
        "fraction":float(bytes)/float(expected) if expected>0 else -1.0,
        "speed_bps":speed,"phase":phase,"attempt":_attempt,
        "elapsed_sec":elapsed,"error":error}
    progress.emit(last_progress.duplicate(true))

func _save_progress(source: String, total: int) -> void:
    _save_manifest(source,total,"paused" if paused else ("cancelled" if cancelled else "downloading"))

func pause() -> void:
    if not active: return
    paused=true
    if _http!=null: _http.close()
    _save_manifest(pending_source,int(last_progress.get("total",-1)),"paused")

func cancel() -> void:
    if not active: return
    cancelled=true
    paused=true
    if _http!=null: _http.close()
    _save_manifest(pending_source,int(last_progress.get("total",-1)),"paused")

func _wait_frame() -> void:
    await get_tree().process_frame

func _one_request(source: String, target: String, offset: int) -> Dictionary:
    var url:=source_url(source)
    var redirects:=0
    var last_error:=""
    while redirects<=MAX_REDIRECTS:
        if paused or cancelled: return {"ok":false,"reason":"paused","total":-1}
        # The resolver deliberately permits HTTPS redirects only.
        var parts:=_split_url(url)
        if parts.is_empty(): return {"ok":false,"reason":"invalid_https_url","total":-1}
        _http=HTTPClient.new()
        _http.read_chunk_size=65536
        var connect_error:=_http.connect_to_host(str(parts["host"]),int(parts["port"]),TLSOptions.client())
        if connect_error!=OK: return {"ok":false,"reason":"connect_error_"+str(connect_error),"total":-1}
        var began:=Time.get_ticks_msec()
        while _http.get_status() in [HTTPClient.STATUS_RESOLVING,HTTPClient.STATUS_CONNECTING]:
            if paused or cancelled: return {"ok":false,"reason":"paused","total":-1}
            var err:=_http.poll()
            if err!=OK: return {"ok":false,"reason":"connect_poll_"+str(err),"total":-1}
            if Time.get_ticks_msec()-began>CONNECT_TIMEOUT_MS:
                return {"ok":false,"reason":"connect_timeout","total":-1}
            await _wait_frame()
        if _http.get_status()!=HTTPClient.STATUS_CONNECTED:
            return {"ok":false,"reason":"tls_or_network_error_"+str(_http.get_status()),"total":-1}
        var headers:=PackedStringArray(["User-Agent: XianfanCanglan/1.0","Accept: application/octet-stream","Accept-Encoding: identity"])
        if offset>0: headers.append("Range: bytes=%d-" % offset)
        var request_err:=_http.request(HTTPClient.METHOD_GET,str(parts["path"]),headers)
        if request_err!=OK: return {"ok":false,"reason":"request_"+str(request_err),"total":-1}
        began=Time.get_ticks_msec()
        while not _http.has_response():
            if paused or cancelled: return {"ok":false,"reason":"paused","total":-1}
            var err:=_http.poll()
            if err!=OK: return {"ok":false,"reason":"headers_poll_"+str(err),"total":-1}
            if Time.get_ticks_msec()-began>STALL_TIMEOUT_MS:
                return {"ok":false,"reason":"response_timeout","total":-1}
            await _wait_frame()
        var status:=_http.get_response_code()
        var response_headers:=_headers_lower(_http.get_response_headers_as_dictionary())
        if status in [301,302,303,307,308]:
            var redirect:=str(response_headers.get("location",""))
            if redirect.begins_with("/"):
                url="https://"+str(parts["host"])+redirect
            elif redirect.begins_with("https://"):
                url=redirect
            else:
                return {"ok":false,"reason":"unsafe_redirect","total":-1}
            redirects+=1
            _http.close()
            continue
        if status==416:
            var remote_length:=range_total(str(response_headers.get("content-range","")))
            if remote_length>0 and remote_length==offset:
                return {"ok":true,"bytes":offset,"total":remote_length,"already_complete":true}
            return {"ok":false,"reason":"range_416","total":remote_length}
        if status not in [200,206]:
            return {"ok":false,"reason":"http_"+str(status),"total":-1}
        if offset>0 and status!=206:
            return {"ok":false,"reason":"server_ignored_range","total":-1}
        if status==206:
            var actual_start:=range_start(str(response_headers.get("content-range","")))
            if actual_start!=offset:
                return {"ok":false,"reason":"content_range_mismatch","total":-1}
        var response_bytes:=int(_http.get_response_body_length())
        var total:=range_total(str(response_headers.get("content-range","")))
        if total<=0 and response_bytes>=0: total=offset+response_bytes
        var f: FileAccess
        if offset>0:
            f=FileAccess.open(target,FileAccess.READ_WRITE)
            if f!=null: f.seek_end()
        else:
            f=FileAccess.open(target,FileAccess.WRITE)
        if f==null: return {"ok":false,"reason":"disk_permission_or_full","total":total}
        _save_manifest(source,total,"downloading")
        _publish(source,offset,total,"下载中")
        var got:=offset
        var last_data:=Time.get_ticks_msec()
        var last_display:=0
        while true:
            if paused or cancelled:
                f.flush()
                f.close()
                return {"ok":false,"reason":"paused","total":total}
            var poll_err:=_http.poll()
            if poll_err!=OK:
                f.flush()
                f.close()
                return {"ok":false,"reason":"connection_lost_"+str(poll_err),"total":total}
            var chunk: PackedByteArray=_http.read_response_body_chunk()
            if not chunk.is_empty():
                f.store_buffer(chunk)
                got+=chunk.size()
                last_data=Time.get_ticks_msec()
                if got%1048576<chunk.size(): f.flush()
                if Time.get_ticks_msec()-last_display>DISPLAY_INTERVAL_MS:
                    _publish(source,got,total,"下载中")
                    last_display=Time.get_ticks_msec()
            elif _http.get_status() in [HTTPClient.STATUS_CONNECTED,HTTPClient.STATUS_DISCONNECTED]:
                break
            elif _http.get_status() in [HTTPClient.STATUS_CONNECTION_ERROR,HTTPClient.STATUS_TLS_HANDSHAKE_ERROR,HTTPClient.STATUS_CANT_CONNECT]:
                f.flush()
                f.close()
                return {"ok":false,"reason":"download_socket_"+str(_http.get_status()),"total":total}
            if Time.get_ticks_msec()-last_data>STALL_TIMEOUT_MS:
                f.flush()
                f.close()
                return {"ok":false,"reason":"download_stalled","total":total}
            await _wait_frame()
        f.flush()
        f.close()
        if total>0 and got!=total:
            return {"ok":false,"reason":"incomplete_"+str(got)+"_of_"+str(total),"total":total}
        if got<1048576:
            return {"ok":false,"reason":"file_too_small","total":total}
        _publish(source,got,total,"下载完成")
        _http.close()
        return {"ok":true,"bytes":got,"total":total}
    return {"ok":false,"reason":"too_many_redirects","total":-1}

static func _split_url(url: String) -> Dictionary:
    if not url.begins_with("https://"): return {}
    var rest:=url.trim_prefix("https://")
    var slash:=rest.find("/")
    var authority:=rest.substr(0,slash) if slash>=0 else rest
    if authority.is_empty() or authority.contains("@"): return {}
    var target:=rest.substr(slash) if slash>=0 else "/"
    var host:=authority
    var port:=443
    if authority.contains(":"):
        var split:=authority.rsplit(":",true,1)
        if split.size()!=2 or not str(split[1]).is_valid_int(): return {}
        host=str(split[0])
        port=int(split[1])
    if host.is_empty() or port<=0 or port>65535: return {}
    return {"host":host,"port":port,"path":target}

func begin(source: String) -> void:
    if active:
        completed.emit({"ok":false,"error":"已有下载任务正在运行"})
        return
    if source_url(source).is_empty():
        completed.emit({"ok":false,"error":"只能下载明确的HTTPS或hf://GGUF模型地址"})
        return
    if not _setup():
        completed.emit({"ok":false,"error":"无法创建本地模型缓存目录"})
        return
    var ready:=final_path(source)
    if FileAccess.file_exists(ready):
        completed.emit({"ok":true,"path":ready,"cached":true})
        return
    active=true
    paused=false
    cancelled=false
    pending_source=source
    _started_ms=Time.get_ticks_msec()
    _last_tick_ms=_started_ms
    _bytes_at_tick=current_bytes(source)
    var expected:=int(_manifest(source).get("expected",-1))
    _save_manifest(source,expected,"downloading")
    _attempt=0
    var reason:=""
    while _attempt<MAX_RETRIES:
        if paused or cancelled: break
        _attempt+=1
        var result: Dictionary=await _one_request(source,partial_path(source),current_bytes(source))
        if bool(result.get("ok",false)):
            if not FileAccess.file_exists(partial_path(source)):
                reason="文件意外丢失"
                break
            var file_length:=current_bytes(source)
            var confirmed:=int(result.get("total",-1))
            if confirmed>0 and file_length!=confirmed:
                reason="下载文件长度不完整"
                continue
            var src:=ProjectSettings.globalize_path(partial_path(source))
            var dst:=ProjectSettings.globalize_path(final_path(source))
            var moved:=DirAccess.rename_absolute(src,dst)
            if moved!=OK:
                reason="无法将临时文件保存为正式GGUF："+str(moved)
                break
            _save_manifest(source,file_length,"complete")
            active=false
            _publish(source,file_length,file_length,"下载完成")
            completed.emit({"ok":true,"path":final_path(source),"bytes":file_length,"cached":false})
            return
        reason=str(result.get("reason","下载失败"))
        if reason=="paused": break
        _save_manifest(source,int(result.get("total",-1)),"retrying")
        _publish(source,current_bytes(source),int(result.get("total",-1)),"网络重试",reason)
        for second in range(mini(15,_attempt*3)):
            if paused or cancelled: break
            await get_tree().create_timer(1.0).timeout
    active=false
    if paused or cancelled:
        _save_manifest(source,int(last_progress.get("total",-1)),"paused")
        _publish(source,current_bytes(source),int(last_progress.get("total",-1)),"已暂停（可自动断点继续）")
        completed.emit({"ok":false,"paused":true,"error":"下载暂停，已保留已接收的数据"})
    else:
        _save_manifest(source,int(last_progress.get("total",-1)),"failed")
        _publish(source,current_bytes(source),int(last_progress.get("total",-1)),"下载失败",reason)
        completed.emit({"ok":false,"error":"下载重试已停止："+reason+"；保留缓存，下次从断点继续"})
