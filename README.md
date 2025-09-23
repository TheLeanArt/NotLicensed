# Not licensed by Nintendo

Game Boy startup logo animation.

![Not licensed by Nintendo](https://img.itch.zone/aW1hZ2UvMzg0MTE4NS8yMjkyNDE1Ny5wbmc=/347x500/UvghrD.png)
![Not licenced by Nintendo](https://img.itch.zone/aW1hZ2UvMzg3OTYyNy8yMzI2MzQ3MC5wbmc=/347x500/qjLjW3.png)

This is my first Game Boy project ever. The code is pure assembly and the art is hand-painted.

The demo consists of three separate scenes:

1. "Not licensed by" dropping from above.
2. ® falling down.
3. Everything flying away.

The 10 sprite-per-scanline limitation is overcome in the third scene by rendering two letters on the background (`e`) and on the window (2nd `n`).

## Building from Source

```
make
```

* EN_GB option: remove the `#` from `-D EN_GB` in Makefile.

## Deployments

* [KULI](https://leanart.itch.io/kuli)
* [Shlimazl](https://leanart.itch.io/shlimazl) ([drop-only](https://github.com/TheLeanArt/NotLicensed/tree/drop-only)+EN_GB+colour+[music](https://github.com/TheLeanArt/NotLicensed/tree/music))
* [Still Got the Blues](https://leanart.itch.io/sgb)
* [The Late Demo](https://leanart.itch.io/latedemo)

Feel free to use in your project (but consider dropping me a line).
