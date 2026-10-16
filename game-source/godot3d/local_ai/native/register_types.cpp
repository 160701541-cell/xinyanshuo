#include "canglan_local_llm.h"
#include <godot_cpp/godot.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;
void initialize_canglan_ai(ModuleInitializationLevel level) {
    if (level == MODULE_INITIALIZATION_LEVEL_SCENE)
        ClassDB::register_class<CanglanLocalLLM>();
}
void uninitialize_canglan_ai(ModuleInitializationLevel) {}
extern "C" GDExtensionBool GDE_EXPORT canglan_ai_init(
        GDExtensionInterfaceGetProcAddress proc,
        GDExtensionClassLibraryPtr library,
        GDExtensionInitialization *initialization) {
    GDExtensionBinding::InitObject init(proc, library, initialization);
    init.register_initializer(initialize_canglan_ai);
    init.register_terminator(uninitialize_canglan_ai);
    init.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
    return init.init();
}
