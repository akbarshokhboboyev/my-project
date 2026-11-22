param(
    [string]$Adb='adb',
    [Parameter(Mandatory=$true)][string]$Serial,
    [Parameter(Mandatory=$true)][string]$FolderName,
    [Parameter(Mandatory=$true)][int]$ExpectedScanned,
    [Parameter(Mandatory=$true)][int]$ExpectedCached
)
$ErrorActionPreference='Stop'
if ($FolderName -notmatch '^ShieldGuard-folder-test-[a-f0-9]{8}$') {throw 'Owned test folder required.'}
$path='/data/local/tmp/shieldguard-folder-scan-ui.xml'
function Nodes {
    $null=& $Adb -s $Serial shell input keyevent KEYCODE_WAKEUP
    $ErrorActionPreference='Continue'
    $dump=(& $Adb -s $Serial shell uiautomator dump $path 2>&1) -join ''
    $ErrorActionPreference='Stop'
    if ($LASTEXITCODE -eq 0 -and $dump -match 'dumped to:') {
        [xml]$tree=(& $Adb -s $Serial shell cat $path) -join ''
        return $tree.SelectNodes('//node') | Where-Object {$_.package -eq 'uz.app.shieldguard'}
    }
}
function Tap($node) {
    if (!$node) {return $false}
    $m=[regex]::Match([string]$node.bounds,'\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
    if (!$m.Success) {return $false}
    $null=& $Adb -s $Serial shell input tap ([int](([int]$m.Groups[1].Value+[int]$m.Groups[3].Value)/2)) ([int](([int]$m.Groups[2].Value+[int]$m.Groups[4].Value)/2))
    return $true
}
try {
    $null=& $Adb -s $Serial shell am start -W -n uz.app.shieldguard/.MainActivity -a android.intent.action.MAIN
    $nodes=Nodes
    $nav=$nodes | Where-Object {$_.text -match '^Himoya' -or $_.'content-desc' -match '^Himoya'} | Select-Object -First 1
    if ($nav) {$null=Tap $nav}
    # Debug-only observation: never print the private URI, labels or cache.
    function Snapshot {
        [xml]$prefs=(& $Adb -s $Serial shell run-as uz.app.shieldguard cat shared_prefs/folder-monitor.xml) -join ''
        $map=@{}
        foreach ($entry in $prefs.map.ChildNodes) {$map[$entry.name]=[string]$entry.InnerText}
        $roots=ConvertFrom-Json $map['roots']
        if (@($roots).Count -ne 1 -or $roots[0].label -ne $FolderName) {throw 'Exclusive owned fixture root required.'}
        $summary=@{time=0}
        if ($map['summary']) {$summary=ConvertFrom-Json $map['summary']}
        return @{state=$map['state'];summary=$summary}
    }
    $before=Snapshot
    for ($i=0;$i -lt 8;$i++) {$null=& $Adb -s $Serial shell input swipe 540 650 540 1850 150}
    $owned=$false
    for ($attempt=0;$attempt -lt 15;$attempt++) {
        $nodes=Nodes
        if ($nodes | Where-Object {$_.text -match [regex]::Escape($FolderName) -or $_.'content-desc' -match [regex]::Escape($FolderName)}) {$owned=$true}
        $now=$nodes | Where-Object {$_.text -eq 'Hozir tekshirish' -or $_.'content-desc' -eq 'Hozir tekshirish'} | Select-Object -First 1
        if ($owned -and $now -and (Tap $now)) {break}
        $null=& $Adb -s $Serial shell input swipe 540 1800 540 1100 200
    }
    if (!$owned -or !$now) {throw 'Owned folder/manual scan button unavailable.'}
    for ($attempt=0;$attempt -lt 45;$attempt++) {
        $result=Snapshot
        if ($result.state -eq 'done' -and $result.summary.time -gt $before.summary.time -and
            $result.summary.scanned -eq $ExpectedScanned -and $result.summary.cached -eq $ExpectedCached -and
            $result.summary.partial -eq $false -and $result.summary.unverified -eq 0) {
            "Folder manual scan passed (UI trigger, debug local summary): scanned=$ExpectedScanned cached=$ExpectedCached."
            exit 0
        }
        Start-Sleep -Seconds 1
    }
    throw 'Expected new completed folder scan not observed; OS/provider scheduling may be delayed.'
} finally {$null=& $Adb -s $Serial shell rm -f $path}
