#include <jni.h>
#include <android/log.h>
#include <algorithm>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>
#include "llama.h"
namespace {
std::mutex gate;
llama_model * model=nullptr;
llama_context * context=nullptr;
std::string error_msg="未载入GGUF模型";
int context_length=2048;
void destroy(){if(context){llama_free(context);context=nullptr;}if(model){llama_model_free(model);model=nullptr;}}
std::string copyString(JNIEnv *env,jstring val){
  if(!val)return {};const char *ptr=env->GetStringUTFChars(val,nullptr);if(!ptr)return {};
  std::string result(ptr);env->ReleaseStringUTFChars(val,ptr);return result;
}
void addBatch(llama_batch_ext *batch,const llama_token *tokens,int count,llama_pos pos){
  llama_batch_ext_clear(batch);
  for(int i=0;i<count;i++){int idx=llama_batch_ext_add_token(batch,0,tokens[i]);llama_pos where=pos+i;llama_batch_ext_set_pos(batch,idx,&where);}
  if(count>0)llama_batch_ext_set_output_logits(batch,count-1,true);
}
std::string piece(const llama_vocab *vocab,llama_token token){
  char small[256];int n=llama_token_to_piece(vocab,token,small,sizeof(small),0,true);
  if(n>=0 && n<static_cast<int>(sizeof(small)))return std::string(small,n);
  if(n<0){std::vector<char> buffer(static_cast<size_t>(-n)+16);n=llama_token_to_piece(vocab,token,buffer.data(),buffer.size(),0,true);if(n>0)return std::string(buffer.data(),n);}
  return {};
}
}
extern "C" JNIEXPORT jboolean JNICALL Java_com_xinyanshuo_zhiyin_NativeLlm_load(JNIEnv *env,jclass,jstring file,jint contextLimit){
  std::lock_guard<std::mutex> lock(gate);destroy();const std::string path=copyString(env,file);
  if(path.empty()||path.size()>4096){error_msg="模型路径无效";return JNI_FALSE;}
  context_length=std::max(512,std::min(4096,(int)contextLimit));
  llama_backend_init();llama_model_params mp=llama_model_default_params();mp.n_gpu_layers=0;
  model=llama_model_load_from_file(path.c_str(),mp);
  if(!model){error_msg="无法读取GGUF；确认是兼容模型、手机内存充足";return JNI_FALSE;}
  llama_context_params cp=llama_context_default_params();cp.n_ctx=context_length;cp.n_batch=512;cp.n_ubatch=256;
  cp.n_threads=std::max(2,std::min(4,(int)std::thread::hardware_concurrency()));
  context=llama_init_from_model(model,cp);
  if(!context){llama_model_free(model);model=nullptr;error_msg="无法创建推理上下文（可能内存不足）";return JNI_FALSE;}
  error_msg.clear();return JNI_TRUE;
}
extern "C" JNIEXPORT jstring JNICALL Java_com_xinyanshuo_zhiyin_NativeLlm_lastError(JNIEnv *env,jclass){
  std::lock_guard<std::mutex> lock(gate);return env->NewStringUTF(error_msg.c_str());
}
extern "C" JNIEXPORT void JNICALL Java_com_xinyanshuo_zhiyin_NativeLlm_unload(JNIEnv *,jclass){
  std::lock_guard<std::mutex> lock(gate);destroy();
}
extern "C" JNIEXPORT jstring JNICALL Java_com_xinyanshuo_zhiyin_NativeLlm_generate(JNIEnv *env,jclass,jstring promptArg,jint maximum){
  std::lock_guard<std::mutex> lock(gate);
  if(!model||!context){error_msg="尚未载入本地模型";return env->NewStringUTF("");}
  error_msg.clear();
  const std::string prompt=copyString(env,promptArg);
  if(prompt.size()>55000){error_msg="提示词超过安全长度";return env->NewStringUTF("");}
  const llama_vocab *vocab=llama_model_get_vocab(model);
  int tokensNeeded=llama_tokenize(vocab,prompt.c_str(),prompt.size(),nullptr,0,true,true);
  if(tokensNeeded<0)tokensNeeded=-tokensNeeded;
  int maxOut=std::max(16,std::min(256,(int)maximum));
  if(tokensNeeded<=0||tokensNeeded+maxOut>=context_length){
    error_msg="记忆上下文太长：请减少历史长度或增加上下文";return env->NewStringUTF("");
  }
  std::vector<llama_token> tokens(tokensNeeded);
  int nt=llama_tokenize(vocab,prompt.c_str(),prompt.size(),tokens.data(),tokens.size(),true,true);
  if(nt<=0){error_msg="模型文本分词失败";return env->NewStringUTF("");}
  // New context per turn clears KV state; model weights remain loaded.
  llama_free(context);context=nullptr;
  llama_context_params cp=llama_context_default_params();cp.n_ctx=context_length;cp.n_batch=512;cp.n_ubatch=256;
  cp.n_threads=std::max(2,std::min(4,(int)std::thread::hardware_concurrency()));
  context=llama_init_from_model(model,cp);
  if(!context){error_msg="重新创建模型上下文失败";return env->NewStringUTF("");}
  llama_batch_ext *batch=llama_batch_ext_init(context);
  if(!batch){error_msg="批次分配失败";return env->NewStringUTF("");}
  int position=0;
  for(int i=0;i<nt;){int count=std::min(256,nt-i);addBatch(batch,tokens.data()+i,count,position);
    if(llama_process(context,LLAMA_PROCESS_TYPE_DECODE,batch)){llama_batch_ext_free(batch);error_msg="提示词计算失败（可能内存不足）";return env->NewStringUTF("");}
    i+=count;position+=count;
  }
  auto params=llama_sampler_chain_default_params();
  llama_sampler *sampler=llama_sampler_chain_init(params);
  llama_sampler_chain_add(sampler,llama_sampler_init_temp(.72f));
  llama_sampler_chain_add(sampler,llama_sampler_init_dist(7757));
  std::string response;
  for(int i=0;i<maxOut;i++){
    llama_token token=llama_sampler_sample(sampler,context,-1);
    if(llama_vocab_is_eog(vocab,token))break;
    response+=piece(vocab,token);
    addBatch(batch,&token,1,position++);
    if(llama_process(context,LLAMA_PROCESS_TYPE_DECODE,batch)){error_msg="生成过程中推理失败";break;}
    if(response.size()>6000)break;
  }
  llama_sampler_free(sampler);llama_batch_ext_free(batch);
  if(response.empty()&&error_msg.empty())error_msg="模型没有产生文本";
  jclass cl=env->FindClass("java/lang/String");
  jmethodID constructor=env->GetMethodID(cl,"<init>","([BLjava/lang/String;)V");
  jbyteArray arr=env->NewByteArray(response.size());if(!arr)return nullptr;
  env->SetByteArrayRegion(arr,0,response.size(),reinterpret_cast<const jbyte*>(response.data()));
  jstring charset=env->NewStringUTF("UTF-8");
  jobject result=env->NewObject(cl,constructor,arr,charset);
  env->DeleteLocalRef(arr);env->DeleteLocalRef(charset);return static_cast<jstring>(result);
}
