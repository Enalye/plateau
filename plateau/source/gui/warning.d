module gui.warning;

import atelier;

final class WarningMessageGui: GuiElement {
    this(string message, string action, string cancel = "Annuler") {
        setAlign(GuiAlignX.center, GuiAlignY.center);

        { //Title
            auto title = new Label(message);
            title.setAlign(GuiAlignX.left, GuiAlignY.top);
            title.position = Vec2f(20f, 10f);
            addChildGui(title);
            size(Vec2f(title.size.x + 40f, 100f));
        }

        { //Validation
            auto box = new HContainer;
            box.setAlign(GuiAlignX.right, GuiAlignY.bottom);
            box.spacing = Vec2f(25f, 15f);
            addChildGui(box);

            if(action.length) {
                auto applyBtn = new TextButton(action);
                applyBtn.size = Vec2f(100f, 35f);
                applyBtn.setCallback(this, "apply");
                box.addChildGui(applyBtn);
            }

            auto cancelBtn = new TextButton(cancel);
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

    override void drawOverlay() {
        drawRect(origin, size, Color.gray);
    }
}