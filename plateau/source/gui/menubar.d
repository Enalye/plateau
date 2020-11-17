module gui.menubar;

import atelier;
import common;
import gui.editor;
import gui.constants;

private {
    bool _isMenuFocused;
    float[] _menuSizes;
    Editor _editor;
}

final class MenuBar: GuiElement {
    private {
        MenuButton[] _buttons;
        Label _mapName;
    }

    this(Editor editor) {
        _editor = editor;
        size(Vec2f(screenWidth, barHeight));
        auto box = new HContainer;
        addChildGui(box);

        const auto menuNames = ["file", "edit", "settings"];
        const auto menuDisplayNames = ["Fichier", "Édition", "Paramètres"];
        const auto menuItems = [
            ["file.open", "file.new", "file.close", "file.save", "file.saveas", "file.quit"],
            ["edit.mapsettings"],
            ["settings.snap", "settings.grid", "settings.fullscreen"]
            ];
        const auto menuItemsDisplayNames = [
            ["Ouvrir (Ctrl+O)", "Nouveau (Ctrl+N)", "Fermer", "Enregistrer (Ctrl+S)", "Enregistrer sous..", "Quitter"],
            ["Réglages de la carte"],
            ["Alignement sur la grille", "Afficher l'arrière-plan", "Plein écran (F12)"]
            ];
        _menuSizes.length = menuNames.length;
        for(size_t i = 0uL; i < menuNames.length; ++ i) {
            auto menuBtn = new MenuButton(menuNames[i], menuDisplayNames[i], menuItems[i], menuItemsDisplayNames[i], cast(uint) i, cast(uint) menuNames.length);
            menuBtn.setCallback(this, "menu");
            box.addChildGui(menuBtn);
            _buttons ~= menuBtn;
        }

        _mapName = new Label("");
        _mapName.setAlign(GuiAlignX.center, GuiAlignY.center);
        addChildGui(_mapName);
    }

    void setMapName(string name) {
        _mapName.text = name;
    }

    override void onEvent(Event event) {
        switch(event.type) with(EventType) {
        case resize:
            size(Vec2f(event.window.size.x, barHeight));
            break;
        default:
            break;
        }
    }

    override void onCallback(string id) {
        _isMenuFocused = true;
        switch(id) {
        case "menu":
            stopOverlay();
            foreach(child; _buttons) {
                child.isHovered = false;
                child.isClicked = false;
                child.hasFocus = false;
            }
            foreach(child; _buttons) {
                if(child.requestChange) {
                    child.requestChange = false;
                    _buttons[child.changeId].isClicked = true;
                    _buttons[child.changeId].onSubmit();
                    break;
                }
            }
            break;
        default:
            break;
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color.fromHex(0x262626));
    }
}

private final class MenuCancel: GuiElement {
    this() {
        size(screenSize);
    }

    override void onSubmit() {
        triggerCallback();
    }
}

private final class MenuChange: GuiElement {
    uint triggerId;

    this(uint id) {
        triggerId = id;
    }

    override void onHover() {
        triggerCallback();
    }
}

private final class MenuButton: GuiElement {
    private {
        Label _label;
        MenuCancel _cancelTrigger;
        MenuChange[] _changeTriggers;
        MenuList _list;
        uint _changeId, _menuId;
        string _nameId;
    }
    bool requestChange;

    @property uint changeId() const { return _changeId; }

    this(const string name, const string displayName, const(string[]) menuItems, const(string[]) menuNames, uint id, uint maxId) {
        _nameId = name;
        _menuId = id;
        _label = new Label(displayName);
        _label.setAlign(GuiAlignX.center, GuiAlignY.center);
        _label.color = Color.white;
        addChildGui(_label);
        size(Vec2f(_label.size.x + 50f, barHeight));
        _menuSizes[_menuId] = size.x;

        _list = new MenuList(this, menuItems, menuNames);
        _cancelTrigger = new MenuCancel;
        _cancelTrigger.setCallback(this, "cancel");

        for(uint i = 0u; i < maxId; ++ i) {
            if(i == _menuId)
                continue;
            auto changeTrigger = new MenuChange(i);
            changeTrigger.size = size;
            changeTrigger.setCallback(this, "change");
            _changeTriggers ~= changeTrigger;
        }
    }

    override void onEvent(Event event) {
        switch(event.type) with(EventType) {
        case resize:
            _cancelTrigger.size = cast(Vec2f) event.window.size;
            break;
        default:
            break;
        }
    }

    override void onSelect() {
        if(isSelected)
            onSubmit();
    }

    override void onSubmit() {
        setOverlay(_cancelTrigger);
        foreach(changeTrigger; _changeTriggers) {
            setOverlay(changeTrigger);
        }
        setOverlay(_list);
    }

    override void update(float deltaTime) {
        if(getButtonDown(KeyButton.f12))
            onCallback("settings.fullscreen");
        if(getButtonDown(KeyButton.f5))
            onCallback("edit.test");
        if(isButtonDown(KeyButton.leftControl) || isButtonDown(KeyButton.rightControl)) {
            if(getButtonDown(KeyButton.w))
                onCallback("edit.cancel");
            if(getButtonDown(KeyButton.y))
                onCallback("edit.restore");
            if(getButtonDown(KeyButton.h))
                onCallback("selection.fliph");
            if(getButtonDown(KeyButton.v))
                onCallback("selection.flipv");
            if(getButtonDown(KeyButton.n))
                onCallback("file.new");
            if(getButtonDown(KeyButton.o))
                onCallback("file.open");
            if(getButtonDown(KeyButton.s))
                onCallback("file.save");
        }
    }

    override void onCallback(string id) {
        switch(id) {
        case "cancel":
            stopOverlay();
            isClicked = false;
            break;
        case "change":
            foreach(changeTrigger; _changeTriggers) {
                if(changeTrigger.isHovered) {
                    _changeId = changeTrigger.triggerId;
                    requestChange = true;
                    triggerCallback();
                    break;
                }
            }
            break;
        case "file.new":
            stopOverlay();
            isClicked = false;
            isHovered = false;
            _editor.openSettings(true);
            break;
        case "file.open":
            stopOverlay();
            isClicked = false;
            isHovered = false;
            _editor.open();
            break;
        case "file.close":
            stopOverlay();
            isClicked = false;
            isHovered = false;
            _editor.close();
            break;
        case "file.save":
            stopOverlay();
            isClicked = false;
            isHovered = false;
            if(!hasTab())
                break;
            _editor.save();
            break;
        case "file.saveas":
            stopOverlay();
            isClicked = false;
            isHovered = false;
            if(!hasTab())
                break;
            _editor.saveAs();
            break;
        case "file.quit":
            stopOverlay();
            isClicked = false;
            isHovered = false;
            _editor.quit();
            break;
        case "edit.mapsettings":
            stopOverlay();
            isClicked = false;
            isHovered = false;
            _editor.openSettings(false);
            break;
        case "settings.snap":
            stopOverlay();
            isClicked = false;
            isHovered = false;
            _editor.openSnapSettings();
            break;
        case "settings.grid":
            stopOverlay();
            isClicked = false;
            isHovered = false;
            _editor.toggleGrid();
            break;
        case "settings.fullscreen":
            stopOverlay();
            isClicked = false;
            isHovered = false;
            if(getWindowDisplay() == DisplayMode.windowed)
                setWindowDisplay(DisplayMode.desktop);
            else
                setWindowDisplay(DisplayMode.windowed);
            break;
        default:
            break;
        }
    }

    override void draw() {
        if(isClicked) {
            drawFilledRect(origin, size, Color.fromHex(0x212121));
            drawRect(origin, size, Color.fromHex(0x444444));
        }
        else if(isHovered) {
            drawFilledRect(origin, size, Color.fromHex(0x444444));
            drawRect(origin, size, Color.fromHex(0x212121));
        }
    }

    override void drawOverlay() {
        _list.position = origin + Vec2f(0f, size.y);

        foreach(changeTrigger; _changeTriggers) {
            float x = 0f;
            for(uint i = 0u; i < changeTrigger.triggerId; ++ i) {
                x += _menuSizes[i];
            }
            changeTrigger.position = Vec2f(x, 0f);
            changeTrigger.size = Vec2f(_menuSizes[changeTrigger.triggerId], 50f);
        }
    }
}

/** 
 * Overlay container
 */
private final class MenuList: VContainer {
    this(GuiElement callbackObject, const(string[]) options, const(string[]) names) {
        position(Vec2f(0f, 20f));
        setChildAlign(GuiAlignX.left);
        foreach(size_t i, option; options) {
            auto btn = new MenuItem(option, names[i]);
            btn.setCallback(callbackObject, option);
            addChildGui(btn);
        }
    }

    override void update(float deltaTime) {
        super.update(deltaTime);
        foreach(child; cast(MenuItem[]) children)
            child.parentSize = size.x;
    }

    override void draw() {
        drawFilledRect(origin, size, Color.fromHex(0x616161));
    }
}

private final class MenuItem: GuiElement {
    private {
        Label _label;
        string _nameId;
    }

    float parentSize = 0f;

    this(string name, string displayName) {
        _nameId = name;
        _label = new Label(displayName);
        _label.position(Vec2f(50f, 0f));
        _label.setAlign(GuiAlignX.left, GuiAlignY.center);
        _label.color = Color.white;
        addChildGui(_label);
        size(Vec2f(_label.size.x + 100f, 30f));
    }

    override void onSubmit() {
        triggerCallback();
    }

    override void onHover() {

    }

    override void draw() {
        if(isHovered) {
            drawFilledRect(origin, Vec2f(parentSize, size.y), Color.fromHex(0x444444));
            drawRect(origin, Vec2f(parentSize, size.y), Color.fromHex(0x555555));
        }
    }
}