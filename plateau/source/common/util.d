module common.util;

import std.path, std.string, std.algorithm, std.file;
import atelier;

private immutable string[] _validDataExtensions = [
    ".json"
];

enum FileType {
    DirectoryType, JsonFileType, ImageFileType, InvalidType
}

/// Check whether the data file format is accepted.
bool isValidDataFileType(string file) {
    return _validDataExtensions.canFind(extension(file).toLower());
}

/// Discriminate between file types.
FileType getFileType(string filePath) {
    try {
        if(isDir(filePath))
            return FileType.DirectoryType;
        if(isValidDataFileType(filePath))
            return FileType.JsonFileType;
        return FileType.InvalidType;
    }
    catch(Exception e) {
        //Functions like isDir can return an exception
        //when reading a file it can't open.
        //So we don't care about those file.
        return FileType.InvalidType;
    }
}