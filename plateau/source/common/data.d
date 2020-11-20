module common.data;

import std.conv: to;
import std.path, std.file;
import std.algorithm.comparison;
import atelier;
import gui;
import common.entity;

private {
    TabData[] _tabs;
    uint _currentTabIndex;
    Editor _editor;
}

/// All the map's data in one tab.
final class TabData {
    private {
        Entity[] _entities;
        string _dataPath, _title = "untitled";
        uint _width = 1u, _height = 1u;
        bool _isTitleDirty =  true, _isDirty = true;
        string _background;
    }

    @property {
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

        string background() const { return _background; }
    }

    void resize(int width_, int height_) {
        _width = width_;
        _height = height_;
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
                if(entity.size.sum() < smallestEntity.size.sum())
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

void setTabDataBackground(string filePath) {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    auto tabData = _tabs[_currentTabIndex];
    tabData._background = filePath;
    tabData._isDirty = true;
}

private void _loadData(TabData tabData) {
    JSONValue json = parseJSON(readText(tabData._dataPath));
    if(getJsonStr(json, "type") != "map")
        return;
    tabData._width = getJsonInt(json, "width", 0);
    tabData._height = getJsonInt(json, "height", 0);
    tabData._background = getJsonStr(json, "background", "");

    if(hasJson(json, "entities")) {
        JSONValue[] entitiesNode = getJsonArray(json, "entities");
        foreach (JSONValue entityNode; entitiesNode) {
            Entity entity = new Entity;
            entity.load(entityNode);
            tabData._entities ~= entity;
        }
    }
    tabData._isDirty = false;
}

private void _saveData(TabData tabData) {
    JSONValue json;
    json["type"] = "map";
    json["width"] = tabData._width;
    json["height"] = tabData._height;
    json["background"] = tabData._background;

    JSONValue[] entitiesNode;
    foreach (Entity entity; tabData._entities) {
        entitiesNode ~= entity.save();
    }
    json["entities"] = entitiesNode;
    std.file.write(tabData._dataPath, toJSON(json));
    tabData._isDirty = false;
}