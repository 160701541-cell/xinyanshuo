cmake_minimum_required(VERSION 3.22)
project(canglan_llm_native LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_LLAMAFILE OFF CACHE BOOL "" FORCE)
set(GGML_BLAS OFF CACHE BOOL "" FORCE)
set(LLAMA_CURL OFF CACHE BOOL "" FORCE)
set(LLAMA_OPENSSL OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
include(FetchContent)
# Pin to vetted major API generation; renovate only after actual Android QA.
FetchContent_Declare(godotcpp
  GIT_REPOSITORY https://github.com/godotengine/godot-cpp.git
  GIT_TAG godot-4.4-stable GIT_SHALLOW TRUE)
FetchContent_Declare(llama_source
  GIT_REPOSITORY https://github.com/ggml-org/llama.cpp.git
  GIT_TAG b6000 GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(godotcpp llama_source)
add_library(canglan_ai SHARED
  canglan_local_llm.cpp register_types.cpp)
target_include_directories(canglan_ai PRIVATE ${llama_source_SOURCE_DIR}/include)
if(NOT TARGET godot::cpp)
  message(FATAL_ERROR "Pinned godot-cpp 4.4 bindings did not configure")
endif()
target_link_libraries(canglan_ai PRIVATE godot::cpp llama)
set_target_properties(canglan_ai PROPERTIES
  PREFIX "lib"
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/stage")
