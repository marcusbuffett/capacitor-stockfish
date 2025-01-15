LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_MODULE := stockfish
LOCAL_C_INCLUDES := $(LOCAL_PATH)/../../stockfish/src/ $(LOCAL_PATH)/../../lib/
LOCAL_SRC_FILES := \
    stockfish-jni.cpp \
    ../../stockfish/src/benchmark.cpp \
    ../../stockfish/src/bitboard.cpp \
    ../../stockfish/src/engine.cpp \
    ../../stockfish/src/evaluate.cpp \
    ../../stockfish/src/main.cpp \
    ../../stockfish/src/memory.cpp \
    ../../stockfish/src/misc.cpp \
    ../../stockfish/src/movegen.cpp \
    ../../stockfish/src/movepick.cpp \
    ../../stockfish/src/nnue/features/half_ka_v2_hm.cpp \
    ../../stockfish/src/nnue/network.cpp \
    ../../stockfish/src/nnue/nnue_misc.cpp \
    ../../stockfish/src/position.cpp \
    ../../stockfish/src/score.cpp \
    ../../stockfish/src/search.cpp \
    ../../stockfish/src/syzygy/tbprobe.cpp \
    ../../stockfish/src/thread.cpp \
    ../../stockfish/src/timeman.cpp \
    ../../stockfish/src/tt.cpp \
    ../../stockfish/src/tune.cpp \
    ../../stockfish/src/uci.cpp \
    ../../stockfish/src/ucioption.cpp
LOCAL_LDLIBS := -llog -landroid
LOCAL_ARM_NEON := true

include $(BUILD_SHARED_LIBRARY)
