module gui.editor;

import std.path, std.file;
import atelier;
import common;
import gui.menubar, gui.viewer, gui.tabslist;
import gui.file;
import gui.warning, gui.entityproperties, gui.snapsettings, gui.mapsettings;

final class Editor: GuiElement {
    private {
        MenuBar _menuBar;
        Viewer _viewer;
        TabsList _tabsList;
        EntityProperties _entityProperties;
        Entity _editedEntity;
    }

    this() {
        size(screenSize);

        _menuBar = new MenuBar(this);
        _viewer = new Viewer(this);

        _tabsList = new TabsList;
        _tabsList.setCallback(this, "tabslist");

        _entityProperties = new EntityProperties;
        editEntity(null);

        addChildGui(_menuBar);
        addChildGui(_viewer);
        addChildGui(_tabsList);
        addChildGui(_entityProperties);
    }

    override void update(float deltaTime) {}

    override void draw() {

    }

    override void onCallback(string id) {
        switch(id) {
        case "tabslist":
            if(!hasTab())
                break;
            reload();
            break;
        case "settings":
            auto modal = popModalGui!MapSettings();
            if(hasTab()) {
                TabData tabData = getCurrentTab();
                if(tabData.width != modal.width || tabData.height != modal.height) {
                    tabData.resize(modal.width, modal.height);
                }
            }
            reload();
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
        if(!hasTab()) {
            _menuBar.setMapName("");
            editEntity(null);
        }
        else {
            _menuBar.setMapName(getCurrentTab().dataPath);
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

    void create() {
        TabData tabData = createTab(0, 0);
        _tabsList.addTab();
    }

    void openSettings() {
        if(!hasTab())
            return;
        auto modal = new MapSettings;
        modal.setCallback(this, "settings");
        pushModalGui(modal);
    }

    void open() {
        auto loadModal = new LoadModal;
        loadModal.setCallback(this, "load.modal");
        pushModalGui(loadModal);
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

    void toggleGrid() {
        _viewer.toggleGrid();
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