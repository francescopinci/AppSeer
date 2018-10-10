package com.example.francesco.overlay;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.net.Uri;
import android.os.Build;
import android.os.CountDownTimer;
import android.os.Environment;
import android.provider.Settings;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v4.content.FileProvider;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ListView;

import java.io.File;
import java.io.FileFilter;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FilenameFilter;
import java.nio.channels.FileChannel;
import java.util.regex.Pattern;

public class MainActivity extends AppCompatActivity implements SensorEventListener {

    private static final String TAG = "FRANCESCO2";

    private Boolean created = false;
    private SensorManager mSensorManager;
    private Sensor mProximitySensor;
    private WindowSetup windowSetup;

    private Boolean recording = false;
    private CountDownTimer countDownTimer;

    private Intent recordingActivity;
    private File appFilesDir;
    private File cameraDirectory;
    private String[] recordingList;
    private ArrayAdapter adapter;
    private ListView listView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        checkNecessaryPermissions();
        //checkOverlayPermission();

        // setup sensors data
        mSensorManager = (SensorManager) getSystemService(Context.SENSOR_SERVICE);
        mProximitySensor = mSensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY);
        mSensorManager.registerListener(this, mProximitySensor, SensorManager.SENSOR_DELAY_UI);

        // setup data used by overlay
        windowSetup = new WindowSetup(this);

        // setup data to be used when proximity sensor is triggered
        recordingActivity = new Intent();
        recordingActivity.setAction("android.media.action.VIDEO_CAMERA");
        countDownTimer = new CountDownTimer(4000, 4000) {

            public void onTick(long millisUntilFinished) {
            }

            public void onFinish() {
                Log.i(TAG, "CountDown finished -> started recording");
                recording = true;
                startActivity(recordingActivity);
            }
        };

        // setup refresh list of stored videos button
        refreshButton();
        // setup delete button
        deleteButton();

        // setup list view
        appFilesDir = this.getFilesDir();
        recordingList = appFilesDir.list();
        adapter = new ArrayAdapter<String>(this, R.layout.activity_listview, recordingList);
        listView = (ListView) findViewById(R.id.my_list);
        listView.setAdapter(adapter);

    }

    private void checkNecessaryPermissions() {

        if (ContextCompat.checkSelfPermission(this,
                Manifest.permission.WRITE_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED) {

            // Permission is not granted, request the permission
            ActivityCompat.requestPermissions(this,
                    new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE},
                    1);
        }

    }

    @Override
    public void onSensorChanged(SensorEvent event) {

        if (event.sensor.getType() == Sensor.TYPE_PROXIMITY) {
            Log.i(TAG, "Proximity = " + event.values[0]);
            if (!recording) {
                if (event.values[0] == 0.0) {
                    // not recording but proximity sensor activated -> start the countdown to start recording
                    Log.i(TAG, "Not recording | proximity sensor activated -> start CountDown");

                    countDownTimer.start();
                }
                else {
                    // not recording and proximity sensor not activated -> stop CountDown
                    Log.i(TAG, "Not recording | proximity sensor NOT activated -> stop CountDown");

                    countDownTimer.cancel();
                }
            }
            else {
                if (event.values[0] == 0.0) {
                    // recording and proximity sensor activated, just keep recording
                    // i should never get here
                    Log.i(TAG, "Recording | proximity sensor activated -> keep recording and Why are you here?");
                }
                else {
                    // recording and proximity sensor deactivated -> stop recording, show home screen and save last recorded video
                    Log.i(TAG, "Recording | proximity sensor NOT activated -> stop recording and show home screen");

                    showDialer();
                    //showHomeScreen();
                    recording = false;

                    saveLastRecord();
                }
            }
        }

        //if ((event.sensor.getType() == Sensor.TYPE_GRAVITY) && (event.values[0] > 0.08)) {
        //    Log.i("SENSOR", "Gravity = " + event.values[0]);
        //}
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
    }

    private void checkOverlayPermission() {

        if (!Settings.canDrawOverlays(this)) {

            // check non necessary when building for Android version >= Marshmallow but keep it as a reminder
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION);
                startActivity(intent);
            }
//            ActivityCompat.requestPermissions(this,
//                    new String[]{Manifest.permission.SYSTEM_ALERT_WINDOW},
//                    1);
//        }

        }
    }

    private void activateButton() {
//        final Button button = findViewById(R.id.button);
//        button.setOnClickListener(new View.OnClickListener() {
//            public void onClick(View v) {
//                // The overlay is created by main thread after user presses button
//                if (!created) {
//                    created = true;
//                    //windowSetup.createOverlay(getApplicationContext());
//                }
//            }
//        });
    }

    private void showHomeScreen() {

        Intent homeIntent = new Intent(Intent.ACTION_MAIN);
        homeIntent.addCategory( Intent.CATEGORY_HOME );
        homeIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        startActivity(homeIntent);

    }

    private void showDialer() {

        Intent dialerIntent = new Intent();
        dialerIntent.setAction("com.android.phone.action.RECENT_CALLS");
        startActivity(dialerIntent);

    }

    private void saveLastRecord() {

        appFilesDir = this.getFilesDir();
        recordingList = appFilesDir.list();
        File dcimDirectory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM);
        cameraDirectory = new File(dcimDirectory + "/Camera");
        File[] videos = cameraDirectory.listFiles(new FileFilter() {
            @Override
            public boolean accept(File file) {

                return (!file.isHidden()) && (file.getName().substring(file.getName().lastIndexOf(".")).equals(".mp4"));
            }
        });
        if (videos.length <= 0)
            return;

        File recordedVideo = videos[videos.length-1];
        Log.i(TAG, "Last video = " + recordedVideo.getAbsolutePath());

        moveFile(recordedVideo, appFilesDir);

    }

    private void moveFile(File src, File destDir) {

        try {

            File dest = new File(destDir.getAbsolutePath()+ "/Record_" + (recordingList.length+1) + ".mp4");

            FileChannel source = new FileInputStream(src).getChannel();
            FileChannel destination = new FileOutputStream(dest).getChannel();

            if(destination != null && source != null)
                destination.transferFrom(source, 0, source.size());

            if (source!=null)
                    source.close();
            if (destination!=null)
                destination.close();

            //src.delete();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void refreshButton() {

        final Button button = findViewById(R.id.button);
        button.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {

                updateView();

            }
        });

    }

    private void deleteButton() {

        final Button button = findViewById(R.id.delete);
        button.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {

                recordingList = appFilesDir.list();
                File[] filesList = appFilesDir.listFiles();
                // for each file in appFilesDir, delete it
                for (int i = 0; i < filesList.length; i++) {
                    filesList[i].delete();
                }
                updateView();

            }
        });

    }

    private void updateView() {

        recordingList = appFilesDir.list();
        adapter = new ArrayAdapter<String>(getApplicationContext(), R.layout.activity_listview, recordingList);
        listView.setAdapter(adapter);

    }

}
