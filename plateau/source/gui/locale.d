module gui.locale;

import std.conv: to;
import atelier;
import common;

final class LocaleGui: GuiElement {
    private {
        DropDownList _keySelector;
        InputField _nameField, _descriptionField;
        bool _isDeleting = false;
    }

    @property {
        bool isDeleting() const { return _isDeleting; }
    }

    string getKey() {
        return _keySelector.getSelectedName();
    }

    string getName() {
        return _nameField.text;
    }

    string getDescription() {
        return _descriptionField.text;
    }
    
    this(string message, string action, string key, string name, string description) {
        super(Flags.movable);
        setAlign(GuiAlignX.center, GuiAlignY.center);
        size(Vec2f(600f, 300f));

        { //Title
            auto title = new Label(message);
            title.setAlign(GuiAlignX.left, GuiAlignY.top);
            title.position = Vec2f(20f, 10f);
            addChildGui(title);
        }
        { //Validation
            auto box = new HContainer;
            box.setAlign(GuiAlignX.right, GuiAlignY.bottom);
            box.spacing = Vec2f(25f, 15f);
            addChildGui(box);

            auto applyBtn = new TextButton(action);
            applyBtn.size = Vec2f(100f, 35f);
            applyBtn.setCallback(this, "apply");
            box.addChildGui(applyBtn);

            if(action == "Éditer") {
                auto delBtn = new TextButton("Supprimer");
                delBtn.size = Vec2f(100f, 35f);
                delBtn.setCallback(this, "delete");
                box.addChildGui(delBtn);
            }

            auto cancelBtn = new TextButton("Annuler");
            cancelBtn.size = Vec2f(100f, 35f);
            cancelBtn.setCallback(this, "cancel");
            box.addChildGui(cancelBtn);
        }

        auto vbox = new VContainer;
        vbox.setChildAlign(GuiAlignX.left);
        vbox.spacing = Vec2f(0f, 10f);
        vbox.setAlign(GuiAlignX.left, GuiAlignY.top);
        vbox.position = Vec2f(10f, 50f);
        addChildGui(vbox);
        {
            auto hbox = new HContainer;
            hbox.spacing = Vec2f(5f, 0f);
            vbox.addChildGui(hbox);
            hbox.addChildGui(new Label("Key:"));
            _keySelector = new DropDownList(Vec2f(200f, 25f));
            _keySelector.add("en_US");
            _keySelector.add("fr_FR");
            _keySelector.setSelectedName(key);
            hbox.addChildGui(_keySelector);
        }

        {
            auto hbox = new HContainer;
            hbox.spacing = Vec2f(5f, 0f);
            vbox.addChildGui(hbox);
            hbox.addChildGui(new Label("Name:"));
            _nameField = new InputField(Vec2f(525f, 25f));
            _nameField.text = to!string(name);
            hbox.addChildGui(_nameField);
        }

        {
            vbox.addChildGui(new Label("Description:"));
            _descriptionField = new InputField(Vec2f(580f, 25f));
            _descriptionField.text = description;
            vbox.addChildGui(_descriptionField);
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
        case "apply":
            triggerCallback();
            break;
        case "cancel":
            stopModalGui();
            break;
        case "delete":
            _isDeleting = true;
            triggerCallback();
            break;
        default:
            break;
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.11f, .08f, .13f));
    }

    override void drawOverlay() {
        drawRect(origin, size, Color.gray);
    }
}