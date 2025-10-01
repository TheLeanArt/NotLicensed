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

* **Game Boy Colour:** B&W palette, multi-colour palettes for _Not licensed by_, gradient, fade-out
* **Super Game Boy:** B&W palette, fade-out
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

The intro provides numerous customisation hooks via `defs.inc`. Following is a non-exhaustive list:

* `INTRO_SONG`: hUGETracker song descriptor.
  * Uncomment `src/intro/intro_song.o` and `src/hUGEDriver.o` in Makefile (and then replace `intro_song` with your own song).
  * `INTRO_SONG_DELAY`: song delay in ticks.
* `COLOR8`: enable multi-colour top letters on GBC.
  * `C_INTRO_TOP`: default top letters' colour.
  * `C_INTRO_TOP_`_n_: (0 <= _n_ <= 7): _n_-th top letter colour.
  * `C_INTRO_BY`: default _by_ letters' colour.
    * `C_INTRO_BY1`: _b_ letter colour.
    * `C_INTRO_BY2`: _y_ letter colour.
* `INTRO_GRADIENT`: enable background gradient on GBC.
  * `C_INTRO_GRADIENT_TOP`: gradient's top colour.
  * `C_INTRO_GRADIENT_BOTTOM`: gradient's bottom colour.
* `INTRO_FADEOUT`: enable fadeout on GBC/SGB.
  * `INTRO_FADEOUT_DMG:` enable fadeout on DMG.
* `EN_GB`: display _licenced_ instead of _licensed_.

Common colour values are defined in `color.inc`.

After changing `Makefile` make sure to execute

```
make clean all
```

**Note:** Uncommented lines that are part of a Makefile multi-line definition must not be preceded by commented-out ones.

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

## Thanks

* calc84maniac for the optimisations
* ISSOtm for great optimisation ideas
* nitro2k01 and ku🐧 for helping to fix the colour LUTs
* Rangi42 for her endless patience
