package fr.grandjean.velour

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

/// [FlutterFragmentActivity] étend [androidx.activity.ComponentActivity] :
/// requis pour [enableEdgeToEdge] (Android 15+ / Play Console bord à bord).
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
