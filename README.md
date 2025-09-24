# Not licensed by Nintendo

Game Boy startup logo animation.

![Not licensed by Nintendo](https://img.itch.zone/aW1hZ2UvMzg0MTE4NS8yMjkyNDE1Ny5wbmc=/347x500/UvghrD.png)
![Not licenced by Nintendo](https://github.com/user-attachments/assets/e0547320-5d25-4b38-a8fe-c750af6ae1b5)

This is my first Game Boy project ever. The code is pure assembly and the art is hand-painted.

The demo consists of three separate scenes:

1. _Not licensed by_ dropping from above.
2. ® falling down.
3. Everything flying away.

## Platform-Specific Features

* **Game Boy Colour:** B&W palette with optional multi-colour palettes for _Not licensed by_
* **DMG0:** ® is invisible

## Flavours

* [drop-only](https://github.com/TheLeanArt/NotLicensed/tree/drop-only) (scene 3 removed, much smaller ROM footprint)

## Technical Details

The 10 sprite-per-scanline limitation is overcome in the third scene by rendering some of the elements separately:

* _by_ and _e_ on the background (causing them to share the vector of movement) and
* 2nd _n_ on the window.

## Building from Source

```
make
```

### Customisations

**Note:** Make sure that any the following isn't preceded in Makefile by any commented-out lines. Otherwise, the changes will have no effect!

* **INTRO_SONG:** remove the `#` from `-D INTRO_SONG=intro_song`, `src/intro/intro_song.o` and `src/hUGEDriver.o` in Makefile (replace `intro_song` with your own hUGETracker song).
* **INTRO_SONG_DELAY:** remove the `#` from `-D INTRO_SONG_DELAY=$10` (replace `10` with the appropriate hexadecimal delay in ticks).
* **COLOR8:** remove the `#` from `-D COLOR8` in Makefile.
* **EN_GB:** remove the `#` from `-D EN_GB` in Makefile.

Once the changes are applied, execute

```
make clean all
```

## Deployments

* [KULI](https://leanart.itch.io/kuli)
* [Shlimazl](https://leanart.itch.io/shlimazl) ([drop-only](https://github.com/TheLeanArt/NotLicensed/tree/drop-only)+EN_GB+colour+music)
* [Still Got the Blues](https://leanart.itch.io/sgb)
* [The Late Demo](https://leanart.itch.io/latedemo) (full colour+music)

Feel free to use in your project (but consider dropping me a line).

## Acknowledgments

* Code portions adapted from [Simple GB ASM Examples](https://github.com/tbsp/simple-gb-asm-examples/) by Dave VanEe
* SGB transfers adapted from [Snek!](https://github.com/gb-archive/snek-gbc/) by Zlago
* CI script adapted from [ISSOtm's contribution](https://github.com/tbsp/simple-gb-asm-examples/pull/2) to _Simple GB ASM Examples_
* [hUGEDriver](https://github.com/SuperDisk/hUGEDriver/) written by SuperDisk
* Audio sample adapted from _Wild Pokemon Appear_ by Junichi Masuda
