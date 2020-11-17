module gui.file.load_modal;

import std.conv: to;
import std.path, std.file;
import std.algorithm: min, max;
import atelier;
import common;

final class LoadModal: GuiElement {
    private {
        InputField _searchField;
        VList _list;
        VContainer _container;
        string[] _elements;
        string _value;
    }

    @property {
        string value() const {
            return buildNormalizedPath("assets", "map", setExtension(_value, "json"));
        }
    }

    this() {
        size(Vec2f(300f, screenHeight));
        setAlign(GuiAlignX.left, GuiAlignY.top);

        _searchField = new InputField(Vec2f(size.x, 25f));
		_list = new VList(Vec2f(size.x, screenHeight));

        _searchField.hasFocus = true;
        _searchField.setCallback(this, "input");

        _container = new VContainer;
        _container.setChildAlign(GuiAlignX.left);
        _container.spacing = Vec2f(0f, 10f);
        _container.setAlign(GuiAlignX.left, GuiAlignY.top);
        addChildGui(_container);
        _container.addChildGui(new Label("Charger:"));
        _container.addChildGui(_searchField);
        _container.addChildGui(_list);

        auto files = dirEntries(buildNormalizedPath("assets", "map"), "{*.json}", SpanMode.shallow);
        foreach(file; files) {
            string fileName = buildNormalizedPath("camp", baseName(stripExtension(file)));
            add(fileName);
        }

        setup();

        //States
        GuiState hiddenState = {
            offset: Vec2f(-size.x, 0f),
            alpha: 0f
        };
        addState("hidden", hiddenState);

        GuiState defaultState = {
            time: .25f,
            easing: getEasingFunction(Ease.sineOut)
        };
        addState("default", defaultState);

        setState("hidden");
        doTransitionState("default");
    }

    private void setValue(string value_) {
        _value = value_;
        onCallback("apply");
    }

    void add(string msg) {
        _elements ~= msg;
	}

    private void setup() {
        _searchField.text = "";
        _list.removeChildrenGuis();
        foreach (key; _elements) {
            auto gui = new MapElement(key, this);
            _list.addChildGui(gui);
            _list.size = Vec2f(size.x, min(10f, _list.getList().length) * 25f);
        }
        setSelectedName(_value);
    }

    private void filter() {
        import std.typecons : No;
        import std.string: indexOf;
        string text = _searchField.text;

        if(text.length == 0u) {
            setup();
            return;
        }

        _list.removeChildrenGuis();
        foreach (key; _elements) {
            if(key.indexOf(text, No.caseSentitive) == -1)
                continue;
            auto gui = new MapElement(key, this);
            _list.addChildGui(gui);
            _list.size = Vec2f(size.x, min(10f, _list.getList().length) * 25f);
        }
        setSelectedName(_value);
    }

    override void onCallback(string id) {
        switch(id) {
        case "input":
            filter();
            break;
        case "apply":
            triggerCallback();
            break;
        case "cancel":
            stopModalGui();
            break;
        default:
            break;
        }
    }

    override void update(float deltaTime) {
        if(getButtonDown(KeyButton.enter))
            onCallback("apply");
        else if(getButtonDown(KeyButton.escape))
            onCallback("cancel");
    }

    override void draw() {
        drawFilledRect(origin, size, Color.fromHex(0x444444));
    }

    private void setSelectedName(string name) {
        auto list = cast(MapElement[]) _list.getList();
        int i;
        foreach(sub; list) {
            if(sub._label.text == name) {
                _list.selected = i;
                return;
            }
            i ++;
        }
    }
}

private class MapElement: Button {
    private {
        Label _label;
        LoadModal _selector;
    }

    this(string title, LoadModal selector) {
        _selector = selector;
        size(Vec2f(200f, 25f));
        _label = new Label(title);
        _label.setAlign(GuiAlignX.center, GuiAlignY.center);
        addChildGui(_label);
    }

    override void onSubmit() {
        super.onSubmit();
        _selector.setValue(_label.text);
    }

    override void draw() {
        drawFilledRect(origin, size, isHovered ? Color.fromHex(0x555555) : Color.fromHex(0x444444));
    }
}