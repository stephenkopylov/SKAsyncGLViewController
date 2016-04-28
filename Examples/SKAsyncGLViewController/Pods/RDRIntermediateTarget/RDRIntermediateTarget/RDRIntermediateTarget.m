//
//  RDRIntermediateTarget.m
//
//  Created by Damiaan Twelker on 20/01/14.
//  Copyright (c) 2014 Damiaan Twelker. All rights reserved.
//
//  LICENSE
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Damiaan Twelker
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#import "RDRIntermediateTarget.h"

@interface RDRIntermediateTarget ()

@property (nonatomic, weak) id target;

@end

@implementation RDRIntermediateTarget

#pragma mark - Class methods

+ (instancetype)intermediateTargetWithTarget:(id)target
{
    return [[[self class] alloc] initWithTarget:target];
}

#pragma mark - Lifecycle

- (id)initWithTarget:(id)target
{
    if (self = [super init])
    {
        _target = target;
    }
    
    return self;
}

#pragma mark - Method forwarding

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    // No need to check which selector is called, because
    // the "source" (NSTimer, CADisplayLink or NSThread)
    // will only call one method on this instance by
    // definition (the one passed to the initializer of
    // respective classes).
    
    SEL selector = [anInvocation selector];
    
    if (![self.target respondsToSelector:selector]) {
        [super forwardInvocation:anInvocation];
    }
    else {
        [anInvocation invokeWithTarget:self.target];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    else {
        return [self.target respondsToSelector:aSelector];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{    
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    
    if (!signature) {
        signature = [self.target methodSignatureForSelector:aSelector];
    }
    
    return signature;
}

@end
