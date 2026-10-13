module jvm::parser;

import std::io;
import libc;

excuse { 
    INVALID_CLASS_FLAGS, 
    INVALID_MAGIC, 
    INVALID_THIS_CLASS,
    INVALID_SUPER_CLASS
}


struct Header {
    uint magic;
    ushort minor;
    ushort major;
    ushort conpool_count;
}

/*
bitstruct Header : char[10] {
    uint magic          : 0..31;
    ushort minor        : 32..47;
    ushort major        : 48..63;
    ushort conpool_count: 64..79;
}


fn void? ClassFile.parse_header(&self) {
    Header hdr = (Header)self.bytecode[0..9];
}
*/

struct ClassFile {
    usz len;
    usz pos;
    Header hdr;
    ushort this_class;
    ushort super_class;
    ClassAccessFlags class_access_flags;
    ConstantPool conpool;
    char[] bytecode;
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
    if (self.hdr.magic != 0xCAFEBABE) return INVALID_MAGIC~; 
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
            return INVALID_CLASS_FLAGS~;
        }
    } else if (class_flags.acc_abstract && class_flags.acc_final) {
        return INVALID_CLASS_FLAGS~;
    }

    self.class_access_flags = class_flags;
    self.parse_this_super()!;
} 

fn void? ClassFile.parse_this_super(&self) {
    ushort this_class = self.parse_u2();
    io::printfn("%d", this_class);
    if (self.conpool[this_class].tag != TYPE_CLASS) return INVALID_THIS_CLASS~;
    ushort super_class = self.parse_u2();
    if (super_class == 0 || self.class_access_flags.acc_interface) {
        usz class_name_index = self.conpool[super_class].etype.entry_16bit;
        char[] class_name = self.conpool[class_name_index].etype.entry_utf8;
        io::printfn("WTFFFF%s", class_name);
        if (class_name != "java/lang/Object") return INVALID_SUPER_CLASS~;    
    }
    
    self.this_class = this_class;
    self.super_class = super_class;
    
}
