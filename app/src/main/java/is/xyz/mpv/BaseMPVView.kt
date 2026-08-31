package `is`.xyz.mpv

import android.content.Context
import android.graphics.PixelFormat
import android.util.AttributeSet
import android.util.Log
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View

// Contains only the essential code needed to get a picture on the screen

abstract class BaseMPVView(context: Context, attrs: AttributeSet) : SurfaceView(context, attrs), SurfaceHolder.Callback {
    private var directVideoSurface: SurfaceView? = null
    private var doviOverlayEnabled = false
    private var playerSurfaceAttached = false
    private var videoSurfaceAttached = false
    private var voActive = false

    private val directVideoSurfaceCallback = object : SurfaceHolder.Callback {
        override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) = Unit

        override fun surfaceCreated(holder: SurfaceHolder) {
            Log.w(TAG, "attaching direct video surface")
            MPVLib.attachVideoSurface(holder.surface)
            videoSurfaceAttached = true
            activateVoIfReady()
        }

        override fun surfaceDestroyed(holder: SurfaceHolder) {
            Log.w(TAG, "detaching direct video surface")
            deactivateVo()
            MPVLib.detachVideoSurface()
            videoSurfaceAttached = false
        }
    }

    fun setDirectVideoSurface(surface: SurfaceView) {
        check(directVideoSurface == null) { "direct video surface already configured" }
        directVideoSurface = surface
    }

    /**
     * Initialize libmpv.
     *
     * Call this once before the view is shown.
     */
    fun initialize(configDir: String, cacheDir: String) {
        MPVLib.create(context.applicationContext)

        /* set normal options (user-supplied config can override) */
        MPVLib.setOptionString("config", "yes")
        MPVLib.setOptionString("config-dir", configDir)
        for (opt in arrayOf("gpu-shader-cache-dir", "icc-cache-dir"))
            MPVLib.setOptionString(opt, cacheDir)
        initOptions()

        MPVLib.init()

        doviOverlayEnabled =
            MPVLib.getPropertyBoolean("options/android-dovi-overlay") == true
        if (doviOverlayEnabled) {
            val videoSurface = checkNotNull(directVideoSurface) {
                "Android Dolby overlay requires a direct video surface"
            }
            holder.setFormat(PixelFormat.TRANSLUCENT)
            setZOrderMediaOverlay(true)
            videoSurface.visibility = View.VISIBLE
            videoSurface.holder.addCallback(directVideoSurfaceCallback)
        }

        /* set hardcoded options */
        postInitOptions()
        // could mess up VO init before surfaceCreated() is called
        MPVLib.setOptionString("force-window", "no")
        // need to idle at least once for playFile() logic to work
        MPVLib.setOptionString("idle", "once")

        holder.addCallback(this)
        observeProperties()
    }

    /**
     * Deinitialize libmpv.
     *
     * Call this once before the view is destroyed.
     */
    fun destroy() {
        // Disable surface callbacks to avoid using uninitialized mpv state
        holder.removeCallback(this)
        if (doviOverlayEnabled)
            directVideoSurface?.holder?.removeCallback(directVideoSurfaceCallback)

        MPVLib.destroy()
        playerSurfaceAttached = false
        videoSurfaceAttached = false
        voActive = false
    }

    protected abstract fun initOptions()
    protected abstract fun postInitOptions()

    protected abstract fun observeProperties()

    private var filePath: String? = null

    /**
     * Set the first file to be played once the player is ready.
     */
    fun playFile(filePath: String) {
        if (voActive)
            MPVLib.command(arrayOf("loadfile", filePath))
        else
            this.filePath = filePath
    }

    private var voInUse: String = "gpu"

    /**
     * Sets the VO to use.
     * It is automatically disabled/enabled when the surface dis-/appears.
     */
    fun setVo(vo: String) {
        voInUse = vo
        MPVLib.setOptionString("vo", vo)
    }

    // Surface callbacks

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        MPVLib.setPropertyString("android-surface-size", "${width}x$height")
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        Log.w(TAG, "attaching surface")
        MPVLib.attachSurface(holder.surface)
        playerSurfaceAttached = true
        activateVoIfReady()
    }

    private fun activateVoIfReady() {
        if (voActive || !playerSurfaceAttached ||
            (doviOverlayEnabled && !videoSurfaceAttached))
            return

        // This forces mpv to render subs/osd/whatever into our surface even if it would ordinarily not
        MPVLib.setOptionString("force-window", "yes")

        if (filePath != null) {
            MPVLib.command(arrayOf("loadfile", filePath as String))
            filePath = null
        } else {
            // We disable video output when the context disappears, enable it back
            MPVLib.setPropertyString("vo", voInUse)
        }
        voActive = true
    }

    private fun deactivateVo() {
        if (!voActive)
            return

        MPVLib.getPropertyString("current-vo")
            ?.takeIf { it.isNotBlank() && it != "null" }
            ?.let { voInUse = it }
        MPVLib.setPropertyString("vo", "null")
        MPVLib.setPropertyString("force-window", "no")
        voActive = false
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        Log.w(TAG, "detaching surface")
        deactivateVo()
        // Note that before calling detachSurface() we need to be sure that libmpv
        // is done using the surface.
        // FIXME: There could be a race condition here, because I don't think
        // setting a property will wait for VO deinit.
        MPVLib.detachSurface()
        playerSurfaceAttached = false
    }

    companion object {
        private const val TAG = "mpv"
    }
}
