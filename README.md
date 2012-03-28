# Generating music based on video
  * mp3 and add audio-ducking (potentially covered by iMovie)
  * midi generation (tough algorithmically, maybe more of an april project or entire thesis)
  * very hard, high likelihood of bad-sounding music
  
* get a movie, get frames from the movie
  * number of attribute variables from video

  * (maybe just analyze images?)
  * build music from images

# options:
## build movie image thing, do music later

* Use EchoNest API to chop up songs into bars and allow users to mix and match, creating a new remixed song.  Pick n' Mixer

** Pros -- potentially fun to play with. Musically oriented
** Cons -- similar to garage band? Might not split up automatically though...

# Echonest technique:

## Movie
1. User picks video 
2. User specifies song from library or URL (or we give list of available remote songs)
3. (automatically) API call to EchoNest and beat match songs
4. (automatically or user) build order of bars to fit video length (longer or shorter)
5. (automatically) duck music volume based on video volume
6. export back to library

3 songs:
a. 1  2  3 [ … n-3]  n-2  n-1 n (bars)
1 2 3 n-2 n-1 n (correct length)

b.  1  2  3  4  5 
c.  

(interface)
movie -> image -> variables -> music

# Variables from music (via echo nest):
* time signature
* key signature


# variables from movie:
## Video import/headers
* length of film (NSString *const MPMediaItemPropertyPlaybackDuration;)?
  - Tracks -> Time -> [1][value]

## With image analysis
* fade-out
* color content

# Effects (output)
* duck audio
* pitch transpose
* switch clips

## Video:
* shake orientation
* discolor
* slow down / speed up


# Resources

## EchoNest / Remix / Chopping code
* Scissor - auto -  https://github.com/youpy/scissor

* Python remix examples (see reverse) https://github.com/echonest/remix

Maybe we can build a web-based version and api…


## iOS sample code

* AVMovieExporter - imports and from Asset/Media library, changes some metadata and re-exports as different filetype - https://developer.apple.com/library/ios/#samplecode/AVMovieExporter/Introduction/Intro.html#//apple_ref/doc/uid/DTS40011364

* MoviePlayer - movie playback, playback controls, scaling and repeat - https://developer.apple.com/library/ios/#samplecode/MoviePlayer_iPhone/Introduction/Intro.html#//apple_ref/doc/uid/DTS40007798

* AVPlayer - play video from Camera roll - https://developer.apple.com/library/ios/#samplecode/AVPlayerDemo/Introduction/Intro.html#//apple_ref/doc/uid/DTS40010101

*auriotouch - waveform display in openGL https://developer.apple.com/library/ios/#samplecode/aurioTouch2/Introduction/Intro.html#//apple_ref/doc/uid/DTS40011369

* StopNGo - capture images to live stream, re-export as movie https://developer.apple.com/library/ios/#samplecode/StopNGo/Introduction/Intro.html#//apple_ref/doc/uid/DTS40011123

## Pizzaz
* Squarecam - live camera, face detection and drawing https://developer.apple.com/library/ios/#samplecode/SquareCam/Introduction/Intro.html#//apple_ref/doc/uid/DTS40011190
