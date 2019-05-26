![alt text](./stride_banner.png "Stride: a cross platform Swift IDE")

Stride is a cross-platform IDE for Swift development.  Stride is in the early stages of its development, but is useful and usable in its present state where alternatives are limited.  It's "self-hosting": you can edit, build and run Stride within itself.

As its project model Stride uses Swift packages, thereby providing first class support for Swift packages.  You simply open a Package.swift in Stride and your full package source will be shown, including any dependencies that have been set to "edit" mode via the Swift Package Manager.  This has not yet been extensively tested outside of Stride's own packages.

Stride uses a custom GUI toolkit, written from scratch in Swift, in order to provide a single consistent codebase and experience across platforms.  While only macOS and Linux are supported today, backends for other platforms are planned once things stabilize a little bit more.

## Building

Stride builds opened projects using the "swift build" command in the project root directory.  Improvements are planned in this area to allow for the customisation of the command's parameters, but in the meantime Stride will prefer a file named exactly "build.sh" over "swift build" if such a file exists in the project's root directory. This can be used if your project relies on additional parameters in its build.  Stride itself is built using such a file.  NB. if you provide a custom build.sh file, please ensure it exits with the appropriate status, since Stride uses this to determine whether the build succeeded or failed.  Take a look at Stride's own build.sh file for an example.

## Debugging

Debugging has not yet been implemented, but it is top of the list once the current feature set is stable and rounded out.

## Contributing

Your input is very much welcomed.  There's a lot to do, but you're getting involved at a time when you can have a major impact and influence on an exciting project.  Stride is developed hand-in-hand with Suit, a cross-platform Swift GUI toolkit, so you'll have to get your hands dirty there, too--but it'll be fun.

## Quick Start

If you're running on macOS, you simply need to pull down the repository, then:

    cd Stride
    swift package update
    ./build.sh
    swift run --skip-build

If you're running Linux, pull down the repository, then:

    cd Stride
    swift package edit Suit
    ./Packages/Suit/install_dependencies_ubuntu.sh
    swift package update
    ./build.sh
    swift run --skip-build

If you subsequently modify the source, then just build and run as you'd expect:

    ./build.sh
    swift run --skip-build