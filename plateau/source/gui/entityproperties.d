module gui.entityproperties;

import std.file, std.path;
import std.conv: to;
import atelier;
import common;
import gui.constants, gui.search;

final class EntityProperties: GuiElement {
    private {
        SearchList _entitySelector;
        InputField _nameField, _xPosField, _yPosField, _wField, _hField;
        bool _ignoreCallbacks;
        Entity _currentEntity;
        VContainer _container;
        HSlider _rSlider, _gSlider, _bSlider, _aSlider;
    }

    @property {
    }

    this() {
        position(Vec2f(0f, barHeight + tabsHeight));
        size(Vec2f(propertiesWidth, screenHeight - (barHeight + tabsHeight)));
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
            alpha: 0f,
            time: .5f,
            easing: getEasingFunction(Ease.sineIn)
        };
        addState("hidden", hiddenState);

        GuiState visibleState = {
            time: .5f,
            easing: getEasingFunction(Ease.sineOut)
        };
        addState("visible", visibleState);

        setState("hidden");
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

        {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.center);
            box.spacing = Vec2f(5f, 0f);
            _container.addChildGui(box);

            box.addChildGui(new Label("w:"));

            _wField = new InputField(Vec2f(50f, 25f));
            _wField.text = to!string(_currentEntity.size.x);
            _wField.setAllowedCharacters("-0123456789");
            _wField.setCallback(this, "w");
            box.addChildGui(_wField);

            box.addChildGui(new Label("h:"));

            _hField = new InputField(Vec2f(50f, 25f));
            _hField.text = to!string(_currentEntity.size.y);
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

        {
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
            _ignoreCallbacks = true;
            _currentEntity = null;
        }
    }

    override void onEvent(Event event) {
        switch(event.type) with(EventType) {
        case resize:
            size(Vec2f(propertiesWidth, event.window.size.y - (barHeight + tabsHeight)));
            break;
        default:
            break;
        }
    }

    override void onCallback(string id) {
        if(_ignoreCallbacks)
            return;
        switch(id) {
        case "name":
            _currentEntity.name = _nameField.text;
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
                const float width = to!float(_wField.text);
                _currentEntity.size = Vec2f(width, _currentEntity.size.y);
            }
            catch(Exception e) {
            }
            break;
        case "h":
            try {
                const float height = to!float(_hField.text);
                _currentEntity.size = Vec2f(_currentEntity.size.x, height);
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
        default:
            break;
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.08f, .09f, .11f));
    }
}