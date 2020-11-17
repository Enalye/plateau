module startup.loader;

import std.file, std.path, std.conv;
import common;
import atelier;

void loadAssets() {
    loadTextures();
    loadFonts();
    loadBrushes();
    loadEntities();
}

void loadBrushes() {
    auto brushCache = new ResourceCache!Brush;
    setResourceCache!Brush(brushCache);

    auto files = dirEntries(buildNormalizedPath("assets", "brush"), "{*.json}", SpanMode.depth);
    foreach(file; files) {
        JSONValue json = parseJSON(readText(file));

        if(getJsonStr(json, "type") != "brush")
            continue;
        
        auto brush = new Brush;
        brush.name = getJsonStr(json, "name");
        brush.tileset = getJsonStr(json, "tileset");
        const auto neighbors = ["0000", "0001", "0010", "0011", "0100", "0101", "0110", "0111", "1000", "1001", "1010", "1011", "1100", "1101", "1110", "1111"];
        const auto neighborsNode = getJson(json, "neighbors");
        foreach(size_t i, string neighbor; neighbors) {
            brush.neighbors[i] = getJsonInt(neighborsNode, neighbor);
        }
        brushCache.set(brush, brush.name);
    }
}

void loadEntities() {
    auto entityCache = new ResourceCache!Entity;
    setResourceCache!Entity(entityCache);

    auto files = dirEntries(buildNormalizedPath("assets", "entity"), "{*.json}", SpanMode.depth);
    foreach(file; files) {
        JSONValue json = parseJSON(readText(file));

        if(getJsonStr(json, "type") != "entity")
            continue;

        foreach(entityNode; getJsonArray(json, "entities")) {
            string key = getJsonStr(entityNode, "id");
            Entity entity = new Entity(entityNode);
            entityCache.set(entity, key);
        }
    }
}

void loadTextures() {
    auto textureCache = new ResourceCache!Texture;
    auto spriteCache = new ResourceCache!Sprite;
    auto tilesetCache = new ResourceCache!Tileset;
    auto animationCache = new ResourceCache!Animation;
    auto ninePathCache = new ResourceCache!NinePatch;

    setResourceCache!Texture(textureCache);
    setResourceCache!Sprite(spriteCache);
    setResourceCache!Tileset(tilesetCache);
    setResourceCache!Animation(animationCache);
    setResourceCache!NinePatch(ninePathCache);

    Flip getFlip(JSONValue node) {
        switch(getJsonStr(node, "flip", "none")) {
        case "none":
            return Flip.none;
        case "horizontal":
            return Flip.horizontal;
        case "vertical":
            return Flip.vertical;
        case "both":
            return Flip.both;
        default:
            return Flip.none;
        }
    }

    Vec4i getClip(JSONValue node) {
        auto clipNode = getJson(node, "clip");
        Vec4i clip;
        clip.x = getJsonInt(clipNode, "x", 0);
        clip.y = getJsonInt(clipNode, "y", 0);
        clip.z = getJsonInt(clipNode, "w", 1);
        clip.w = getJsonInt(clipNode, "h", 1);
        return clip;
    }

    Vec2i getMargin(JSONValue node) {
        if(hasJson(node, "margin")) {
            auto marginNode = getJson(node, "margin");
            Vec2i margin;
            margin.x = getJsonInt(marginNode, "x", 0);
            margin.y = getJsonInt(marginNode, "y", 0);
            return margin;
        }
        return Vec2i.zero;
    }

	auto files = dirEntries(buildNormalizedPath("assets", "img"), "{*.json}", SpanMode.depth);
    foreach(file; files) {
        JSONValue json = parseJSON(readText(file));

        if(getJsonStr(json, "type") != "spritesheet")
            continue;

        auto srcImage = buildNormalizedPath(dirName(file), convertPathToImport(getJsonStr(json, "texture")));
        auto texture = new Texture(srcImage);
        textureCache.set(texture, srcImage);

        auto elementsNode = getJsonArray(json, "elements");

		foreach(JSONValue elementNode; elementsNode) {
            string name = getJsonStr(elementNode, "name");
            Vec4i clip = getClip(elementNode);
            Flip flip = getFlip(elementNode);

            const string elementType = getJsonStr(elementNode, "type", "null");
            switch(elementType) {
            case "sprite":
                auto sprite = new Sprite;
                sprite.clip = clip;
                sprite.flip = flip;
                sprite.size = to!Vec2f(clip.zw);
                sprite.texture = texture;
                spriteCache.set(sprite, name);
                break;
            case "tileset":
                auto tileset = new Tileset;
                tileset.clip = clip;
                tileset.size = to!Vec2f(clip.zw);
                tileset.texture = texture;
                tileset.flip = flip;

                tileset.columns = getJsonInt(elementNode, "columns", 1);
                tileset.lines = getJsonInt(elementNode, "lines", 1);
                tileset.maxtiles = getJsonInt(elementNode, "maxtiles", 0);

                tilesetCache.set(tileset, name);
                break;
            case "multiDirAnimation":
            case "animation":
                const int columns = getJsonInt(elementNode, "columns", 1);
                const int lines = getJsonInt(elementNode, "lines", 1);
                const int maxtiles = getJsonInt(elementNode, "maxtiles", 0);

                const Vec2i margin = getMargin(elementNode);

                auto animation = new Animation(texture,
                    clip,
                    columns, lines, maxtiles,
                    margin
                    );
                
                switch(getJsonStr(elementNode, "mode", "once")) {
                case "once":
                    animation.mode = Animation.Mode.once;
                    break;
                case "reverse":
                    animation.mode = Animation.Mode.reverse;
                    break;
                case "loop":
                    animation.mode = Animation.Mode.loop;
                    break;
                case "loop_reverse":
                    animation.mode = Animation.Mode.loopReverse;
                    break;
                case "bounce":
                    animation.mode = Animation.Mode.bounce;
                    break;
                case "bounce_reverse":
                    animation.mode = Animation.Mode.bounceReverse;
                    break;
                default:
                    break;
                }
                animation.duration = getJsonFloat(elementNode, "duration", 1f);
                animation.flip = flip;

                if(hasJson(json, "frames")) {
                    int[] frames = getJsonArrayInt(json, "frames");
                    if(frames.length)
                        animation.frames = frames;
                }

                if(elementType == "multiDirAnimation") {
                    animation.dirs = getJsonInt(elementNode, "dirs", 1);
                    animation.maxDirs = getJsonInt(elementNode, "maxDirs", 1);
                    animation.dirOffset = Vec2i(
                        getJsonInt(elementNode, "dirXOffset", 0),
                        getJsonInt(elementNode, "dirYOffset", 0));
                }
                
                animationCache.set(animation, name);
                break;
            case "ninepatch":
                auto ninePath = new NinePatch;
                ninePath.clip = clip;
                ninePath.size = to!Vec2f(clip.zw);
                ninePath.texture = texture;

                ninePath.top = getJsonInt(elementNode, "top", 0);
                ninePath.bottom = getJsonInt(elementNode, "bottom", 0);
                ninePath.left = getJsonInt(elementNode, "left", 0);
                ninePath.right = getJsonInt(elementNode, "right", 0);

                ninePathCache.set(ninePath, name);
                break;
            default:
                break;
            }
        }
    }
}

void loadFonts() {
    auto fontCache = new ResourceCache!TrueTypeFont;
	setResourceCache!TrueTypeFont(fontCache);

    auto files = dirEntries(buildNormalizedPath("assets", "font"), "{*.ttf}", SpanMode.depth);
    foreach(file; files) {
        fontCache.set(new TrueTypeFont(file), baseName(file, ".ttf"));
    }
}