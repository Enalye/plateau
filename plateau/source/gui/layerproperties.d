module gui.layerproperties;

import atelier;
import common;
import gui.constants, gui.search;

final class LayerProperties: GuiElement {
    private {
        DropDownList _layerTypeSelector, _layerBrushSelector;
        SearchList _layerTilesetSelector;
        string _currentTileset, _currentType, _currentBrush;
        bool _ignoreCallbacks;
    }

    @property {
        string brushName() const { return _currentBrush; }
        string tilesetName() const { return _currentTileset; }
        string typeName() const { return _currentType; }
    }

    this() {
        position(Vec2f(0f, (barHeight + tabsHeight + layersListHeight + layersControlerHeight)));
        size(Vec2f(layersListWidth, screenHeight - (barHeight + tabsHeight + layersListHeight + layersControlerHeight)));
        setAlign(GuiAlignX.left, GuiAlignY.top);

        auto vbox = new VContainer;
        vbox.position = Vec2f(0f, 40f);
        vbox.spacing = Vec2f(5f, 20f);
        vbox.setChildAlign(GuiAlignX.right);
        addChildGui(vbox);

        { //Title
            auto title = new Label("Propriétés");
            title.position = Vec2f(0f, 15f);
            title.setAlign(GuiAlignX.center, GuiAlignY.top);
            addChildGui(title);
        }

        {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.center);
            box.spacing = Vec2f(15f, 0f);
            vbox.addChildGui(box);

            box.addChildGui(new Label("Type:"));

            _layerTypeSelector = new DropDownList(Vec2f(125f, 25f), 5);
            _layerTypeSelector.add("terrain");
            _layerTypeSelector.add("collision");
            _layerTypeSelector.add("movement");
            _layerTypeSelector.add("sight");
            _layerTypeSelector.add("height");
            _layerTypeSelector.add("spawn");
            _layerTypeSelector.setCallback(this, "type");
            box.addChildGui(_layerTypeSelector);
        }

        {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.center);
            box.spacing = Vec2f(15f, 0f);
            vbox.addChildGui(box);

            box.addChildGui(new Label("Tileset:"));

            _layerTilesetSelector = new SearchList("Tileset", Vec2f(125f, 25f));
            foreach(tuple; fetchAllTuples!Tileset()) {
                _layerTilesetSelector.add(tuple[1]);
            }
            _layerTilesetSelector.setCallback(this, "tileset");
            box.addChildGui(_layerTilesetSelector);
        }

        {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.center);
            box.spacing = Vec2f(15f, 0f);
            vbox.addChildGui(box);

            box.addChildGui(new Label("Brush:"));

            _layerBrushSelector = new DropDownList(Vec2f(125f, 25f), 5);
            foreach(tuple; fetchAllTuples!Brush()) {
                if(tuple[0].tileset != _layerTilesetSelector.getSelectedName())
                    continue;
                _layerBrushSelector.add(tuple[1]);
            }
            _layerBrushSelector.setCallback(this, "brush");
            box.addChildGui(_layerBrushSelector);
        }

        //States
        GuiState hiddenState = {
            offset: Vec2f(-300f, 0f),
            alpha: 0f
        };
        addState("hidden", hiddenState);

        GuiState visibleState = {
            time: .5f,
            easing: getEasingFunction(Ease.sineOut)
        };
        addState("visible", visibleState);

        setState("visible");
    }

    void setData(TilesetLayerData data) {
        _ignoreCallbacks = true;
        string typeName = data.getTypeName();
        _layerTypeSelector.setSelectedName(typeName);
        switch(typeName) {
        case "height":
        case "sight":
        case "movement":
            _layerTilesetSelector.setSelectedName("editor.tactical");
            _layerTilesetSelector.isLocked = true;
            break;
        case "collision":
            _layerTilesetSelector.setSelectedName("editor.collision");
            _layerTilesetSelector.isLocked = true;
            break;
        case "spawn":
            _layerTilesetSelector.setSelectedName("editor.spawn");
            _layerTilesetSelector.isLocked = true;
            break;
        default:
            _layerTilesetSelector.setSelectedName(data.getTilesetName());
            _layerTilesetSelector.isLocked = false;
            break;
        }
        if(!data.getBrushName().length && _layerBrushSelector.getChildrenGuisCount() > 0) {
            _layerBrushSelector.selected(0);
            data.setBrushName(_layerBrushSelector.getSelectedName());
        }
        else
            _layerBrushSelector.setSelectedName(data.getBrushName());
        _ignoreCallbacks = false;
    }

    override void onEvent(Event event) {
        switch(event.type) with(EventType) {
        case resize:
            size(Vec2f(layersListWidth, event.window.size.y - (barHeight + tabsHeight + layersListHeight + layersControlerHeight)));
            break;
        default:
            break;
        }
    }

    override void onCallback(string id) {
        if(_ignoreCallbacks)
            return;
        switch(id) {
        case "type":
            const string newType = _layerTypeSelector.getSelectedName();
            if(_currentType == newType)
                break;
            _currentType = newType;
            if(_currentType == "height" ||
                _currentType == "sight" ||
                _currentType == "movement") {
                _layerTilesetSelector.setSelectedName("editor.tactical");
                onCallback("tileset");
                _layerTilesetSelector.isLocked = true;
            }
            else if(_currentType == "collision") {
                _layerTilesetSelector.setSelectedName("editor.collision");
                onCallback("tileset");
                _layerTilesetSelector.isLocked = true;
            }
            else if(_currentType == "spawn") {
                _layerTilesetSelector.setSelectedName("editor.spawn");
                onCallback("tileset");
                _layerTilesetSelector.isLocked = true;
            }
            else {
                _layerTilesetSelector.isLocked = false;
                triggerCallback();
            }
            break;
        case "tileset":
            const string newTileset = _layerTilesetSelector.getSelectedName();
            if(_currentTileset == newTileset)
                break;
            _currentTileset = newTileset;

            ///Update brush list
            _layerBrushSelector.removeChildrenGuis();
            foreach(tuple; fetchAllTuples!Brush()) {
                if(tuple[0].tileset != _layerTilesetSelector.getSelectedName())
                    continue;
                _layerBrushSelector.add(tuple[1]);
            }

            triggerCallback();
            break;
        case "brush":
            const string newBrush = _layerBrushSelector.getSelectedName();
            if(_currentBrush == newBrush)
                break;
            _currentBrush = newBrush;
            triggerCallback();
            break;
        default:
            break;
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.08f, .09f, .11f));
    }
}