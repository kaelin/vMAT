vMAT
====

The **vMAT** library implements a grab-bag of mathematical functions inspired by **MATLAB**[^fn].

This library is being developed as part of a facial recognition project. As such, it
contains a small (but growing) set of matrix functions and related utilities which that project happens to use. In its present
state, there's probably not enough here to be of much interest to anyone outside of that effort, except perhaps as an
example of how **MATLAB** code can be expressed in vectorized **Objective-C**.

# matxd

**matxd** is a command-line tool for exploring the layout of the binary `.mat` file format of **MATLAB**.
It's still in development right now, and not terribly useful for anything beyond validating the
`.mat` reading code in the **vMAT** library (which is _also_ a work-in-progress).


[^fn]: **MATLAB**® is a registered trademark of **[The MathWorks, Inc.](http://www.mathworks.com/products/matlab/)**

[![githalytics.com alpha](https://cruel-carlota.pagodabox.com/a18bc315ffe0cc33fbb2f6a6b275bf88 "githalytics.com")](http://githalytics.com/kaelin/vMAT)