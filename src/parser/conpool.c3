module jvm::parser;
import std::io;
import libc;

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
        default: return TYPE_NONEXIST~;
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

faultdef TYPE_NONEXIST, INVALID_MAGIC;



struct MethodHandle {
    char ref_kind;
    ushort ref_index;
}

struct ConPoolEntry {
    ConstantType tag;
    union etype {
        ushort entry_16bit;
        MethodHandle entry_method_handle;
        uint entry_32bit;
        ulong entry_64bit;
        char[] entry_utf8;
    }
}


struct ConstantPool {
    ConPoolEntry[] map;    
}

fn void ConstantPool.init(&self,  ushort conpool_count) {
    *self = {
        .map = mem::new_array(ConPoolEntry, conpool_count)
    };
}

fn void ConstantPool.append(&self, ConPoolEntry entry, uint index) {
   self.map[index] = entry; 
}


fn void? ClassFile.parse_conpool(&self, ConstantPool* pool) {
    for (uint i = 1; i < self.hdr.conpool_count; i++) {
        char tag = self.bytecode[self.pos];
        self.pos++;       
        ConstantType entag = get_type(tag)!;
       
        ConPoolEntry entry = { .tag = entag };

        switch (entag) {
            case ConstantType.TYPE_UTF8: 
                ushort length = self.parse_u2();
                char[] parsed = self.bytecode[self.pos:length];
                self.pos += length;
                entry.etype.entry_utf8 = parsed; 
            case ConstantType.TYPE_FIELDREF:
            case ConstantType.TYPE_METHODREF:
            case ConstantType.TYPE_INTERFACE_METHODREF:
            case ConstantType.TYPE_NAMEANDTYPE:
            case ConstantType.TYPE_DYNAMIC:
            case ConstantType.TYPE_INVOKEDYNAMIC:
            case ConstantType.TYPE_INTEGER:
            case ConstantType.TYPE_FLOAT:                
                uint parsed = self.parse_u4();
                entry.etype.entry_32bit = parsed;
            case ConstantType.TYPE_LONG:
            case ConstantType.TYPE_DOUBLE:
                uint f32 = self.parse_u4();
                uint s32 = self.parse_u4();
                ulong parsed = ((ulong) f32 << 32)
                                | ((ulong)s32);
                entry.etype.entry_64bit = parsed;
            case ConstantType.TYPE_CLASS:
            case ConstantType.TYPE_STRING:
            case ConstantType.TYPE_METHODTYPE:
            case ConstantType.TYPE_MODUL:
            case ConstantType.TYPE_PACKAGE:
                ushort parsed = self.parse_u2();
                entry.etype.entry_16bit = parsed;
            case ConstantType.TYPE_METHODHANDLE:
                MethodHandle handle = {
                    .ref_kind = self.bytecode[self.pos++],
                    .ref_index = self.parse_u2()
                };

                entry.etype.entry_method_handle = handle;            
        }
        pool.append(entry, i);
    }
}
