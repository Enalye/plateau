module gui.viewer;

import std.algorithm: canFind;
import std.conv: to;
import atelier;
import common;
import gui.typeselector, gui.constants;
import gui.entityselector, gui.editor, gui.snapsettings;

enum BrushType {
    none, copying, pasting, autotiling, entity
}

final class Viewer: GuiElement {
    private {
        TabData _currentTabData;
        TilesetLayerData _currentLayer;

        Vec2i _startCopyPosition, _endCopyPosition;
        bool _isSelecting, _hasCopySelection, _showGrid;
        BrushType _brushType = BrushType.none;

        EditType _editType;

        //Mouse control        
		Vec2f _startMovingCursorPosition, _cursorPosition = Vec2f.zero;
		bool _isGrabbed;
        float _scale = 1f;
        Timer _timer;
        
        TilesSelection _tilesSelection;
        Brush _brush;

        Vec2i _tileSize = Vec2i(32, 32);

        EntitySelector _entitySelector;
        bool _isEntityGrabbed, _isSelectingEntity;
        Entity[] _selectedEntities;
        Vec2i[] _unsnappedEntityPositions;
        Editor _editor;
    }

    this(Editor editor) {
        _editor = editor;
        position(Vec2f(layersListWidth, (barHeight + tabsHeight)));
        size(Vec2f(screenWidth - layersListWidth, screenHeight - (barHeight + tabsHeight)));
        _timer.mode = Timer.Mode.bounce;
        _timer.start(5f);
		super(GuiElement.Flags.canvas);
    }

    void setEditType(EditType type) {
        if(type == _editType)
            return;
        _editType = type;
        final switch(_editType) with(EditType) {
        case entities:
            _brushType = BrushType.entity;
            break;
        case layers:
            _brushType = BrushType.copying;
            break;
        }
    }

    void setLayer(TilesetLayerData layerData) {
        _currentLayer = layerData;
        if(_currentLayer) {
            _tileSize = _currentLayer.tileset.clip.zw;
            if(_currentLayer.getBrushName().length)
                _brush = fetch!Brush(_currentLayer.getBrushName());
            else
                _brush = null;
        }
        else {
            _tileSize = Vec2i(32, 32);
            _brush = null;
        }
    }

    void setTilesSelection(TilesSelection selection) {
        _tilesSelection = selection;
        _brushType = BrushType.pasting;
    }

    void toggleGrid() {
        _showGrid = !_showGrid;
    }

    override void onEvent(Event event) {
        switch(event.type) with(EventType) {
        case resize:
            size(Vec2f(event.window.size.x - layersListWidth, event.window.size.y - (barHeight + tabsHeight)));
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
                
                if(_brushType == BrushType.entity &&
                    (isButtonDown(KeyButton.leftControl)
                    || isButtonDown(KeyButton.rightControl))) {
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
        /*canvas.position =
            (_texture is null) ? canvas.size / 2f :
            canvas.position.clamp(Vec2f.zero, Vec2f(_texture.width, _texture.height));*/
    }

    void brushMouseUpdate(Vec2i cursorPosition) {
        final switch(_brushType) with(BrushType) {
        case none:
            break;
        case copying:
            _endCopyPosition = cursorPosition / _tileSize;
            _endCopyPosition = _endCopyPosition.clamp(Vec2i.zero, Vec2i(_currentTabData.width, _currentTabData.height) - 1);
            triggerCallback();
            break;
        case pasting:
            _startCopyPosition = cursorPosition / _tileSize;
            _currentLayer.setTilesAt(
                _startCopyPosition.x,
                _startCopyPosition.y,
                _tilesSelection);
            break;
        case entity:
            if(_isEntityGrabbed) {
                const Vec2i deltaPosition = (cursorPosition - _startCopyPosition);
                if(isButtonDown(KeyButton.leftShift) || isButtonDown(KeyButton.rightShift)) {
                    int i;
                    foreach (Entity entity; _selectedEntities) {
                        _unsnappedEntityPositions[i] += deltaPosition;
                        if(entity.isTilable) {
                            entity.position = (cast(Vec2i) ((cast(Vec2f) (_unsnappedEntityPositions[i] - 16) / 32).round() * 32)) + 16;
                        }
                        else {
                            const float snapValue = cast(float) getSnapValue();
                            entity.position = cast(Vec2i) ((cast(Vec2f) _unsnappedEntityPositions[i] / snapValue).round() * snapValue);
                        }
                        i ++;
                    }
                }
                else {
                    int i;
                    foreach (Entity entity; _selectedEntities) {
                        if(entity.isTilable) {
                            _unsnappedEntityPositions[i] += deltaPosition;
                            entity.position = (cast(Vec2i) ((cast(Vec2f) (_unsnappedEntityPositions[i] - 16) / 32).round() * 32)) + 16;
                        }
                        else {
                            entity.position = entity.position + deltaPosition;
                            _unsnappedEntityPositions[i] = entity.position;
                        }
                        i ++;
                    }
                }
                _startCopyPosition = cursorPosition;
                _editor.updateEntity();
            }
            _endCopyPosition = cursorPosition;
            break;
        case autotiling:
            _startCopyPosition = cursorPosition / _tileSize;
            _currentLayer.setTilesAt(
                _startCopyPosition.x,
                _startCopyPosition.y,
                _brush);
            break;
        }
    }

    void brushMouseDown(Vec2i cursorPosition) {
        final switch(_brushType) with(BrushType) {
        case none:
            break;
        case copying:
            _startCopyPosition = cursorPosition / _tileSize;
            _endCopyPosition = cursorPosition / _tileSize;
            _startCopyPosition = _startCopyPosition.clamp(Vec2i.zero, Vec2i(_currentTabData.width, _currentTabData.height) - 1);
            _endCopyPosition = _endCopyPosition.clamp(Vec2i.zero, Vec2i(_currentTabData.width, _currentTabData.height) - 1);
            _tilesSelection.isValid = false;
            _hasCopySelection = true;
            triggerCallback();
            break;
        case pasting:
            _startCopyPosition = cursorPosition / _tileSize;
            _currentLayer.setTilesAt(
                _startCopyPosition.x,
                _startCopyPosition.y,
                _tilesSelection);
            break;
        case entity:
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
            break;
        case autotiling:
            _startCopyPosition = cursorPosition / _tileSize;
            _currentLayer.setTilesAt(
                _startCopyPosition.x,
                _startCopyPosition.y,
                _brush);
            break;
        }
    }

    void brushMouseUp(Vec2i cursorPosition) {
        final switch(_brushType) with(BrushType) {
        case none:
            break;
        case copying:
            _endCopyPosition = cursorPosition / _tileSize;
            _endCopyPosition = _endCopyPosition.clamp(Vec2i.zero, Vec2i(_currentTabData.width, _currentTabData.height) - 1);
            
            const Vec2i startingPoint = _startCopyPosition.min(_endCopyPosition);
            const Vec2i endingPoint = _startCopyPosition.max(_endCopyPosition);
            const Vec2i selectSize = (endingPoint - startingPoint) + 1;
            _tilesSelection = _currentLayer.getTilesAt(
                startingPoint.x,
                startingPoint.y,
                selectSize.x,
                selectSize.y);
            triggerCallback();
            break;
        case pasting:
            _startCopyPosition = cursorPosition / _tileSize;
            _currentLayer.setTilesAt(
                _startCopyPosition.x,
                _startCopyPosition.y,
                _tilesSelection);
            break;
        case entity:
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
                _unsnappedEntityPositions.length = 0;
                foreach (Entity sub; _selectedEntities) {
                    _unsnappedEntityPositions ~= sub.position;
                }
            }
            break;
        case autotiling:
            _startCopyPosition = cursorPosition / _tileSize;
            _currentLayer.setTilesAt(
                _startCopyPosition.x,
                _startCopyPosition.y,
                _brush);
            break;
        }
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
            
            if(_currentLayer)
                _tileSize = _currentLayer.tileset.clip.zw;

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
            _currentLayer = null;
        }
    }

    override void onCallback(string id) {
        switch(id) {
        case "addEntity":
            if(_entitySelector.value.length) {
                Entity entity = fetch!Entity(_entitySelector.value);
                entity.position = _entitySelector.targetPosition;
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
        _timer.update(deltaTime);

        if(!isHovered) {
            _isSelecting = false;
            _isGrabbed = false;
        }

        if(!_currentTabData) {
            _isSelecting = false;
            _isGrabbed = false;
            _brushType = BrushType.none;
        }
        else {
            final switch(_editType) with(EditType) {
            case layers:
                if(!_currentLayer) {
                    _brushType = BrushType.none;
                    break;
                }
                if(_brushType == BrushType.autotiling) {
                    if(!isButtonDown(KeyButton.leftShift) && !isButtonDown(KeyButton.rightShift)) {
                        _brushType = BrushType.pasting;
                        _hasCopySelection = false;
                    }
                }
                else {
                    if(isButtonDown(KeyButton.leftShift) || isButtonDown(KeyButton.rightShift)) {
                        _brushType = BrushType.autotiling;
                    }
                    else if(_brushType == BrushType.copying) {
                        if(!isButtonDown(KeyButton.leftControl) && !isButtonDown(KeyButton.rightControl)) {
                            _brushType = BrushType.pasting;
                            _hasCopySelection = false;
                        }
                        else {
                            _brushType = BrushType.copying;
                        }
                    }
                    else {
                        if(isButtonDown(KeyButton.leftControl) || isButtonDown(KeyButton.rightControl)) {
                            _brushType = BrushType.copying;
                            _hasCopySelection = false;
                        }
                    }
                }
                break;
            case entities:
                _brushType = BrushType.entity;
                if(_selectedEntities.length) {
                    if(getButtonDown(KeyButton.remove)) {
                        _editor.editEntity(null);
                        foreach (Entity entity; _selectedEntities)
                            _currentTabData.removeEntity(entity);
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
                break;
            }
        }
    }

    override void draw() {
        if(!_currentTabData)
            return;

        drawFilledRect(-Vec2f.one * 5f, Vec2f(
            _currentTabData.width * _currentTabData.tileWidth,
            _currentTabData.height * _currentTabData.tileHeight) + 2f * 5f,
            Color.red);

        drawFilledRect(Vec2f.zero, Vec2f(
            _currentTabData.width * _currentTabData.tileWidth,
            _currentTabData.height * _currentTabData.tileHeight),
            Color.black);

        if(_showGrid) {
            const Color c1 = Color(0.74f, 0.74f, 0.74f);
            const Color c2 = Color(0.49f, 0.49f, 0.49f);
            int x, y, i;
            for(y = 0; y < _currentTabData.height; ++ y) {
                for(x = 0; x < _currentTabData.width; ++ x) {
                    drawFilledRect(
                        Vec2f(x * _currentTabData.tileWidth, y * _currentTabData.tileHeight),
                        Vec2f(_currentTabData.tileWidth, _currentTabData.tileHeight),
                        i % 2 > 0 ? c1 : c2);
                    i ++;
                }
                i ++;
            }
        }

        bool isAboveCurrentLayer = false;
        foreach_reverse(layer; _currentTabData.layers) {
            if(layer == _currentLayer) {
                layer.draw(1f);
                isAboveCurrentLayer = true;
            }
            else if(isAboveCurrentLayer)
                layer.draw(.5f);
            else
                layer.draw(1f);
        }

        foreach (entity; _currentTabData.entities) {
            entity.draw();
        }

        final switch(_brushType) with(BrushType) {
        case none:
        case entity:
            if(_isSelectingEntity) {
                drawRect(cast(Vec2f) _startCopyPosition, cast(Vec2f) (_endCopyPosition - _startCopyPosition), Color.blue);
            }
            break;
        case copying:
            Vec2i startingPoint = _startCopyPosition.min(_endCopyPosition);
            Vec2i endingPoint = _startCopyPosition.max(_endCopyPosition);

            if(_tilesSelection.isValid) {
                _tilesSelection.tileset.color = Color.white;
                for(int iy; iy < _tilesSelection.height; ++ iy) {
                    for(int ix; ix < _tilesSelection.width; ++ ix) {
                        if(_tilesSelection.tiles[ix][iy] < 0)
                            continue;
                        _tilesSelection.tileset.draw(
                            _tilesSelection.tiles[ix][iy],
                            (Vec2f(ix, iy) + startingPoint.to!Vec2f()) * _tilesSelection.tileset.clip.zw.to!Vec2f);
                    }
                }
            }
            if(_hasCopySelection) {
                auto rectOrigin = to!Vec2f(startingPoint * _tileSize);
                auto rectSize = to!Vec2f(((endingPoint - startingPoint) + 1) * _tileSize);
                drawRect(rectOrigin, rectSize, Color.orange);
            }
            break;
        case pasting:
            if(_tilesSelection.isValid) {
                _tilesSelection.tileset.color = Color.white;
                Vec2f offsetCoords = (_cursorPosition / _tileSize.to!Vec2f()).floor();
                for(int iy; iy < _tilesSelection.height; ++ iy) {
                    for(int ix; ix < _tilesSelection.width; ++ ix) {
                        if(_tilesSelection.tiles[ix][iy] < 0)
                            continue;
                        _tilesSelection.tileset.draw(_tilesSelection.tiles[ix][iy], (Vec2f(ix, iy) + offsetCoords) * _tileSize.to!Vec2f());
                    }
                }
                auto rectOrigin = offsetCoords * _tileSize.to!Vec2f();
                auto rectSize = Vec2f(_tilesSelection.width * _tileSize.x, _tilesSelection.height * _tileSize.y);
                drawRect(rectOrigin, rectSize, Color.white);
            }
            break;
        case autotiling:
            Vec2f offsetCoords = (_cursorPosition / _tileSize.to!Vec2f()).floor();
            auto rectOrigin = offsetCoords * _tileSize.to!Vec2f();
            auto rectSize = Vec2f(_tileSize.x, _tileSize.y);
            if(_brush && _currentLayer) {
                _currentLayer.tileset.draw(_brush.neighbors[15], offsetCoords * _tileSize.to!Vec2f());
            }
            drawRect(rectOrigin, rectSize, Color.green);
            break;
        }
        
    }

    override void drawOverlay() {
        
    }

    void flipH() {
        _tilesSelection.flipH();
    }

    void flipV() {
        _tilesSelection.flipV();
    }
}