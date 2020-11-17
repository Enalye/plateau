module common.brush;

import atelier;

final class Brush {
    string name, tileset;
    int[16] neighbors;

    this() {

    }

    this(Brush brush) {
        name = brush.name;
        tileset = brush.tileset;
        neighbors = brush.neighbors;
    }
}