# drag-chain

A parametric cable drag chain link in OpenSCAD: set the link's width, length and height, how far
it bends each way, and whether the top clips open or is closed.

[Customize and download a link in the browser](https://cameronbrooks11.github.io/drag-chain/), or
open `drag_chain.scad` in [OpenSCAD](https://openscad.org).

## Checks

`just test` renders the link's variants and joins two links at the axle: turned
to `over_angle` or `under_angle` they clear each other, and turned 5 degrees
further they collide. `just fmt` formats the `.scad` file with topiary 0.8.0,
and `just check` fails if it is not formatted.

## Credit and licence

This is an adaptation of [Joerg Scheuermann's cable chain link](https://www.thingiverse.com/thing:8239),
which is licensed CC BY-SA 3.0. The changes are listed at the top of `drag_chain.scad`. As the
ShareAlike terms require, this adaptation is licensed
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/); see [LICENSE](LICENSE).
