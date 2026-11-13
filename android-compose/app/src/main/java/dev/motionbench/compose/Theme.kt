package dev.motionbench.compose

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.vector.PathParser
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay

object C {
    val bg = Color(0xFF0B0B0F)
    val surface = Color(0xFF14141B)
    val border = Color(0xFF1F1F29)
    val text = Color(0xFFF4F4F6)
    val muted = Color(0xFF9A9AA6)
    val lime = Color(0xFFC6F432)
    val heart = Color(0xFFFF5C7A)
}

val EaseFrame = CubicBezierEasing(0.2f, 0.9f, 0.1f, 1f)
val EaseSheet = CubicBezierEasing(0.22f, 1f, 0.36f, 1f)
val EaseDraw = CubicBezierEasing(0.65f, 0f, 0.35f, 1f)
val EaseBack = CubicBezierEasing(0.34f, 1.56f, 0.64f, 1f)
val EaseInOut = CubicBezierEasing(0.42f, 0f, 0.58f, 1f)

data class Bench(val load: Int = 1, val auto: Boolean = false)

data class Track(val title: String, val artist: String, val mono: String, val color: Color, val orbA: Color, val orbB: Color, val len: Int)

val TRACKS = listOf(
    Track("Neon Monsoon", "Kavya & The Static", "NM", Color(0xFFC6F432), Color(0xFF5B4BFF), Color(0xFFC6F432), 222),
    Track("Paper Satellites", "Low Orbit Club", "PS", Color(0xFF8B7CFF), Color(0xFFFF7A59), Color(0xFF8B7CFF), 198),
    Track("Saltwater Static", "Mira Okafor", "SS", Color(0xFFFF7A59), Color(0xFF4FD1C5), Color(0xFFFF7A59), 245),
)

val LYRICS = listOf(
    "City lights are melting in the rain",
    "Every signal turning into gold",
    "We ride the hum of the last train",
    "Holding on to stories never told",
    "Neon rivers running through the night",
    "Your laugh is louder than the thunder",
    "Count the seconds, hold the light",
    "Let the monsoon pull us under",
)

val BAR_H = intArrayOf(18, 30, 22, 40, 34, 44, 26, 38, 20, 42, 30, 36, 24, 44, 32, 28, 40, 22, 36, 44, 26, 34, 18, 40, 30, 42, 24, 38, 20, 32, 28, 16)

data class Trek(
    val name: String, val alt: String, val days: String, val diff: String, val season: String, val blurb: String,
    val sky1: Color, val sky2: Color, val sun: Color, val m1: Color, val m2: Color, val m3: Color,
    val ink: Color, val night: Boolean, val accent: Color, val prof: List<Int>, val col: Int, val dy: Int, val h: Int,
)

val TREKS = listOf(
    Trek("Buran Ghati", "4,575 m", "8 days", "Hard", "May–Jun",
        "Kinnaur, Himachal. Meadows to a high snow pass, then a long snow-slope descent into the Pabbar valley.",
        Color(0xFF1B1F3B), Color(0xFFE07A5F), Color(0xFFFFD6A5), Color(0xFF5A3D5C), Color(0xFF3A2740), Color(0xFF17111D),
        Color.White, true, Color(0xFFFF9F80), listOf(2500, 2800, 3100, 3300, 3500, 3700, 4575, 3900, 3200, 2600, 2200), 0, 0, 250),
    Trek("Kedarkantha", "3,810 m", "6 days", "Easy", "Dec–Apr",
        "Uttarakhand. A classic winter summit climb through pine forest and snow-covered clearings.",
        Color(0xFF9EC5EA), Color(0xFFEAF2FA), Color.White, Color(0xFFE6EEF6), Color(0xFF7E96B2), Color(0xFF22334A),
        C.bg, false, Color(0xFF7FB5FF), listOf(1900, 2400, 2900, 3200, 3400, 3810, 3400, 2900, 2400, 1900), 1, 0, 200),
    Trek("Hampta Pass", "4,270 m", "5 days", "Moderate", "Jun–Sep",
        "Kullu to Lahaul. Green valleys on one side of the pass, stark high-desert on the other.",
        Color(0xFFF6C177), Color(0xFFF28C6B), Color(0xFFFFF1C9), Color(0xFF9A5B67), Color(0xFF5E3448), Color(0xFF22162A),
        C.bg, false, Color(0xFFF6C177), listOf(2900, 3200, 3500, 3700, 4270, 3800, 3600, 3900, 3300), 0, 262, 200),
    Trek("Valley of Flowers", "3,658 m", "6 days", "Easy", "Jul–Sep",
        "Chamoli, Uttarakhand. Alpine meadows that burst into bloom during the monsoon months.",
        Color(0xFFBFE3CB), Color(0xFFF4F1DE), Color(0xFFFFF7D6), Color(0xFF8DB580), Color(0xFF4E7A45), Color(0xFF1F3A26),
        C.bg, false, Color(0xFF9BD88A), listOf(1800, 2200, 3000, 3300, 3658, 3400, 3000, 2600, 2000), 1, 212, 250),
)

val FAR = floatArrayOf(0f, 100f, 0f, 55f, 15f, 35f, 28f, 50f, 45f, 18f, 60f, 45f, 72f, 28f, 88f, 48f, 100f, 36f, 100f, 100f)
val MID = floatArrayOf(0f, 100f, 0f, 60f, 20f, 38f, 35f, 58f, 55f, 28f, 75f, 55f, 90f, 40f, 100f, 52f, 100f, 100f)
val NEAR = floatArrayOf(0f, 100f, 0f, 48f, 25f, 28f, 50f, 52f, 70f, 34f, 100f, 58f, 100f, 100f)

/** Draws a 24×24 SVG path string. */
@Composable
fun SvgIcon(d: String, size: Dp, color: Color, modifier: Modifier = Modifier, stroke: Float = 0f) {
    val path = remember(d) { PathParser().parsePathString(d).toPath() }
    Canvas(modifier.size(size)) {
        scale(this.size.width / 24f, this.size.height / 24f, pivot = androidx.compose.ui.geometry.Offset.Zero) {
            drawPath(path, color, style = if (stroke > 0f) Stroke(width = stroke) else Fill)
        }
    }
}

/** One-shot 0→1 progress that starts after [delayMs]. Used for "entering" animations. */
@Composable
fun rememberEnter(delayMs: Int, durationMs: Int, easing: androidx.compose.animation.core.Easing = EaseSheet): State<Float> {
    val a = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        delay(delayMs.toLong())
        a.animateTo(1f, tween(durationMs, easing = easing))
    }
    return a.asState()
}

val Int.pxDp: Dp get() = this.dp
