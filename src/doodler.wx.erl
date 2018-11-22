-module('doodler.wx').

-export([batch/1]).

batch(F) ->
  wx:batch(fun() -> clj_rt:apply(F, []) end).
