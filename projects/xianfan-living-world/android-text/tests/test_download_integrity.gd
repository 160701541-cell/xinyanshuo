extends SceneTree
var failures: Array[String]=[]

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, why: String) -> void:
    if not ok:
        failures.append(why)
        push_error("DOWNLOAD INTEGRITY FAILURE: "+why)

func _run() -> void:
    var worker:=XianfanResumableModelDownload.new()
    root.add_child(worker)
    check(XianfanResumableModelDownload.source_url(
        "hf://Qwen/Qwen3-8B-GGUF/Qwen3-8B-Q4_K_M.gguf").contains("/resolve/main/"),
        "official Hugging Face file translates to direct GGUF URL")
    check(XianfanResumableModelDownload.range_start("bytes 8388608-16777215/5028000000")==8388608,
        "content range validates resume start")
    check(XianfanResumableModelDownload.range_total("bytes 8388608-16777215/5028000000")==5028000000,
        "5GB total uses 64-bit integer")
    check(worker.is_pending("hf://Qwen/unknown-no-download-GGUF/file.gguf")==false,
        "new model does not auto-start without previous user consent")
    var root_path: String="user://download_integrity_test"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_path))
    var path: String=root_path+"/model.gguf.part"
    var f:=FileAccess.open(path,FileAccess.WRITE)
    check(f!=null,"device writable storage")
    if f!=null:
        f.store_buffer("GGUF".to_ascii_buffer())
        var buffer:=PackedByteArray()
        buffer.resize(1048576)
        f.store_buffer(buffer)
        f.close()
        var valid: Dictionary=await worker.validate_disk_file("hf://test/test-GGUF/file.gguf",path,1048580)
        check(bool(valid.get("ok",false)),"valid header and exact byte count accepted for custom file")
        check(str(valid.get("verified","")).contains("大小"),"unknown model never claims verified cryptographic hash")
        var truncated: Dictionary=await worker.validate_disk_file("hf://test/test-GGUF/file.gguf",path,1048581)
        check(not bool(truncated.get("ok",true)),"truncated file cannot be loaded")
        var official: Dictionary=await worker.validate_disk_file(
            "hf://Qwen/Qwen3-8B-GGUF/Qwen3-8B-Q4_K_M.gguf",path,1048580)
        check(not bool(official.get("ok",true)),"incorrect official Qwen 8B digest blocks loading")
        var broken:=FileAccess.open(path,FileAccess.WRITE)
        broken.store_buffer("NOT-A-GGUF".to_ascii_buffer())
        var junk:=PackedByteArray()
        junk.resize(1048576)
        broken.store_buffer(junk)
        broken.close()
        var invalid: Dictionary=await worker.validate_disk_file("hf://test/test-GGUF/file.gguf",path,1048586)
        check(not bool(invalid.get("ok",true)),"server HTML or corrupt magic rejected")
    print("XIANFAN DOWNLOAD INTEGRITY TESTS PASS" if failures.is_empty() else "XIANFAN DOWNLOAD INTEGRITY TESTS FAILED")
    quit(0 if failures.is_empty() else 1)
