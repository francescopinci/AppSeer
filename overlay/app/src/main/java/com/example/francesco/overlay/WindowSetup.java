package com.example.francesco.overlay;

import android.content.Context;
import android.graphics.PixelFormat;
import android.graphics.Point;
import android.view.Display;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;

public class WindowSetup {

    private static WindowManager windowManager;
    private int width, height;
    volatile View padding;
    private int type =  WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY;
    private int flag = 0;

    public WindowSetup(Context context) {

        windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        Display display = windowManager.getDefaultDisplay();
        Point size = new Point();
        display.getSize(size);
        width = size.x;
        height = size.y;

    }

    public void createOverlay(Context context) {

        final Context parentContext = context;

        windowManager = (WindowManager) parentContext.getSystemService(Context.WINDOW_SERVICE);

        padding = View.inflate(parentContext, R.layout.padding_view, null);
        WindowManager.LayoutParams layoutParams_padding = new WindowManager.LayoutParams(width, height, type, flag
                | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                | WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT);
        layoutParams_padding.gravity = Gravity.FILL;
        windowManager.addView(padding, layoutParams_padding);
    }

}
