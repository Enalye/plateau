module common.locale;

import atelier;

struct Locale {
    struct Value {
        string name, description;
    }

    private {
        Value[string] _values;
    }

    @property {
        Value[string] values() { return _values; }
    }

    this(Value[string] values_) {
        _values = values_;
    }

    string getName(string key) const {
        auto p = key in _values;
        if(p is null)
            return "?";
        return p.name;
    }

    string getDescription(string key) const {
        auto p = key in _values;
        if(p is null)
            return "?";
        return p.description;
    }

    void load(JSONValue json) {
        if(!hasJson(json, "locale"))
            return;
        auto metaNode = getJson(json, "locale");
        foreach (string key, ref JSONValue localeNode; metaNode.object) {
            _values[key] = Value(
                getJsonStr(localeNode, "name", "?"),
                getJsonStr(localeNode, "description", "?"));
        }
    }

    void save(JSONValue json) {
        if(!_values.length)
            return;
        JSONValue metaNode;
        foreach (string key, ref Value value; _values) {
            JSONValue localeNode;
            localeNode["name"] = value.name;
            localeNode["description"] = value.description;
            metaNode[key] = localeNode;
        }
        json["locale"] = metaNode;
    }
}