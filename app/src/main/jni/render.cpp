#include <jni.h>

#include <mpv/client.h>

#include "jni_utils.h"
#include "log.h"
#include "globals.h"

extern "C" {
    jni_func(void, attachSurface, jobject surface_);
    jni_func(void, detachSurface);
    jni_func(void, attachVideoSurface, jobject surface_);
    jni_func(void, detachVideoSurface);
};

static jobject surface;
static jobject video_surface;

static bool attach_surface(JNIEnv *env, jobject *dst, jobject source,
                           const char *option) {
    jobject ref = env->NewGlobalRef(source);
    if (!ref)
        die("invalid surface provided");

    int64_t wid = reinterpret_cast<intptr_t>(ref);
    int result = mpv_set_option(g_mpv, option, MPV_FORMAT_INT64, &wid);
    if (result < 0) {
        ALOGE("mpv_set_option(%s) returned error %s", option,
              mpv_error_string(result));
        env->DeleteGlobalRef(ref);
        return false;
    }

    if (*dst)
        env->DeleteGlobalRef(*dst);
    *dst = ref;
    return true;
}

static bool detach_surface(JNIEnv *env, jobject *dst, const char *option) {
    if (!*dst)
        return true;

    int64_t wid = 0;
    int result = mpv_set_option(g_mpv, option, MPV_FORMAT_INT64, &wid);
    if (result < 0) {
        ALOGE("mpv_set_option(%s) returned error %s", option,
              mpv_error_string(result));
        return false;
    }

    env->DeleteGlobalRef(*dst);
    *dst = NULL;
    return true;
}

void release_render_surfaces(JNIEnv *env) {
    if (surface) {
        env->DeleteGlobalRef(surface);
        surface = NULL;
    }
    if (video_surface) {
        env->DeleteGlobalRef(video_surface);
        video_surface = NULL;
    }
}

jni_func(void, attachSurface, jobject surface_) {
    CHECK_MPV_INIT();
    attach_surface(env, &surface, surface_, "wid");
}

jni_func(void, detachSurface) {
    CHECK_MPV_INIT();
    detach_surface(env, &surface, "wid");
}

jni_func(void, attachVideoSurface, jobject surface_) {
    CHECK_MPV_INIT();
    attach_surface(env, &video_surface, surface_, "android-video-wid");
}

jni_func(void, detachVideoSurface) {
    CHECK_MPV_INIT();
    detach_surface(env, &video_surface, "android-video-wid");
}
