module gui.localesettings;

import std.conv: to;
import atelier;
import gui.locale;
import common;

private {
    LocaleSettings _localeSettingsGui;
}

final class LocaleSettings: GuiElement {
    private {
        VList _effectList, _localeList;
        InputField _idField, _durationField, _costField, _conditionFlagField;
        DropDownList _conditionSelector;
        Locale _locale;
    }

    @property {
        Locale locale() { return _locale; }
    }

    this() {
        super(Flags.movable);
        _localeSettingsGui = this;
        size(Vec2f(600f, 400f));
        setAlign(GuiAlignX.center, GuiAlignY.center);

        { //Title
            auto title = new Label("Localisation:");
            title.setAlign(GuiAlignX.left, GuiAlignY.top);
            title.position = Vec2f(20f, 10f);
            addChildGui(title);
        }

        auto vbox = new VContainer;
        vbox.position = Vec2f(20f, 40f);
        vbox.setChildAlign(GuiAlignX.left);
        vbox.spacing = Vec2f(0f, 10f);
        addChildGui(vbox);

        { // Locale
            auto hbox = new HContainer;
            vbox.addChildGui(hbox);
            hbox.addChildGui(new Label("Nouvelle entrée:"));
            auto addBtn = new TextButton("[ Ajouter ]");
            addBtn.setCallback(this, "addLocale");
            hbox.addChildGui(addBtn);
            _localeList = new VList(Vec2f(size.x - 40f, 250f));

            TabData tabData = getCurrentTab();
            foreach (string key, Locale.Value value; tabData.locale.values) {
                auto localeBtn = new LocaleButton(key, value.name, value.description);
                _localeList.addChildGui(localeBtn);
            }
            vbox.addChildGui(_localeList);
        }

        { //Validation
            auto box = new HContainer;
            box.position = Vec2f(5f, 5f);
            box.setAlign(GuiAlignX.right, GuiAlignY.bottom);
            box.spacing = Vec2f(25f, 15f);
            addChildGui(box);

            auto applyBtn = new TextButton("Appliquer");
            applyBtn.size = Vec2f(100f, 35f);
            applyBtn.setCallback(this, "apply");
            box.addChildGui(applyBtn);
            
            auto cancelBtn = new TextButton("Annuler");
            cancelBtn.size = Vec2f(100f, 35f);
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

    override void onCallback(string id) {
        switch(id) {
        case "addLocale":
            auto gui = new LocaleGui("Ajouter une localisation", "Ajouter", "", "", "");
            gui.setCallback(this, "addLocale.add");
            pushModalGui(gui);
            break;
        case "addLocale.add":
            auto gui = popModalGui!LocaleGui;
            auto localeBtn = new LocaleButton(gui.getKey(), gui.getName(), gui.getDescription());
            _localeList.addChildGui(localeBtn);
            goto case "locale";
        case "locale":
            Locale.Value[string] values;
            foreach(LocaleButton localeBtn; cast(LocaleButton[]) _localeList.getList()) {
                Locale.Value value;
                value.name = localeBtn.name;
                value.description = localeBtn.description;
                values[localeBtn.key] = value;
            }
            _locale = Locale(values);
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

    override void draw() {
        drawFilledRect(origin, size, Color(.11f, .08f, .15f));
    }
}

final class LocaleButton: GuiElement {
    private {
        string _key, _name, _description;
        Label _label;
    }

    @property {
        string key() const { return _key; }
        string name() const { return _name; }
        string description() const { return _description; }
    }

    this(string key, string name, string description) {
        size(Vec2f(300f, 25f));
        _key = key;
        _name = name;
        _description = description;

        _label = new Label;
        _label.setAlign(GuiAlignX.left, GuiAlignY.center);
        addChildGui(_label);

        load(key, name, description);
    }

    private void load(string key, string name, string description) {
        _key = key;
        _name = name;
        _description = description;
        _label.text = "[" ~ _key ~ "]:{" ~ _name ~ "},{"
            ~ _description ~ "}";
    }

    override void onSubmit() {
        auto gui = new LocaleGui("Éditer une localisation", "Éditer", _key, _name, _description);
        gui.setCallback(this, "addLocale.edit");
        pushModalGui(gui);
    }

    override void onCallback(string id) {
        switch(id) {
        case "addLocale.edit":
            auto gui = popModalGui!LocaleGui;
            if(gui.isDeleting)
                removeSelfGui();
            else
                load(gui.getKey(), gui.getName(), gui.getDescription());
            _localeSettingsGui.onCallback("locale");
            break;
        default:
            break;
        }
    }

    override void draw() {
		if(isHovered)
			drawFilledRect(origin, size, Color.white * 0.4f);
		else
			drawFilledRect(origin, size, Color.white * 0.15f);
	}
}

