# Not licensed by Nintendo

Game Boy startup logo animation.

![Not licensed by Nintendo](https://img.itch.zone/aW1hZ2UvMzg0MTE4NS8yMjkyNDE1Ny5wbmc=/347x500/UvghrD.png)
![Not licenced by Nintendo](https://img.itch.zone/aW1hZ2UvMzg1NzQ1Mi8yMzI5MzU0MC5wbmc=/347x500/kopBdB.png)

This is my first Game Boy project ever. The code is pure assembly and the art is hand-painted.

The demo consists of three separate scenes:

1. "Not licensed by" dropping from above.
2. ® falling down.
3. Everything flying away.

## Flavours

* [drop-only](https://github.com/TheLeanArt/NotLicensed/tree/drop-only) (much smaller ROM footprint)
* [music](https://github.com/TheLeanArt/NotLicensed/tree/music) (hUGEDriver integration)

## Technical Details

The 10 sprite-per-scanline limitation is overcome in the third scene by rendering some of the elements separately:

* _by_ and _e_ on the background (causing them to share the vector of movement) and
* 2nd _n_ on the window.

## Building from Source

```
make
```

### Customisations

Make sure that any the following isn't preceded by a comment (`#`).

* **COLOR8:** remove the `#` from `-D COLOR8` in Makefile.
* **EN_GB:** remove the `#` from `-D EN_GB` in Makefile.

## Deployments

* [KULI](https://leanart.itch.io/kuli)
* [Shlimazl](https://leanart.itch.io/shlimazl) ([drop-only](https://github.com/TheLeanArt/NotLicensed/tree/drop-only)+EN_GB+colour+[music](https://github.com/TheLeanArt/NotLicensed/tree/music))
* [Still Got the Blues](https://leanart.itch.io/sgb)
* [The Late Demo](https://leanart.itch.io/latedemo) (full colour)

Feel free to use in your project (but consider dropping me a line).

## Acknowledgments

* Code portions adapted from [Simple GB ASM Examples](https://github.com/tbsp/simple-gb-asm-examples/) by Dave VanEe
* CI script adapted from [ISSOtm's contribution](https://github.com/tbsp/simple-gb-asm-examples/pull/2) to _Simple GB ASM Examples_
* [hUGEDriver](https://github.com/SuperDisk/hUGEDriver/) written by SuperDisk
* Audio sample adapted from _Wild Pokemon Appear_ by Junichi Masuda
