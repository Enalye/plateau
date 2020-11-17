module common.entity;

import std.array;
import std.conv: to;
import atelier;
import common.data;

final class Entity {
    private {
        Vec2i _position, _hitbox;
        Sprite _currentSprite;
        Animation _currentAnim;
        bool _isSpawned, _isEdited, _isGrabbed;
        string _id, _type, _name, _flags, _behavior, _map, _tpName;
        string _sprite, _anim;
        int _dirsCount, _direction, _faction;
        bool _hasAnim, _hasSprite;
        bool _isCollidable;

        //Light
        Color _color;
        float _alpha;
    }

    @property {
        string type() const { return _type; }
        int dirsCount() const { return _dirsCount; }

        bool isTilable() const { return _type == "tank" || _type == "tacticalcamp"; }
        bool hasNoRender() const { return _type == "collider" || _type == "teleporter"; }

        string name() const { return _name; }
        string name(string name_) {
            if(_name != name_) {
                onEntityDirty();
                _name = name_;
            }
            return _name;
        }

        string flags() const { return _flags; }
        string flags(string flags_) {
            if(_flags != flags_) {
                onEntityDirty();
                _flags = flags_;
            }
            return _flags;
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

        string behavior() const { return _behavior; }
        string behavior(string behavior_) {
            if(_behavior != behavior_) {
                onEntityDirty();
                _behavior = behavior_;
            }
            return _behavior;
        }

        string map() const { return _map; }
        string map(string map_) {
            if(_map != map_) {
                onEntityDirty();
                _map = map_;
            }
            return _map;
        }

        string tpName() const { return _tpName; }
        string tpName(string tpName_) {
            if(_tpName != tpName_) {
                onEntityDirty();
                _tpName = tpName_;
            }
            return _tpName;
        }

        Vec2i position() const { return _position; }
        Vec2i position(Vec2i position_) {
            if(_position != position_) {
                if(_type == "tank") { 
                    const TabData tabData = getCurrentTab();
                    position_ = position_.clamp(
                        Vec2i(tabData.tileWidth, tabData.tileHeight) / 2,
                        (Vec2i(tabData.width, tabData.height) - 1) * Vec2i(tabData.tileWidth, tabData.tileHeight));
                    position_ = (cast(Vec2i) ((cast(Vec2f) (position_ - 16) / 32).round() * 32)) + 16;
                }
                onEntityDirty();
                _position = position_;
            }
            return _position;
        }

        int direction() const { return _direction; }
        int direction(int direction_) {
            if(_direction != direction_) {
                _direction = direction_;
                reload();
                onEntityDirty();
            }
            return _direction;
        }

        int faction() const { return _faction; }
        int faction(int faction_) {
            if(_faction != faction_) {
                _faction = faction_;
                onEntityDirty();
            }
            return _faction;
        }

        Vec2i hitbox() const { return _hitbox; }
        Vec2i hitbox(Vec2i hitbox_) {
            if(_hitbox != hitbox_) {
                onEntityDirty();
                _hitbox = hitbox_;
            }
            return _hitbox;
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

        bool isCollidable() const { return _isCollidable; }
        bool isCollidable(bool isCollidable_) {
            if(_isCollidable != isCollidable_) {
                _isCollidable = isCollidable_;
                onEntityDirty();
            }
            return _isCollidable;
        }
    }

    this() {}

    this(Entity entity) {
        _id = entity._id;
        _type = entity._type;
        _name = entity._name;
        _behavior = entity._behavior;
        _flags = entity._flags;
        _position = entity._position;
        _hitbox = entity._hitbox;
        _sprite = entity._sprite;
        _anim = entity._anim;
        _hasSprite = entity._hasSprite;
        _hasAnim = entity._hasAnim;
        _direction = entity._direction;
        _dirsCount = entity._dirsCount;
        _color = entity._color;
        _alpha = entity._alpha;
        _isCollidable = entity._isCollidable;
        _map = entity._map;
        _tpName = entity._tpName;
        _faction = entity._faction;
    }

    /// For loader only, not map loading
    this(JSONValue json) {
        _id = getJsonStr(json, "id", "NO_ID");
        _type = getJsonStr(json, "type", "NO_TYPE");
        if(isTilable) {
            _hitbox = Vec2i.one * 16;
        }
        if(_type == "tank") {
            _dirsCount = 4;
        }
        else {
            _hitbox = Vec2i(getJsonInt(json, "width", 0), getJsonInt(json, "height", 0));
            _dirsCount = getJsonInt(json, "dirs", 1);
        }

        //Default value for type-specific fields
        switch(_type) {
        case "prop":
        case "collider":
            _isCollidable = getJsonBool(json, "isCollidable", true);
            break;
        default:
            break;
        }

        if(hasJson(json, "sprite")) {
            _hasSprite = true;
            _sprite = getJsonStr(json, "sprite");
        }
        else if(hasJson(json, "anims")) {
            JSONValue animsNode = getJson(json, "anims");
            foreach (string key, JSONValue animNode; animsNode) {
                if(key == "idle") {
                    _hasAnim = true;
                    _anim = animNode.str;
                }
            }
        }
    }

    void reload() {
        const Entity copy = fetch!Entity(_id);
        _type = copy._type;
        _sprite = copy._sprite;
        _anim = copy._anim;
        _hasAnim = copy._hasAnim;
        _hasSprite = copy._hasSprite;
        _dirsCount = copy._dirsCount;
        _isCollidable = copy._isCollidable;

        _isSpawned = true;
        if(_hasSprite)
            _currentSprite = fetch!Sprite(_sprite);
        else if(_hasAnim)
            _currentAnim = fetch!Animation(_anim);

        if(hasNoRender) {
            _currentSprite = fetch!Sprite("rect");
        }
        else if(_type == "tank") {
            _dirsCount = 4;
        }
        if(isTilable) {
            _hitbox = Vec2i.one * 16;
        }
    }

    void draw() {
        if(!_isSpawned)
            return;
        if(hasNoRender) {
            Color colliderColor = Color(0f, 1f, 0f);
            if(_isEdited && _isGrabbed) {
                colliderColor = Color(1f, .65f, 0f);
            }
            else if(_isEdited) {
                colliderColor = Color(1f, 0f, 0f);
            }
            else if(_isGrabbed) {
                colliderColor = Color(0f, 0f, 1f);
            }
            _currentSprite.color = colliderColor;
            _currentSprite.alpha = .25f;
            _currentSprite.size = cast(Vec2f) (_hitbox * 2);
            _currentSprite.draw(cast(Vec2f) _position);
        }
        else {
            if(_hasSprite)
                _currentSprite.draw(cast(Vec2f) _position);
            else if(_hasAnim) {
                if(_dirsCount <= 1)
                    _currentAnim.draw(cast(Vec2f) _position);
                else {
                    _currentAnim.draw(cast(Vec2f) _position, _direction);
                }
            }
        }

        if(_isEdited && _isGrabbed) {
            drawRect(cast(Vec2f) (_position - _hitbox), cast(Vec2f) (_hitbox * 2), Color.blue);
        }
        else if(_isEdited) {
            drawRect(cast(Vec2f) (_position - _hitbox), cast(Vec2f) (_hitbox * 2), Color.orange);
        }
        else if(_isGrabbed) {
            drawRect(cast(Vec2f) (_position - _hitbox), cast(Vec2f) (_hitbox * 2), Color.white);
        }
    }

    bool collideWith(Vec2i position_) {
        return position_.isBetween(_position - _hitbox, _position + _hitbox);
    }

    bool isInside(Vec2i start, Vec2i end) {
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
        _hitbox = Vec2i(getJsonInt(json, "width", 0), getJsonInt(json, "height", 0));
        _name = getJsonStr(json, "name", "");

        if(hasJson(json, "flags")) {
            _flags = join(getJsonArrayStr(json, "flags"), " ");
        }
        else {
            _flags = "";
        }
        _direction = getJsonInt(json, "direction", 0);
        reload();

        // Type specific values
        switch(_type) {
        case "light":
            if(hasJson(json, "light")) {
                JSONValue lightNode = getJson(json, "light");
                _color = Color(
                    getJsonFloat(lightNode, "r", 1f),
                    getJsonFloat(lightNode, "g", 1f),
                    getJsonFloat(lightNode, "b", 1f));
                _alpha = getJsonFloat(lightNode, "a", 1f);
            }
            else {
                _color = Color.white;
                _alpha = 1f;
            }
            break;
        case "prop":
        case "collider":
            _isCollidable = getJsonBool(json, "isCollidable", _isCollidable);
            break;
        case "tank":
            _behavior = getJsonStr(json, "behavior", "playable");
            _faction = getJsonInt(json, "faction", 0);
            break;
        case "teleporter":
            _map = getJsonStr(json, "map", "");
            _tpName = getJsonStr(json, "tpName", "");
            break;
        default:
            break;
        }
        if(isTilable) {
            _position = (_position * 32) + 16;
        }
    }

    /// Map saving
    JSONValue save() {
        JSONValue json;
        json["id"] = id;
        if(isTilable) {
            const TabData tabData = getCurrentTab();
            Vec2i gridPos = (_position - 16) / 32;
            gridPos = gridPos.clamp(Vec2i.zero, Vec2i(tabData.width, tabData.height) - 1);
            json["x"] = gridPos.x;
            json["y"] = gridPos.y;
        }
        else {
            json["x"] = _position.x;
            json["y"] = _position.y;
        }
        json["width"] = _hitbox.x;
        json["height"] = _hitbox.y;
        json["name"] = _name;

        JSONValue[] flagsNode;
        foreach(string sub; _flags.split) {
            flagsNode ~= JSONValue(sub);
        }
        json["flags"] = flagsNode;
        json["direction"] = _direction;

        // Type specific values
        switch(_type) {
        case "light":
            JSONValue lightNode;
            lightNode["r"] = _color.r;
            lightNode["g"] = _color.g;
            lightNode["b"] = _color.b;
            lightNode["a"] = _alpha;
            json["light"] = lightNode;
            break;
        case "prop":
        case "collider":
            json["isCollidable"] = _isCollidable;
            break;
        case "tank":
            json["behavior"] = _behavior;
            json["faction"] = _faction;
            break;
        case "teleporter":
            json["map"] = _map;
            json["tpName"] = _tpName;
            break;
        default:
            break;
        }

        return json;
    }
}