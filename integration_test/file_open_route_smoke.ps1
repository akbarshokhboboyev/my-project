param(
    [string]$Adb = 'adb',
    [Parameter(Mandatory=$true)][string]$Serial
)
$ErrorActionPreference = 'Stop'
$package = 'uz.app.shieldguard'
$dumpPath = '/data/local/tmp/shieldguard-route-' + [guid]::NewGuid().ToString('N') + '.xml'
# No real document or provider: the expected result is a qualified read-permission error.
# This tests routing and native inbox delivery, not successful APK parsing/signing.
$uri = 'content://uz.app.shieldguard.synthetic/' + [guid]::NewGuid().ToString('N') + '.apk'
function OwnText {
    $null = & $Adb -s $Serial shell input keyevent KEYCODE_WAKEUP
    $dump = & $Adb -s $Serial shell uiautomator dump $dumpPath
    if ($LASTEXITCODE -ne 0) {return ''}
    [xml]$tree = (& $Adb -s $Serial shell cat $dumpPath) -join ''
    return ($tree.SelectNodes('//node') | Where-Object {$_.package -eq $package} |
        ForEach-Object {$_.text; $_.'content-desc'}) -join "`n"
}
function ReturnHome {
    $own = OwnText
    if ($own -match 'Tekshiruv yakunlanmadi') {
        [xml]$modalTree = (& $Adb -s $Serial shell cat $dumpPath) -join ''
        $discardNode = $modalTree.SelectNodes('//node') | Where-Object {
            $_.package -eq $package -and ($_.text -match '^O.rnatmaslik$' -or $_.'content-desc' -match '^O.rnatmaslik$')
        } | Select-Object -First 1
        if (!$discardNode) {throw 'Unknown APK dialog cancel action missing.'}
        $bounds = [regex]::Match([string]$discardNode.bounds, '\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
        $null = & $Adb -s $Serial shell input tap ([int](([int]$bounds.Groups[1].Value+[int]$bounds.Groups[3].Value)/2)) ([int](([int]$bounds.Groups[2].Value+[int]$bounds.Groups[4].Value)/2))
        $null = OwnText
    }
    [xml]$tree = (& $Adb -s $Serial shell cat $dumpPath) -join ''
    $homeNode = $tree.SelectNodes('//node') | Where-Object {
        $_.package -eq $package -and ($_.text -match '^Bosh sahifa' -or $_.'content-desc' -match '^Bosh sahifa')
    } | Select-Object -First 1
    if (!$homeNode) {throw 'ShieldGuard home navigation unavailable.'}
    $bounds = [regex]::Match([string]$homeNode.bounds, '\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
    if (!$bounds.Success) {throw 'Home navigation bounds unavailable.'}
    $x = [int](([int]$bounds.Groups[1].Value + [int]$bounds.Groups[3].Value) / 2)
    $y = [int](([int]$bounds.Groups[2].Value + [int]$bounds.Groups[4].Value) / 2)
    $null = & $Adb -s $Serial shell input tap $x $y
    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        $own = OwnText
        if ($own -match 'Raqamli xavfsizligingiz uchun' -and $own -notmatch 'Tekshiruv natijasi') {return}
    }
    throw 'Home screen was not observed before the next warm intent.'
}
try {
    foreach ($scenario in @('cold-view', 'warm-view', 'warm-send')) {
        if ($scenario -ne 'cold-view') {ReturnHome}
        $arguments = @('-s', $Serial, 'shell', 'am', 'start', '-W', '-n', "$package/.MainActivity")
        if ($scenario -eq 'cold-view') {
            # Recreate the Activity/task, preserving the notification-listener process/service.
            $arguments += @('-f', '0x10008000')
        }
        if ($scenario -eq 'warm-send') {
            $arguments += @('-a', 'android.intent.action.SEND', '-t', 'application/vnd.android.package-archive',
                '--eu', 'android.intent.extra.STREAM', $uri)
        } else {
            $arguments += @('-a', 'android.intent.action.VIEW', '-t', 'application/vnd.android.package-archive', '-d', $uri)
        }
        $null = & $Adb @arguments
        if ($LASTEXITCODE -ne 0) {throw "Activity launch failed: $scenario"}
        $passed = $false
        for ($attempt = 0; $attempt -lt 12; $attempt++) {
            $own = OwnText
            if ($own -match 'GoException|No routes for location' -or $own.Contains($uri)) {
                throw "Raw route/URI error was displayed: $scenario"
            }
            if ($own -match 'Tekshiruv natijasi|Tekshiruv yakunlanmadi' -and $own -match 'qish.*ruxsat|ruxsat.*qish') {
                $passed = $true; break
            }
            Start-Sleep -Milliseconds 300
        }
        if (!$passed) {throw "Expected qualified scan result missing: $scenario. Check that the device is unlocked."}
        "PASS $scenario (synthetic inaccessible URI; no APK installed or executed)."
    }
} finally {
    $null = & $Adb -s $Serial shell rm -f $dumpPath
}
