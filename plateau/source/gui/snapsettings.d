module gui.snapsettings;

import std.conv: to;
import atelier;

private {
    int _snapValue = 16;
}

int getSnapValue() {
    return _snapValue;
}

final class SnapSettings: GuiElement {
    private {
        InputField _snapField;
        TextButton _applyBtn;
    }

    this() {
        size(Vec2f(450f, 200f));
        setAlign(GuiAlignX.center, GuiAlignY.center);

        { //Title
            auto title = new Label("Alignement sur la grille:");
            title.setAlign(GuiAlignX.left, GuiAlignY.top);
            title.position = Vec2f(20f, 10f);
            addChildGui(title);
        }

        {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.center, GuiAlignY.center);
            box.spacing = Vec2f(15f, 5f);
            addChildGui(box);

            box.addChildGui(new Label("Alignement: "));

            _snapField = new InputField(Vec2f(100f, 25f), to!string(_snapValue));
            _snapField.setAllowedCharacters("0123456789");
            _snapField.setCallback(this, "snap");
            box.addChildGui(_snapField);
        }

        { //Validation
            auto box = new HContainer;
            box.setAlign(GuiAlignX.right, GuiAlignY.bottom);
            box.spacing = Vec2f(25f, 15f);
            addChildGui(box);

            auto applyBtn = new TextButton("Changer");
            applyBtn.size = Vec2f(100f, 35f);
            applyBtn.setCallback(this, "apply");
            box.addChildGui(applyBtn);
            _applyBtn = applyBtn;
            
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

    override void update(float deltaTime) {
        if(getButtonDown(KeyButton.enter))
            onCallback("apply");
        else if(getButtonDown(KeyButton.escape))
            onCallback("cancel");
    }

    override void onCallback(string id) {
        switch(id) {
        case "snap":
            try {
                to!int(_snapField.text);
                _applyBtn.isLocked = false;
            }
            catch(Exception e) {
                _applyBtn.isLocked = true;
            }
            break;
        case "apply":
            try {
                _snapValue = to!int(_snapField.text);
            }
            catch(Exception e) {}
            stopModalGui();
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