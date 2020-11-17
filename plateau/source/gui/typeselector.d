module gui.typeselector;

import atelier;
import gui.constants;

enum EditType {
    layers, entities
}

final class TypeSelector: GuiElement {
    private {
        TypeSelectorButton _layersBtn, _entitiesBtn;
        EditType _editType = EditType.layers;
    }

    @property {
        EditType type() const { return _editType; }
    }

    this() {
        position(Vec2f(0f, barHeight));
        size(Vec2f(layersListWidth, tabsHeight));

        auto box = new HContainer;
        addChildGui(box);

        _layersBtn = new TypeSelectorButton("Calques");
        _entitiesBtn = new TypeSelectorButton("Objets");

        _layersBtn.setCallback(this, "layers");
        _entitiesBtn.setCallback(this, "entities");

        box.addChildGui(_layersBtn);
        box.addChildGui(_entitiesBtn);

        _layersBtn.isLocked = true;
    }

    override void onCallback(string id) {
        switch(id) {
        case "layers":
            _layersBtn.isLocked = true;
            _entitiesBtn.isLocked = false;
            _editType = EditType.layers;
            triggerCallback();
            break;
        case "entities":
            _layersBtn.isLocked = false;
            _entitiesBtn.isLocked = true;
            _editType = EditType.entities;
            triggerCallback();
            break;
        default:
            break;
        }
    }
}

private final class TypeSelectorButton: Button {
    private Label _label;

    this(string text) {
        _label = new Label(text);
        _label.setAlign(GuiAlignX.center, GuiAlignY.center);
        addChildGui(_label);

        size(Vec2f(layersListWidth / 2f, tabsHeight));
    }

    override void update(float deltaTime) {
        
    }

    override void draw() {
        _label.color = Color.white;
        if(isLocked) {
            drawFilledRect(origin, size, Color(.1f, .15f, .25f));
            _label.color = Color(.6f, .7f, .8f);
            return;
        }
        if(isHovered)
            drawFilledRect(origin, size, Color(.2f, .2f, .2f));
        if(isClicked)
            drawFilledRect(origin, size, Color(.5f, .5f, .5f));
    }
}