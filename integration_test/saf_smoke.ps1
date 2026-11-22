param(
    [string]$Adb = 'adb',
    [string]$Serial,
    [string]$FixturePath,
    [string]$ExpectedText
)
$ErrorActionPreference = 'Stop'
$serialArgs = @()
if ($Serial) { $serialArgs = @('-s', $Serial) }
$extension = if ($FixturePath) { [IO.Path]::GetExtension($FixturePath) } else { '.pdf' }
$fixtureName = 'ShieldGuard-test-' + [guid]::NewGuid().ToString('N').Substring(0, 8) + $extension
$fixture = '/sdcard/Download/' + $fixtureName
$treePath = '/data/local/tmp/shieldguard-saf-test.xml'

function Get-Nodes {
    $null = & $adb @serialArgs shell input keyevent KEYCODE_WAKEUP
    for ($attempt = 0; $attempt -lt 3; $attempt++) {
        $dumpOutput = (& $adb @serialArgs shell uiautomator dump $treePath 2>&1) -join ''
        if ($LASTEXITCODE -eq 0 -and $dumpOutput -match 'dumped to:') {
            [xml]$tree = (& $adb @serialArgs shell cat $treePath) -join ''
            return $tree.SelectNodes('//node')
        }
        Start-Sleep -Milliseconds 500
    }
}
function Tap-Node($node, [switch]$LongPress) {
    if (!$node) { return $false }
    $bounds = [regex]::Match([string]$node.bounds, '\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
    if (!$bounds.Success) { return $false }
    $x = [int](([int]$bounds.Groups[1].Value + [int]$bounds.Groups[3].Value) / 2)
    $y = [int](([int]$bounds.Groups[2].Value + [int]$bounds.Groups[4].Value) / 2)
    if ($LongPress) { $null = & $adb @serialArgs shell input swipe $x $y $x $y 800 }
    else { $null = & $adb @serialArgs shell input tap $x $y }
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
    if ($FixturePath) {
        Copy-Item -LiteralPath $FixturePath -Destination $localFixture
    } else {
        [IO.File]::WriteAllText($localFixture, '%PDF-1.7 /OpenAction /EmbeddedFile %%EOF', [Text.Encoding]::ASCII)
    }
    $null = & $adb @serialArgs push $localFixture $fixture
    if ($LASTEXITCODE -ne 0) { throw 'Could not copy the synthetic fixture.' }
    $null = & $adb @serialArgs shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d ("file://" + $fixture)
    $null = & $adb @serialArgs shell input keyevent KEYCODE_WAKEUP
    for ($i = 0; $i -lt 3; $i++) {
        $focus = (& $adb @serialArgs shell dumpsys window | Select-String 'mCurrentFocus') -join ''
        if ($focus -notmatch 'documentsui') { break }
        $null = & $adb @serialArgs shell input keyevent KEYCODE_BACK
        Start-Sleep -Milliseconds 300
    }
    $null = & $adb @serialArgs shell am force-stop uz.app.shieldguard
    $null = & $adb @serialArgs shell am start -W -n 'uz.app.shieldguard/.MainActivity' -a android.intent.action.MAIN
    $firstScreen = Wait-Node '^Davom etish$|^Faylni tekshirish$'
    if ($firstScreen -and $firstScreen.'content-desc' -eq 'Davom etish') { $null = Tap-Node $firstScreen }
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
            ($_.text -eq 'Downloads' -or $_.text -eq 'Yuklamalar' -or $_.text -eq 'Yuklab olish' -or $_.text -match '^Ko.chirmalar$|^\u0417\u0430\u0433\u0440\u0443\u0437')
        } | Select-Object -First 1
        if (!(Tap-Node $downloads)) { throw 'Downloads location missing in DocumentsUI.' }
        $file = Wait-Node ([regex]::Escape($fixtureName))
    }
    if (!$file) {
        $search = Get-Nodes | Where-Object {
            $_.'resource-id' -match ':id/(option_menu_search|action_menu_search)$' -or
            $_.'content-desc' -match '^Search$|^Qidiruv$'
        } | Select-Object -First 1
        if (Tap-Node $search) {
            $searchField = $null
            for ($attempt = 0; $attempt -lt 4; $attempt++) {
                $searchField = Get-Nodes | Where-Object { $_.class -eq 'android.widget.EditText' } | Select-Object -First 1
                if ($searchField) { break }
            }
            if (!$searchField) { throw 'DocumentsUI search input did not open.' }
            $null = Tap-Node $searchField
            $null = & $adb @serialArgs shell input text $fixtureName
            $null = & $adb @serialArgs shell input keyevent KEYCODE_ENTER
            $file = Wait-Node ([regex]::Escape($fixtureName))
        }
    }
    if (!(Tap-Node $file -LongPress)) { throw 'Synthetic fixture was not listed by DocumentsUI.' }
    $confirm = Wait-Node '^Open$|^OPEN$|^Select$|^SELECT$|^Ochish$|^Tanlash$'
    if (!(Tap-Node $confirm)) { throw 'DocumentsUI selection confirmation missing.' }
    if ($ExpectedText) {
        for ($attempt = 0; $attempt -lt 10; $attempt++) {
            if (Search-Node $ExpectedText) {
                'Android SAF scan returned the expected fixture evidence.'
                exit 0
            }
            $null = & $adb @serialArgs shell input swipe 540 1900 540 900 350
        }
        throw 'The expected fixture evidence was not visible.'
    }
    $result = Wait-Node '45/100'
    $format = Search-Node '132aa3d9440b48e561fc147f04482f1dd2cd33f1b7bd3d4b946078809910bfc5'
    if (!$result -or !$format) { throw 'The expected PDF score and SHA-256 were not visible.' }
    'Android SAF PDF scan returned the expected score and SHA-256.'
} finally {
    if (Test-Path -LiteralPath $localFixture) { Remove-Item -LiteralPath $localFixture }
    $null = & $adb @serialArgs shell rm -f $fixture $treePath
}
