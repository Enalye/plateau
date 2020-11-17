module startup.setup;

import std.file: exists, thisExePath;
import std.path: buildNormalizedPath, dirName;
import atelier;
import gui;
import startup.loader;

void setupApplication(string[] args) {
	//Initialization
	createApplication(Vec2u(1280, 720), "Map Editor");

    const string iconPath = buildNormalizedPath("assets", "img", "logo.png");
	if(exists(iconPath))
		setWindowIcon(iconPath);

    loadAssets();
    setDefaultFont(fetch!TrueTypeFont("Cascadia"));

	Sprite cursor = fetch!Sprite("editor.cursor");
	cursor.size *= 2f;
	setWindowCursor(cursor);

	//Run
    onMainMenu(args);
	runApplication();
    destroyApplication();
}

private void onMainMenu(string[] args) {
	removeRootGuis();
    addRootGui(new Editor);
}