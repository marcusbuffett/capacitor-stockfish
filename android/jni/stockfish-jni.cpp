#include <jni.h>
#include <android/log.h>
#include <string>
#include "bitboard.h"
#include "misc.h"
#include "position.h"
#include "types.h"
#include "uci.h"
#include "tune.h"
#include "threadbuf.h"

using namespace Stockfish;

#define LOGD(TAG,...) __android_log_print(ANDROID_LOG_DEBUG  , TAG,__VA_ARGS__)

extern "C" {
  JNIEXPORT void JNICALL Java_org_lichess_mobileapp_stockfish_Stockfish_jniInit(JNIEnv *env, jobject obj);
  JNIEXPORT void JNICALL Java_org_lichess_mobileapp_stockfish_Stockfish_jniExit(JNIEnv *env, jobject obj);
  JNIEXPORT void JNICALL Java_org_lichess_mobileapp_stockfish_Stockfish_jniCmd(JNIEnv *env, jobject obj, jstring jcmd);
};

static JavaVM *jvm;
static jobject jobj;
static jmethodID onMessage;
static UCIEngine* uci = nullptr;

static std::string CMD_EXIT = "stockfish:exit";

auto readstdout = []() {
  JNIEnv *jenv;

  jvm->GetEnv((void **)&jenv, JNI_VERSION_1_6);
  jvm->AttachCurrentThread(&jenv, (void*) NULL);

  std::streambuf* out = std::cout.rdbuf();

  threadbuf lichbuf(8, 8096);
  std::ostream lichout(&lichbuf);
  std::cout.rdbuf(lichout.rdbuf());
  std::istream lichin(&lichbuf);

  std::string o = "";

  while(o != CMD_EXIT) {
    std::string line;
    std::getline(lichin, line);
    if(line != CMD_EXIT) {
      const char* coutput = line.c_str();
      int len = strlen(coutput);
      jbyteArray aoutput = jenv->NewByteArray(len);
      jenv->SetByteArrayRegion(aoutput, 0, len, (jbyte*)coutput);
      jenv->CallVoidMethod(jobj, onMessage, aoutput);
      jenv->DeleteLocalRef(aoutput);
    } else {
      o = CMD_EXIT;
    }
  };

  std::cout.rdbuf(out);
  lichbuf.close();
  jvm->DetachCurrentThread();
};

std::thread reader;

JNIEXPORT void JNICALL Java_org_lichess_mobileapp_stockfish_Stockfish_jniInit(JNIEnv *env, jobject obj) {
  jobj = env->NewGlobalRef(obj);
  env->GetJavaVM(&jvm);
  jclass classStockfish = env->GetObjectClass(obj);
  onMessage = env->GetMethodID(classStockfish, "onMessage", "([B)V");

  std::cout << engine_info() << std::endl;

  reader = std::thread(readstdout);

  Bitboards::init();
  Position::init();

  // Create UCI engine with no command line arguments
  char* argv[] = {const_cast<char*>("stockfish")};  // Program name as first arg
  uci = new UCIEngine(0, argv);
}

JNIEXPORT void JNICALL Java_org_lichess_mobileapp_stockfish_Stockfish_jniExit(JNIEnv *env, jobject obj) {
  if (uci) {
    uci->command("quit");
    sync_cout << CMD_EXIT << sync_endl;
    reader.join();
    delete uci;
    uci = nullptr;
  }
}

JNIEXPORT void JNICALL Java_org_lichess_mobileapp_stockfish_Stockfish_jniCmd(JNIEnv *env, jobject obj, jstring jcmd) {
  const char *cmd = env->GetStringUTFChars(jcmd, (jboolean *)0);
  if (uci) {
    uci->command(cmd);
  }
  env->ReleaseStringUTFChars(jcmd, cmd);
}
