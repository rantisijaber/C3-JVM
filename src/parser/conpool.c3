module jvm::parser;

fn ConstantType? get_type(char tag)  {
    switch (tag) {
        case 1: return ConstantType.TYPE_UTF8;
        case 3: return ConstantType.TYPE_INTEGER;
        case 4: return ConstantType.TYPE_FLOAT;
        case 5: return ConstantType.TYPE_LONG;
        case 6: return ConstantType.TYPE_DOUBLE;
        case 7: return ConstantType.TYPE_CLASS;
        case 8: return ConstantType.TYPE_STRING;
        case 9: return ConstantType.TYPE_FIELDREF;
        case 10: return ConstantType.TYPE_METHODREF;
        case 11: return ConstantType.TYPE_INTERFACE_METHODREF;
        case 12: return ConstantType.TYPE_NAMEANDTYPE;
        case 15: return ConstantType.TYPE_METHODHANDLE;
        case 16: return ConstantType.TYPE_METHODTYPE;
        case 17: return ConstantType.TYPE_DYNAMIC;
        case 18: return ConstantType.TYPE_INVOKEDYNAMIC;
        case 19: return ConstantType.TYPE_MODUL;
        case 20: return ConstantType.TYPE_PACKAGE;
        default: return ClassFileError.TYPE_NONEXIST;
    }

}

enum ConstantType  {
    TYPE_UTF8,
    TYPE_INTEGER,
    TYPE_FLOAT,
    TYPE_LONG,
    TYPE_DOUBLE,
    TYPE_CLASS,
    TYPE_STRING,
    TYPE_FIELDREF,
    TYPE_METHODREF,
    TYPE_INTERFACE_METHODREF,
    TYPE_NAMEANDTYPE,
    TYPE_METHODHANDLE,
    TYPE_METHODTYPE,
    TYPE_DYNAMIC,
    TYPE_INVOKEDYNAMIC,
    TYPE_MODUL,
    TYPE_PACKAGE,
}

fault ClassFileError {
    TYPE_NONEXIST,
    INVALID_MAGIC,
}


struct MethodHandle {
    char ref_kind;
    ushort ref_index;
}

struct ConPoolEntry {
    char tag;
    union type {
        ushort entry_class;
        ushort entry_string;
        ushort entry_module;
        ushort entry_package;
        ushort entry_method_type;

        MethodHandle entry_method_handle;
        
        uint entry_integer;
        uint entry_float;
        uint entry_fieldref;
        uint entry_methodref;
        uint entry_interface_methodref;
        uint entry_name_and_type;
        uint entry_dynamic;
        uint entry_invoke_dynamic;

        ulong entry_long;
        ulong entry_double;
    
        char[] entry_utf8;
    };
}

struct ConstantPool {
    ConPoolEntry[] map;
    
}


