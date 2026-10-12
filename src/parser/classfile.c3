module jvm::parser;

import jvm::excuse;
import std::io;
import libc;

struct Header {
    uint magic;
    uint minor;
    uint major;
    ushort conpool_count;
}

struct ClassFile {
    usz len;
    usz pos;
    Header hdr; 
    ConstantPool conpool;
    char[] bytecode;
    ClassAccessFlags class_access_flags;
}

fn void? ClassFile.init_cf(&self, char[] bc) {
    *self = { 
        .bytecode = bc, 
        .len = bc.len, 
        .pos = 0,
        .hdr = {},
        .conpool = {},
        .class_access_flags = {}
    };

    self.parse_header()!;
    self.conpool.init_conpool(self.hdr.conpool_count);
    self.parse_conpool()!;
    self.parse_class_acc()!;
}



fn void? ClassFile.parse_header(&self)  {
    self.hdr.magic = self.parse_u4();
    if (self.hdr.magic != 0xCAFEBABE) return excuse::INVALID_MAGIC~; 
    self.hdr.minor = self.parse_u2();
    self.hdr.major = self.parse_u2();
    self.hdr.conpool_count = self.parse_u2();
}


fn ushort ClassFile.parse_u2(&self) @inline {
    ushort res = ((uint) self.bytecode[self.pos] << 8 
                  | (uint) self.bytecode[self.pos + 1]);
    self.pos += 2; 
    return res;
}

fn uint ClassFile.parse_u4(&self) @inline {
    uint res = ((uint) self.bytecode[self.pos] << 24 
                | ((uint) self.bytecode[self.pos + 1] << 16)
                | (uint) self.bytecode[self.pos + 2] << 8
                | (uint) self.bytecode[self.pos + 3]);
    self.pos += 4;
    return res;
}


// access flag rules, have to use bit masking
/* 
1. if interface is set, abstract must also be set.  
2. if interface not specified then it must be a class
3. if interface is not set then it can have any of the other flags other than annotation flag
4. class cannot be both abstract and final
5. set all classes to super

*/


bitstruct ClassAccessFlags : ushort {
    bool acc_public     : 0;
    bool acc_final      : 4;
    bool acc_super      : 5;
    bool acc_interface  : 9;
    bool acc_abstract   : 10;
    bool acc_synthetic  : 12;
    bool acc_annotation : 13;
    bool acc_enum       : 14;
}


fn void? ClassFile.parse_class_acc(&self) {
    ushort acc_flags = self.parse_u2();
    ClassAccessFlags class_flags = (ClassAccessFlags) acc_flags;
    if (class_flags.acc_interface) {
        if (!class_flags.acc_abstract || class_flags.acc_final 
            || class_flags.acc_super  || class_flags.acc_synthetic
            || class_flags.acc_enum) {
            return excuse::INVALID_CLASS_FLAGS~;
        }
    } else if (class_flags.acc_abstract && class_flags.acc_final) {
        return excuse::INVALID_CLASS_FLAGS~;
    }

    self.class_access_flags = class_flags;
} 
