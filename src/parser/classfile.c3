module jvm::parser;
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
    AccessFlag[] access_flag;
}

// access flag rules, have to use bit masking

enum AccessFlag {
    AF_PUBLIC,
    AF_FINAL,
    AF_SUPER,
    AF_INTERFACE,
    AF_ABSTRACT,
    AF_SYNTEHTIC,
    AF_ANNOTATION,
    AF_ENUM
}

fn void? ClassFile.init_cf(&self, char[] bc) {
    *self = { 
        .bytecode = bc, 
        .len = bc.len, 
        .pos = 0,
        .hdr = {},
        .conpool = {}
    };

    self.parse_header()!;
    self.conpool.init_conpool(self.hdr.conpool_count);
    self.parse_conpool()!;
}



fn void? ClassFile.parse_header(&self) @private {
    self.hdr.magic = self.parse_u4();
    if (self.hdr.magic != 0xCAFEBABE) return INVALID_MAGIC~; 
    self.hdr.minor = self.parse_u2();
    self.hdr.major = self.parse_u2();
    self.hdr.conpool_count = self.parse_u2();
}


fn ushort ClassFile.parse_u2(&self) {
    ushort res = ((uint) self.bytecode[self.pos] << 8 
                  | (uint) self.bytecode[self.pos + 1]);
    self.pos += 2; 
    return res;
}

fn uint ClassFile.parse_u4(&self) {
    uint res = ((uint) self.bytecode[self.pos] << 24 
                | ((uint) self.bytecode[self.pos + 1] << 16)
                | (uint) self.bytecode[self.pos + 2] << 8
                | (uint) self.bytecode[self.pos + 3]);
    self.pos += 4;
    return res;
}


fn void ClassFile.parse_acc(&self) {

} 
