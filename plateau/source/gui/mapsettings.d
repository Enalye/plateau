module gui.mapsettings;

import std.file, std.path;
import std.conv: to;
import atelier;
import common;

final class MapSettings: GuiElement {
    private {
        InputField _widthField, _heightField;
        DropDownList _weatherSelector, _scriptSelector;
        Checkbox _cameraBoundCB;
        HSlider _globalIlluminationSlider;
        TextButton _applyBtn;
        bool _isNew;
        uint _width, _height;
        bool _isCameraBound;
        Weather _weather;
        string _script;
        float _globalIllumination;
    }

    @property {
        bool isNew() const { return _isNew; }
        uint width() const { return _width; }
        uint height() const { return _height; }
        bool isCameraBound() const { return _isCameraBound; }
        Weather weather() const { return _weather; }
        string script() const { return _script; }
        float globalIllumination() const { return _globalIllumination; }
    }

    this(bool isNew_) {
        size(Vec2f(500f, 500f));
        setAlign(GuiAlignX.center, GuiAlignY.center);
        _isNew = isNew_;
        
        if(!_isNew && hasTab()) {
            const TabData tabData = getCurrentTab();
            _width = tabData.width;
            _height = tabData.height;
            _isCameraBound = tabData.isCameraBound;
            _weather = tabData.weather;
            _script = tabData.script;
            _globalIllumination = tabData.globalIllumination;
        }
        else {
            _width = 20;
            _height = 20;
            _isCameraBound = false;
            _weather = Weather.none;
            _script = "";
            _globalIllumination = 1f;
        }

        auto vbox = new VContainer;
        vbox.position = Vec2f(0f, 30f);
        vbox.spacing = Vec2f(0f, 10f);
        vbox.setChildAlign(GuiAlignX.left);
        addChildGui(vbox);

        { //Title
            auto title = new Label(_isNew ? "Nouvelle carte" : "Paramètres de la carte");
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

        {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.center, GuiAlignY.center);
            box.spacing = Vec2f(15f, 0f);
            vbox.addChildGui(box);

            box.addChildGui(new Label("Limiter la caméra ?"));
            _cameraBoundCB = new Checkbox;
            _cameraBoundCB.value = _isCameraBound;
            _cameraBoundCB.setCallback(this, "cameraBound");
            box.addChildGui(_cameraBoundCB);
        }

        {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.center);
            box.spacing = Vec2f(15f, 0f);
            vbox.addChildGui(box);

            box.addChildGui(new Label("Météo:"));

            _weatherSelector = new DropDownList(Vec2f(125f, 25f), 5);
            _weatherSelector.add("Aucune");
            _weatherSelector.add("Ensoleillée");
            _weatherSelector.selected = _weather;
            _weatherSelector.setCallback(this, "weather");
            box.addChildGui(_weatherSelector);
        }

        {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.center);
            box.spacing = Vec2f(15f, 0f);
            vbox.addChildGui(box);

            box.addChildGui(new Label("Script:"));

            _scriptSelector = new DropDownList(Vec2f(125f, 25f), 5);
            _scriptSelector.add("");
            auto files = dirEntries(buildNormalizedPath("assets", "script"), "{*.gr}", SpanMode.shallow);
            foreach(file; files) {
                string fileName = baseName(stripExtension(file));
                _scriptSelector.add(fileName);
            }
            _scriptSelector.setSelectedName(_script);
            _scriptSelector.setCallback(this, "script");
            box.addChildGui(_scriptSelector);
        }

        {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.center);
            box.spacing = Vec2f(15f, 0f);
            vbox.addChildGui(box);

            box.addChildGui(new Label("Illumination Globale:"));

            _globalIlluminationSlider = new HSlider;
            _globalIlluminationSlider.size = Vec2f(150f, 15f);
            _globalIlluminationSlider.step = 1_000;
            _globalIlluminationSlider.fvalue = _globalIllumination;
            _globalIlluminationSlider.setCallback(this, "illumination");
            box.addChildGui(_globalIlluminationSlider);
        }

        { //Validation
            auto box = new HContainer;
            box.setAlign(GuiAlignX.right, GuiAlignY.bottom);
            box.spacing = Vec2f(25f, 15f);
            addChildGui(box);

            auto applyBtn = new TextButton(_isNew ? "Créer" : "Mettre à jour");
            applyBtn.size = Vec2f(150f, 35f);
            applyBtn.setCallback(this, "apply");
            box.addChildGui(applyBtn);
            _applyBtn = applyBtn;
            
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
        case "cancel":
            stopModalGui();
            break;
        case "width":
        case "height":
            break;
        case "cameraBound":
            _isCameraBound = _cameraBoundCB.value;
            break;
        case "weather":
            _weather = cast(Weather) _weatherSelector.selected;
            break;
        case "script":
            _script = _scriptSelector.getSelectedName();
            break;
        case "illumination":
            _globalIllumination = _globalIlluminationSlider.fvalue;
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