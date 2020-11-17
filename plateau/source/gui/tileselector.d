module gui.tileselector;

import std.conv: to;
import std.algorithm.comparison;
import atelier;
import common;

final class TileSelector: VContainer {
    private {
        TileSelectorList _list;
    }

    @property {
        TilesSelection selection() { return _list._tilesSelection; }
    }

    this() {
        setAlign(GuiAlignX.right, GuiAlignY.bottom);
        position(Vec2f(10f, 20f));
        isMovable(true);
        
        auto title = new Label("Tile selector");
        title.setAlign(GuiAlignX.center, GuiAlignY.top);
        addChildGui(title);

        _list = new TileSelectorList;
        _list.setCallback(this, "list");
        addChildGui(_list);

        //States
        GuiState hiddenState = {
            offset: Vec2f(0f, -5000f),
            alpha: 0f
        };
        addState("hidden", hiddenState);

        GuiState visibleState;
        addState("visible", visibleState);

        setState("hidden");
    }

    override void onCallback(string id) {
        if(id == "list")
            triggerCallback();
    }

    void setTileset(Tileset tileset) {
        position(Vec2f(10f, 20f));
        _list.setTileset(tileset);
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.18f, .2f, .5f));
    }
}

private final class TileSelectorList: GuiElement {
    private {
        Tileset _tileset;
        uint _selectionWidth, _selectionHeight;
        Vec2i _startSelection, _endSelection;
        bool _isSelecting, _hasSelection;
        TilesSelection _tilesSelection;
        Vec2i _tileSize = Vec2i(32, 32);
    }

    this() {
        position(Vec2f(0f, 20f));
        size(Vec2f(128f, 20f));

        if(_tileset) {
            const Vec2f tilesetSize = _tileset.size * Vec2f(_tileset.columns, _tileset.lines);
            size(tilesetSize);
        }
		super(GuiElement.Flags.canvas);
    }

    private void setupSelection(uint x, uint y, uint width_, uint height_) {
        x = max(0, x);
        y = max(0, y);
        width_ = min(width_, _tileset.columns - cast(int) x);
        height_ = min(height_, _tileset.lines - cast(int) y);

        _tilesSelection.tileset = _tileset;
        _tilesSelection.width = width_;
        _tilesSelection.height = height_;
        _tilesSelection.tiles = new int[][](width_, height_);

        const int startId = (y * _tileset.columns) + x;
        for(int iy; iy < height_; ++ iy) {
            for(int ix; ix < width_; ++ ix) {
                _tilesSelection.tiles[ix][iy] = startId + ((iy * _tileset.columns) + ix);
            }
        }
        _tilesSelection.isValid = true;
    }

    override void onEvent(Event event) {
        if(!_tileset)
            return;
        switch(event.type) with(EventType) {
        case mouseDown:
            const Vec2i roundedPosition = to!Vec2i(event.mouse.position.round());

            if(roundedPosition.y < 0)
                break;

            if(!_isSelecting && isButtonDown(MouseButton.left)) {
                _isSelecting = true;
                _hasSelection = true;

                _startSelection = roundedPosition / _tileSize;
                _endSelection = roundedPosition / _tileSize;
                _startSelection = _startSelection.clamp(Vec2i.zero, Vec2i(_tileset.columns, _tileset.lines) - 1);
                _endSelection = _endSelection.clamp(Vec2i.zero, Vec2i(_tileset.columns, _tileset.lines) - 1);
            }
            break;
        case mouseUp:
            const Vec2i roundedPosition = to!Vec2i(event.mouse.position.round());

            if(roundedPosition.y < 0)
                break;

            if(_isSelecting && !isButtonDown(MouseButton.left)) {
                _endSelection = roundedPosition / _tileSize;
                _endSelection = _endSelection.clamp(Vec2i.zero, Vec2i(_tileset.columns, _tileset.lines) - 1);
                
                const Vec2i startingPoint = _startSelection.min(_endSelection);
                const Vec2i endingPoint = _startSelection.max(_endSelection);
                const Vec2i selectSize = (endingPoint - startingPoint) + 1;
                _isSelecting = false;
                setupSelection(
                    startingPoint.x,
                    startingPoint.y,
                    selectSize.x,
                    selectSize.y);
                triggerCallback();
            }
            break;
        case mouseUpdate:
            const Vec2i roundedPosition = to!Vec2i(event.mouse.position.round());

            if(roundedPosition.y < 0)
                break;

            if(_isSelecting) {
                _endSelection = roundedPosition / _tileSize;
                _endSelection = _endSelection.clamp(Vec2i.zero, Vec2i(_tileset.columns, _tileset.lines) - 1);
            }
            break;
        default:
            break;
        }
    }

    void setTileset(Tileset tileset) {
        _hasSelection = false;
        _tileset = tileset;
        if(_tileset) {
            const Vec2f tilesetSize = _tileset.size * Vec2f(_tileset.columns, _tileset.lines);
            size(tilesetSize);
            _tileSize = _tileset.clip.zw;
        }
        else {
            size(Vec2f(128f, 20f));
            _tileSize = Vec2i(32, 32);
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.11f, .12f, .2f));
        if(!_tileset)
            return;
        _tileset.color = Color.white;
        int id;
        __render: for(int y; y < _tileset.lines; ++ y) {
            for(int x; x < _tileset.columns; ++ x) {
                _tileset.draw(id, Vec2f(x * _tileSize.x, y * _tileSize.y));
                id ++;
                if(id >= _tileset.maxtiles)
                    break __render;
            }
        }

        if(_hasSelection) {
            Vec2i startingPoint = _startSelection.min(_endSelection);
            Vec2i endingPoint = _startSelection.max(_endSelection);
            auto rectOrigin = to!Vec2f(startingPoint * _tileSize);
            auto rectSize = to!Vec2f(((endingPoint - startingPoint) + 1) * _tileSize);
            drawRect(rectOrigin, rectSize, Color.white);
        }
    }
}