package dev.motionbench.compose

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.PathParser
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.roundToInt

private const val HEART = "M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"
private const val PLAY = "M7 4.5v15a1 1 0 0 0 1.5.86l12-7.5a1 1 0 0 0 0-1.72l-12-7.5A1 1 0 0 0 7 4.5z"
private const val PAUSE = "M6 4h4v16H6zM14 4h4v16h-4z"
private const val PREV = "M6 5h2v14H6zM20 5v14L9.5 12z"
private const val NEXT = "M16 5h2v14h-2zM4 5v14l10.5-7z"

@Composable
private fun Orb(color: Color, size: Dp, x0: Dp, y0: Dp, durMs: Int, mid: Offset, end: Offset, playing: Boolean) {
    val x = remember { Animatable(0f) }
    val y = remember { Animatable(0f) }
    LaunchedEffect(playing) {
        if (!playing) return@LaunchedEffect
        val half = durMs / 2
        launch {
            while (true) {
                x.animateTo(mid.x, tween(half, easing = EaseInOut)); x.animateTo(end.x, tween(half, easing = EaseInOut))
                x.animateTo(mid.x, tween(half, easing = EaseInOut)); x.animateTo(0f, tween(half, easing = EaseInOut))
            }
        }
        while (true) {
            y.animateTo(mid.y, tween(half, easing = EaseInOut)); y.animateTo(end.y, tween(half, easing = EaseInOut))
            y.animateTo(mid.y, tween(half, easing = EaseInOut)); y.animateTo(0f, tween(half, easing = EaseInOut))
        }
    }
    Canvas(
        Modifier.offset(x0, y0).size(size).graphicsLayer {
            translationX = x.value * density; translationY = y.value * density
        }
    ) { drawCircle(Brush.radialGradient(listOf(color.copy(alpha = .5f), color.copy(alpha = 0f)))) }
}

@Composable
private fun EqBar(i: Int, color: Color, width: Dp, playing: Boolean) {
    val dur = ((0.32f + ((i * 37) % 23) / 40f) * 1000).toInt()
    val phase = ((i * 53) % 17) / 20f
    val s = remember { Animatable(0.12f + 0.88f * phase) }
    LaunchedEffect(playing) {
        if (!playing) return@LaunchedEffect
        val rem = (dur * (1f - (s.value - 0.12f) / 0.88f)).toInt().coerceAtLeast(16)
        s.animateTo(1f, tween(rem, easing = EaseInOut))
        while (true) {
            s.animateTo(0.12f, tween(dur, easing = EaseInOut))
            s.animateTo(1f, tween(dur, easing = EaseInOut))
        }
    }
    Box(
        Modifier.width(width).height(BAR_H[i % 32].dp)
            .graphicsLayer { scaleY = s.value; transformOrigin = TransformOrigin(0.5f, 1f) }
            .clip(RoundedCornerShape(3.dp)).background(color)
    )
}

@Composable
private fun LyricLine(text: String, dist: Int) {
    val alpha by animateFloatAsState(if (dist == 0) 1f else if (dist == 1) .4f else .18f, tween(500), label = "a")
    val scale by animateFloatAsState(if (dist == 0) 1.04f else 1f, spring(dampingRatio = .4f, stiffness = 180f), label = "s")
    Text(
        text, maxLines = 1, overflow = TextOverflow.Clip,
        color = if (dist == 0) Color.White else Color(0xFFC9C9D3), fontSize = 18.sp, fontWeight = FontWeight.SemiBold,
        modifier = Modifier.height(44.dp).wrapContentHeight(Alignment.CenterVertically)
            .graphicsLayer { this.alpha = alpha; scaleX = scale; scaleY = scale; transformOrigin = TransformOrigin(0f, .5f) },
    )
}

private fun fmt(s: Float): String { val m = (s / 60).toInt(); val r = (s % 60).toInt(); return "$m:${r.toString().padStart(2, '0')}" }

@Composable
fun PlayerScreen(bench: Bench) {
    var playing by remember { mutableStateOf(true) }
    var progress by remember { mutableFloatStateOf(0.06f) }
    var track by remember { mutableIntStateOf(0) }
    var liked by remember { mutableStateOf(false) }
    val t = TRACKS[track]
    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        while (true) {
            delay(100)
            if (playing) {
                val p = progress + 0.0025f
                if (p >= 1f) { track = (track + 1) % 3; progress = 0f } else progress = p
            }
        }
    }
    fun go(dir: Int) { track = (track + dir + 3) % 3; progress = 0f }

    val accent by animateColorAsState(t.color, tween(800), label = "accent")
    val orbA by animateColorAsState(t.orbA, tween(1000), label = "orbA")
    val orbB by animateColorAsState(t.orbB, tween(1000), label = "orbB")

    val rot = remember { Animatable(0f) }
    LaunchedEffect(playing) {
        if (!playing) return@LaunchedEffect
        val s = rot.value % 360f
        rot.snapTo(s)
        while (true) { rot.animateTo(s + 360f, tween(5000, easing = LinearEasing)); rot.snapTo(s) }
    }
    val beat = remember { Animatable(0f) }
    LaunchedEffect(playing) {
        if (!playing) return@LaunchedEffect
        while (true) { beat.animateTo(1f, tween(470, easing = EaseInOut)); beat.animateTo(0f, tween(470, easing = EaseInOut)) }
    }
    val arm by animateFloatAsState(if (playing) 22f else 0f, spring(dampingRatio = .46f, stiffness = 170f), label = "arm")
    val playRadius by animateDpAsState(if (playing) 28.dp else 40.dp, spring(dampingRatio = .5f, stiffness = 220f), label = "rad")
    val pop = remember { Animatable(1f) }

    val idx = (progress * LYRICS.size).toInt().coerceAtMost(LYRICS.size - 1)
    val lyY by animateFloatAsState(44f - idx * 44f, spring(dampingRatio = .55f, stiffness = 140f), label = "ly")

    val nBars = 32 * bench.load
    val barW = if (bench.load == 4) 2.dp else 5.dp
    val grooves = remember(bench.load) { val n = 24 * bench.load; List(n) { 40f + 92f * it / (n - 1) } }
    val armPath = remember { PathParser().parsePathString("M96 22 L90 120 L62 150").toPath() }

    Box(Modifier.fillMaxSize().background(C.bg)) {
        Orb(orbA, 320.dp, (-120).dp, (-60).dp, 11000, Offset(60f, 40f), Offset(-30f, 90f), playing)
        BoxWithConstraints(Modifier.fillMaxSize()) {
            Orb(orbB, 280.dp, maxWidth - 170.dp, 260.dp, 13000, Offset(-70f, -30f), Offset(20f, -80f), playing)
        }

        Column(Modifier.fillMaxSize().padding(start = 24.dp, end = 24.dp, top = 20.dp, bottom = 16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            // Disc
            Box(Modifier.size(268.dp).align(Alignment.CenterHorizontally)) {
                Box(
                    Modifier.requiredSize(296.dp).align(Alignment.Center)
                        .graphicsLayer { val b = beat.value; scaleX = .96f + .1f * b; scaleY = scaleX; alpha = .45f + .4f * b }
                        .border(2.dp, accent, CircleShape)
                )
                Box(Modifier.fillMaxSize().graphicsLayer { rotationZ = rot.value }, contentAlignment = Alignment.Center) {
                    Canvas(Modifier.fillMaxSize()) {
                        drawCircle(Color(0xFF15151B))
                        val sw = 1.5.dp.toPx()
                        grooves.forEachIndexed { i, r ->
                            drawCircle(if (i % 2 == 1) Color(0xFF1E1E27) else Color(0xFF111116), radius = r.dp.toPx(), style = Stroke(sw))
                        }
                        drawArc(Color.White.copy(alpha = .06f), startAngle = -50f, sweepAngle = 22f, useCenter = true)
                    }
                    Box(Modifier.size(104.dp).clip(CircleShape).background(accent), contentAlignment = Alignment.Center) {
                        Text(t.mono, color = C.bg, fontWeight = FontWeight.Bold, fontSize = 24.sp)
                        Box(Modifier.size(10.dp).clip(CircleShape).background(C.bg))
                    }
                }
                Canvas(
                    Modifier.offset(192.dp, (-26).dp).size(120.dp, 170.dp)
                        .graphicsLayer { rotationZ = arm; transformOrigin = TransformOrigin(96f / 120f, 22f / 170f) }
                ) {
                    val u = density
                    drawCircle(Color(0xFF23232D), 16 * u, Offset(96 * u, 22 * u))
                    drawCircle(Color(0xFF3A3A47), 16 * u, Offset(96 * u, 22 * u), style = Stroke(2 * u))
                    drawCircle(Color(0xFF6E6E7A), 6 * u, Offset(96 * u, 22 * u))
                    scale(u, u, pivot = Offset.Zero) {
                        drawPath(armPath, Color(0xFFC9C9D3), style = Stroke(5f, cap = StrokeCap.Round, join = StrokeJoin.Round))
                        rotate(-40f, pivot = Offset(61f, 149f)) {
                            drawRoundRect(Color(0xFFE9E9EF), Offset(48f, 140f), Size(26f, 18f), CornerRadius(4f))
                        }
                    }
                }
            }

            // Title + like
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(top = 6.dp)) {
                key(track) {
                    val e = rememberEnter(0, 550)
                    Column(Modifier.weight(1f).graphicsLayer { alpha = e.value; translationY = (1f - e.value) * 14.dp.toPx() }) {
                        Text(t.title, color = C.text, fontSize = 26.sp, fontWeight = FontWeight.Bold)
                        Text(t.artist, color = Color(0xFFA3A3AF), fontSize = 14.sp)
                    }
                }
                Box(
                    Modifier.size(48.dp).clip(CircleShape).background(Color.White.copy(alpha = .06f)).clickable {
                        liked = !liked
                        scope.launch { pop.animateTo(1.45f, tween(180)); pop.animateTo(1f, tween(270, easing = EaseBack)) }
                    },
                    contentAlignment = Alignment.Center,
                ) {
                    Box(Modifier.graphicsLayer { scaleX = pop.value; scaleY = pop.value }) {
                        if (liked) SvgIcon(HEART, 22.dp, C.heart) else SvgIcon(HEART, 22.dp, Color(0xFFC9C9D3), stroke = 2f)
                    }
                }
            }

            // EQ
            Row(Modifier.fillMaxWidth().height(44.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.Bottom) {
                for (i in 0 until nBars) {
                    val c = when (i % 3) { 0 -> accent; 1 -> Color(0x8CF4F4F6); else -> Color(0x40F4F4F6) }
                    key(i, bench.load) { EqBar(i, c, barW, playing) }
                }
            }

            // Progress
            Column {
                BoxWithConstraints(
                    Modifier.fillMaxWidth().height(22.dp).pointerInput(Unit) {
                        detectTapGestures { o -> progress = (o.x / size.width).coerceIn(0f, .999f) }
                    },
                    contentAlignment = Alignment.CenterStart,
                ) {
                    val w = maxWidth
                    Box(Modifier.fillMaxWidth().height(5.dp).clip(RoundedCornerShape(5.dp)).background(Color.White.copy(alpha = .12f)))
                    Box(Modifier.fillMaxWidth(progress).height(5.dp).clip(RoundedCornerShape(5.dp)).background(accent))
                    Box(Modifier.offset { IntOffset(((w * progress) - 8.dp).roundToPx(), 0) }.size(16.dp).clip(CircleShape).background(C.text))
                }
                Row(Modifier.fillMaxWidth().padding(top = 6.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text(fmt(progress * t.len), color = C.muted, fontSize = 12.sp)
                    Text(fmt(t.len.toFloat()), color = C.muted, fontSize = 12.sp)
                }
            }

            // Controls
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(36.dp, Alignment.CenterHorizontally), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(56.dp).clip(CircleShape).clickable { go(-1) }, contentAlignment = Alignment.Center) { SvgIcon(PREV, 30.dp, C.text) }
                Box(Modifier.size(80.dp).clip(RoundedCornerShape(playRadius)).background(accent).clickable { playing = !playing }, contentAlignment = Alignment.Center) {
                    key(playing) {
                        val e = rememberEnter(0, 350, EaseBack)
                        SvgIcon(if (playing) PAUSE else PLAY, 30.dp, C.bg, Modifier.graphicsLayer {
                            val v = e.value; scaleX = .4f + .6f * v; scaleY = scaleX; rotationZ = -90f * (1f - v); alpha = v.coerceIn(0f, 1f)
                        })
                    }
                }
                Box(Modifier.size(56.dp).clip(CircleShape).clickable { go(1) }, contentAlignment = Alignment.Center) { SvgIcon(NEXT, 30.dp, C.text) }
            }

            // Lyrics
            Box(
                Modifier.fillMaxWidth().weight(1f).heightIn(min = 132.dp).clip(RoundedCornerShape(24.dp))
                    .background(Color.White.copy(alpha = .04f)).border(1.dp, Color.White.copy(alpha = .06f), RoundedCornerShape(24.dp))
            ) {
                Column(Modifier.wrapContentHeight(Alignment.Top, unbounded = true).padding(horizontal = 22.dp).graphicsLayer { translationY = lyY * density }) {
                    LYRICS.forEachIndexed { i, l -> LyricLine(l, abs(i - idx)) }
                }
            }
        }
    }
}
