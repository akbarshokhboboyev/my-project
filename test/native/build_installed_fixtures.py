from pathlib import Path
import os, subprocess
sdk=Path(os.environ["LOCALAPPDATA"])/"Android/Sdk"
bt=sdk/"build-tools/36.0.0"
root=Path(".dart_tool/installed-fixture").resolve();root.mkdir(exist_ok=True)
for version in [1,2]:
    permissions="" if version==1 else "".join('<uses-permission android:name="android.permission.'+p+'"/>' for p in ["READ_SMS","INTERNET","REQUEST_INSTALL_PACKAGES"])
    manifest=root/("AndroidManifest"+str(version)+".xml")
    manifest.write_text('<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="uz.app.shieldguard.synthetic.monitor" android:versionCode="'+str(version)+'" android:versionName="'+str(version)+'.0">'+permissions+'<application android:hasCode="false" android:label="ShieldGuard sintetik sinov"><activity android:name="android.app.Activity" android:exported="true"><intent-filter><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LAUNCHER"/></intent-filter></activity></application></manifest>',encoding="utf-8")
    unsigned=root/("unsigned"+str(version)+".apk"); signed=root/("fixture"+str(version)+".apk")
    subprocess.run([str(bt/"aapt2.exe"),"link","-o",str(unsigned),"-I",str(sdk/"platforms/android-36/android.jar"),"--manifest",str(manifest),"--min-sdk-version","26","--target-sdk-version","36"],check=True)
    subprocess.run([str(bt/"apksigner.bat"),"sign","--ks",str(Path.home()/".android/debug.keystore"),"--ks-key-alias","androiddebugkey","--ks-pass","pass:android","--key-pass","pass:android","--out",str(signed),str(unsigned)],check=True)
    print("Benign hasCode=false fixture built:",signed.name)
