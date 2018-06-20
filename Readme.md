VideoKit
===

Apple's video player and streamer solutions are very limited, supporting only specific video file formats, HTTP streaming and the h264 video codec. The source code powering the player and streamer is proprietary and it renders the task of streaming a very difficult one.

iOS VideoKit is a custom video player that plays divx, mkv, flv, (and many more formats) and uses other popular streaming protocols such as MMS, RTSP, RTMP. This SDK is capable of playing video files and streams from an HTTP server while using different audio/video codecs or playing video files and streams from a server which utilize the apple API (MPMoviePlayerController or AVPlayerItem).

It has some key features such as multiple players on same view, recording functionality, screenshot capturing and Custom I/O feature.

If you ever find yourself in need to modify the video player, the buffering duration, audio or video raw data or many other aspects then iOS VideoKit is for you.

This SDK was built using FFmpeg, OpenGL ES 2.0 & Apple's AudioUnit.

Note: The trial version is same as the paid one, except trial has logo on screen and it has a 15 minutes play duration limitation.


###You can purchase a commercial license at [iOS VideoKit](http://iosvideokit.com).

# Features

- Supports RTSP, RTMP, HTTP, MMS and secure streams with openSSL support (https, rtmps, rtmpe, rtmpte, rtsps & tls)
- Supports multiple players on same view
- Supports recording functionality (No transcoding, record as it is)
- Supports screenshot capture
- Custom I/O support (support playing audio/video stream in memory)
- iOS and tvOS support
- Bitcode support
- Xcode 8 and iOS10 support
- Play most popular media files locally that Apple doesn’t support
- Stream from popular protocols (http, mms, rtsp & rtmp)
- Supports all popular audio & video codecs
- Supports mjpeg streams - mostly for ipcams
- Supports animated GIF files with full transparency
- Supports real time video effects with using pixel shaders
- Successful Audio & video syncing
- Very easy to use (very similar to Apple's MPMoviePlayerViewController API & MPMoviePlayerController)
- Look & feel like Apple's MPMoviePlayerViewController & MPMoviePlayerController
- Works with Wifi & 3G,LTE
- Shows detailed information about stream (audio & video codecs,total streamed data in bytes, connection type)
- Works on these iOS devices (iPhone 4/4S, 5, 6, 6+, 6s, 6s+, and all iPad minis,iPad 2, 3, 4, air, air2) devices & supports all screen types and rotations
- Works on new AppleTV (4th Generation)
- Supports pausing stream
- Supports streaming in background
- Robust error handling
- Supports audio resampling
- Supports seeking in local & remote file streams
- Airplay
- Showing files/streams both in fullscreen and embedded
- Player is an NSObject instance, so can be used without UI
- Supports transition from embedded/fullscreen to fullscreen/embedded
- Supports fullscreen, embedded and non UI control modes
- Supports initial playback time for files
- Supports looping for files
- Supports adjusting volume level for each player
- Supports changing audio streams in realtime
- Supports disabling audio stream in file/stream
- Supports pinch in/out to zoom in/out in any where of video
- Support autolayout for both iOS & tvOS players
- Support HW Video acceleration for h264 codec
- Support HW Audio acceleration for ac3, aac, eac3, amr, and mp3 codecs


#Documentation
For features, integration, usage and some important notes please see [docs](https://iosvideokit.com/documentation/)

All public classes of iOS VideoKit are fully documented. See the [Technical Documentation](http://iosvideokit.com/VKAppleDoc/html) for further information.


# Screenshot of Demo App

![screenshot 1](http://iosvideokit.com/wp-content/uploads/2013/12/vk-ss-welcome.jpg)
![screenshot 2](http://iosvideokit.com/wp-content/uploads/2013/12/vk-ss-fs-playing.jpg)
![screenshot 3](http://iosvideokit.com/wp-content/uploads/2013/12/vk-ss-embedded-playing.jpg)
![screenshot 4](http://iosvideokit.com/wp-content/uploads/2013/12/vk-ss-embedded-ipcams.jpg)
![screenshot 5](http://iosvideokit.com/wp-content/uploads/2013/12/vk-ss-multi-playing.jpg)
![screenshot 6](http://iosvideokit.com/wp-content/uploads/2015/06/vk-ss-record2.jpg)
![screenshot 7](http://iosvideokit.com/wp-content/uploads/2015/06/vk-ss-ss.jpg)
![screenshot 8](http://iosvideokit.com/wp-content/uploads/2015/06/vk-ss-record.jpg)
![screenshot 9](http://iosvideokit.com/wp-content/uploads/2013/12/vk-ss-fs-landscape3.jpg)



