# General Goal of this Project

I want to create a pair of demo apps that effectively implement the same overal functionality, but go about it differently. I want to compare performance between the of usage of AnyView when constructing SwiftUI views vs avoiding the need to use AnyView at all in the equivalent functionality app.

## End Goal

I want two apps where the one that misuses AnyView shows **visually obvious performance issues** when create a screen containing full of the problematic pattern and the other uses SwiftUI best practices. My plan is to take videos and Instrument traces of both in a presentation for teaching purposes.

* Create both apps as separate targets in the same Xcode project.
* Use a local package to hold any code that can be used between both targets without modification.

## Anti-patterns to consider for the Wrong Way

1. ViewModels that create their view and store it as a property of said ViewModels. I actually see this pattern a lot when developers think they are creating a flexible framework where the ultimate container view can be ignorant of the details and just work of protocols that the various ViewModels implement.
   
2. Use of non-persistent `id` properties as the `id` of views. For example, the use of UUID that are recreated continually



