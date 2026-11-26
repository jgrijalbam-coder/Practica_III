# WorkManager creates its Room database implementation through reflection.
# Preserve these classes so R8 does not remove their constructors in release APKs.
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
