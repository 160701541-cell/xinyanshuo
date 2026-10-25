extends SceneTree
var failures: Array[String]=[]

func _initialize() -> void:
    call_deferred("_run")

func verify(ok: bool, description: String) -> void:
    if not ok:
        failures.append(description)
        push_error("GGUF DOWNLOAD TEST FAILURE: "+description)

func _run() -> void:
    var d:=XianfanResumableModelDownload.new()
    root.add_child(d)
    var url:=XianfanResumableModelDownload.source_url("hf://Qwen/Qwen3-8B-GGUF/Qwen3-8B-Q4_K_M.gguf")
    verify(url=="https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf?download=true",
        "Hugging Face shorthand resolves to direct HTTPS model bytes")
    verify(XianfanResumableModelDownload.source_url("http://unsafe/file.gguf").is_empty(),"plaintext model URL rejected")
    verify(XianfanResumableModelDownload.range_start("bytes 1048576-2097151/5000000000")==1048576,
        "HTTP 206 resume response start is parsed exactly")
    verify(XianfanResumableModelDownload.range_total("bytes 1048576-2097151/5000000000")==5000000000,
        "large file content range keeps 64bit size")
    verify(XianfanResumableModelDownload.range_start("garbage")==-1,"malformed range is rejected")
    verify(XianfanResumableModelDownload._split_url("https://huggingface.co/Qwen/file?download=true").get("path","").contains("?download=true"),
        "download query preserved during requests")
    verify(XianfanResumableModelDownload._split_url("http://example.com").is_empty(),"plain HTTP never accepted")
    var src: String="https://example.org/tests/fake_model_v001.gguf"
    verify(not d.is_pending(src),"unknown model does not auto-download without consent")
    verify(d._setup(),"GGUF cache directory exists on disk")
    var raw:=PackedByteArray()
    raw.resize(1048576)
    var part:=FileAccess.open(d.partial_path(src),FileAccess.WRITE)
    verify(part!=null,"can create partial GGUF file")
    if part!=null:
        part.store_buffer(raw)
        part.close()
    d._save_manifest(src,3000000000,"paused")
    verify(d.is_pending(src),"incomplete consented download eligible for automatic resume")
    verify(d.current_bytes(src)==1048576,"saved download keeps exact physical byte offset")
    var reopened:=XianfanResumableModelDownload.new()
    root.add_child(reopened)
    verify(reopened.is_pending(src) and reopened.current_bytes(src)==1048576,
        "download state survives node recreation and app restart")
    reopened._publish(src,1048576,3000000000,"下载中")
    verify(float(reopened.last_progress.get("fraction",-1))>0.0,"progress derived from actual received bytes")
    verify(int(reopened.last_progress.get("total",0))==3000000000,"progress understands 3GB file totals")
    var pause_file:=FileAccess.open(reopened.partial_path(src),FileAccess.READ)
    verify(pause_file!=null and pause_file.get_length()==1048576,"stateless status checks never truncate a partial model")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(reopened.partial_path(src)))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(reopened.manifest_path(src)))
    var ui=load("res://main.tscn").instantiate()
    root.add_child(ui)
    ui._change_tab("对话")
    verify(ui.scene_text.scroll_following,"dialogue page is configured to follow newly appended speech")
    ui._on_model_download_progress({"source":src,"bytes":1000000000,"total":4000000000,
        "phase":"下载中","speed_bps":4200000.0,"attempt":2})
    verify(not ui.model_progress_label.visible,"completed or inactive download widgets do not clutter dialogue or story")
    verify(ui.model_progress_label.text.contains("1.00 GB / 4.00 GB"),"UI shows real downloaded and total GB")
    verify(ui.model_progress_bar.value>=24.9 and ui.model_progress_bar.value<=25.1,
        "real 25% progress bar is computed from byte ratio")
    verify(ui.model_progress_label.text.contains("4.20 MB/s"),"real transfer speed is displayed")
    ui._change_tab("剧情")
    verify(ui.scene_text.scroll_following,"story follows new incoming narration too")
    ui._change_tab("世界")
    verify(not ui.scene_text.scroll_following,"non-chronological pages start at overview")
    print("XIANFAN GGUF DOWNLOAD TESTS PASS" if failures.is_empty() else "XIANFAN GGUF DOWNLOAD TESTS FAILED")
    quit(0 if failures.is_empty() else 1)
