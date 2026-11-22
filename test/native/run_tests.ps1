param([string]$KotlinLib)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$output = Join-Path $root 'build/native-tests.jar'
$null = New-Item -ItemType Directory -Force -Path (Join-Path $root 'build')
$sourceRoot = Join-Path $root 'android/app/src/main/kotlin/uz/app/shieldguard'
$sources = @('FileAnalyzer.kt', 'NotificationAnalyzer.kt', 'ScanLimits.kt', 'StructuralInspector.kt', 'AlertGate.kt', 'ApkContentInspector.kt', 'SplitApkAnalyzer.kt') |
    ForEach-Object { Join-Path $sourceRoot $_ }
$tests = @('FileAnalyzerTest.kt', 'NotificationAnalyzerTest.kt', 'AdvancedFileTest.kt', 'V3StaticTest.kt', 'TelegramPhishingTest.kt') |
    ForEach-Object { Join-Path $PSScriptRoot $_ }
if ($KotlinLib) {
    $stdlib = (Get-ChildItem -LiteralPath $KotlinLib -Filter 'kotlin-stdlib-*.jar' | Select-Object -First 1).FullName
    & java -cp "$KotlinLib/*" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler -no-stdlib -no-reflect -classpath $stdlib -d $output @sources @tests
    $runtime = "$output;$stdlib"
} else {
    & kotlinc @sources @tests -include-runtime -d $output
    $runtime = $output
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
foreach ($main in @('FileAnalyzerTestKt', 'NotificationAnalyzerTestKt', 'AdvancedFileTestKt', 'V3StaticTestKt')) {
    & java -cp $runtime "uz.app.shieldguard.$main"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
& java -cp $runtime 'uz.app.shieldguard.TelegramPhishingTestKt' (Join-Path $root 'test/fixtures/telegram_phishing.tsv')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
