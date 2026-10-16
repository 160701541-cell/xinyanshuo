#pragma once
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <atomic>
#include <mutex>
#include <thread>

struct llama_model;
namespace godot {
class CanglanLocalLLM : public Node {
    GDCLASS(CanglanLocalLLM, Node)
    std::mutex state_mutex;
    std::thread worker;
    std::atomic<bool> cancel_flag{false};
    std::atomic<bool> loaded_flag{false};
    std::atomic<bool> busy_flag{false};
    llama_model * model = nullptr;
    int context_limit = 2048;
    int cpu_threads = 3;
    static void _bind_methods();
    void load_internal(String absolute_path);
    void reply_internal(String entity_code, String system_prompt, String human_text, int max_tokens);
public:
    CanglanLocalLLM() = default;
    ~CanglanLocalLLM() override;
    void load_gguf(String absolute_path, int context_tokens=2048, int threads=3);
    void request_reply(String entity_code, String system_prompt, String human_text, int max_tokens=96);
    bool model_loaded() const { return loaded_flag.load(); }
    bool inference_busy() const { return busy_flag.load(); }
    void cancel();
};
}
