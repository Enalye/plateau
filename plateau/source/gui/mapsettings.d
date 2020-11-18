module gui.mapsettings;

import std.file, std.path;
import std.conv: to;
import atelier;
import common;

final class MapSettings: GuiElement {
    private {
        InputField _widthField, _heightField;
        TextButton _applyBtn;
        uint _width, _height;
    }

    @property {
        uint width() const { return _width; }
        uint height() const { return _height; }
    }

    this() {
        size(Vec2f(500f, 500f));
        setAlign(GuiAlignX.center, GuiAlignY.center);
        
        if(hasTab()) {
            const TabData tabData = getCurrentTab();
            _width = tabData.width;
            _height = tabData.height;
        }
        else {
            _width = 0;
            _height = 0;
        }

        auto vbox = new VContainer;
        vbox.position = Vec2f(0f, 30f);
        vbox.spacing = Vec2f(0f, 10f);
        vbox.setChildAlign(GuiAlignX.left);
        addChildGui(vbox);

        { //Title
            auto title = new Label("Paramètres de la carte");
            title.setAlign(GuiAlignX.center, GuiAlignY.top);
            title.position = Vec2f(20f, 10f);
            addChildGui(title);
        }

        {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.center, GuiAlignY.center);
            box.spacing = Vec2f(15f, 5f);
            vbox.addChildGui(box);

            box.addChildGui(new Label("Taille:"));
            box.addChildGui(new Label("Longueur: "));

            _widthField = new InputField(Vec2f(50f, 25f), to!string(_width));
            _widthField.setAllowedCharacters("0123456789");
            _widthField.setCallback(this, "width");
            box.addChildGui(_widthField);

            box.addChildGui(new Label("Hauteur: "));

            _heightField = new InputField(Vec2f(50f, 25f), to!string(_height));
            _heightField.setAllowedCharacters("0123456789");
            _heightField.setCallback(this, "height");
            box.addChildGui(_heightField);
        }

        { //Validation
            auto box = new HContainer;
            box.setAlign(GuiAlignX.right, GuiAlignY.bottom);
            box.spacing = Vec2f(25f, 15f);
            addChildGui(box);

            auto applyBtn = new TextButton("Valider");
            applyBtn.size = Vec2f(150f, 35f);
            applyBtn.setCallback(this, "apply");
            box.addChildGui(applyBtn);
            _applyBtn = applyBtn;

            auto resetBtn = new TextButton("Réinitialiser");
            resetBtn.size = Vec2f(150f, 35f);
            resetBtn.setCallback(this, "reset");
            box.addChildGui(resetBtn);
            
            auto cancelBtn = new TextButton("Annuler");
            cancelBtn.size = Vec2f(150f, 35f);
            cancelBtn.setCallback(this, "cancel");
            box.addChildGui(cancelBtn);
        }

        //States
        GuiState hiddenState = {
            offset: Vec2f(0f, -50f),
            alpha: 0f
        };
        addState("hidden", hiddenState);

        GuiState defaultState = {
            time: .5f,
            easing: getEasingFunction(Ease.sineOut)
        };
        addState("default", defaultState);

        setState("hidden");
        doTransitionState("default");
    }

    override void update(float deltaTime) {
        checkSizeFields();

        if(getButtonDown(KeyButton.enter))
            onCallback("apply");
        else if(getButtonDown(KeyButton.escape))
            onCallback("cancel");
    }

    private void checkSizeFields() {
        if(!_widthField.text.length || !_heightField.text.length ||
            _widthField.text.length > 3u  || _heightField.text.length > 3u) {
            _applyBtn.isLocked = true;
            return;
        }
        _width = _widthField.text.to!uint();
        _height = _heightField.text.to!uint();
        if(_width == 0u || _height == 0u) {
            _width = 1u;
            _height = 1u;
            _applyBtn.isLocked = true;
            return;
        }
        _applyBtn.isLocked = false;
    }

    override void onCallback(string id) {
        switch(id) {
        case "apply":
            triggerCallback();
            break;
        case "reset":
            //TODO
            break;
        case "cancel":
            stopModalGui();
            break;
        case "width":
        case "height":
            break;
        default:
            break;
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.11f, .08f, .15f));
    }

    override void drawOverlay() {
        drawRect(origin, size, Color.gray);
    }
}