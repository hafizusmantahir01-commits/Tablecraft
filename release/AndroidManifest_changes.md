# android/app/src/main/AndroidManifest.xml

1. App name shown under the icon:

       <application
           android:label="Tablecraft"
           ...

2. Inside the existing `<queries>` block (near the bottom), add this so "Contact us" can open the email app:

       <intent>
           <action android:name="android.intent.action.SENDTO" />
           <data android:scheme="mailto" />
       </intent>

No INTERNET permission is needed: the app works fully offline (fonts are bundled).
