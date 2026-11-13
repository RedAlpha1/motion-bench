package dev.motionbench.compose

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.metrics.performance.JankStats

class MainActivity : ComponentActivity() {
    private lateinit var jank: JankStats

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        // Logs every janky frame to logcat under tag "MotionBench".
        jank = JankStats.createAndTrack(window) { f ->
            if (f.isJank) Log.d("MotionBench", "jank frame ${f.frameDurationUiNanos / 1_000_000}ms ${f.states}")
        }
        setContent { App() }
    }

    override fun onResume() { super.onResume(); jank.isTrackingEnabled = true }
    override fun onPause() { super.onPause(); jank.isTrackingEnabled = false }
}

@Composable
private fun Pill(label: String, on: Boolean, onClick: () -> Unit) {
    Box(
        Modifier
            .height(32.dp)
            .clip(RoundedCornerShape(50))
            .background(if (on) C.text else C.bg)
            .border(1.dp, if (on) C.text else C.border, RoundedCornerShape(50))
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(label, color = if (on) C.bg else Color(0xFFC9C9D3), fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
    }
}

private typealias Color = androidx.compose.ui.graphics.Color

@Composable
fun App() {
    var screen by remember { mutableStateOf("player") }
    var bench by remember { mutableStateOf(Bench()) }
    Column(Modifier.fillMaxSize().background(C.bg).safeDrawingPadding()) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Pill("Player", screen == "player") { screen = "player" }
            Pill("Explore", screen == "explore") { screen = "explore" }
            Spacer(Modifier.weight(1f))
            Pill("Load ${bench.load}×", bench.load == 4) { bench = bench.copy(load = if (bench.load == 1) 4 else 1) }
            Pill("Auto", bench.auto) { bench = bench.copy(auto = !bench.auto) }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(C.border))
        Box(Modifier.weight(1f)) {
            if (screen == "player") PlayerScreen(bench) else ExploreScreen(bench)
        }
    }
}
