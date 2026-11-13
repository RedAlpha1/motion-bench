package dev.motionbench.compose

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.lerp as lerpColor
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.layout
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.lerp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import kotlinx.coroutines.delay
import kotlin.math.roundToInt

private const val GRID_TOP = 200
private val CHIPS = listOf("All", "Himachal", "Uttarakhand", "Winter", "Beginner")

private fun lerpF(a: Float, b: Float, t: Float) = a + (b - a) * t

/** Fixed-position, animated-size frame. Reads [p] only in the layout phase (no recomposition per frame). */
private fun Modifier.frame(p: State<Float>, x: Dp, y: Dp, w: Dp, h: Dp, fullW: Dp, fullH: Dp) = layout { m, c ->
    val t = p.value
    val ww = lerp(w, fullW, t).roundToPx(); val hh = lerp(h, fullH, t).roundToPx()
    val pl = m.measure(Constraints.fixed(ww, hh))
    // The node fills the parent so hit-testing works; the card is placed at its animated origin.
    layout(c.maxWidth, c.maxHeight) { pl.place(lerp(x, 0.dp, t).roundToPx(), lerp(y, 0.dp, t).roundToPx()) }
}

private fun polygon(pts: FloatArray, w: Float, h: Float) = Path().apply {
    moveTo(pts[0] / 100f * w, pts[1] / 100f * h)
    var i = 2
    while (i < pts.size) { lineTo(pts[i] / 100f * w, pts[i + 1] / 100f * h); i += 2 }
    close()
}

@Composable
private fun Star(xf: Float, yf: Float, size: Dp, period: Int, delayMs: Int) {
    val inf = rememberInfiniteTransition(label = "star")
    val a by inf.animateFloat(.2f, 1f, infiniteRepeatable(tween(period / 2, easing = EaseInOut), RepeatMode.Reverse, StartOffset(delayMs)), label = "tw")
    BoxWithConstraints(Modifier.fillMaxSize()) {
        Box(Modifier.offset(maxWidth * xf, maxHeight * yf).size(size).graphicsLayer { alpha = a }.clip(CircleShape).background(Color.White))
    }
}

@Composable
private fun Layer(pts: FloatArray, heightFrac: Float, lift: Float, pl: State<Float>, color: Color) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.BottomStart) {
        Canvas(Modifier.fillMaxWidth().fillMaxHeight(heightFrac).graphicsLayer { translationY = -lift * pl.value * density }) {
            drawPath(polygon(pts, size.width, size.height), color)
        }
    }
}

@Composable
private fun TrekCard(k: Trek, i: Int, open: Int, fullW: Dp, fullH: Dp, onOpen: () -> Unit) {
    val colW = (fullW - 60.dp) / 2
    val x = 24.dp + (colW + 12.dp) * k.col
    val y = (GRID_TOP + k.dy).dp
    val me = open == i
    val to = if (me) 1f else 0f
    val p = animateFloatAsState(to, tween(700, easing = EaseFrame), label = "p")
    val f by animateFloatAsState(if (open >= 0 && !me) 1f else 0f, tween(350), label = "f")
    val pl1 = animateFloatAsState(to, tween(900, easing = EaseFrame), label = "pl1")
    val pl2 = animateFloatAsState(to, tween(900, 50, EaseFrame), label = "pl2")
    val pl3 = animateFloatAsState(to, tween(900, 100, EaseFrame), label = "pl3")
    val t = p.value // read in composition for title size/colour

    Box(
        Modifier
            .zIndex(if (t > 0.001f) 30f else 1f)
            .frame(p, x, y, colW, k.h.dp, fullW, fullH)
            .graphicsLayer {
                alpha = 1f - f; scaleX = 1f - .12f * f; scaleY = scaleX
                shape = RoundedCornerShape((26f * (1f - p.value)).dp); clip = true
            }
            .background(Brush.verticalGradient(listOf(k.sky1, k.sky2)))
    ) {
        if (k.night) {
            Star(.18f, .09f, 3.dp, 2100, 0); Star(.42f, .05f, 2.dp, 1600, 400); Star(.70f, .13f, 3.dp, 2600, 900)
            Star(.86f, .06f, 2.dp, 1900, 200); Star(.30f, .18f, 2.dp, 2300, 1100); Star(.58f, .22f, 2.dp, 1700, 700)
        }
        Canvas(Modifier.fillMaxSize()) {
            val s = lerpF(30f, 64f, p.value).dp.toPx()
            val cx = size.width * (0.6f + 0.08f * p.value) + s / 2
            val cy = size.height * (0.14f + 0.01f * p.value) + s / 2
            drawCircle(Brush.radialGradient(listOf(k.sun.copy(alpha = .45f), Color.Transparent), Offset(cx, cy), s * 1.3f), s * 1.3f, Offset(cx, cy))
            drawCircle(k.sun, s / 2, Offset(cx, cy))
        }
        Layer(FAR, .70f, 150f, pl1, k.m1)
        Layer(MID, .50f, 190f, pl2, k.m2)
        Layer(NEAR, .34f, 232f, pl3, k.m3)
        val ink = lerpColor(Color.White, k.ink, t)
        Column(Modifier.offset(lerpF(14f, 24f, t).dp, lerpF(k.h - 62f, 84f, t).dp).padding(end = 14.dp)) {
            Text(k.name, color = ink, fontWeight = FontWeight.Bold, fontSize = lerpF(18f, 38f, t).sp, lineHeight = lerpF(19f, 40f, t).sp)
            Text("${k.alt} · ${k.days}", color = ink.copy(alpha = .85f), fontSize = 12.sp, fontWeight = FontWeight.Medium, modifier = Modifier.padding(top = 4.dp))
        }
        if (open < 0) Box(Modifier.fillMaxSize().clickable(onClick = onOpen))
    }
}

@Composable
private fun Elevation(k: Trek) {
    val draw = rememberEnter(850, 1600, EaseDraw)
    Canvas(Modifier.fillMaxWidth().height(84.dp)) {
        val w = size.width; val h = size.height; val pad = 6.dp.toPx()
        val max = k.prof.max().toFloat(); val min = k.prof.min().toFloat()
        val line = Path()
        k.prof.forEachIndexed { i, v ->
            val px = i * w / (k.prof.size - 1); val py = h - pad - (v - min) / (max - min) * (h - pad * 2)
            if (i == 0) line.moveTo(px, py) else line.lineTo(px, py)
        }
        val area = Path().apply { addPath(line); lineTo(w, h); lineTo(0f, h); close() }
        drawPath(area, k.accent.copy(alpha = .12f))
        val pm = PathMeasure(); pm.setPath(line, false)
        val seg = Path(); pm.getSegment(0f, pm.length * draw.value, seg, true)
        drawPath(seg, k.accent, style = Stroke(2.5.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

@Composable
private fun Modifier.rise(delayMs: Int): Modifier {
    val e = rememberEnter(delayMs, 600)
    return graphicsLayer { alpha = e.value; translationY = (1f - e.value) * 22.dp.toPx() }
}

@Composable
private fun Sheet(k: Trek, onClose: () -> Unit) {
    val up = rememberEnter(180, 750)
    Box(Modifier.fillMaxSize().zIndex(40f)) {
        Row(Modifier.fillMaxWidth().padding(24.dp), horizontalArrangement = Arrangement.SpaceBetween) {
            val c1 = rememberEnter(450, 400, EaseBack); val c2 = rememberEnter(550, 400, EaseBack)
            Box(Modifier.graphicsLayer { val v = c1.value; alpha = v.coerceIn(0f, 1f); scaleX = .6f + .4f * v; scaleY = scaleX }
                .size(44.dp).clip(CircleShape).background(C.bg.copy(alpha = .55f)).clickable(onClick = onClose), contentAlignment = Alignment.Center) {
                SvgIcon("M18 6 6 18M6 6l12 12", 20.dp, Color.White, stroke = 2.2f)
            }
            Box(Modifier.graphicsLayer { val v = c2.value; alpha = v.coerceIn(0f, 1f); scaleX = .6f + .4f * v; scaleY = scaleX }
                .size(44.dp).clip(CircleShape).background(C.bg.copy(alpha = .55f)), contentAlignment = Alignment.Center) {
                SvgIcon("M6 3h12v18l-6-4-6 4z", 20.dp, Color.White, stroke = 2f)
            }
        }
        Column(
            Modifier.align(Alignment.BottomCenter).fillMaxWidth().height(452.dp)
                .graphicsLayer { translationY = (1f - up.value) * 480.dp.toPx() }
                .clip(RoundedCornerShape(topStart = 32.dp, topEnd = 32.dp)).background(C.bg)
                .padding(start = 24.dp, end = 24.dp, top = 14.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Box(Modifier.align(Alignment.CenterHorizontally).size(40.dp, 4.dp).clip(RoundedCornerShape(4.dp)).background(Color(0xFF2A2A36)))
            Text(k.blurb, color = Color(0xFFB8B8C4), fontSize = 14.sp, lineHeight = 21.sp, modifier = Modifier.rise(450))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf("ALTITUDE" to k.alt, "DURATION" to k.days, "GRADE" to k.diff, "SEASON" to k.season).forEachIndexed { j, (kk, v) ->
                    Column(
                        Modifier.weight(1f).rise(500 + j * 70).clip(RoundedCornerShape(16.dp)).background(C.surface)
                            .border(1.dp, C.border, RoundedCornerShape(16.dp)).padding(horizontal = 8.dp, vertical = 10.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                    ) {
                        Text(kk, color = C.muted, fontSize = 10.sp)
                        Text(v, color = C.text, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
            Column(
                Modifier.rise(700).clip(RoundedCornerShape(20.dp)).background(C.surface).border(1.dp, C.border, RoundedCornerShape(20.dp)).padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("Elevation profile", color = C.muted, fontSize = 12.sp); Text("${k.alt} summit", color = C.muted, fontSize = 12.sp)
                }
                Elevation(k)
            }
            Spacer(Modifier.weight(1f))
            val inf = rememberInfiniteTransition(label = "shimmer")
            val sh by inf.animateFloat(0f, 1f, infiniteRepeatable(tween(2400, easing = EaseInOut), RepeatMode.Restart, StartOffset(1400)), label = "sh")
            Box(
                Modifier.rise(850).fillMaxWidth().height(56.dp).clip(RoundedCornerShape(18.dp)).background(C.lime),
                contentAlignment = Alignment.Center,
            ) {
                BoxWithConstraints(Modifier.fillMaxSize()) {
                    Box(Modifier.width(60.dp).fillMaxHeight().graphicsLayer {
                        translationX = lerpF(-100.dp.toPx(), maxWidth.toPx() + 20.dp.toPx(), sh); rotationZ = 0f
                    }.background(Color.White.copy(alpha = .45f)))
                }
                Text("Check batch dates  →", color = C.bg, fontSize = 16.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
fun ExploreScreen(bench: Bench) {
    var open by remember { mutableIntStateOf(-1) }
    var chip by remember { mutableIntStateOf(0) }
    var query by remember { mutableStateOf("") }
    val hdr by animateFloatAsState(if (open >= 0) 1f else 0f, tween(500, easing = EaseSheet), label = "hdr")

    LaunchedEffect(bench.auto) {
        if (!bench.auto) return@LaunchedEffect
        var i = 0
        try {
            while (true) { open = i; delay(1600); open = -1; delay(900); i = (i + 1) % TREKS.size }
        } finally { open = -1 }
    }

    BoxWithConstraints(Modifier.fillMaxSize().background(C.bg).clip(RoundedCornerShape(0.dp))) {
        val fullW = maxWidth; val fullH = maxHeight
        Column(
            Modifier.padding(start = 24.dp, end = 24.dp, top = 16.dp).graphicsLayer { alpha = 1f - hdr; translationY = -20.dp.toPx() * hdr },
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text("HIMALAYA · WINTER 2026", color = C.muted, fontSize = 12.sp, letterSpacing = 1.sp)
            Text("Explore treks", color = C.text, fontSize = 28.sp, fontWeight = FontWeight.Bold, modifier = Modifier.offset(y = (-8).dp))
            BasicTextField(
                query, { query = it }, singleLine = true,
                textStyle = TextStyle(color = C.text, fontSize = 15.sp),
                cursorBrush = SolidColor(C.lime),
                modifier = Modifier.fillMaxWidth().height(48.dp).clip(RoundedCornerShape(16.dp)).background(C.surface)
                    .border(1.dp, C.border, RoundedCornerShape(16.dp)).padding(horizontal = 16.dp),
                decorationBox = { inner ->
                    Box(contentAlignment = Alignment.CenterStart) {
                        if (query.isEmpty()) Text("Search treks, passes, regions", color = Color(0xFF8C8C99), fontSize = 15.sp)
                        inner()
                    }
                },
            )
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                CHIPS.forEachIndexed { i, c ->
                    val on = i == chip
                    Box(
                        Modifier.height(36.dp).clip(RoundedCornerShape(50)).background(if (on) C.text else Color(0xFF121218))
                            .border(1.dp, if (on) C.text else Color(0xFF23232D), RoundedCornerShape(50)).clickable { chip = i }.padding(horizontal = 16.dp),
                        contentAlignment = Alignment.Center,
                    ) { Text(c, color = if (on) C.bg else Color(0xFFC9C9D3), fontSize = 13.sp, fontWeight = FontWeight.SemiBold) }
                }
            }
        }

        TREKS.forEachIndexed { i, k -> TrekCard(k, i, open, fullW, fullH) { open = i } }

        if (open >= 0) key(open) { Sheet(TREKS[open]) { open = -1 } }
    }
}
