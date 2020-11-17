module common.data;

import std.conv: to;
import std.path, std.file;
import std.algorithm.comparison;
import atelier;
import gui;
import common.brush, common.history, common.entity;
import common.locale;

private {
    TabData[] _tabs;
    uint _currentTabIndex;
    Editor _editor;
}

enum Weather {
    none, sunny
}

struct TilesSelection {
    Tileset tileset;
    int[][] tiles;
    uint width, height;
    bool isValid;

    void flipH() {
        if(!isValid)
            return;
        int[][] result = new int[][](width, height);
        for(int iy; iy < height; ++ iy) {
            for(int ix; ix < width; ++ ix) {
                result[width - (ix + 1)][iy] = tiles[ix][iy];
            }
        }
        tiles = result;
    }

    void flipV() {
        if(!isValid)
            return;
        int[][] result = new int[][](width, height);
        for(int iy; iy < height; ++ iy) {
            for(int ix; ix < width; ++ ix) {
                result[ix][height - (iy + 1)] = tiles[ix][iy];
            }
        }
        tiles = result;
    }
}

final class TilesetLayerData {
    private {
        string _name = "Sans-Titre";
        Tileset _tileset;
        int[][] _tiles;
        int _width = 1, _height = 1;
        bool _isVisible = true;
        string _typeName, _tilesetName, _brushName;
        int _tileWidth = 32, _tileHeight = 32;
        LayerHistoryFrame[] _historyStack;
        int _historyIndex = -1;
    }

    @property {
        Tileset tileset() { return _tileset; }

        /// Key name
        string name() const { return _name; }
        /// Ditto
        string name(string v) { _onDirty(); return _name = v; }

        int tileWidth() const { return _tileWidth; }
        int tileHeight() const { return _tileHeight; }
    }

    this() {
    }

    this(TilesetLayerData data) {
        _name = data._name;
        _typeName = data._typeName;
        _tilesetName = data._tilesetName;
        _brushName = data._brushName;
        _tileset = data._tileset;
        _width = data._width;
        _height = data._height;
        _tileWidth = data._tileWidth;
        _tileHeight = data._tileHeight;
        _tiles = new int[][](_width, _height);

        for(int iy; iy < _height; ++ iy) {
            for(int ix; ix < _width; ++ ix) {
                _tiles[ix][iy] = data._tiles[ix][iy];
            }
        }
        saveHistoryFrame(true);
    }
    
    void resize(int width_, int height_) {
        int[][] ntiles = new int[][](width_, height_);

        const int minX = std.algorithm.comparison.min(width_, _width);
        const int minY = std.algorithm.comparison.min(height_, _height);
        for(int iy; iy < minY; ++ iy) {
            for(int ix; ix < minX; ++ ix) {
                ntiles[ix][iy] = _tiles[ix][iy];
            }
        }
        _tiles = ntiles;
        _width = width_;
        _height = height_;
    }

    void setDefault() {
        _typeName = "terrain";
        auto tuples = fetchAllTuples!Tileset();
        if(!tuples.length)
            throw new Exception("No tileset defined");
        _tilesetName = tuples[0][1];
        _tileset = fetch!Tileset(_tilesetName);
        _tileset.anchor = Vec2f.zero;

        foreach(tuple; fetchAllTuples!Brush()) {
            if(tuple[0].tileset == _tilesetName) {
                _brushName = tuple[1];
            }
        }
        const auto tab = getCurrentTab();
        _width = tab.width;
        _height = tab.height;
        _tiles = new int[][](_width, _height);

        for(int iy; iy < _height; ++ iy) {
            for(int ix; ix < _width; ++ ix) {
                _tiles[ix][iy] = 0;
            }
        }
        saveHistoryFrame(true);
    }

    void setTypeName(string name_) {
        _typeName = name_;
        _onDirty();
    }

    string getTypeName() const {
        return _typeName;
    }

    void setTilesetName(string name_) {
        _tilesetName = name_;
        _tileset = fetch!Tileset(_tilesetName);
        _tileset.anchor = Vec2f.zero;
        _onDirty();
    }

    string getTilesetName() const {
        return _tilesetName;
    }

    void setBrushName(string name_) {
        _brushName = name_;
    }

    string getBrushName() const {
        return _brushName;
    }

    void setVisibility(bool isVisible) {
        _isVisible = isVisible;
    }

    bool getVisibility() const {
        return _isVisible;
    }

    void setTilesAt(int x, int y, Brush brush, bool updateNeighbors = true, bool saveHistory = true) {
        x = clamp(x, 0, _width);
        y = clamp(y, 0, _height);

        immutable Vec2i[4] neighborsOffset = [
			Vec2i(-1, 0), Vec2i(0, -1),
			Vec2i(1, 0), Vec2i(0, 1)
			];

        Vec2i[] tilesToUpdate;

        ubyte tileId;
        foreach(int i, Vec2i neighborOffset; neighborsOffset) {        
            Vec2i neighbor = Vec2i(x, y) + neighborOffset;
            if(neighbor.x < 0 || neighbor.x >= _width || neighbor.y < 0 || neighbor.y >= _height) {
                tileId |= 0x1 << i;
                continue;
            }
                
            const int neighborId = _tiles[neighbor.x][neighbor.y];
            foreach(listedId; brush.neighbors) {
                if(listedId == neighborId) {
                    tileId |= 0x1 << i;
                    tilesToUpdate ~= neighbor;
                }
            }
        }
        _tiles[x][y] = brush.neighbors[tileId];

        if(updateNeighbors) {
			foreach(Vec2i tileToUpdate; tilesToUpdate)
				setTilesAt(tileToUpdate.x, tileToUpdate.y, brush, false, false);
		}

        if(saveHistory) {
            saveHistoryFrame();
        }
    }

    void setTilesAt(int x, int y, TilesSelection selection, bool saveHistory = true) {
        if(!selection.tiles || !selection.isValid)
            return;
        x = clamp(x, 0, _width);
        y = clamp(y, 0, _height);
        uint width_ = min(selection.width, _width - cast(int) x);
        uint height_ = min(selection.height, _height - cast(int) y);
        
        for(int iy; iy < height_; ++ iy) {
            for(int ix; ix < width_; ++ ix) {
                _tiles[x + ix][y + iy] = selection.tiles[ix][iy];
            }
        }

        if(saveHistory) {
            saveHistoryFrame();
        }
        _onDirty();
    }

    TilesSelection getTilesAt(int x, int y, uint width_, uint height_) {
        x = max(0, x);
        y = max(0, y);
        width_ = min(width_, _width - cast(int) x);
        height_ = min(height_, _height - cast(int) y);

        TilesSelection selection;
        selection.tileset = _tileset;
        selection.width = width_;
        selection.height = height_;
        selection.tiles = new int[][](width_, height_);

        for(int iy; iy < height_; ++ iy) {
            for(int ix; ix < width_; ++ ix) {
                selection.tiles[ix][iy] = _tiles[x + ix][y + iy];
            }
        }
        selection.isValid = true;
        return selection;
    }

    void draw(float alpha) {
        if(!_isVisible)
            return;

        _tileset.alpha = alpha;
        const Vec2f clipSize = Vec2f(_tileWidth, _tileHeight);
        for(int iy; iy < _height; ++ iy) {
            for(int ix; ix < _width; ++ ix) {
                _tileset.draw(_tiles[ix][iy], Vec2f(ix, iy) * clipSize);
            }
        }
    }

    private void saveHistoryFrame(bool clear = false) {
        bool canSave = false;
        if(clear) {
            canSave = true;
            _historyIndex = -1;
        }
        else if(_historyStack.length) {
            auto prevFrame = _historyStack[_historyIndex];
            for(int iy; iy < _height; ++ iy) {
                for(int ix; ix < _width; ++ ix) {
                    if(prevFrame.tiles[ix][iy] != _tiles[ix][iy])
                        canSave = true;
                }
            }
        }
        if(!canSave)
            return;
        LayerHistoryFrame frame = new LayerHistoryFrame;
        frame.tiles = new int[][](_width, _height);
        for(int iy; iy < _height; ++ iy) {
            for(int ix; ix < _width; ++ ix) {
                frame.tiles[ix][iy] = _tiles[ix][iy];
            }
        }
        _historyIndex ++;
        _historyStack.length = _historyIndex;
        _historyStack ~= frame;
    }

    void cancelHistory() {
        if(_historyIndex <= 0)
            return;
        _historyIndex --;
        for(int iy; iy < _height; ++ iy) {
            for(int ix; ix < _width; ++ ix) {
                _tiles[ix][iy] = _historyStack[_historyIndex].tiles[ix][iy];
            }
        }
        _onDirty();
    }

    void restoreHistory() {
        if(_historyStack.length <= 0)
            return;
        if((_historyIndex + 1) >= _historyStack.length)
            return;
        _historyIndex ++;
        for(int iy; iy < _height; ++ iy) {
            for(int ix; ix < _width; ++ ix) {
                _tiles[ix][iy] = _historyStack[_historyIndex].tiles[ix][iy];
            }
        }
        _onDirty();
    }
}

/// All the map's data in one tab.
final class TabData {
    private {
        TilesetLayerData[] _layers;
        Entity[] _entities;
        string _dataPath, _title = "untitled";
        uint _width = 1u, _height = 1u;
        bool _isTitleDirty =  true, _isDirty = true;
        uint _tileWidth = 32, _tileHeight = 32;
        bool _isCameraBound = false;
        Weather _weather;
        string _script;
        float _globalIllumination = 1f;
        Locale _locale;
    }

    @property {
        TilesetLayerData[] layers() { return _layers; }
        Entity[] entities() { return _entities; }
        bool isTitleDirty(bool v) { return _isTitleDirty = v; }
        bool isTitleDirty() const { return _isTitleDirty; }
        string title() { _isTitleDirty = false; return _title;}
        string dataPath() const { return _dataPath; }
        bool isDirty() const { return _isDirty; }

        /// Tileset specific data
        int width() const { return _width; }
        /// Ditto
        int height() const { return _height; }

        int tileWidth() const { return _tileWidth; }
        int tileHeight() const { return _tileHeight; }

        bool isCameraBound() const { return _isCameraBound; }
        bool isCameraBound(bool isBound) { _onDirty(); return _isCameraBound = isBound; }

        Weather weather() const { return _weather; }
        Weather weather(Weather weather_) { _onDirty(); return _weather = weather_; }

        string script() const { return _script; }
        string script(string script_) { _onDirty(); return _script = script_; }

        float globalIllumination() const { return _globalIllumination; }
        float globalIllumination(float globalIllumination_) { _onDirty(); return _globalIllumination = globalIllumination_; }

        Locale locale() { return _locale; }
        Locale locale(Locale locale_) { _onDirty(); return _locale = locale_; }
    }

    void resize(int width_, int height_) {
        _width = width_;
        _height = height_;
        foreach(layer; _layers)
            layer.resize(_width, _height);
        _onDirty();
    }

    Entity getEntityAt(Vec2i at) {
        Entity[] entities;
        foreach (entity; _entities) {
            if(entity.collideWith(at))
                entities ~= entity;
        }
        if(!entities.length)
            return null;
        Entity smallestEntity;
        foreach (Entity entity; entities) {
            if(smallestEntity) {
                if(entity.hitbox.sum() < smallestEntity.hitbox.sum())
                    smallestEntity = entity;
            }
            else {
                smallestEntity = entity;
            }
        }
        return smallestEntity;
    }

    Entity[] searchEntities(Vec2i start, Vec2i end) {
        Entity[] entities;
        foreach (entity; _entities) {
            if(entity.isInside(start, end))
                entities ~= entity;
        }
        return entities;
    }

    void addEntity(Entity entity) {
        entity.reload();
        _entities ~= entity;
        _onDirty();
    }

    void removeEntity(Entity entity_) {
        int id;
        foreach (entity; _entities) {
            if(entity == entity_) {
                if(id + 1 == _entities.length) {
                    _entities.length --;
                }
                else if(id == 0u) {
                    _entities = _entities[1..$];
                }
                else {
                    _entities = _entities[0..id] ~ _entities[id + 1..$];
                }
                _onDirty();
                return;
            }
            id ++;
        }
    }

    bool hasSavePath() {
        return _dataPath.length > 0uL;
    }

    bool canReload() {
        return false;
    }

    //Temporary data, not saved
    bool hasViewerData;
    float viewerScale = 1f;
    Vec2f viewerPosition = Vec2f.zero;

    bool hasPreviewerData;
    float previewerSpeed;

    bool hasLayersListData;
    uint layersListIndex;
}

void initData(Editor editor) {
    _editor = editor;
}

TabData createTab(uint width, uint height) {
    auto tabData = new TabData;
    tabData._width = width;
    tabData._height = height;
    _tabs ~= tabData;
    setCurrentTab(tabData);
    return tabData;
}

/// Open either an image or a json file format in a new tab.
bool openTab(string filePath) {
    auto tabData = new TabData;

    if(exists(filePath)) {
        tabData._dataPath = filePath;
        try {
            _loadData(tabData);
        }
        catch(Exception e) {
            return false;
        }
    }
    else
        return false;

    _tabs ~= tabData;
    setCurrentTab(tabData);
    return true;
}

void reloadTab() {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    auto tabData = _tabs[_currentTabIndex];
    if(!exists(tabData._dataPath))
        return;
    _loadData(tabData);
    _updateTitle();
}

void setTabDataPath(string filePath) {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    auto tabData = _tabs[_currentTabIndex];
    tabData._dataPath = filePath;
    _updateTitle();
}

void saveTab() {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    _saveData(_tabs[_currentTabIndex]);
    _updateTitle();
}

void closeTab() {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");

    if((_currentTabIndex + 1) == _tabs.length) {
        _tabs.length --;
        _currentTabIndex = (_currentTabIndex == 0) ? 0 : (_currentTabIndex - 1);
    }
    else if(_currentTabIndex == 0) {
        _tabs = _tabs[1.. $];
        _currentTabIndex = 0;
    }
    else {
        _tabs = _tabs[0.. _currentTabIndex] ~ _tabs[(_currentTabIndex + 1).. $];
        _currentTabIndex --;
    }
    _updateTitle();
}

void setCurrentTab(TabData tabData) {
    _currentTabIndex = cast(uint)_tabs.length;
    for(int i; i < _tabs.length; i ++) {
        if(tabData == _tabs[i]) {
            _currentTabIndex = i;
            break;
        }
    }
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab no found");
    _updateTitle();
}

void setPreviousTab() {
    if(!hasTab())
        return;
    _currentTabIndex = (_currentTabIndex == 0u) ? (cast(int)_tabs.length - 1) : (_currentTabIndex - 1);
    _updateTitle();
}

void setNextTab() {
    if(!hasTab())
        return;
    _currentTabIndex = ((_currentTabIndex + 1) >= _tabs.length) ? 0u : (_currentTabIndex + 1u);
    _updateTitle();
}

private void _updateTitle() {
    if(_currentTabIndex >= _tabs.length) {
        setWindowTitle("Map Editor");
    }
    else {
        auto tabData = _tabs[_currentTabIndex];
        tabData._isTitleDirty = true;
        string dirtyString = (tabData._isDirty ? " *" : "");
        if(tabData._dataPath.length) {
            tabData._title = baseName(tabData._dataPath) ~ dirtyString;
            setWindowTitle("Map Editor - " ~ tabData._dataPath ~ dirtyString);
        }
        else {
            tabData._title =  tabData._isDirty ? "*" : "";
            setWindowTitle("Map Editor -"  ~ dirtyString);
        }
    }
}

TabData getCurrentTab() {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds5");
    return _tabs[_currentTabIndex];
}

bool hasTab() {
    return _tabs.length > 0uL;
}

TilesetLayerData[] getCurrentElements() {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    return _tabs[_currentTabIndex]._layers;
}

void setCurrentElements(TilesetLayerData[] elements) {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    _tabs[_currentTabIndex]._layers = elements;
    _onDirty();
}

void setSavePath(string filePath) {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    _tabs[_currentTabIndex]._dataPath = filePath;
}

private void _onDirty() {
    if(_tabs[_currentTabIndex]._isDirty)
        return;
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    _tabs[_currentTabIndex]._isDirty = true;
    _updateTitle();
}

package void onEntityDirty() {
    _onDirty();
}

private void _loadData(TabData tabData) {
    JSONValue json = parseJSON(readText(tabData._dataPath));
    if(getJsonStr(json, "type") != "map")
        return;
    tabData._width = getJsonInt(json, "width");
    tabData._height = getJsonInt(json, "height");
    tabData._tileWidth = getJsonInt(json, "tileWidth", 32);
    tabData._tileHeight = getJsonInt(json, "tileHeight", 32);
    tabData._isCameraBound = getJsonBool(json, "isCameraBound", false);
    switch(getJsonStr(json, "weather", "none")) {
    case "none":
        tabData._weather = Weather.none;
        break;
    case "sunny":
        tabData._weather = Weather.sunny;
        break;
    default:
        goto case "none";
    }
    tabData._globalIllumination = getJsonFloat(json, "globalIllumination", 1f);
    tabData._script = getJsonStr(json, "script", "");

    JSONValue[] layersNode = getJsonArray(json, "layers");
    tabData._layers.length = 0uL;
    foreach(JSONValue layerNode; layersNode) {
        TilesetLayerData layer = new TilesetLayerData;
        layer._name = getJsonStr(layerNode, "name");
        layer._typeName = getJsonStr(layerNode, "type");
        switch(layer._typeName) {
        case "height":
        case "sight":
        case "movement":
            layer._tilesetName = "editor.tactical";
            break;
        case "collision":
            layer._tilesetName = "editor.collision";
            break;
        case "spawn":
            layer._tilesetName = "editor.spawn";
            break;
        default:
            layer._tilesetName = getJsonStr(layerNode, "tileset");
            break;
        }
        layer._tileset = fetch!Tileset(layer._tilesetName);
        layer._tileset.anchor = Vec2f.zero;
        layer._brushName = getJsonStr(layerNode, "brush", "");
        layer._width = getJsonInt(layerNode, "width");
        layer._height = getJsonInt(layerNode, "height");
        layer._tileWidth = getJsonInt(layerNode, "tileWidth");
        layer._tileHeight = getJsonInt(layerNode, "tileHeight");
        layer._isVisible = getJsonBool(layerNode, "visible");
        
        int[] tiles = getJsonArrayInt(layerNode, "tiles");
        layer._tiles = new int[][](layer._width, layer._height);
        int i;
        for(int iy; iy < layer._height; ++ iy) {
            for(int ix; ix < layer._width; ++ ix) {
                layer._tiles[ix][iy] = tiles[i];
                i ++;
            }
        }
        layer.saveHistoryFrame(true);

        tabData._layers ~= layer;
    }
    if(hasJson(json, "entities")) {
        JSONValue[] entitiesNode = getJsonArray(json, "entities");
        foreach (JSONValue entityNode; entitiesNode) {
            Entity entity = new Entity;
            entity.load(entityNode);
            tabData._entities ~= entity;
        }
    }
    tabData._locale.load(json);
    tabData._isDirty = false;
}

private void _saveData(TabData tabData) {
    JSONValue json;
    json["type"] = "map";
    json["width"] = tabData._width;
    json["height"] = tabData._height;
    json["tileWidth"] = tabData._tileWidth;
    json["tileHeight"] = tabData._tileHeight;
    json["isCameraBound"] = tabData._isCameraBound;
    json["script"] = tabData._script;
    final switch(tabData._weather) with(Weather) {
    case none:
        json["weather"] = "none";
        break;
    case sunny:
        json["weather"] = "sunny";
        break;
    }
    json["globalIllumination"] = tabData._globalIllumination;

    JSONValue[] layersNode;
    foreach(TilesetLayerData layer; tabData._layers) {
        JSONValue layerNode;
        layerNode["name"] = layer._name;
        layerNode["type"] = layer._typeName;
        switch(layer._typeName) {
        case "height":
        case "sight":
        case "movement":
        case "collision":
        case "spawn":
            break;
        default:
            layerNode["tileset"] = layer._tilesetName;
            break;
        }
        layerNode["brush"] = layer._brushName;
        layerNode["width"] = layer._width;
        layerNode["height"] = layer._height;
        layerNode["tileWidth"] = layer._tileWidth;
        layerNode["tileHeight"] = layer._tileHeight;
        layerNode["visible"] = layer._isVisible;

        int[] tiles;
        for(int iy; iy < layer._height; ++ iy) {
            for(int ix; ix < layer._width; ++ ix) {
                tiles ~= layer._tiles[ix][iy];
            }
        }
        layerNode["tiles"] = tiles;
        layersNode ~= layerNode;
    }
    json["layers"] = layersNode;

    JSONValue[] entitiesNode;
    foreach (Entity entity; tabData._entities) {
        entitiesNode ~= entity.save();
    }
    json["entities"] = entitiesNode;
    tabData._locale.save(json);
    std.file.write(tabData._dataPath, toJSON(json));
    tabData._isDirty = false;
}