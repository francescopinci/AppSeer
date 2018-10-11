package com.example.francesco.overlay;

import android.accessibilityservice.AccessibilityService;
import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.view.accessibility.AccessibilityEvent;

public class MyAccessibilityService extends AccessibilityService {

    @Override
    public void onAccessibilityEvent(AccessibilityEvent accessibilityEvent) {
    }

    @Override
    public void onInterrupt() {
    }

}
