module gui.entityproperties;

import std.file, std.path;
import std.conv: to;
import atelier;
import common;
import gui.constants, gui.search;

final class EntityProperties: GuiElement {
    private {
        SearchList _entitySelector;
        DropDownList _dirSelector, _behaviorSelector, _mapSelector;
        InputField _nameField, _xPosField, _yPosField, _wField, _hField, _flagsField, _tpField, _factionField;
        string _currentTileset, _currentType, _currentBrush;
        bool _ignoreCallbacks;
        Entity _currentEntity;
        VContainer _container;
        HSlider _rSlider, _gSlider, _bSlider, _aSlider;
        Checkbox _collidableCB;
    }

    @property {
    }

    this() {
        position(Vec2f(0f, barHeight + tabsHeight));
        size(Vec2f(layersListWidth, screenHeight - (barHeight + tabsHeight)));
        setAlign(GuiAlignX.left, GuiAlignY.top);

        { //Title
            auto title = new Label("Propriétés");
            title.position = Vec2f(0f, 15f);
            title.setAlign(GuiAlignX.center, GuiAlignY.top);
            addChildGui(title);
        }

        _container = new VContainer;
        _container.position = Vec2f(0f, 40f);
        _container.spacing = Vec2f(0f, 20f);
        _container.setChildAlign(GuiAlignX.right);
        addChildGui(_container);

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

    private void reload() {
        _container.removeChildrenGuis();

        { // ID
            auto box = new HContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.center);
            box.spacing = Vec2f(5f, 0f);
            _container.addChildGui(box);

            box.addChildGui(new Label("Objet:"));

            _entitySelector = new SearchList("Objet", Vec2f(150f, 25f));
            foreach(tuple; fetchAllTuples!Entity()) {
                _entitySelector.add(tuple[1]);
            }
            _entitySelector.setSelectedName(_currentEntity.id);
            _entitySelector.setCallback(this, "type");
            box.addChildGui(_entitySelector);
        }

        { // Position
            auto box = new HContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.center);
            box.spacing = Vec2f(5f, 0f);
            _container.addChildGui(box);

            box.addChildGui(new Label("x:"));

            _xPosField = new InputField(Vec2f(50f, 25f));
            _xPosField.text = to!string(_currentEntity.position.x);
            _xPosField.setAllowedCharacters("-0123456789");
            _xPosField.setCallback(this, "x");
            box.addChildGui(_xPosField);

            box.addChildGui(new Label("y:"));

            _yPosField = new InputField(Vec2f(50f, 25f));
            _yPosField.text = to!string(_currentEntity.position.y);
            _yPosField.setAllowedCharacters("-0123456789");
            _yPosField.setCallback(this, "y");
            box.addChildGui(_yPosField);
        }

        // Hitbox
        if(!_currentEntity.isTilable) {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.center);
            box.spacing = Vec2f(5f, 0f);
            _container.addChildGui(box);

            box.addChildGui(new Label("w:"));

            _wField = new InputField(Vec2f(50f, 25f));
            _wField.text = to!string(_currentEntity.hitbox.x);
            _wField.setAllowedCharacters("-0123456789");
            _wField.setCallback(this, "w");
            box.addChildGui(_wField);

            box.addChildGui(new Label("h:"));

            _hField = new InputField(Vec2f(50f, 25f));
            _hField.text = to!string(_currentEntity.hitbox.y);
            _hField.setAllowedCharacters("-0123456789");
            _hField.setCallback(this, "h");
            box.addChildGui(_hField);
        }

        { // Name
            auto box = new HContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.center);
            box.spacing = Vec2f(5f, 0f);
            _container.addChildGui(box);

            box.addChildGui(new Label("Nom:"));
            _nameField = new InputField(Vec2f(150f, 25f));
            _nameField.text = _currentEntity.name;
            _nameField.setCallback(this, "name");
            box.addChildGui(_nameField);
        }

        { // Flags
            auto box = new HContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.center);
            box.spacing = Vec2f(5f, 0f);
            _container.addChildGui(box);

            box.addChildGui(new Label("Flags:"));
            _flagsField = new InputField(Vec2f(150f, 25f));
            _flagsField.text = _currentEntity.flags;
            _flagsField.setCallback(this, "flags");
            box.addChildGui(_flagsField);
        }

        // Direction
        if(_currentEntity.dirsCount() > 1) {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.center);
            box.spacing = Vec2f(5f, 0f);
            _container.addChildGui(box);

            box.addChildGui(new Label("Direction:"));

            _dirSelector = new DropDownList(Vec2f(125f, 25f), 5);
            switch(_currentEntity.dirsCount()) {
            case 1:
                _dirSelector.add("Aucun");
                break;
            case 2:
                _dirSelector.add("Nord");
                _dirSelector.add("Sud");
                break;
            case 4:
                _dirSelector.add("Nord");
                _dirSelector.add("Est");
                _dirSelector.add("Sud");
                _dirSelector.add("Ouest");
                break;
            case 6:
                _dirSelector.add("Nord-est");
                _dirSelector.add("Est");
                _dirSelector.add("Sud-est");
                _dirSelector.add("Sud-ouest");
                _dirSelector.add("Ouest");
                _dirSelector.add("Nord-ouest");
                break;
            case 8:
                _dirSelector.add("Nord");
                _dirSelector.add("Nord-est");
                _dirSelector.add("Est");
                _dirSelector.add("Sud-est");
                _dirSelector.add("Sud");
                _dirSelector.add("Sud-ouest");
                _dirSelector.add("Ouest");
                _dirSelector.add("Nord-ouest");
                break;
            default:
                goto case 1;
            }
            _dirSelector.selected(_currentEntity.direction);
            _dirSelector.setCallback(this, "dir");
            box.addChildGui(_dirSelector);
        }

        if(_currentEntity.type == "light") {
            const Color barColor = Color(_currentEntity.red, _currentEntity.green, _currentEntity.blue);
            {
                auto box = new HContainer;
                box.setAlign(GuiAlignX.left, GuiAlignY.center);
                box.spacing = Vec2f(5f, 0f);
                _container.addChildGui(box);

                box.addChildGui(new Label("Rouge:"));

                _rSlider = new HSlider;
                _rSlider.size = Vec2f(150f, 15f);
                _rSlider.step = 256;
                _rSlider.color = barColor;
                _rSlider.fvalue = _currentEntity.red;
                _rSlider.setCallback(this, "r");
                box.addChildGui(_rSlider);
            }
            {
                auto box = new HContainer;
                box.setAlign(GuiAlignX.left, GuiAlignY.center);
                box.spacing = Vec2f(5f, 0f);
                _container.addChildGui(box);

                box.addChildGui(new Label("Vert:"));

                _gSlider = new HSlider;
                _gSlider.size = Vec2f(150f, 15f);
                _gSlider.step = 256;
                _gSlider.color = barColor;
                _gSlider.fvalue = _currentEntity.green;
                _gSlider.setCallback(this, "g");
                box.addChildGui(_gSlider);
            }
            {
                auto box = new HContainer;
                box.setAlign(GuiAlignX.left, GuiAlignY.center);
                box.spacing = Vec2f(5f, 0f);
                _container.addChildGui(box);

                box.addChildGui(new Label("Bleu:"));

                _bSlider = new HSlider;
                _bSlider.size = Vec2f(150f, 15f);
                _bSlider.step = 256;
                _bSlider.color = barColor;
                _bSlider.fvalue = _currentEntity.blue;
                _bSlider.setCallback(this, "b");
                box.addChildGui(_bSlider);
            }
            {
                auto box = new HContainer;
                box.setAlign(GuiAlignX.left, GuiAlignY.center);
                box.spacing = Vec2f(5f, 0f);
                _container.addChildGui(box);

                box.addChildGui(new Label("Alpha:"));

                _aSlider = new HSlider;
                _aSlider.size = Vec2f(150f, 15f);
                _aSlider.step = 256;
                _aSlider.color = barColor;
                _aSlider.fvalue = _currentEntity.alpha;
                _aSlider.setCallback(this, "a");
                box.addChildGui(_aSlider);
            }
        }
        if(_currentEntity.type == "prop" || _currentEntity.type == "collider") {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.center);
            box.spacing = Vec2f(5f, 0f);
            _container.addChildGui(box);

            box.addChildGui(new Label("Collision ?:"));

            _collidableCB = new Checkbox;
            _collidableCB.value = _currentEntity.isCollidable;
            _collidableCB.setCallback(this, "isCollidable");
            box.addChildGui(_collidableCB);
        }
        if(_currentEntity.type == "tank") {
            {           
                auto box = new HContainer;
                box.setAlign(GuiAlignX.left, GuiAlignY.center);
                box.spacing = Vec2f(5f, 0f);
                _container.addChildGui(box);

                box.addChildGui(new Label("Behavior:"));

                _behaviorSelector = new DropDownList(Vec2f(125f, 25f), 5);
                _behaviorSelector.add("playable");
                _behaviorSelector.add("passive");
                _behaviorSelector.add("easy");
                _behaviorSelector.setSelectedName(_currentEntity.behavior);
                _behaviorSelector.setCallback(this, "behavior");
                box.addChildGui(_behaviorSelector);
            }
            
            {
                auto box = new HContainer;
                box.setAlign(GuiAlignX.left, GuiAlignY.center);
                box.spacing = Vec2f(5f, 0f);
                _container.addChildGui(box);

                box.addChildGui(new Label("Faction:"));

                _factionField = new InputField(Vec2f(125f, 25f));
                _factionField.text = to!string(_currentEntity.faction);
                _factionField.setAllowedCharacters("0123456789");
                _factionField.setCallback(this, "faction");
                box.addChildGui(_factionField);
            }
        }
        if(_currentEntity.type == "teleporter") {
            {
                auto box = new HContainer;
                box.setAlign(GuiAlignX.left, GuiAlignY.center);
                box.spacing = Vec2f(5f, 0f);
                _container.addChildGui(box);

                box.addChildGui(new Label("Carte:"));
                _mapSelector = new DropDownList(Vec2f(175f, 25f), 5);

                auto files = dirEntries(buildNormalizedPath("assets", "map", "camp"), "{*.json}", SpanMode.shallow);
                foreach(file; files) {
                    string fileName = buildNormalizedPath("camp", baseName(stripExtension(file)));
                    _mapSelector.add(fileName);
                }
                files = dirEntries(buildNormalizedPath("assets", "map", "tactical"), "{*.json}", SpanMode.shallow);
                foreach(file; files) {
                    string fileName = buildNormalizedPath("tactical", baseName(stripExtension(file)));
                    _mapSelector.add(fileName);
                }
                _mapSelector.setSelectedName(_currentEntity.map);
                _mapSelector.setCallback(this, "map");
                box.addChildGui(_mapSelector);
            }
            {
                auto box = new HContainer;
                box.setAlign(GuiAlignX.left, GuiAlignY.center);
                box.spacing = Vec2f(5f, 0f);
                _container.addChildGui(box);

                box.addChildGui(new Label("TP:"));
                _tpField = new InputField(Vec2f(150f, 25f));
                _tpField.text = _currentEntity.tpName;
                _tpField.setCallback(this, "tp");
                box.addChildGui(_tpField);
            }
        }
    }
    
    void setData(Entity entity) {
        if(entity) {
            _ignoreCallbacks = true;
            if(entity == _currentEntity) {
                _xPosField.text = to!string(entity.position.x);
                _yPosField.text = to!string(entity.position.y);
            }
            else {
                _currentEntity = entity;
                reload();
            }
            _ignoreCallbacks = false;
        }
        else {
            _container.removeChildrenGuis();
            _currentEntity = null;
        }
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
            const string newPropId = _entitySelector.getSelectedName();
            if(_currentEntity.id == newPropId)
                break;
            _currentEntity.id = newPropId;
            reload();
            break;
        case "dir":
            _currentEntity.direction = _dirSelector.selected();
            break;
        case "name":
            _currentEntity.name = _nameField.text;
            break;
        case "flags":
            _currentEntity.flags = _flagsField.text;
            break;
        case "behavior":
            _currentEntity.behavior = _behaviorSelector.getSelectedName();
            break;
        case "faction":
            try {
                const int factionId = to!int(_factionField.text);
                _currentEntity.faction = factionId;
            }
            catch(Exception e) {
            }
            break;
        case "x":
            try {
                const int xPos = to!int(_xPosField.text);
                _currentEntity.position = Vec2i(xPos, _currentEntity.position.y);
            }
            catch(Exception e) {
            }
            break;
        case "y":
            try {
                const int yPos = to!int(_yPosField.text);
                _currentEntity.position = Vec2i(_currentEntity.position.x, yPos);
            }
            catch(Exception e) {
            }
            break;
        case "w":
            try {
                const int wPos = to!int(_wField.text);
                _currentEntity.hitbox = Vec2i(wPos, _currentEntity.hitbox.y);
            }
            catch(Exception e) {
            }
            break;
        case "h":
            try {
                const int hPos = to!int(_hField.text);
                _currentEntity.hitbox = Vec2i(_currentEntity.hitbox.x, hPos);
            }
            catch(Exception e) {
            }
            break;
        case "r":
            _currentEntity.red = _rSlider.fvalue;
            const Color barColor = Color(_currentEntity.red, _currentEntity.green, _currentEntity.blue);
            _rSlider.color = barColor;
            _gSlider.color = barColor;
            _bSlider.color = barColor;
            _aSlider.color = barColor;
            break;
        case "g":
            _currentEntity.green = _gSlider.fvalue;
            const Color barColor = Color(_currentEntity.red, _currentEntity.green, _currentEntity.blue);
            _rSlider.color = barColor;
            _gSlider.color = barColor;
            _bSlider.color = barColor;
            _aSlider.color = barColor;
            break;
        case "b":
            _currentEntity.blue = _bSlider.fvalue;
            const Color barColor = Color(_currentEntity.red, _currentEntity.green, _currentEntity.blue);
            _rSlider.color = barColor;
            _gSlider.color = barColor;
            _bSlider.color = barColor;
            _aSlider.color = barColor;
            break;
        case "a":
            _currentEntity.alpha = _aSlider.fvalue;
            break;
        case "isCollidable":
            _currentEntity.isCollidable = _collidableCB.value;
            break;
        case "map":
            _currentEntity.map = _mapSelector.getSelectedName();
            break;
        case "tp":
            _currentEntity.tpName = _tpField.text;
            break;
        default:
            break;
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.08f, .09f, .11f));
    }
}