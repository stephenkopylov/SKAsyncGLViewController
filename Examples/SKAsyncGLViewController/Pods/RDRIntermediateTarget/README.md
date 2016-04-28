RDRIntermediateTarget
=====================

A project that demonstrates the use of Objective-C's message passing capabilities to prevent retain cycles caused by interaction with `NSTimer`, `NSThread` or `CADisplayLink` instances.

# Introduction
As you may already know, `NSTimer`, `NSThread`, and `CADisplayLink` instances retain their targets. If the target retains an instance of one of these classes as well, we have a retain cycle: neither the target nor the instance will ever be deallocated.

Why would you want to retain an instance of one of these classes? Imagine you have a certain view animation that requires the use of a `CADisplayLink` instance. As soon as the animation has finished, the `CADisplayLink` instance is not needed anymore and should be paused to prevent your app from waisting resources. In order to pause it, you will have to keep a reference to it.

At this point you might wonder: why not keep a weak reference to the instance instead of a strong one? Doesn't this solve all our problems? The answer is no, because it doesn't change the fact that the target is retained. For example, a `UIViewController` instance that has a weak reference to a repeating `NSTimer` object will never be deallocated because it is retained by the timer.

# What does it do
It enables you to create `NSTimer`, `NSThread` and `CADisplayLink` objects without having to worry about retain cycles.

# How does it work
Internally a `RDRIntermediateTarget` object keeps a weak reference to the actual target (your `UIViewController` for example). It forwards all invocations originated by the `NSTimer`, `NSThread` or `CADisplayLink` to the actual target.

# How to use
Note that the `RDRIntermediateTarget` is not retained! Check out the sample project to learn more.
```objectivec
RDRIntermediateTarget *target = 
[RDRIntermediateTarget intermediateTargetWithTarget:self];
self.timer = [NSTimer timerWithTimeInterval:1.0f
                                     target:target
                                   selector:@selector(_timerFired:)
                                   userInfo:nil
                                    repeats:YES];
                                    
[[NSRunLoop currentRunLoop] addTimer:timer
                             forMode:NSDefaultRunLoopMode];
```

# About the sample project
The sample project features a single `UIViewController` subclass called `ViewController` with a timer, a switch, a label and a button. The timer is repeating and acts as a counter - on every tick, an integer is increased and subsequently displayed on the label. The switch allows you to toggle between a default implementation and an implementation where `RDRIntermediateTarget` is used. The latter is the case when the switch is on. Clicking on the button causes the application to reset the application window's `rootViewController`, which is an instance of `ViewController`. If `rootViewController` is successfully deallocated, you will notice a "DEALLOC" message in the console. If there is a retain cycle, it will not deallocate and thus nothing is logged.

Inside `ViewController` you can change the `strong` keyword for the `timer` property to `weak` to see for yourself that this change does not make a difference. 

# Requirements
* ARC

# License
The code is licensed under the MIT license. See `LICENSE` for more details.
