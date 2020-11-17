module gui.search;

import std.conv: to;
import std.algorithm: min, max;
import atelier;

final class SearchList: Button {
    private {
        SearchModal _modal;
        string _selectedName;
        Label _label;
    }

    this(string title, Vec2f size_) {
        _modal = new SearchModal(title);
        _modal.setCallback(this, "modal");

        _label = new Label("[...]");
        _label.setAlign(GuiAlignX.center, GuiAlignY.center);
		size = size_;
        addChildGui(_label);
    }

    void add(string msg) {
        _modal.add(msg);
	}

    override void onSubmit() {
        if(isLocked)
            return;
        _modal.setup();
        pushModalGui(_modal);
    }

    string getSelectedName() {
        return _selectedName;
    }

    void setSelectedName(string name) {
        _selectedName = name;
        _label.text = _selectedName;
        _modal.setName(_selectedName);
    }

    override void onCallback(string id) {
        switch(id) {
        case "modal":
            if(_modal._name.length) {
                _selectedName = _modal._name;
                _label.text = _selectedName;
                triggerCallback();
            }
            stopModalGui();
            break;
        default:
            break;
        }
    }

    override void draw() {
		if(isLocked)
			drawFilledRect(origin, size, Color(0.3f, 0.4f, 0.5f));
		else if(isSelected)
			drawFilledRect(origin, size, Color.white * 0.4f);
		else if(isHovered)
			drawFilledRect(origin, size, Color.white * 0.25f);
		else
			drawFilledRect(origin, size, Color.white * 0.15f);
        drawRect(origin, size, Color.white);
	}
}

private final class SearchModal: GuiElement {
    private {
        InputField _searchField;
        VList _list;
        VContainer _container;
        Label _label;
        string[] _elements;
        string _name, _title;
    }

    this(string title) {
        super(Flags.movable);
        size(Vec2f(250f, 25f));
        setAlign(GuiAlignX.center, GuiAlignY.center);
        _title = title;

        _searchField = new InputField(Vec2f(250f, 25f));
		_list = new VList(Vec2f(250f, 300f));
        _label = new Label(_title ~ ": ...");

        _searchField.hasFocus = true;
        _searchField.setCallback(this, "input");

        _container = new VContainer;
        _container.setAlign(GuiAlignX.center, GuiAlignY.center);
        addChildGui(_container);
        _container.addChildGui(_label);
        _container.addChildGui(_searchField);
        _container.addChildGui(_list);

        { //Validation
            auto box = new HContainer;
            box.setAlign(GuiAlignX.right, GuiAlignY.bottom);
            box.spacing = Vec2f(25f, 15f);
            _container.addChildGui(box);

            auto applyBtn = new TextButton("Apply");
            applyBtn.size = Vec2f(100f, 35f);
            applyBtn.setCallback(this, "apply");
            box.addChildGui(applyBtn);

            auto cancelBtn = new TextButton("Cancel");
            cancelBtn.size = Vec2f(100f, 35f);
            cancelBtn.setCallback(this, "cancel");
            box.addChildGui(cancelBtn);
        }
    }

    void setName(string name) {
        _name = name;
        if(_name.length)
            _label.text = _title ~ ": " ~ _name;
        else
            _label.text = _title ~ ": [...]";
    }

    void add(string msg) {
        _elements ~= msg;
	}

    void setup() {
        _searchField.text = "";
        _list.removeChildrenGuis();
        foreach (key; _elements) {
            auto gui = new SearchListSubElement(key, this);
            _list.addChildGui(gui);
            _list.size = Vec2f(250f, min(10f, _list.getList().length) * 25f);
        }
        setSelectedName(_name);
    }

    void filter() {
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
            auto gui = new SearchListSubElement(key, this);
            _list.addChildGui(gui);
            _list.size = Vec2f(250f, min(10f, _list.getList().length) * 25f);
        }
        setSelectedName(_name);
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
        size(_container.size + Vec2f(10f, 10f));

        if(getButtonDown(KeyButton.enter))
            onCallback("apply");
        else if(getButtonDown(KeyButton.escape))
            onCallback("cancel");
    }

    override void draw() {
        drawFilledRect(origin, size, Color.black);
    }

    void setSelectedName(string name) {
        auto list = cast(SearchListSubElement[]) _list.getList();
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

private class SearchListSubElement: Button {
    private {
        Label _label;
        SearchModal _modal;
    }

    this(string title, SearchModal modal) {
        _modal = modal;
        size(Vec2f(250f, 25f));
        _label = new Label(title);
        _label.setAlign(GuiAlignX.left, GuiAlignY.center);
        addChildGui(_label);
    }

    override void onSubmit() {
        super.onSubmit();
        _modal.setName(_label.text);
    }

    override void draw() {
        if(isSelected)
            drawFilledRect(origin, size, Color(.8f, .8f, .9f));
        else
            drawFilledRect(origin, size, isHovered ? Color.gray : Color.black);
    }
}