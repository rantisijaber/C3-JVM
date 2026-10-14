module jvm::parser;


excuse { INVALID_FIELD_ACCESS_FLAGS }


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


fn void? Field.init(&self, ClassFile* cf) {
    self.parse_acc(cf)!;
    self.name_index = cf.parse_u2();
    self.descriptor_count = cf.parse_u2();
    self.attribute_count = cf.parse_u2();
    self.attributes = mem::new_array(Attribute, (sz) self.attribute_count);
}

fn void? Field.parse_acc(&self, ClassFile* cf){
    FieldAccessFlags acc_flags = (FieldAccessFlags) cf.parse_u2();
    if (!(acc_flags.acc_public ^ acc_flags.acc_private ^ acc_flags.acc_protected) 
        || (acc_flags.acc_public && acc_flags.acc_public && acc_flags.acc_protected)) {
        return INVALID_FIELD_ACCESS_FLAGS~;
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


