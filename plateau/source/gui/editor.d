module gui.editor;

import std.path, std.file;
import atelier;
import common;
import gui.menubar, gui.layerslist, gui.layerscontroler, gui.viewer, gui.tabslist;
import gui.typeselector, gui.tileselector, gui.layerproperties, gui.file;
import gui.warning, gui.entityproperties, gui.snapsettings, gui.mapsettings;
import gui.localesettings;

final class Editor: GuiElement {
    private {
        MenuBar _menuBar;
        LayersList _layersList;
        Viewer _viewer;
        TabsList _tabsList;
        TypeSelector _typeSelector;
        LayersControler _layersControler;
        TileSelector _tileSelector;
        LayerProperties _layerProperties;
        EntityProperties _entityProperties;

        Entity _editedEntity;
    }

    this() {
        size(screenSize);

        _menuBar = new MenuBar(this);
        _layersList = new LayersList;
        _layersList.setCallback(this, "layerslist");
        _layersControler = new LayersControler(_layersList);
        _viewer = new Viewer(this);

        _tabsList = new TabsList;
        _tabsList.setCallback(this, "tabslist");

        _typeSelector = new TypeSelector;
        _typeSelector.setCallback(this, "type");

        _tileSelector = new TileSelector;
        _tileSelector.setCallback(this, "tiles");

        _layerProperties = new LayerProperties;
        _layerProperties.setCallback(this, "layerProperties");
        _layerProperties.setState("hidden");

        _entityProperties = new EntityProperties;
        editEntity(null);

        addChildGui(_menuBar);
        addChildGui(_layersControler);
        addChildGui(_layersList);
        addChildGui(_viewer);
        addChildGui(_tabsList);
        addChildGui(_typeSelector);
        addChildGui(_layerProperties);
        addChildGui(_entityProperties);
        addChildGui(_tileSelector);
    }

    override void update(float deltaTime) {}

    override void draw() {

    }

    override void onCallback(string id) {
        switch(id) {
        case "layerslist":
            if(_layersList.isSelectingData()) {
                auto data = _layersList.getSelectedData();
                _viewer.setLayer(data);
                _tileSelector.setTileset(data.tileset);
                _tileSelector.setState("visible");
                _layerProperties.setData(data);
                _layerProperties.setState("visible");
            }
            else {
                _layerProperties.setState("hidden");
            }
            break;
        case "tabslist":
            if(!hasTab())
                break;
            reload();
            break;
        case "settings":
            auto modal = popModalGui!MapSettings();
            if(modal.isNew) {
                TabData tabData = createTab(modal.width, modal.height);
                _tabsList.addTab();
                tabData.isCameraBound = modal.isCameraBound;
                tabData.weather = modal.weather;
                tabData.script = modal.script;
                tabData.globalIllumination = modal.globalIllumination;
            }
            else if(hasTab()) {
                TabData tabData = getCurrentTab();
                if(tabData.width != modal.width || tabData.height != modal.height) {
                    tabData.resize(modal.width, modal.height);
                }
                tabData.isCameraBound = modal.isCameraBound;
                tabData.weather = modal.weather;
                tabData.script = modal.script;
                tabData.globalIllumination = modal.globalIllumination;
            }
            reload();
            break;
        case "locale":
            auto modal = popModalGui!LocaleSettings();
            if(!hasTab())
                break;
            TabData tabData = getCurrentTab();
            tabData.locale = modal.locale;
            break;
        case "type":
            final switch(_typeSelector.type) with(EditType) {
            case layers:
                _layersControler.setState("visible");
                _layersList.setState("visible");
                _tileSelector.setState("visible");
                if(_layersList.isSelectingData()) {
                    _tileSelector.setTileset(_layersList.getSelectedData().tileset);
                }
                break;
            case entities:
                _layersControler.setState("hidden");
                _layersList.setState("hidden");
                _tileSelector.setState("hidden");
                _tileSelector.setTileset(null);
                break;
            }
            reload();
            break;
        case "tiles":
            _viewer.setTilesSelection(_tileSelector.selection);
            break;
        case "layerProperties":
            if(_layersList.isSelectingData()) {
                auto data = _layersList.getSelectedData();
                if(_layerProperties.typeName.length)
                    data.setTypeName(_layerProperties.typeName);
                if(_layerProperties.tilesetName.length)
                    data.setTilesetName(_layerProperties.tilesetName);
                if(_layerProperties.brushName.length)
                    data.setBrushName(_layerProperties.brushName);
                reload();
            }
            break;
        case "save.modal":
            auto saveModal = popModalGui!SaveModal;
            setTabDataPath(saveModal.getPath());
            saveTab();
            if(hasTab())
                _menuBar.setMapName(getCurrentTab().dataPath);
            break;
        case "load.modal":
            auto loadGui = popModalGui!LoadModal;
            if(!openTab(loadGui.value)) {
                auto gui = new WarningMessageGui("Impossible d'ouvrir ce fichier", "", "Ok");
                pushModalGui(gui);
            }
            else {
                reload();
                _tabsList.addTab();
            }
            break;
        case "close.modal":
            stopModalGui();
            _tabsList.removeTab();
            closeTab();
            reload();
            break;
        case "quit.modal":
            stopModalGui();
            stopApplication();
            break;
        default:
            break;
        }
    }

    void reload() {
        _layersList.reload();

        if(!hasTab()) {
            _menuBar.setMapName("");
            _tileSelector.setState("hidden");
            _tileSelector.setTileset(null);
            _layerProperties.setState("hidden");
            editEntity(null);
            _viewer.setLayer(null);
        }
        else {
            _menuBar.setMapName(getCurrentTab().dataPath);
            _viewer.setEditType(_typeSelector.type);
            if(_typeSelector.type != EditType.layers) {
                _viewer.setLayer(null);
                _tileSelector.setTileset(null);
                _tileSelector.setState("hidden");
                _layerProperties.setState("hidden");
            }
            else if(_layersList.isSelectingData()) {
                auto data = _layersList.getSelectedData();
                _viewer.setLayer(data);
                _tileSelector.setTileset(data.tileset);
                _tileSelector.setState("visible");
                _layerProperties.setData(data);
                _layerProperties.setState("visible");
                editEntity(null);
            }
            else {
                _viewer.setLayer(null);
                _tileSelector.setTileset(null);
                _tileSelector.setState("hidden");
                _layerProperties.setState("hidden");
                editEntity(null);
            }
        }
        _viewer.reload();
    }

    override void onEvent(Event event) {
        super.onEvent(event);
		switch(event.type) with(EventType) {
        case resize:
            size = cast(Vec2f) event.window.size;
            break;
        default:
            break;
        }
    }

    void openSettings(bool isNew) {
        if(!hasTab() && !isNew)
            return;
        auto modal = new MapSettings(isNew);
        modal.setCallback(this, "settings");
        pushModalGui(modal);
    }

    void open() {
        auto loadModal = new LoadModal;
        loadModal.setCallback(this, "load.modal");
        pushModalGui(loadModal);
    }

    void openLocaleSettings() {
        if(!hasTab())
            return;
        auto modal = new LocaleSettings();
        modal.setCallback(this, "locale");
        pushModalGui(modal);
    }

    // Save an already saved project.
    void save() {
        if(!hasTab())
            return;
        auto tabData = getCurrentTab();
        if(tabData.hasSavePath())
            saveTab();
        else
            saveAs();
    }

    /// Select a new save file and save the project.
    void saveAs() {
        if(!hasTab())
            return;
        auto saveModal = new SaveModal;
        saveModal.setCallback(this, "save.modal");
        pushModalGui(saveModal);
    }

    void close() {
        if(!hasTab())
            return;
        if(getCurrentTab().isDirty) {
            auto gui = new WarningMessageGui("Il y a des modifications non-sauvegardées. Veux-tu vraiment fermer ?", "Fermer");
            gui.setCallback(this, "close.modal");
            pushModalGui(gui);
        }
        else {
            _tabsList.removeTab();
            closeTab();
            reload();
        }
    }

    void quit() {
        if(!hasTab()) {
            stopApplication();
            return;
        }
        if(getCurrentTab().isDirty) {
            auto gui = new WarningMessageGui("Il y a des modifications non-sauvegardées. Veux-tu vraiment quitter ?", "Quitter");
            gui.setCallback(this, "quit.modal");
            pushModalGui(gui);
            return;
        }
        stopApplication();
    }

    void testMap() {
        import std.process: spawnShell;
        if(!hasTab())
            return;
        TabData tabData = getCurrentTab();
        if(!tabData.hasSavePath() ||tabData.isDirty()) {
            auto gui = new WarningMessageGui("Impossible de tester une carte non-sauvegardée", "", "Ok");
            gui.setCallback(this, "quit.modal");
            pushModalGui(gui);
            return;
        }
        string dataPath = tabData.dataPath;
        string dir = baseName(dirName(dataPath));
        string fileName = buildNormalizedPath(dir, baseName(stripExtension(dataPath)));
        spawnShell("cd pzdv & dub run -- " ~ fileName);
    }

    void toggleGrid() {
        _viewer.toggleGrid();
    }

    void flipH() {
        _viewer.flipH();
    }

    void flipV() {
        _viewer.flipV();
    }

    void cancelChange() {
        if(_layersList.isSelectingData()) {
            auto data = _layersList.getSelectedData();
            data.cancelHistory();
        }
    }

    void restoreChange() {
        if(_layersList.isSelectingData()) {
            auto data = _layersList.getSelectedData();
            data.restoreHistory();
        }
    }

    void openSnapSettings() {
        pushModalGui(new SnapSettings);
    }

    void updateEntity() {
        if(_editedEntity) {
            _entityProperties.setData(_editedEntity);
        }
    }

    void editEntity(Entity entity) {
        if(entity && entity == _editedEntity) {
            _entityProperties.setData(entity);
            return;
        }
        if(_editedEntity)
            _editedEntity.setEdit(false);
        if(!entity) {
            _editedEntity = entity;
            _entityProperties.setData(null);
            _entityProperties.setState("hidden");
            return;
        }
        _editedEntity = entity;
        _editedEntity.setEdit(true);
        _entityProperties.setData(_editedEntity);
        _entityProperties.setState("visible");
    }
}