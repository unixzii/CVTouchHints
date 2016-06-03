# CVTouchHints

Add touch hints to your screencasts in a **super easy way**.

Since we know, in Android's developer settings, we can toggle on a option that while we are touching the screen, system will display a cute dot to indicate the location we touch. But upsetly, iOS doesn't provide such feature. And now, with this library, you can do it even better!

## Screencast
![](https://github.com/unixzii/CVTouchHints/raw/master/Images/screencast.gif)

## Features
* Supports multitouch.
* Supports customized hint image.

## Usage
**Step 0.** Before using it, don't forget to make a hint image. Of course, I had included my crafty image in this repo (see `Resources` directory), you can directly use it.

**Step 1.** Drop the `UIApplication+TouchHints.m` and `UIApplication+TouchHints.h` to your project.

**Step 2.** Add below line of code to `AppDelegate.m`:
```objective-c
#import "UIApplication+TouchHints.h"
```

**Step 3.** Call `tch_enableTouchHintsWithImage:` in your delegate method, just like this:
```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    // ...
    [[UIApplication sharedApplication] tch_enableTouchHintsWithImage:[UIImage imageNamed:@"touch"]];

    return YES;
}
```
The only argument you need to pass is the `UIImage` you want to use.

OK, just start your wonderful demonstration!

## License
The project is available under the MIT license. See the LICENSE file for more info.
