doodler
=====

A Clojerl application to create drawings.

Build
-----

    $ rebar3 compile

Examples
-----

There are some example sketches that you can run.

For example to start the `circles` example use the following code:

    $ rebar3 clojerl repl
    Clojure 0.9.0
    clje.user=> (require '[doodler.examples.circles :as c])
    nil
    ;; Start the sketch with a regular 2D canvas
    clje.user=> (c/sketch)
    #erl[:wx_ref 35 :wxFrame #<0.615.0>]

There's also (currently limited) for OpenGL which can be enabled by
providing `:open-gl true` to the skecth:

    ;; Start the sketch with an OpenGL canvas
    clje.user=> (c/sketch :open-gl true)
    Renderer: AMD Radeon Pro 5300M OpenGL Engine
    Version: 2.1 ATI-4.6.20
    Alpha test: 0
    Point size: [0,0,0,0,-1184628731,149241419,944143440,32707,1,0,0,0,944143448,
                 32707,946432320,32707]
    #erl[:wx_ref 35 :wxFrame #<0.643.0>]

References
-----------

- [Getting started with OpenGL in Elixir][opengl-elixir]
- [Introduction to OpenGL][opengl-intro]
- [An Efficient Way to Draw Approximate Circles in OpenGL][opengl-circle]
- [Scenic][scenic]

[opengl-elixir]: https://wtfleming.github.io/2016/01/06/getting-started-opengl-elixir/
[opengl-intro]: https://www3.ntu.edu.sg/home/ehchua/programming/opengl/cg_introduction.html
[opengl-circle]: http://slabode.exofire.net/circle_draw.shtml
[scenic]: https://github.com/boydm/scenic
