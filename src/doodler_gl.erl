-module(doodler_gl).

-export([ canvas/2
        , render/1
        , draw/0
        ]).

-export([info/0]).

-export([ arc/5
        , circle/3
        , line/4
        , point/2
        , quad/8
        , rect/4
        , triangle/6
        ]).

-export([ begin_shape/0
        , begin_shape/1
        , end_shape/0
        , vertex/2
        , vertex/3
        ]).

-export([ background/1
        , fill/1
        , stroke/1
        ]).

-export([resize/2]).

-include_lib("wx/include/gl.hrl").
-include_lib("wx/include/wx.hrl").

-define(WINDOW_TITLE_HEIGHT, 20).
-define(STROKE_COLOR, '__STROKE_COLOR__').
-define(FILL_COLOR, '__FILL_COLOR__').
-define(BACKGROUND_COLOR, '__BACKGROUND_COLOR__').

-type color() :: {integer(), integer(), integer(), integer()}.
-type colorf() :: {float(), float(), float(), float()}.

%%==============================================================================
%% API
%%==============================================================================

-spec canvas(wxWindow:wxWindow(), color() | undefined) ->
  {wxWindow:wxWindow(), wxGLContext:wxGLContext()}.
canvas(Frame, BgColor) ->
  Size = wxWindow:getSize(Frame),
  Opts = [{size, Size}],
  Attrs = [ { attribList
            , [ ?WX_GL_RGBA
              , ?WX_GL_MIN_RED, 8
              , ?WX_GL_MIN_GREEN, 8
              , ?WX_GL_MIN_BLUE, 8
              , ?WX_GL_DEPTH_SIZE, 24
              , ?WX_GL_DOUBLEBUFFER
                %% Multisampling Anti-aliasing
              , ?WX_GL_SAMPLE_BUFFERS, ?GL_TRUE
              , ?WX_GL_SAMPLES, 4
              , 0
              ]
            }
          ],
  Canvas = wxGLCanvas:new(Frame, Opts ++ Attrs),
  Context = wxGLContext:new(Canvas),

  %% Setup OpenGL
  setup_gl(Canvas, Context, BgColor),

  io:format(info()),

  {Canvas, Context}.

-spec info() -> binary().
info() ->
  io_lib:format( "Renderer: ~s~n"
                 "Version: ~s~n"
                 "Alpha test: ~p~n"
                 "Point size: ~p~n"
               , [ renderer()
                 , version()
                 , gl:isEnabled(?GL_ALPHA_TEST)
                 , gl:getIntegerv(?GL_PROGRAM_POINT_SIZE)
                 ]).

%% Shapes

-spec arc(float(), float(), float(), float(), float()) -> ok.
arc(CX, CY, R, StartAngle, ArcAngle) ->
  NumSegments = 30 * math:sqrt(R),

  Theta = ArcAngle / (NumSegments - 1),

  TanFactor = math:tan(Theta),
  RadialFactor = math:cos(Theta),

  X = R * math:cos(StartAngle),
  Y = R * math:sin(StartAngle),

  Fun = fun(_, {X0, Y0}) ->
            gl:vertex2f(X0 + CX, Y0 + CY), %% output vertex
            TX = -Y0,
            TY = X0,

            X1 = X0 + TX * TanFactor,
            Y1 = Y0 + TY * TanFactor,

            X2 = X1 * RadialFactor,
            Y2 = Y1 * RadialFactor,

            {X2, Y2}
        end,

  gl:'begin'(?GL_LINE_STRIP),
  lists:foldl(Fun, {X, Y}, lists:seq(0, erlang:trunc(NumSegments))),
  gl:'end'().

-spec circle(float(), float(), float()) -> ok.
circle(CX, CY, R) ->
  NumSegments = 30 * math:sqrt(R),
  circle(CX, CY, R, NumSegments).

-spec circle(float(), float(), float(), float()) -> ok.
circle(_CX, _CY, _R, NumSegments) when NumSegments < 0.1 ->
  ok;
circle(CX, CY, R, NumSegments) ->
  Theta = 2 * 3.1415926 / NumSegments,

  Cos = math:cos(Theta),
  Sin = math:sin(Theta),
  X = R, %% we start at angle = 0
  Y = 0,

  IsFill = setup_color(?FILL_COLOR),
  IsStroke = is_color(?STROKE_COLOR),
  Fun = fun(_, {X0, Y0, PointsAcc}) ->
            %% output vertex is there is a fill color
            PointX = X0 + CX,
            PointY = Y0 + CY,
            IsFill andalso gl:vertex2f(PointX, PointY),
            X1 = Cos * X0 - Sin * Y0,
            Y1 = Sin * X0 + Cos * Y0,
            {X1, Y1, [{PointX, PointY} | PointsAcc]}
        end,

  %% Only calculate points if there is a stroke or a fill color
  Points = (IsStroke orelse IsFill) andalso
    begin
      Seq = lists:seq(0, erlang:trunc(NumSegments)),
      gl:'begin'(?GL_POLYGON),
      {_, _, Result} = lists:foldl(Fun, {X, Y, []}, Seq),
      gl:'end'(),
      Result
    end,

  setup_color(?STROKE_COLOR) andalso
    begin
      gl:'begin'(?GL_LINE_LOOP),
      [gl:vertex2f(StrokeX, StrokeY) || {StrokeX, StrokeY} <- Points],
      gl:'end'()
    end.

-spec point(float(), float()) -> ok.
point(X, Y) ->
  setup_color(?STROKE_COLOR) andalso
    begin
      gl:'begin'(?GL_POINTS),
      gl:vertex2f(X, Y),
      gl:'end'()
    end.

-spec line(float(), float(), float(), float()) -> ok.
line(X1, Y1, X2, Y2) ->
  setup_color(?STROKE_COLOR) andalso
    begin
      gl:'begin'(?GL_LINES),
      gl:vertex2f(X1, Y1),
      gl:vertex2f(X2, Y2),
      gl:'end'()
    end.

-spec quad( float(), float()
          , float(), float()
          , float(), float()
          , float(), float()
          ) -> ok.
quad(X1, Y1, X2, Y2, X3, Y3, X4, Y4) ->
  setup_color(?STROKE_COLOR) andalso
    begin
      gl:'begin'(?GL_LINE_LOOP),
      gl:vertex2f(X1, Y1),
      gl:vertex2f(X2, Y2),
      gl:vertex2f(X3, Y3),
      gl:vertex2f(X4, Y4),
      gl:'end'()
    end,

  setup_color(?FILL_COLOR) andalso
    begin
      gl:'begin'(?GL_QUADS),
      gl:vertex2f(X1, Y1),
      gl:vertex2f(X2, Y2),
      gl:vertex2f(X3, Y3),
      gl:vertex2f(X4, Y4),
      gl:'end'()
    end.

-spec rect(float(), float(), float(), float()) -> ok.
rect(X, Y, W, H) ->
  setup_color(?STROKE_COLOR) andalso
    begin
      gl:'begin'(?GL_LINE_LOOP),
      gl:vertex2f(X, Y),
      gl:vertex2f(X + W, Y),
      gl:vertex2f(X + W, Y + H),
      gl:vertex2f(X, Y + H),
      gl:'end'()
    end,

  setup_color(?FILL_COLOR) andalso
    begin
      gl:'begin'(?GL_POLYGON),
      gl:vertex2f(X, Y),
      gl:vertex2f(X + W, Y),
      gl:vertex2f(X + W, Y + H),
      gl:vertex2f(X, Y + H),
      gl:'end'()
    end.

-spec triangle(float(), float(), float(), float(), float(), float()) -> ok.
triangle(X1, Y1, X2, Y2, X3, Y3) ->
  setup_color(?STROKE_COLOR) andalso
    begin
      gl:'begin'(?GL_LINE_LOOP),
      gl:vertex2f(X1, Y1),
      gl:vertex2f(X2, Y2),
      gl:vertex2f(X3, Y3),
      gl:'end'()
    end,

  setup_color(?FILL_COLOR) andalso
    begin
      gl:'begin'(?GL_TRIANGLES),
      gl:vertex2f(X1, Y1),
      gl:vertex2f(X2, Y2),
      gl:vertex2f(X3, Y3),
      gl:'end'()
    end.

%% Shapes

-type shape_mode() :: points
                    | lines
                    | 'line-loop'
                    | triangles
                    | 'triangle-fan'
                    | 'triangle-strip'
                    | quads
                    | 'quad-strip'.

-spec shape_mode(shape_mode()) -> integer().
shape_mode(points) -> ?GL_POINTS;
shape_mode(lines) -> ?GL_LINES;
shape_mode('line-loop') -> ?GL_LINE_LOOP;
shape_mode(triangles) -> ?GL_TRIANGLES;
shape_mode('triangle-fan') -> ?GL_TRIANGLE_FAN;
shape_mode('triangle-strip') -> ?GL_TRIANGLE_STRIP;
shape_mode(quads) -> ?GL_QUADS;
shape_mode('quad-strip') -> ?GL_QUAD_STRIP.

-spec begin_shape() -> ok.
begin_shape() ->
  begin_shape('line-loop').

-spec begin_shape(shape_mode()) -> ok.
begin_shape(Mode) ->
  gl:'begin'(shape_mode(Mode)).

-spec end_shape() -> ok.
end_shape() ->
  gl:'end'().

-spec vertex(float(), float()) -> ok.
vertex(X, Y) ->
  gl:vertex2f(X, Y).

-spec vertex(float(), float(), float()) -> ok.
vertex(X, Y, Z) ->
  gl:vertex3f(X, Y, Z).

%% Colors

-spec background(color()) -> ok.
background(Color) ->
  erlang:put(?BACKGROUND_COLOR, Color),
  {R, G, B, A} = colorf(Color),
  gl:clearColor(R, G, B, A),
  gl:clear(?GL_COLOR_BUFFER_BIT).

-spec fill(color()) -> ok.
fill(Color) ->
  erlang:put(?FILL_COLOR, Color).

-spec stroke(color()) -> ok.
stroke(Color) ->
  erlang:put(?STROKE_COLOR, Color).

-spec setup_color(?FILL_COLOR | ?STROKE_COLOR) -> boolean().
setup_color(FillOrStroke) ->
  case erlang:get(FillOrStroke) of
    undefined -> false;
    Color ->
      gl:color4ubv(Color),
      true
  end.

-spec is_color(?FILL_COLOR | ?STROKE_COLOR) -> boolean().
is_color(FillOrStroke) ->
  erlang:get(FillOrStroke) =/= undefined.

%% Events

-spec resize(wxWindow:wxWindow(), wxGLContext:wxGLContext()) ->
  {integer(), integer()}.
resize(Canvas, Context) ->
  resize(Canvas, Context, erlang:get(?BACKGROUND_COLOR)).

-spec resize(wxWindow:wxWindow(), wxGLContext:wxGLContext(),color()) ->
  {integer(), integer()}.
resize(Canvas, Context, BgColor) ->
  wxGLCanvas:setCurrent(Canvas, Context),

  {Width, Height} = wxWindow:getSize(Canvas),
  gl:viewport(0, 0, Width, Height),
  gl:matrixMode(?GL_PROJECTION),
  gl:loadIdentity(),
  glu:ortho2D(0.0, 1.0 * Width, 1.0 * Height, 0.0),
  gl:matrixMode(?GL_MODELVIEW),
  gl:loadIdentity(),

  %% Background color
  background(BgColor),

  {Width, Height}.

%%==============================================================================
%% Internal functions
%%==============================================================================

-spec colorf(color()) -> colorf().
colorf({R, G, B, Alpha}) ->
  {R / 255, G / 255, B / 255, Alpha / 255}.

-spec setup_gl(wxWindow:wxWindow(), wxGLContext:wxGLContext(), color()) -> ok.
setup_gl(Canvas, Context, BgColor) ->
  resize(Canvas, Context, BgColor),

  %% Smooth shading
  gl:shadeModel(?GL_SMOOTH),

  %% Enable multisample anti-aliasing for nicer looking lines.
  %%
  %% NOTE: This introduces some issues when rendering point
  %% primitives, which instead of occupying a single pixel get
  %% extended to more than one (i.e. 4).
  %%
  %% Disabling MSAA when drawing pixels does make the point occupy a
  %% single pixel, but it also results in some weird horizontal lines
  %% showing up (i.e. in the mandelbrot example).
  gl:enable(?GL_MULTISAMPLE),

  %% Until 3D is included, disable this
  gl:disable(?GL_DEPTH_TEST),

  %% Enable alpha blending, otherwise alpha component is ignored
  gl:enable(?GL_BLEND),
  gl:blendFunc(?GL_SRC_ALPHA, ?GL_ONE_MINUS_SRC_ALPHA),

  ok.

-spec renderer() -> binary().
renderer() ->
  getBinary(?GL_RENDERER).

-spec version() -> binary().
version() ->
  getBinary(?GL_VERSION).

-spec getBinary(integer()) -> binary().
getBinary(Key) ->
  list_to_binary(gl:getString(Key)).

%%==============================================================================
%% Testing functions
%%==============================================================================

-spec draw() -> ok.
draw() ->
  %% background({255, 100, 100, 255}),
  %% gl:clear(?GL_COLOR_BUFFER_BIT bor ?GL_DEPTH_BUFFER_BIT),
  gl:loadIdentity(),
  gl:translatef(0.0, 0.0, 0.0),

  %% gl:'begin'(?GL_TRIANGLES),
  %% gl:color3f(0.0, 0.0, 0.0),
  %% gl:vertex3f(0.0, 1.0, 0.0),
  %% gl:vertex3f(-1.0, -1.0, 0.0),
  %% gl:vertex3f(1.0, -1.0, 0.0),
  %% gl:'end'(),

  %% gl:color3f(1.0, 1.0, 1.0),

  %% [circle(0.0, 0.0, R/10) || R <- lists:seq(1, 10, 2)],

  %% [line(X/10, 1.0, 1.0, X/10) || X <- lists:seq(1, 10, 2)],

  %% [rect(X/10, 1.0, 1.0, X/10) || X <- lists:seq(1, 10, 2)],

  %% [point(X/10, 2.0) || X <- lists:seq(1, 10, 2)],

  %% [ triangle(-X/10, -X/5, -X/3, -X/4, -X/7, -X/6)
  %%   || X <- lists:seq(1, 10, 2)
  %% ],

  %% [rect(-X/10, X/5, 0.5, 0.5) || X <- lists:seq(1, 10, 2)],

  ok.

-spec render(wxWindow:wxWindow()) -> ok.
render(Canvas) ->
  draw(),
  wxGLCanvas:swapBuffers(Canvas),
  ok.
