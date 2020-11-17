module gui.layerslist;

import atelier;
import common;
import gui.constants;

final class LayersList: VList {
    private {
        TabData _currentTabData;
    }

    this() {
        super(Vec2f(layersListWidth, layersListHeight));
        position(Vec2f(0f, (barHeight + tabsHeight)));

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
        auto elementId = selected();
        super.onCallback(id);
        if(elementId != selected())
            triggerCallback();
    }

    override void update(float deltaTime) {
        super.update(deltaTime);
        if(!(isButtonDown(KeyButton.leftControl) || isButtonDown(KeyButton.rightControl))) {
            if(getButtonDown(KeyButton.up)) {
                selected(selected() - 1);
                triggerCallback();
            }
            if(getButtonDown(KeyButton.down)) {
                selected(selected() + 1);      
                triggerCallback();            
            }
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.08f, .09f, .11f));
    }

    void moveUpElement() {
		auto elements = getList();
        auto id = selected();

        if(!elements.length)
            return;
        
		if(id >= elements.length)
			throw new Exception("Element id out of bounds");
		else if(id == 0u)
			return;
		else if(id + 1 == elements.length)
			elements = elements[0..$-2] ~ [elements[$-1], elements[$-2]];
		else
			elements = elements[0..id-1] ~ [elements[id], elements[id-1]] ~ elements[id+1..$];

		removeChildrenGuis();
		foreach(element; elements)
			addChildGui(element);
        selected(id - 1);

        setElements();
        triggerCallback();
	}

    void moveDownElement() {
		auto elements = getList();
        auto id = selected();

        if(!elements.length)
            return;

		if(id >= elements.length)
			throw new Exception("Element id out of bounds");
		else if(id + 1 == elements.length)
			return;
		else if(id == 0u)
			elements = [elements[1], elements[0]] ~ elements[2..$];
		else
			elements = elements[0..id] ~ [elements[id+1], elements[id]] ~ elements[id+2..$];

		removeChildrenGuis();
		foreach(element; elements)
			addChildGui(element);
        selected(id + 1);

        setElements();
        triggerCallback();
    }

    void addElement() {
        auto data = new TilesetLayerData;
        data.setDefault();
        auto newElement = new LayerElement(data);
        auto elements = getList();
        auto id = selected();

        if(elements.length == 0u) {
            elements ~= newElement;
            id = 0u;
        }
        else if(id >= elements.length)
            throw new Exception("Element id out of bounds");
        else if(id + 1 == elements.length) {
            elements = elements[0.. id] ~ newElement ~ elements[$ - 1];
        }
        else if(id == 0u) {
            elements = newElement ~ elements;
        }
        else {
            elements = elements[0..id] ~ newElement ~ elements[id..$];
        }

        removeChildrenGuis();
        foreach(element; elements)
            addChildGui(element);
        selected(id);

        setElements();
        triggerCallback();
    }

    void dupElement() {
        auto elements = cast(LayerElement[])getList();
        auto id = selected();

        if(elements.length == 0u)
            return;

        auto newElement = new LayerElement(elements[id]);
        newElement.label.text = elements[id].label.text;

        if(id >= elements.length)
            throw new Exception("Element id out of bounds");
        else if(id + 1 == elements.length) {
            elements = elements[0.. id] ~ newElement ~ elements[$ - 1];
        }
        else if(id == 0u) {
            elements = newElement ~ elements;
        }
        else {
            elements = elements[0..id] ~ newElement ~ elements[id..$];
        }

        removeChildrenGuis();
        foreach(element; elements)
            addChildGui(element);
        selected(id);

        setElements();
        triggerCallback();
    }

    void removeElement() {
		auto elements = getList();
        auto id = selected();

        if(!elements.length)
            return;

		if(id >= elements.length)
			throw new Exception("Element id out of bounds");
		else if(id + 1 == elements.length) {
			elements.length --;
            id --;
        }
		else if(id == 0u) {
			elements = elements[1..$];
            id = 0u;
        }
		else {
			elements = elements[0..id] ~ elements[id + 1..$];
            id --;
        }

		removeChildrenGuis();
		foreach(element; elements)
			addChildGui(element);
        if(elements.length)
            selected(id);

        setElements();
        triggerCallback();
    }

    TilesetLayerData getSelectedData() {
        auto elements = getList();
        auto id = selected();

        if(!elements.length || id >= elements.length)
            throw new Exception("No image element selected");
        return (cast(LayerElement)elements[id]).data;
    }

    void setElements() {
        TilesetLayerData[] elements;
		foreach(LayerElement elementGui; cast(LayerElement[])getList()) {
            elements ~= elementGui.data;
        }
        setCurrentElements(elements);
    }

    bool isSelectingData() {
        const auto elements = getList();
        const auto id = selected();

        return (elements.length && id < elements.length);
    }
    
    void reload() {
        const auto lastIndex = selected();
        removeChildrenGuis();
        if(hasTab()) {
            auto tabData = getCurrentTab();
            foreach(TilesetLayerData element; tabData.layers) {
                auto elementGui = new LayerElement(element);
                elementGui.label.text = element.name;
                addChildGui(elementGui);
            }
            if(_currentTabData) {
                _currentTabData.hasLayersListData = true;
                _currentTabData.layersListIndex = lastIndex;
            }
            _currentTabData = tabData;
            selected(_currentTabData.hasLayersListData ? _currentTabData.layersListIndex : 0);
        }
        triggerCallback();
    }
}

private final class LayerElement: GuiElement {
    private {
        Timer _timer;
    }

    Label label;
    InputField inputField;
    bool isEditingName, isFirstClick = true;
    LayerVisibilityButton visibilityButton;

    TilesetLayerData data;

    this(LayerElement element) {
        label = new Label(element.label.text ~ " (Copie)");
        label.setAlign(GuiAlignX.center, GuiAlignY.center);
        addChildGui(label);
        size = label.size;
        data = new TilesetLayerData(element.data);

        _timer.mode = Timer.Mode.bounce;
        _timer.start(2f);

        visibilityButton = new LayerVisibilityButton;
        visibilityButton.isVisible = data.getVisibility();
        visibilityButton.setAlign(GuiAlignX.right, GuiAlignY.center);
        visibilityButton.setCallback(this, "visibility");
        addChildGui(visibilityButton);
    }

    this(TilesetLayerData data_) {
        label = new Label("Sans-Titre");
        label.setAlign(GuiAlignX.center, GuiAlignY.center);
        addChildGui(label);
        size = label.size;

        data = data_;
        _timer.mode = Timer.Mode.bounce;
        _timer.start(2f);

        visibilityButton = new LayerVisibilityButton;
        visibilityButton.isVisible = data.getVisibility();
        visibilityButton.setAlign(GuiAlignX.right, GuiAlignY.center);
        visibilityButton.setCallback(this, "visibility");
        addChildGui(visibilityButton);
    }

    override void onCallback(string id) {
        if(id == "visibility")
            data.setVisibility(visibilityButton.isVisible);
    }

    override void update(float deltaTime) {
        _timer.update(deltaTime);
        if(isSelected && !isEditingName) {
            if(isButtonDown(KeyButton.leftControl) || isButtonDown(KeyButton.rightControl)) {
                if(getButtonDown(KeyButton.r))
                    switchToEditMode();
            }
        }
        else if(isEditingName && getButtonDown(KeyButton.enter)) {
            applyEditedName();
        }
        if(!isSelected && isEditingName) {
            applyEditedName();
        }
        else if(!isSelected) {
            isFirstClick = true;
        }

        if(label.size.x > size.x && isSelected) {
            label.setAlign(GuiAlignX.left, GuiAlignY.center);
            label.position = Vec2f(lerp(-(label.size.x - size.x), 0f, easeInOutSine(_timer.value01)), 0f);
        }
        else {
            label.setAlign(GuiAlignX.center, GuiAlignY.center);
            label.position = Vec2f.zero;
        }
    }

    void applyEditedName() {
        if(!isEditingName)
            throw new Exception("The element is not in an editing state");
        isEditingName = false;
        isFirstClick = true;

        data.name = inputField.text;
        label.text = data.name;
        removeChildrenGuis();
        addChildGui(label);
        addChildGui(visibilityButton);
    }

    private void switchToEditMode() {
        isEditingName = true;
        removeChildrenGuis();
        inputField = new InputField(size, label.text != "untitled" ? label.text : "");
        inputField.setAlign(GuiAlignX.center, GuiAlignY.center);
        inputField.hasFocus = true;
        addChildGui(inputField);
        addChildGui(visibilityButton);
    }

    override void onSubmit() {
        if(!data.getVisibility()) {
            visibilityButton.isVisible = true;
            data.setVisibility(true);
        }
        if(isSelected && !isEditingName) {
            if(!isFirstClick) {
                switchToEditMode();
            }
            isFirstClick = false;
        }
        triggerCallback();
    }

    override void draw() {
        Color color = isSelected ? Color.fromHex(0x9EBBFF) : Color.fromHex(0x8B7CCC);
        drawFilledRect(origin, Vec2f(10f, size.y), color);
        if(isSelected)
            drawFilledRect(origin + Vec2f(10f, 0), size - Vec2f(10f, 0f), Color.fromHex(0x3B4D6E));
    }
}

private final class LayerVisibilityButton: Button {
    private {
        Sprite _visibleSprite, _hiddenSprite;
    }

    bool isVisible = true;

    this() {
        _visibleSprite = fetch!Sprite("editor.visible");
        _hiddenSprite = fetch!Sprite("editor.hidden");
        size(Vec2f(25f, 25f));
    }

    override void onSubmit() {
        isVisible = !isVisible;
        triggerCallback();
    }

    override void draw() {
        _visibleSprite.fit(size);
        _hiddenSprite.fit(size);

        if(isVisible)
            _visibleSprite.draw(center);
        else
            _hiddenSprite.draw(center);
    }
}