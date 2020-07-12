doodler
=====

A Clojerl application to create drawings.

Build
-----

    $ rebar3 compile

Examples
-----

There are some example sketches that you can run. For example
to start the circles example use the following code:

    $ rebar3 clojerl repl
    Clojure 0.4.0
    clje.user=> (require '[doodler.examples.circles :as c]) (c/sketch)
    nil

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
