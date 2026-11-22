param([string]$Adb = 'adb')
$ErrorActionPreference = 'Stop'
$fixtureName = 'ShieldGuard-test-' + [guid]::NewGuid().ToString('N').Substring(0, 8) + '.pdf'
$fixture = '/sdcard/Download/' + $fixtureName
$treePath = '/data/local/tmp/shieldguard-saf-test.xml'

function Get-Nodes {
    $null = & $adb shell input keyevent KEYCODE_WAKEUP
    for ($attempt = 0; $attempt -lt 3; $attempt++) {
        $null = & $adb shell uiautomator dump $treePath
        if ($LASTEXITCODE -eq 0) {
            [xml]$tree = (& $adb shell cat $treePath) -join ''
            return $tree.SelectNodes('//node')
        }
        Start-Sleep -Milliseconds 500
    }
}
function Tap-Node($node) {
    if (!$node -or $node.bounds -notmatch '\[(\d+),(\d+)\]\[(\d+),(\d+)\]') { return $false }
    $x = [int](([int]$Matches[1] + [int]$Matches[3]) / 2)
    $y = [int](([int]$Matches[2] + [int]$Matches[4]) / 2)
    $null = & $adb shell input tap $x $y
    return $true
}
function Search-Node([string]$pattern) {
    Get-Nodes | Where-Object { $_.text -match $pattern -or $_.'content-desc' -match $pattern } | Select-Object -First 1
}
function Wait-Node([string]$pattern) {
    for ($i = 0; $i -lt 4; $i++) {
        $node = Search-Node $pattern
        if ($node) { return $node }
        Start-Sleep -Milliseconds 500
    }
}

$localFixture = Join-Path ([IO.Path]::GetTempPath()) $fixtureName
try {
    [IO.File]::WriteAllText($localFixture, '%PDF-1.7 /OpenAction /EmbeddedFile %%EOF', [Text.Encoding]::ASCII)
    $null = & $adb push $localFixture $fixture
    if ($LASTEXITCODE -ne 0) { throw 'Could not copy the synthetic fixture.' }
    $null = & $adb shell input keyevent KEYCODE_WAKEUP
    for ($i = 0; $i -lt 3; $i++) {
        $focus = (& $adb shell dumpsys window | Select-String 'mCurrentFocus') -join ''
        if ($focus -notmatch 'documentsui') { break }
        $null = & $adb shell input keyevent KEYCODE_BACK
        Start-Sleep -Milliseconds 300
    }
    $null = & $adb shell am force-stop uz.app.shieldguard
    $null = & $adb shell am start -W -n 'uz.app.shieldguard/.MainActivity' -a android.intent.action.MAIN
    if (!(Tap-Node (Wait-Node '^Faylni tekshirish$'))) { throw 'File scan tile missing.' }
    if (!(Tap-Node (Wait-Node '^Faylni tanlash$'))) { throw 'File picker button missing.' }
    $file = Search-Node ([regex]::Escape($fixtureName))
    if (!$file) {
        $drawer = Get-Nodes | Where-Object {
            $_.class -eq 'android.widget.ImageButton' -and
            $_.bounds -match '^\[(0|[1-9]\d?),'
        } | Select-Object -First 1
        if (!(Tap-Node $drawer)) { throw 'DocumentsUI navigation drawer missing.' }
        $downloads = Get-Nodes | Where-Object {
            $_.'resource-id' -match ':id/title$' -and
            ($_.text -eq 'Downloads' -or $_.text -eq 'Yuklamalar' -or $_.text -match '^Ko.chirmalar$|^\u0417\u0430\u0433\u0440\u0443\u0437')
        } | Select-Object -First 1
        if (!(Tap-Node $downloads)) { throw 'Downloads location missing in DocumentsUI.' }
        $file = Wait-Node ([regex]::Escape($fixtureName))
    }
    if (!(Tap-Node $file)) { throw 'Synthetic fixture was not listed by DocumentsUI.' }
    $result = Wait-Node '45/100'
    $format = Search-Node '132aa3d9440b48e561fc147f04482f1dd2cd33f1b7bd3d4b946078809910bfc5'
    if (!$result -or !$format) { throw 'The expected PDF score and SHA-256 were not visible.' }
    'Android SAF PDF scan returned the expected score and SHA-256.'
} finally {
    if (Test-Path -LiteralPath $localFixture) { Remove-Item -LiteralPath $localFixture }
    $null = & $adb shell rm -f $fixture $treePath
}
