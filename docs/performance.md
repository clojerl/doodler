# Performance Issues

## Draw

When synchronous calls are used inside the draw function, the frame rate drops
considerably. Things like getting the canvas' brush/pen, or even creating a
new brush/pen are synchronous operations, which means that when changing the color
of the current brush we should avoid creating a new brush/pen or fetching the
exisiting one.

- A possible workaround would be to keep a copy of both pen & brush and just calling
  setColour function (which is async).

  NOTE: this worked in terms of reducing the amount spent on the draw function. But
  the frame rate didn't get any better for some reason.



## Image Size

The bigger the image size the lower the frame rate.

This doesn't look like it's caused by drawing the image in the wxPaintDC for the
canvas but something else. <- WRONG

The slowdown *is* related to the drawing of the bitmap, commenting it out improves
the frame rate by a considerable amount.

## Frame Rate

It seem like the maximum frame rate in OS X is limited by the refresh rate of the
monitor where the canvas is shown.

- https://github.com/processing/p5.js/issues/2372
- https://www.testufo.com/

## Tools

- Use eflame to figure out where is time spent.
- It seems that wx_object:loop is always consuming CPU (could be the message passing)
  for synchronizing the drawing.
