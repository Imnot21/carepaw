# google_mlkit_text_recognition references every script's options class,
# but CarePaw only bundles the Latin recognizer. The others are never loaded.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
