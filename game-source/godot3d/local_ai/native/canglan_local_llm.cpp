#include "canglan_local_llm.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <llama.h>
#include <algorithm>
#include <string>
#include <vector>

using namespace godot;

void CanglanLocalLLM::_bind_methods() {
    ClassDB::bind_method(D_METHOD("load_gguf", "absolute_path", "context_tokens", "threads"),
        &CanglanLocalLLM::load_gguf, DEFVAL(2048), DEFVAL(3));
    ClassDB::bind_method(D_METHOD("request_reply", "entity_code", "persona", "text", "max_tokens"),
        &CanglanLocalLLM::request_reply, DEFVAL(96));
    ClassDB::bind_method(D_METHOD("model_loaded"), &CanglanLocalLLM::model_loaded);
    ClassDB::bind_method(D_METHOD("inference_busy"), &CanglanLocalLLM::inference_busy);
    ClassDB::bind_method(D_METHOD("cancel"), &CanglanLocalLLM::cancel);
    ADD_SIGNAL(MethodInfo("model_ready"));
    ADD_SIGNAL(MethodInfo("model_error", PropertyInfo(Variant::STRING, "error")));
    ADD_SIGNAL(MethodInfo("reply_ready", PropertyInfo(Variant::STRING,"entity_id"),
                          PropertyInfo(Variant::STRING,"reply")));
}

CanglanLocalLLM::~CanglanLocalLLM() {
    cancel_flag = true;
    if (worker.joinable()) worker.join();
    std::scoped_lock guard(state_mutex);
    if (model != nullptr) {
        llama_model_free(model);
        model = nullptr;
    }
    if (loaded_flag.exchange(false)) llama_backend_free();
}

void CanglanLocalLLM::load_gguf(String absolute_path, int context_tokens, int threads) {
    if (busy_flag.exchange(true)) return;
    cancel_flag = false;
    context_limit = std::clamp(context_tokens, 512, 2048);
    cpu_threads = std::clamp(threads, 1, 4);
    if (worker.joinable()) worker.join();
    worker = std::thread(&CanglanLocalLLM::load_internal, this, absolute_path);
}

void CanglanLocalLLM::load_internal(String absolute_path) {
    std::string filename = absolute_path.utf8().get_data();
    if (filename.empty() || filename.size() > 2048) {
        busy_flag = false;
        call_deferred("emit_signal", "model_error", "模型绝对路径无效");
        return;
    }
    // Never access any network: only an already-verified file in app-private storage.
    llama_backend_init();
    auto params = llama_model_default_params();
    params.n_gpu_layers = 0;  // safe ARM64 CPU baseline; no untested GPU/Vulkan extension
    llama_model * candidate = llama_model_load_from_file(filename.c_str(), params);
    if (candidate == nullptr || cancel_flag) {
        if (candidate) llama_model_free(candidate);
        llama_backend_free();
        busy_flag = false;
        call_deferred("emit_signal", "model_error", "GGUF模型文件损坏、缺失或内存不足");
        return;
    }
    {
        std::scoped_lock guard(state_mutex);
        model = candidate;
        loaded_flag = true;
    }
    busy_flag = false;
    call_deferred("emit_signal", "model_ready");
}

void CanglanLocalLLM::request_reply(String entity_code, String persona,
                                     String text, int max_tokens) {
    if (!loaded_flag || busy_flag.exchange(true)) return;
    cancel_flag = false;
    if (worker.joinable()) worker.join();
    worker = std::thread(&CanglanLocalLLM::reply_internal, this, entity_code, persona,
                         text, std::clamp(max_tokens, 16, 128));
}

void CanglanLocalLLM::reply_internal(String entity, String persona, String human, int cap) {
    llama_model * m = nullptr;
    {
        std::scoped_lock guard(state_mutex);
        m = model;
    }
    if (m == nullptr) {
        busy_flag = false;
        call_deferred("emit_signal", "model_error", "本地模型尚未加载");
        return;
    }
    auto context_params = llama_context_default_params();
    context_params.n_ctx = context_limit;
    context_params.n_batch = context_limit;
    context_params.n_threads = cpu_threads;
    context_params.n_threads_batch = cpu_threads;
    llama_context * ctx = llama_init_from_model(m, context_params);
    if (ctx == nullptr) {
        busy_flag = false;
        call_deferred("emit_signal", "model_error", "手机RAM不足以创建推理上下文");
        return;
    }
    std::string prompt = "<|im_start|>system\n";
    prompt += persona.utf8().get_data();
    prompt += "\n只输出角色在场景中实际会说的话；不要写动作指令或凭空确认交易。/no_think<|im_end|>\n<|im_start|>user\n";
    prompt += human.utf8().get_data();
    prompt += "<|im_end|>\n<|im_start|>assistant\n";
    const llama_vocab * vocab = llama_model_get_vocab(m);
    int need = -llama_tokenize(vocab, prompt.c_str(), (int32_t)prompt.size(),
                               nullptr, 0, true, true);
    if (need < 1 || need > context_limit - cap - 12) {
        llama_free(ctx);
        busy_flag = false;
        call_deferred("emit_signal", "model_error", "对话上下文超出手机本地模型容量");
        return;
    }
    std::vector<llama_token> tokens(need);
    int n = llama_tokenize(vocab, prompt.c_str(), (int32_t)prompt.size(),
                           tokens.data(), need, true, true);
    if (n <= 0) {
        llama_free(ctx);
        busy_flag = false;
        call_deferred("emit_signal", "model_error", "GGUF分词失败");
        return;
    }
    auto batch = llama_batch_get_one(tokens.data(), n);
    int failure = llama_decode(ctx, batch);
    llama_sampler * sampler = llama_sampler_init_greedy();
    std::string answer;
    for (int i = 0; i < cap && failure == 0 && !cancel_flag; ++i) {
        llama_token next = llama_sampler_sample(sampler, ctx, -1);
        if (llama_vocab_is_eog(vocab, next)) break;
        char part[256];
        int size = llama_token_to_piece(vocab, next, part, sizeof(part), 0, true);
        if (size > 0) answer.append(part, (size_t)size);
        batch = llama_batch_get_one(&next, 1);
        failure = llama_decode(ctx, batch);
    }
    llama_sampler_free(sampler);
    llama_free(ctx);
    busy_flag = false;
    if (cancel_flag || failure != 0 || answer.empty()) {
        call_deferred("emit_signal", "model_error",
            failure != 0 ? "llama.cpp解码失败" : "本地对话已取消或模型未产生文本");
        return;
    }
    call_deferred("emit_signal", "reply_ready", entity, String::utf8(answer.c_str()));
}

void CanglanLocalLLM::cancel() { cancel_flag = true; }
