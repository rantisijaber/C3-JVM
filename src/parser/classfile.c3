module jvm::parser;

import std::io;
import libc;

excuse { 
    INVALID_CLASS_FLAGS, 
    INVALID_MAGIC, 
    INVALID_THIS_CLASS,
    INVALID_SUPER_CLASS,
    INVALID_INTERFACE
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
    DynamicArenaAllocator parser_arena;
    usz len;
    usz pos;
    Header hdr;
    ushort this_class;
    ushort super_class;
    ushort interface_count;
    ushort field_count;
    ushort method_count;
    ClassAccessFlags class_access_flags;
    ushort[] interface_indices;
    Field[] fields;
    Method[] methods;
    char[] bytecode;
    ConstantPool conpool;
}

fn void? ClassFile.init_cf(&self, char[] bc) {
    *self = { 
        .bytecode = bc, 
        .len = bc.len, 
    };

    self.parser_arena.init(mem, 16 * 1024);
    self.parse_header()!;
    self.conpool.init_conpool(self, self.hdr.conpool_count);
}

fn void? ClassFile.parse_classfile(&self) {
    self.parse_conpool()!;
    self.parse_class_acc()!;
    self.parse_interfaces()!;
    self.parse_fields()!;
    self.parse_methods()!;
}

fn void ClassFile.destroy(&self) {
    self.parser_arena.free();
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
    if (self.conpool[this_class].tag != TYPE_CLASS) return INVALID_THIS_CLASS~;
    ushort super_class = self.parse_u2();
    if (super_class == 0 || self.class_access_flags.acc_interface) {
        usz class_name_index = self.conpool[super_class].etype.entry_16bit;
        char[] class_name = self.conpool[class_name_index].etype.entry_utf8;
        if (class_name != "java/lang/Object") return INVALID_SUPER_CLASS~;    
    }
    
    self.this_class = this_class;
    self.super_class = super_class;
    
}

fn void? ClassFile.parse_interfaces(&self) {
    ushort interface_count = self.parse_u2();
    ushort[] interface_indices = alloc::new_array(&self.parser_arena, ushort, interface_count); 
    for (usz i = 0; i < interface_count; i++) {
        interface_indices[i] = self.parse_u2();
        if (self.conpool[interface_indices[i]].tag != TYPE_CLASS) return INVALID_INTERFACE~;
    }

    self.interface_count = interface_count;
    self.interface_indices = interface_indices;
}


fn void? ClassFile.parse_fields(&self) {
    ushort field_count = self.parse_u2();
    self.field_count = field_count;
    self.fields = alloc::new_array(&self.parser_arena, Field, self.field_count);
    for (usz i = 0; i < field_count; i++) {
        Field field = {};
        field.init(self)!;
        self.fields[i] = field;
    }
}


struct Attribute {
    ushort name_index;
    uint length;
    char[] info;
}


fn void Attribute.init(&self, ClassFile* cf, ushort name_index, uint length) {
    *self = {
        .name_index = name_index,
        .length = length,
        .info = cf.bytecode[cf.pos:length]
    };
}

fn void ClassFile.parse_attributes(&self, Attribute[] attributes, ushort attribute_count) {
    attributes = alloc::new_array(&self.parser_arena, Attribute, attribute_count);
    for (usz i = 0; i < attribute_count; i++) {
        ushort name_index = self.parse_u2();
        uint length = self.parse_u4();
        Attribute attribute = {};
        attribute.init(self, name_index, length);
        attributes[i] = attribute; 
    }
}

fn void? ClassFile.parse_methods(&self) {
    ushort method_count = self.parse_u2();
    self.method_count = method_count;
    self.methods = alloc::new_array(&self.parser_arena, Method, self.method_count); 
    for (usz i = 0; i < self.method_count; i++) {    
        Method method = {};
        method.init(self)!;
        self.methods[i] = method;
    }
    
}
