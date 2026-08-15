# AniMe Matrix assets

`rog-logo-static.png` — upright greyscale ROG Fearless Eye for Static.

## Apply

```bash
asusctl anime --enable-powersave-anim false
asusctl anime --enable-display true
asusctl anime image --path … --scale 1.25 --x-pos 0.0 --y-pos -0.8 --bright 1.0
asusctl anime --enable-display true
```

`image` (not `pixel-image`) — same projector path as GHelper Picture mode.
Placement tuned for GA402 so the eye sits like firmware `RogLogoGlitch`.

## Notes

- Logo chip = firmware `RogLogoGlitch` (animated); no static builtin exists
- GHelper does not ship a Logo PNG
- Install: `~/.local/share/power-deck/anime/rog-logo-static.png`
