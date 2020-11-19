module gui.viewer;

import std.algorithm: canFind;
import std.file: exists;
import std.conv: to;
import atelier;
import common;
import gui.constants, gui.entityselector, gui.editor, gui.snapsettings;

final class Viewer: GuiElement {
    private {
        TabData _currentTabData;

        Vec2i _startCopyPosition, _endCopyPosition;
        bool _isSelecting, _hasCopySelection, _showGrid;

        //Mouse control        
		Vec2f _startMovingCursorPosition, _cursorPosition = Vec2f.zero;
		bool _isGrabbed;
        float _scale = 1f;

        EntitySelector _entitySelector;
        bool _isEntityGrabbed, _isSelectingEntity;
        Entity[] _selectedEntities;
        Vec2i[] _unsnappedEntityPositions;
        Editor _editor;

        Sprite _background;
    }

    this(Editor editor) {
        _editor = editor;
        position(Vec2f(propertiesWidth, (barHeight + tabsHeight)));
        size(Vec2f(screenWidth - propertiesWidth, screenHeight - (barHeight + tabsHeight)));
		super(GuiElement.Flags.canvas);
    }

    void toggleGrid() {
        _showGrid = !_showGrid;
    }

    override void onEvent(Event event) {
        if(!hasTab())
            return;
        switch(event.type) with(EventType) {
        case resize:
            size(Vec2f(event.window.size.x - propertiesWidth, event.window.size.y - (barHeight + tabsHeight)));
            break;
        case mouseUpdate:
            _cursorPosition = event.mouse.position;
            Vec2i roundedPosition = to!Vec2i(event.mouse.position.round());

            if(_isSelecting) {
                brushMouseUpdate(roundedPosition);
            }
            if(_isGrabbed) {
				canvas.position += (_startMovingCursorPosition - event.mouse.position);
            }
            break;
        case mouseDown:
            _cursorPosition = event.mouse.position;
            Vec2i roundedPosition = to!Vec2i(event.mouse.position.round());

            if(!_isSelecting && isButtonDown(MouseButton.left)) {
                _isSelecting = true;
                
                if(isButtonDown(KeyButton.leftControl)
                    || isButtonDown(KeyButton.rightControl)) {
                    if(_entitySelector) {
                        _entitySelector.removeSelfGui();
                        _entitySelector = null;
                    }
                    _entitySelector = new EntitySelector(roundedPosition);
                    _entitySelector.setAlign(GuiAlignX.left, GuiAlignY.top);
                    _entitySelector.position = _cursorPosition;
                    _entitySelector.setCallback(this, "addEntity");
                    addChildGui(_entitySelector);
                }
                else if(_entitySelector) {
                    _entitySelector.removeSelfGui();
                    _entitySelector = null;
                }
                else {
                    brushMouseDown(roundedPosition);
                }
            }
            if(!_isGrabbed && isButtonDown(MouseButton.right)) {
                _isGrabbed = true;
				_startMovingCursorPosition = event.mouse.position;
            }
            break;
        case mouseUp:
            _cursorPosition = event.mouse.position;
            Vec2i roundedPosition = to!Vec2i(event.mouse.position.round());

            if(_isSelecting && !isButtonDown(MouseButton.left)) {
                brushMouseUp(roundedPosition);
                _isSelecting = false;
            }
            if(_isGrabbed && !isButtonDown(MouseButton.right)) {
				_isGrabbed = false;
                canvas.position += (_startMovingCursorPosition - event.mouse.position);
            }
            break;
        case mouseWheel:
            const Vec2f delta = (_cursorPosition - canvas.position) / (canvas.size);
            if(event.mouse.position.y > 0f) {
                if(_scale > 0.25f)
                    _scale *= 0.5f;
            }
            else {
                if(_scale < 4f)
                    _scale /= 0.5f;
            }
            canvas.size = size * _scale;
            const Vec2f delta2 = (_cursorPosition - canvas.position) / (canvas.size);
            canvas.position += (delta2 - delta) * canvas.size;
            break;
        default:
            break;
        }
    }

    void brushMouseUpdate(Vec2i cursorPosition) {
        if(_isEntityGrabbed) {
            const Vec2i deltaPosition = (cursorPosition - _startCopyPosition);
            if(isButtonDown(KeyButton.leftShift) || isButtonDown(KeyButton.rightShift)) {
                int i;
                foreach (Entity entity; _selectedEntities) {
                    _unsnappedEntityPositions[i] += deltaPosition;
                    const float snapValue = cast(float) getSnapValue();
                    entity.position = cast(Vec2i) ((cast(Vec2f) _unsnappedEntityPositions[i] / snapValue).round() * snapValue);
                    i ++;
                }
            }
            else {
                int i;
                foreach (Entity entity; _selectedEntities) {
                    entity.position = entity.position + deltaPosition;
                    _unsnappedEntityPositions[i] = entity.position;
                    i ++;
                }
            }
            _startCopyPosition = cursorPosition;
            _editor.updateEntity();
        }
        _endCopyPosition = cursorPosition;
    }

    void brushMouseDown(Vec2i cursorPosition) {
        _startCopyPosition = cursorPosition;
        _endCopyPosition = cursorPosition;
        Entity entity = _currentTabData.getEntityAt(cursorPosition);
        if(entity) {
            _isEntityGrabbed = true;
            if(!_selectedEntities.canFind(entity)) {
                foreach (Entity sub; _selectedEntities)
                    sub.setGrab(false);
                _selectedEntities = [entity];
                entity.setGrab(true);
            }
            _unsnappedEntityPositions.length = 0;
            foreach (Entity sub; _selectedEntities) {
                _unsnappedEntityPositions ~= sub.position;
            }
            
            _editor.editEntity(entity);
        }
        else {
            _isSelectingEntity = true;
        }
    }

    void brushMouseUp(Vec2i cursorPosition) {
        if(_isEntityGrabbed) {
            _isEntityGrabbed = false;
        }
        else if(_isSelectingEntity) {
            _isSelectingEntity = false;
            foreach (Entity entity; _selectedEntities)
                entity.setGrab(false);
            _selectedEntities = _currentTabData.searchEntities(_startCopyPosition, _endCopyPosition);
            foreach (Entity entity; _selectedEntities)
                entity.setGrab(true);
            if(_selectedEntities.length)
                _editor.editEntity(_selectedEntities[0]);
            else
                _editor.editEntity(null);
            _unsnappedEntityPositions.length = 0;
            foreach (Entity sub; _selectedEntities) {
                _unsnappedEntityPositions ~= sub.position;
            }
        }
    }

    void reloadBackground() {
        if(!hasTab()) {
            _background = null;
            return;
        }
        auto tabData = getCurrentTab();
        if(!exists(tabData.background)) {
            _background = null;
            return;
        }
        auto tex = new Texture(tabData.background);
        _background = new Sprite(tex);
    }

    void reload() {
        if(hasTab()) {
            auto tabData = getCurrentTab();
            if(_currentTabData && _currentTabData != tabData) {
                _currentTabData.hasViewerData = true;
                _currentTabData.viewerPosition = canvas.position;
                _currentTabData.viewerScale = _scale;
            }
            _currentTabData = tabData;

            if(!tabData.hasViewerData) {
                //Reset camera position
                canvas.position = canvas.size / 2f;
                _scale = 1f;
                canvas.size = size * _scale;
            }
            else {
                //Restore camera position
                canvas.position = tabData.viewerPosition;
                _scale = tabData.viewerScale;
                canvas.size = size * _scale;
            }
        }
        else {
            //Reset camera position
            canvas.position = canvas.size / 2f;
            _scale = 1f;
            canvas.size = size * _scale;
            _currentTabData = null;
        }
        reloadBackground();
    }

    override void onCallback(string id) {
        if(!hasTab())
            return;
        switch(id) {
        case "addEntity":
            if(_entitySelector.value.length) {
                Entity entity = fetch!Entity(_entitySelector.value);
                entity.position = _entitySelector.targetPosition;
                auto label = new Label;
                addChildGui(label);
                entity.setData(_currentTabData, label);
                _currentTabData.addEntity(entity);
                _editor.editEntity(entity);
            }
            _entitySelector.removeSelfGui();
            _entitySelector = null;
            break;
        default:
            break;
        }
    }

    override void update(float deltaTime) {
        if(!hasTab())
            return;

        if(!isHovered) {
            _isSelecting = false;
            _isGrabbed = false;
        }

        if(!_currentTabData) {
            _isSelecting = false;
            _isGrabbed = false;
        }
        else {
            if(_selectedEntities.length) {
                if(getButtonDown(KeyButton.remove)) {
                    foreach (Entity entity; _selectedEntities) {
                        entity.onRemove();
                    }
                    _selectedEntities.length = 0;
                    _isEntityGrabbed = false;
                    _isSelecting = false;
                }
                else if(isButtonDown(KeyButton.leftControl) || isButtonDown(KeyButton.rightControl)) {
                    if(getButtonDown(KeyButton.d)) {
                        foreach (Entity entity; _selectedEntities) {
                            Entity cpy = new Entity(entity);
                            cpy.reload();
                            _currentTabData.addEntity(cpy);
                        }
                    }
                }
            }
        }

        foreach (entity; _currentTabData.entities) {
            entity.update(deltaTime);
        }
    }

    override void draw() {
        if(!hasTab())
            return;
        if(!_currentTabData)
            return;
/*
        if(_currentTabData.width > 0f && _currentTabData.height > 0f) {
            drawFilledRect(-Vec2f.one * 5f,
                Vec2f(_currentTabData.width, _currentTabData.height) + 2f * 5f,
                Color.red);
        }*/
/*
        drawFilledRect(Vec2f.zero,
            Vec2f(_currentTabData.width, _currentTabData.height),
            Color.black);*/

        if(_background) {
            _background.anchor = Vec2f.zero;
            _background.draw(Vec2f.zero);
        }

        if(_showGrid) {
            const Color c1 = Color(0.74f, 0.74f, 0.74f);
            const Color c2 = Color(0.49f, 0.49f, 0.49f);
            int x, y, i;
            const int snapValue = getSnapValue();
            for(y = 0; y < _currentTabData.height; ++ y) {
                for(x = 0; x < _currentTabData.width; ++ x) {
                    drawFilledRect(
                        Vec2f(x * snapValue, y * snapValue),
                        Vec2f(snapValue, snapValue),
                        i % 2 > 0 ? c1 : c2);
                    i ++;
                }
                i ++;
            }
        }

        foreach (entity; _currentTabData.entities) {
            entity.draw();
        }

        if(_isSelectingEntity) {
            drawRect(cast(Vec2f) _startCopyPosition, cast(Vec2f) (_endCopyPosition - _startCopyPosition), Color.blue);
        }
    }
}