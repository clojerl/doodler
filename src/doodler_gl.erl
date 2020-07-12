-module(doodler_gl).

-export([ canvas/1
        , render/1
        ]).

-export([ version/0
        , renderer/0
        ]).

-export([ arc/3
        , circle/3
        , line/4
        , point/2
        , rect/4
        , triangle/6
        ]).

-include_lib("wx/include/gl.hrl").
-include_lib("wx/include/wx.hrl").

-define(WINDOW_TITLE_HEIGHT, 20).

%%==============================================================================
%% API
%%==============================================================================

-spec canvas(wxWindow:wxWindow()) -> wxWindow:wxWindow().
canvas(Frame) ->
  {Width, Height} = Size = wxWindow:getSize(Frame),
  Opts = [{size, Size}],
  Attrs = [ { attribList
            , [ ?WX_GL_RGBA
              , ?WX_GL_MIN_RED, 8
              , ?WX_GL_MIN_GREEN, 8
              , ?WX_GL_MIN_BLUE, 8
              , ?WX_GL_DEPTH_SIZE, 24
              , ?WX_GL_DOUBLEBUFFER
                %% Anti-aliasing
              , ?WX_GL_SAMPLE_BUFFERS, 1
              , ?WX_GL_SAMPLES, 4
              , 0
              ]
            }
          ],
  Canvas = wxGLCanvas:new(Frame, Opts ++ Attrs),

  wxGLCanvas:connect(Canvas, size),
  %% wxWindow:reparent(Canvas, Frame),
  wxGLCanvas:setCurrent(Canvas),

  %% Setup OpenGL
  setup_gl(Width, Height),

  Canvas.

-spec renderer() -> string().
renderer() ->
  getBinary(?GL_RENDERER).

-spec version() -> string().
version() ->
  getBinary(?GL_VERSION).

%% Shapes

-spec arc(float(), float(), float()) -> ok.
arc(_CX, _CY, _R) ->
  ok.

-spec circle(float(), float(), float()) -> ok.
circle(CX, CY, R) ->
  NumSegments = 30 * math:sqrt(R),
  Theta = 2 * 3.1415926 / NumSegments,

  Cos = math:cos(Theta),
  Sin = math:sin(Theta),
  X = R, %% we start at angle = 0
  Y = 0,

  Fun = fun(_, {X0, Y0}) ->
            gl:vertex2f(X0 + CX, Y0 + CY), %% output vertex
            X1 = Cos * X0 - Sin * Y0,
            Y1 = Sin * X0 + Cos * Y0,
            {X1, Y1}
        end,

  gl:'begin'(?GL_LINE_LOOP),
  lists:foldl(Fun, {X, Y}, lists:seq(0, erlang:trunc(NumSegments))),
  gl:'end'().

-spec point(float(), float()) -> ok.
point(X, Y) ->
  gl:'begin'(?GL_POINTS),
  gl:vertex2f(X, Y),
  gl:'end'().

-spec line(float(), float(), float(), float()) -> ok.
line(X1, Y1, X2, Y2) ->
  gl:'begin'(?GL_LINES),
  gl:vertex2f(X1, Y1),
  gl:vertex2f(X2, Y2),
  gl:'end'().

-spec rect(float(), float(), float(), float()) -> ok.
rect(X, Y, W, H) ->
  gl:'begin'(?GL_LINE_LOOP),
  gl:vertex2f(X, Y),
  gl:vertex2f(X + W, Y),
  gl:vertex2f(X + W, Y + H),
  gl:vertex2f(X, Y + H),
  gl:'end'().

-spec triangle(float(), float(), float(), float(), float(), float()) -> ok.
triangle(X1, Y1, X2, Y2, X3, Y3) ->
  gl:'begin'(?GL_LINE_LOOP),
  gl:vertex2f(X1, Y1),
  gl:vertex2f(X2, Y2),
  gl:vertex2f(X3, Y3),
  gl:'end'().

%%==============================================================================
%% Internal functions
%%==============================================================================

-spec setup_gl(integer(), integer()) -> ok.
setup_gl(Width, Height) ->
  resize_gl_scene(Width, Height),

  %% Smooth shading
  gl:shadeModel(?GL_SMOOTH),

  %% Background color
  gl:clearColor(0.0, 0.0, 0.0, 0.0),
  gl:clearDepth(1.0),

  %% Anti-aliasing
  gl:enable(?GL_MULTISAMPLE),
  gl:enable(?GL_MULTISAMPLE_ARB),
  gl:disable(?GL_DEPTH_TEST),

  %% gl:depthFunc(?GL_LEQUAL),
  %% gl:hint(?GL_PERSPECTIVE_CORRECTION_HINT, ?GL_NICEST),
  %% gl:hint(?GL_POLYGON_SMOOTH_HINT, ?GL_NICEST),
  %% gl:hint(?GL_LINE_SMOOTH_HINT, ?GL_NICEST),

  ok.

-spec resize_gl_scene(integer(), integer()) -> ok.
resize_gl_scene(Width, Height) ->
  gl:viewport(0, 0, Width, Height + ?WINDOW_TITLE_HEIGHT),
  gl:matrixMode(?GL_PROJECTION),
  gl:loadIdentity(),
  glu:perspective(45.0, Width / Height, 0.1, 100.0),
  gl:matrixMode(?GL_MODELVIEW),
  gl:loadIdentity(),
  ok.

-spec draw() -> ok.
draw() ->
  gl:clear(?GL_COLOR_BUFFER_BIT bor ?GL_DEPTH_BUFFER_BIT),
  gl:loadIdentity(),
  gl:translatef(0.0, 0.0, -6.0),

  gl:'begin'(?GL_TRIANGLES),
  gl:color3f(0.0, 0.0, 0.0),
  gl:vertex3f(0.0, 1.0, 0.0),
  gl:vertex3f(-1.0, -1.0, 0.0),
  gl:vertex3f(1.0, -1.0, 0.0),
  gl:'end'(),

  gl:color3f(1.0, 1.0, 1.0),

  [circle(0.0, 0.0, R/10) || R <- lists:seq(1, 10, 2)],

  [line(X/10, 1.0, 1.0, X/10) || X <- lists:seq(1, 10, 2)],

  [rect(X/10, 1.0, 1.0, X/10) || X <- lists:seq(1, 10, 2)],

  [point(X/10, 2.0) || X <- lists:seq(1, 10, 2)],

  [ triangle(-X/10, -X/5, -X/3, -X/4, -X/7, -X/6)
    || X <- lists:seq(1, 10, 2)
  ],

  [rect(-X/10, X/5, 0.5, 0.5) || X <- lists:seq(1, 10, 2)],

  ok.

-spec render(wxWindow:wxWindow()) -> ok.
render(Canvas) ->
  draw(),
  wxGLCanvas:swapBuffers(Canvas),
  ok.

-spec getBinary(integer()) -> binary().
getBinary(Key) ->
  list_to_binary(gl:getString(Key)).
