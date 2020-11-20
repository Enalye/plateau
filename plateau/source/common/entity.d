module common.entity;

import std.array;
import std.conv: to;
import atelier;
import common.data;

private enum _labelOffset = 25f;

final class Entity {
    private {
        Vec2i _position;
        Vec2f _size;
        Sprite _currentSprite;

        bool _isSpawned, _isEdited, _isGrabbed;
        string _id, _name;
        string _sprite;

        //Light
        Color _color = Color.white;
        float _alpha = 1f;

        Label _label;
        bool _isRemoved;
        Timer _fxTimer;

        TabData _tabData;
    }

    @property {
        string name() const { return _name; }
        string name(string name_) {
            if(_name != name_) {
                onEntityDirty();
                _name = name_;
                if(_label)
                    _label.text = _name;
            }
            return _name;
        }

        string id() const { return _id; }
        string id(string id_) {
            if(_id != id_) {
                _id = id_;
                reload();
                onEntityDirty();
            }
            return _id;
        }

        Vec2i position() const { return _position; }
        Vec2i position(Vec2i position_) {
            if(_position != position_) {
                onEntityDirty();
                _position = position_;
                if(_label)
                    _label.position = (cast(Vec2f) _position) + Vec2f(-_label.size.x / 2f, -(_labelOffset + (_size.y / 2f)));
            }
            return _position;
        }

        Vec2f size() const { return _size; }
        Vec2f size(Vec2f size_) {
            if(_size != size_) {
                onEntityDirty();
                _size = size_;
            }
            return _size;
        }

        float red() const { return _color.r; }
        float red(float r) {
            if(_color.r != r) {
                _color.r = r;
                onEntityDirty();
            }
            return _color.r;
        }

        float blue() const { return _color.b; }
        float blue(float b) {
            if(_color.b != b) {
                _color.b = b;
                onEntityDirty();
            }
            return _color.b;
        }

        float green() const { return _color.g; }
        float green(float g) {
            if(_color.g != g) {
                _color.g = g;
                onEntityDirty();
            }
            return _color.g;
        }

        float alpha() const { return _alpha; }
        float alpha(float a) {
            if(_alpha != a) {
                _alpha = a;
                onEntityDirty();
            }
            return _alpha;
        }
    }

    this() {}

    this(Entity entity) {
        _id = entity._id;
        _name = entity._name;
        _position = entity._position;
        _size = entity._size;
        _sprite = entity._sprite;
        _color = entity._color;
        _alpha = entity._alpha;
    }

    /// For loader only, not map loading
    this(JSONValue json) {
        _id = getJsonStr(json, "id", "NO_ID");
        _size = Vec2f(getJsonFloat(json, "w", 0f), getJsonFloat(json, "h", 0f));

        if(hasJson(json, "img")) {
            _sprite = getJsonStr(json, "img");
        }
    }

    void setLabel(Label label) {
        if(_label) {
            _label.removeSelfGui();
        }
        _label = label;
        if(_label) {
            _label.text = _name;
            _label.position = (cast(Vec2f) _position) + Vec2f(-_label.size.x / 2f, -(_labelOffset + (_size.y / 2f)));
        }
    }

    void setData(TabData tabData, ) {
        _tabData = tabData;
    }

    void reload() {
        const Entity copy = fetch!Entity(_id);
        _sprite = copy._sprite;

        _isSpawned = true;
        if(_sprite.length)
            _currentSprite = fetch!Sprite(_sprite);
        else
            _currentSprite = fetch!Sprite("rect");

        if(_currentSprite) {
            if(_size.x <= 0f)
                _size.x = _currentSprite.size.x;
            if(_size.y <= 0f)
                _size.y = _currentSprite.size.y;
        }
    }

    void onRemove() {
        if(_isRemoved)
            return;
        _isRemoved = true;
        _fxTimer.start(5f);
    }

    void update(float deltaTime) {
        if(!_isSpawned)
            return;
        _fxTimer.update(deltaTime);
        if(_isRemoved && !_fxTimer.isRunning) {
            _tabData.removeEntity(this);
            if(_label)
                _label.removeSelfGui();
        }

        if(_label) {
            _label.position = (cast(Vec2f) _position) + Vec2f(-_label.size.x / 2f, -(_labelOffset + (_size.y / 2f)));
            _label.color = _color;
            if(_isRemoved)
                _label.alpha = lerp(_alpha, 0f, easeInOutSine(_fxTimer.value01));
            else
                _label.alpha = _alpha;
        }
    }

    void draw() {
        if(!_isSpawned)
            return;
        if(_currentSprite) {
            _currentSprite.size = _size;
            _currentSprite.color = _color;
            if(_isRemoved)
                _currentSprite.alpha = lerp(_alpha, 0f, easeInOutSine(_fxTimer.value01));
            else
                _currentSprite.alpha = _alpha;
            _currentSprite.draw(cast(Vec2f) _position);
        }

        if(!_isRemoved) {
            if(_isEdited && _isGrabbed) {
                drawRect((cast(Vec2f) _position) - (_size / 2f), _size, Color.blue);
            }
            else if(_isEdited) {
                drawRect((cast(Vec2f) _position) - (_size / 2f), _size, Color.orange);
            }
            else if(_isGrabbed) {
                drawRect((cast(Vec2f) _position) - (_size / 2f), _size, Color.white);
            }
        }
    }

    bool collideWith(Vec2i position_) {
        if(_isRemoved)
            return false;
        return (cast(Vec2f) position_).isBetween((cast(Vec2f) _position) - (_size / 2f), (cast(Vec2f) _position) + (_size / 2f));
    }

    bool isInside(Vec2i start, Vec2i end) {
        if(_isRemoved)
            return false;
        return _position.isBetween(start, end);
    }

    void setEdit(bool isEdited) {
        _isEdited = isEdited;
    }

    void setGrab(bool isGrabbed) {
        _isGrabbed = isGrabbed;
    }

    /// Map loading
    void load(JSONValue json) {
        _id = getJsonStr(json, "id", "NO_ID");
        _position = Vec2i(getJsonInt(json, "x", 0), getJsonInt(json, "y", 0));
        _size = Vec2f(getJsonFloat(json, "w", 0), getJsonFloat(json, "h", 0));
        _name = getJsonStr(json, "name", "");

        reload();

        if(hasJson(json, "color")) {
            JSONValue colorNode = getJson(json, "color");
            _color = Color(
                getJsonFloat(colorNode, "r", 1f),
                getJsonFloat(colorNode, "g", 1f),
                getJsonFloat(colorNode, "b", 1f));
            _alpha = getJsonFloat(colorNode, "a", 1f);
        }
        else {
            _color = Color.white;
            _alpha = 1f;
        }
    }

    /// Map saving
    JSONValue save() {
        JSONValue json;
        json["id"] = id;
        json["x"] = _position.x;
        json["y"] = _position.y;
        json["w"] = _size.x;
        json["h"] = _size.y;
        json["name"] = _name;

        JSONValue colorNode;
        colorNode["r"] = _color.r;
        colorNode["g"] = _color.g;
        colorNode["b"] = _color.b;
        colorNode["a"] = _alpha;
        json["color"] = colorNode;

        return json;
    }
}