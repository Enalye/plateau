module gui.layerscontroler;

import atelier;
import common;
import gui.layerslist, gui.warning, gui.constants;

final class LayersControler: GuiElement {
    private {
        LayersList _layersList;
        LayersControlerButton _addBtn, _dupBtn, _removeBtn, _upBtn, _downBtn;
    }
    
    this(LayersList layersList) {
        position(Vec2f(0f, (barHeight + tabsHeight + layersListHeight)));
        size(Vec2f(layersListWidth, layersControlerHeight));

        _layersList = layersList;
        auto btns = new HContainer;
        addChildGui(btns);
        
        _addBtn = new LayersControlerButton("Ajouter un calque", fetch!Sprite("editor.add"));
        _addBtn.setCallback(this, "add");
        btns.addChildGui(_addBtn);
        _dupBtn = new LayersControlerButton("Dupliquer le calque", fetch!Sprite("editor.duplicate"));
        _dupBtn.setCallback(this, "dup");
        btns.addChildGui(_dupBtn);
        _removeBtn = new LayersControlerButton("Supprimer le calque", fetch!Sprite("editor.remove"));
        _removeBtn.setCallback(this, "remove");
        btns.addChildGui(_removeBtn);
        _upBtn = new LayersControlerButton("Déplacer le calque vers le haut", fetch!Sprite("editor.moveup"));
        _upBtn.setCallback(this, "up");
        btns.addChildGui(_upBtn);
        _downBtn = new LayersControlerButton("Déplacer le calque vers le bas", fetch!Sprite("editor.movedown"));
        _downBtn.setCallback(this, "down");
        btns.addChildGui(_downBtn);

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

    override void onCallback(string id) {
        switch(id) {
        case "add":
            if(!hasTab())
                break;
            _layersList.addElement();
            break;
        case "dup":
            if(!hasTab())
                break;
            _layersList.dupElement();
            break;
        case "remove":
            if(!hasTab())
                break;
            auto gui = new WarningMessageGui("Veux-tu vraiment supprimer ce calque ?", "Supprimer");
            gui.setCallback(this, "remove.modal");
            pushModalGui(gui);
            break;
        case "remove.modal":
            auto gui = popModalGui!WarningMessageGui;
            _layersList.removeElement();
            break;
        case "up":
            if(!hasTab())
                break;
            _layersList.moveUpElement();
            break;
        case "down":
            if(!hasTab())
                break;
            _layersList.moveDownElement();
            break;
        default:
            break;
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.1f, .11f, .13f));
    }
}

private final class LayersControlerButton: Button {
    private {
        Sprite _sprite;
    }

    this(string text, Sprite sprite) {
        setHint(text);

        size(Vec2f(layersControlerHeight, layersControlerHeight));

        _sprite = sprite;
        _sprite.size = Vec2f(layersControlerHeight, layersControlerHeight);
    }

    override void update(float deltaTime) {
        isLocked = !hasTab();
    }

    override void draw() {
        _sprite.color = Color(.6f, .7f, .8f);
        if(isLocked) {
            _sprite.color = Color(.4f, .5f, .6f);
            _sprite.draw(center);
            return;
        }
        if(isHovered)
            _sprite.color = Color(.85f, .9f, 1f);
        if(isClicked)
            _sprite.color = Color.white;
        _sprite.draw(center + (isClicked ? Vec2f.one : Vec2f.zero));
    }
}