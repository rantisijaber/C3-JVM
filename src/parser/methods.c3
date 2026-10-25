module jvm::parser;
import std::io;

excuse { INVALID_METHOD_ACCESS_FLAGS ,  INVALID_METHOD_NAME_INDEX, INVALID_METHOD_DESC_INDEX }


struct Method {
    MethodAccessFlags access_flags;
    ushort name_index;
    ushort descriptor_index;
    ushort attribute_count;
    Attribute[] attributes;
}


bitstruct MethodAccessFlags : ushort {
    bool acc_public         : 0;
    bool acc_private        : 1;
    bool acc_protected      : 2;
    bool acc_static         : 3;
    bool acc_final          : 4;
    bool acc_synchronized   : 5;
    bool acc_bridge         : 6;
    bool acc_varargs        : 7;
    bool acc_native         : 8;
    bool acc_abstract       : 10;
    bool acc_strict         : 11;
    bool acc_synthetic      : 12;
}

fn void? Method.init(&self, ClassFile* cf) {
    self.parse_acc(cf)!;
    self.name_index = cf.parse_u2();
    io::printfn("%d", self.name_index);
    io::printfn("%s", cf.conpool[self.name_index].tag);
    if (cf.conpool[self.name_index].tag != TYPE_UTF8) return INVALID_METHOD_NAME_INDEX~;
    self.descriptor_index = cf.parse_u2();
    if (cf.conpool[self.descriptor_index].tag != TYPE_UTF8) return INVALID_METHOD_DESC_INDEX~;
    self.attribute_count = cf.parse_u2();
    cf.parse_attributes(self.attributes, self.attribute_count);
}


fn void? Method.parse_acc(&self, ClassFile* cf) {
    MethodAccessFlags acc_flags = (MethodAccessFlags) cf.parse_u2();
    if (acc_flags.acc_public || acc_flags.acc_private || acc_flags.acc_protected) {      
        if (!(acc_flags.acc_public ^ acc_flags.acc_private ^ acc_flags.acc_protected)  
            || (acc_flags.acc_public && acc_flags.acc_public && acc_flags.acc_protected)) {
            return INVALID_METHOD_ACCESS_FLAGS~;
        }

        if (cf.hdr.major < 52 && !(acc_flags.acc_public || acc_flags.acc_private)) {
            return INVALID_METHOD_ACCESS_FLAGS~;
        }
    }

    if (cf.class_access_flags.acc_interface) {
        if (acc_flags.acc_protected || acc_flags.acc_final || acc_flags.acc_synchronized 
            || acc_flags.acc_native) {
            return INVALID_METHOD_ACCESS_FLAGS~;
        }
    }

    if (cf.class_access_flags.acc_abstract) {
       if (acc_flags.acc_private || acc_flags.acc_static || acc_flags.acc_final 
            || acc_flags.acc_synchronized || acc_flags.acc_native) {
            return INVALID_METHOD_ACCESS_FLAGS~;
        } 
    }
    
    self.access_flags = acc_flags;
}


