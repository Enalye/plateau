module gui.file.save_modal;

import std.file, std.path;
import atelier;
import common;
import gui.file.editable_path_gui;

final class SaveModal: GuiElement {
    final class DirListGui: VList {
        private {
            string[] _subDirs;
        }

        this() {
            super(Vec2f(400f, 300f));
        }

        override void onCallback(string id) {
            super.onCallback(id);
            if(id == "list") {
                triggerCallback();
            }
        }

        override void draw() {
            drawFilledRect(origin, size, Color(.08f, .09f, .11f));
        }

        void add(string subDir) {
            addChildGui(new TextButton(subDir));
            _subDirs ~= subDir;
        }

        string getSubDir() {
            if(selected() >= _subDirs.length)
                throw new Exception("Subdirectory index out of range");
            return _subDirs[selected()];
        }

        void reset() {
            removeChildrenGuis();
            _subDirs.length = 0;
        }
    }

	private {
		InputField _inputField;
        EditablePathGui _pathLabel;
        DirListGui _list;
		string _path;
    }
    
	this() {
        _path = buildNormalizedPath("assets", "map");
        if(hasTab()) {
            auto tabData = getCurrentTab();
            if(tabData.hasSavePath())
                _path = dirName(tabData.dataPath());
        }

        size(Vec2f(500f, 500f));
        setAlign(GuiAlignX.center, GuiAlignY.center);

        { //Title
            auto title = new Label("Save to Json:");
            title.setAlign(GuiAlignX.left, GuiAlignY.top);
            title.position = Vec2f(20f, 10f);
            addChildGui(title);
        }

        {
            _pathLabel = new EditablePathGui(_path);
            _pathLabel.setAlign(GuiAlignX.left, GuiAlignY.top);
            _pathLabel.position = Vec2f(20f, 50f);
            _pathLabel.setCallback(this, "path");
            addChildGui(_pathLabel);
        }

        { //Text Field
            auto box = new HContainer;
            box.setAlign(GuiAlignX.center, GuiAlignY.bottom);
            box.position = Vec2f(0f, 60f);
            addChildGui(box);

            _inputField = new InputField(Vec2f(300f, 25f), "untitled");
            box.addChildGui(_inputField);

            box.addChildGui(new Label(".json"));
        }

        { //Validation
            auto box = new HContainer;
            box.setAlign(GuiAlignX.right, GuiAlignY.bottom);
            box.spacing = Vec2f(25f, 15f);
            addChildGui(box);

            auto applyBtn = new TextButton("Save");
            applyBtn.size = Vec2f(80f, 35f);
            applyBtn.setCallback(this, "apply");
            box.addChildGui(applyBtn);

            auto cancelBtn = new TextButton("Cancel");
            cancelBtn.size = Vec2f(80f, 35f);
            cancelBtn.setCallback(this, "cancel");
            box.addChildGui(cancelBtn);
        }

        { //List
            auto vbox = new VContainer;
            vbox.setAlign(GuiAlignX.center, GuiAlignY.center);
            vbox.position = Vec2f.zero;
            addChildGui(vbox);

            {
                auto hbox = new HContainer;
                vbox.addChildGui(hbox);

                auto parentBtn = new TextButton("Parent");
                parentBtn.setCallback(this, "parent_folder");
                hbox.addChildGui(parentBtn);
            }
            {
                _list = new DirListGui;
                _list.setCallback(this, "sub_folder");
                vbox.addChildGui(_list);
            }
        }

        reloadList();

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

    string getPath() {
        return buildNormalizedPath(_path, setExtension(_inputField.text, ".json"));
    }
    
    override void onCallback(string id) {
        switch(id) {
        case "path":
            if(exists(_pathLabel.text) && isDir(_pathLabel.text)) {
                _path = _pathLabel.text;
                reloadList();
            }
            else {
                _pathLabel.text = _path;
            }
            break;
        case "sub_folder":
            _path = buildNormalizedPath(_path, _list.getSubDir());
            reloadList();
            break;
        case "parent_folder":
            _path = dirName(_path);
            reloadList();
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

    void reloadList() {
        _pathLabel.text = _path;
        _list.reset();
        auto files = dirEntries(_path, SpanMode.shallow);
        foreach(file; files) {
            if(!file.isDir())
                continue;
            _list.add(baseName(file));
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.11f, .08f, .15f));
    }

    override void drawOverlay() {
        drawRect(origin, size, Color.gray);
    }
}