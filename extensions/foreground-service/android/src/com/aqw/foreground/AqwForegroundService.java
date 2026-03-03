package com.aqw.foreground;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;

import java.lang.reflect.Constructor;
import java.lang.reflect.Method;

public class AqwForegroundService extends Service {
    public static final String ACTION_START = "com.aqw.foreground.START";
    private static final String CHANNEL_ID = "aqw_pocket_foreground";
    private static final int NOTIFICATION_ID = 777001;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        ensureChannelIfNeeded();
        Notification notification = createNotification();
        startForeground(NOTIFICATION_ID, notification);
        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        stopForeground(true);
        super.onDestroy();
    }

    private void ensureChannelIfNeeded() {
        if (Build.VERSION.SDK_INT < 26) {
            return;
        }
        try {
            NotificationManager manager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
            if (manager == null) {
                return;
            }
            if (manager.getNotificationChannel(CHANNEL_ID) != null) {
                return;
            }

            Class<?> channelClass = Class.forName("android.app.NotificationChannel");
            Constructor<?> ctor = channelClass.getConstructor(String.class, CharSequence.class, int.class);
            Object channel = ctor.newInstance(CHANNEL_ID, "AQW Pocket Service", NotificationManager.IMPORTANCE_LOW);

            Method setDescription = channelClass.getMethod("setDescription", String.class);
            Method setShowBadge = channelClass.getMethod("setShowBadge", boolean.class);
            setDescription.invoke(channel, "Keeps AQW Pocket alive in background");
            setShowBadge.invoke(channel, false);

            Method createChannel = NotificationManager.class.getMethod("createNotificationChannel", channelClass);
            createChannel.invoke(manager, channel);
        } catch (Exception ignored) {
        }
    }

    @SuppressWarnings("deprecation")
    private Notification createNotification() {
        Notification.Builder builder = Build.VERSION.SDK_INT >= 26
                ? new Notification.Builder(this, CHANNEL_ID)
                : new Notification.Builder(this);

        builder
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setSmallIcon(android.R.drawable.stat_notify_sync)
                .setContentTitle("AQW Pocket running")
                .setContentText("Background mode active to keep connection alive")
                .setWhen(System.currentTimeMillis());

        return builder.build();
    }
}
