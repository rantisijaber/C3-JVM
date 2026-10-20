module jvm::parser;


excuse { INVALID_FIELD_ACCESS_FLAGS, INVALID_FIELD_NAME_INDEX, INVALID_FIELD_DESC_COUNT }


struct Field {
    FieldAccessFlags access_flags;
    ushort name_index;
    ushort descriptor_count;
    ushort attribute_count;
    Attribute[] attributes;
}

bitstruct FieldAccessFlags : ushort {
    bool acc_public     : 0;
    bool acc_private    : 1;
    bool acc_protected  : 2;
    bool acc_static     : 3;
    bool acc_final      : 4;
    bool acc_volatile   : 6;
    bool acc_transient  : 7;
    bool acc_synthetic  : 12;
    bool acc_enum       : 14;
}

struct Attribute {
    ushort name_index;
    uint length;
    char[] info;
}


fn void? Attribute.init(&self, ClassFile* cf, ushort name_index, uint length) {
    *self = {
        .name_index = name_index,
        .length = length,
        .info = cf.bytecode[cf.pos:length]
    };
}

fn void? Field.init(&self, ClassFile* cf) {
    self.parse_acc(cf)!;
    self.name_index = cf.parse_u2();
    if (cf.conpool[self.name_index].tag != TYPE_UTF8) return INVALID_FIELD_NAME_INDEX~;
    self.descriptor_count = cf.parse_u2();
    if (cf.conpool[self.descriptor_count].tag != TYPE_UTF8) return INVALID_FIELD_DESC_COUNT~;
    self.attribute_count = cf.parse_u2();
    self.attributes = alloc::new_array(&cf.parser_arena, Attribute, self.attribute_count);
    for (usz i = 0; i < self.attribute_count; i++) {
        ushort name_index = cf.parse_u2();
        uint length = cf.parse_u4();
        Attribute attr = {};
        attr.init(cf, name_index, length)!;
        self.attributes[i] = attr;
    }
}

fn void? Field.parse_acc(&self, ClassFile* cf){
    FieldAccessFlags acc_flags = (FieldAccessFlags) cf.parse_u2();
   if (acc_flags.acc_public || acc_flags.acc_private || acc_flags.acc_protected) {      
        if (!(acc_flags.acc_public ^ acc_flags.acc_private ^ acc_flags.acc_protected)  
            || (acc_flags.acc_public && acc_flags.acc_public && acc_flags.acc_protected)) {
            return INVALID_FIELD_ACCESS_FLAGS~;
        }
    }

    if (cf.class_access_flags.acc_interface) {
        if (!(acc_flags.acc_public && acc_flags.acc_static && acc_flags.acc_final)) {
            return INVALID_FIELD_ACCESS_FLAGS~;
        }

        if (acc_flags.acc_private || acc_flags.acc_protected || acc_flags.acc_volatile 
            || acc_flags.acc_transient || acc_flags.acc_enum) {
            return INVALID_FIELD_ACCESS_FLAGS~;
        }
    }

    self.access_flags = acc_flags;

}


