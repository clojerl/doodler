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
    clje.user=> (require '[doodler.examples.circles :as c]) (c/circles)
    nil
