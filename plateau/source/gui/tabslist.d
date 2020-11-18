module gui.tabslist;

import std.path;
import atelier;
import common;
import gui.constants;

final class TabsList: GuiElement {
    private {
        HContainer _box;
    }

    this() {
        position(Vec2f(0f, barHeight));
        size(Vec2f(screenWidth, tabsHeight));
        setEventHook(true);

        _box = new HContainer;
        addChildGui(_box);
		super(GuiElement.Flags.canvas);
    }

    override void onEvent(Event event) {
        switch(event.type) with(EventType) {
        case resize:
            size(Vec2f(event.window.size.x, tabsHeight));
            break;
        case mouseWheel:
            const float delta = event.scroll.delta.y - event.scroll.delta.x;
            canvas.position.x -= delta * 50f;
            canvas.position = canvas.position.clamp(canvas.size / 2f, Vec2f(_box.size.x - canvas.size.x / 2f, canvas.size.y));
            break;
        default:
            break;
        }
    }

    override void onCallback(string id) {
        if(id == "tab") {
            triggerCallback();
        }
    }

    void addTab() {
        if(!hasTab())
            return;
        auto tabData = getCurrentTab();
        auto tabGui = new TabButton(this, tabData);
        tabGui.setCallback(this, "tab");
        _box.addChildGui(tabGui);
    }

    void removeTab() {
        foreach(TabButton tabGui; cast(TabButton[])_box.children()) {
            if(tabGui._tabData == getCurrentTab()) {
                tabGui.close();
            }
        }
    }

    void _remove() {
        TabButton[] tabs;
        foreach(TabButton tabGui; cast(TabButton[])_box.children()) {
            if(!tabGui._isDeleted) {
                tabs ~= tabGui;
            }
        }
        _box.removeChildrenGuis();
        foreach(TabButton tabGui; tabs) {
            _box.addChildGui(tabGui);
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.1f, .11f, .13f));
    }
}

final private class TabButton: GuiElement {
    private {
        Label _label;
        TabData _tabData;
        TabsList _tabs;
        bool _isDeleted;
    }

    this(TabsList tabs, TabData tabData) {
        _tabs = tabs;
        _tabData = tabData;
        _label = new Label("untitled");

        GuiState hiddenState = {
            alpha: 0f,
            time: .5f,
            easing: getEasingFunction(Ease.sineInOut)
        };

        GuiState visibleState = {
            time: .5f,
            easing: getEasingFunction(Ease.sineInOut)
        };

        _label.addState("hidden", hiddenState);
        _label.addState("visible", visibleState);
        _label.setState("hidden");


        _label.setAlign(GuiAlignX.center, GuiAlignY.center);
        addChildGui(_label);

        size(Vec2f(_label.size.x + 20f, tabsHeight));

        GuiState startState = {
            scale: Vec2f(0f, 1f),
            time: .5f,
            easing: getEasingFunction(Ease.sineInOut)
        };

        GuiState endState = {
            scale: Vec2f(0f, 1f),
            time: .5f,
            easing: getEasingFunction(Ease.sineInOut),
            callback: "end"
        };

        GuiState defaultState = {
            time: .5f,
            easing: getEasingFunction(Ease.sineInOut)
        };

        addState("start", startState);
        addState("default", defaultState);
        addState("end", endState);

        setState("start");
        doTransitionState("default");
        _label.doTransitionState("visible");
    }

    override void update(float deltaTime) {
        if(!hasTab())
            return;
        isSelected = getCurrentTab() == _tabData;
        if(isSelected) {
            if(_tabData.isTitleDirty) {
                _tabData.isTitleDirty = false;
                _label.text = _tabData.title;
                size(Vec2f(_label.size.x + 20f, tabsHeight));
            }
        }
    }

    override void onSubmit() {
        if(isLocked)
            return;
        if(!isSelected) {
            setCurrentTab(_tabData);
            triggerCallback();
        }
    }

    override void draw() {
        drawFilledRect(origin, scaledSize, Color(.12f, .13f, .19f));
        if(isLocked)
            return;
        if(isHovered)
            drawFilledRect(origin, scaledSize, Color(.2f, .2f, .2f));
        if(isClicked)
            drawFilledRect(origin, scaledSize, Color(.5f, .5f, .5f));
        if(isSelected)
            drawFilledRect(origin, scaledSize, Color(.4f, .4f, .5f));
    }

    void close() {
        doTransitionState("end");
        _label.doTransitionState("hidden");
        isLocked = true;
    }
    
    override void onCallback(string id) {
        if(id == "end") {
            _isDeleted = true;
            _tabs._remove();
        }
    }
}