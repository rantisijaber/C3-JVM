module jvm::parser;
import std::io;


macro String[16] @flag_names($Type) {
    String[16] names;
    $foreach $member : $Type::members:
        names[$member.bitoffset] = $member.name;
    $endforeach
    return names;
}


struct Organized {
    ClassFile* cf;
}

fn void Organized.read_class_flags(&self, ushort val) {
    io::printfn("CLASS ACCESS FLAGS");
    io::printfn("============");
    String[16] names = @flag_names(ClassAccessFlags);
    for (ushort i = 0; i < 16; i++) {
        if (val & (1 << i)) io::printfn(names[i]);
    }
    ushort this_class = self.cf.this_class;
    ushort super_class = self.cf.super_class;

    ushort this_class_utf8_ind = self.cf.conpool[this_class].etype.entry_16bit;
    ushort super_class_utf8_ind = self.cf.conpool[super_class].etype.entry_16bit;

    io::printfn("this_class: %d, %s", this_class, 
                (String)self.cf.conpool[this_class_utf8_ind].etype.entry_utf8);
    io::printfn("super_class: %d, parent class: %s", super_class, 
                (String)self.cf.conpool[super_class_utf8_ind].etype.entry_utf8);

    ushort interface_count = self.cf.interface_count;
    io::printfn("Interface Count: %d", interface_count);
    ushort[] interface_indices = self.cf.interface_indices;

    foreach (ushort index : interface_indices) {
        ushort inter_index = self.cf.conpool[index].etype.entry_16bit;
        io::printfn("Interface %d: %s", index, (String) self.cf.conpool[inter_index].etype.entry_utf8);
    io::printfn("============");
    }
}

fn void Organized.init_organized(&self, ClassFile* cf) {
    self.cf = cf;

}

fn void Organized.read_header(&self) {
    io::printfn("============");
    io::printfn("HEADER");
    io::printfn("============");
    Header hdr = self.cf.hdr;
    io::printfn("Magic: 0x%08x", hdr.magic);
    io::printfn("Minor Version: %d", hdr.minor);
    io::printfn("Major Version: %d", hdr.major);
    io::printfn("Constant Pool Counter: %d", hdr.conpool_count);
    io::printfn("============");
}

fn void Organized.read_conpool(&self) {
    io::printfn("CONSTANT POOL");
    io::printfn("============");
    foreach (i, ConPoolEntry entry : self.cf.conpool.map) {
        io::printfn("Index: %d <-> Tag: %s" , i, entry.tag);
    
        switch (entry.tag) {
            case ConstantType.TYPE_UTF8:
                io::printfn("\tValue: \"%s\" ", (String) entry.etype.entry_utf8);
            case ConstantType.TYPE_FIELDREF:
            case ConstantType.TYPE_METHODREF:
            case ConstantType.TYPE_INTERFACE_METHODREF:
                ushort class_index = 
                    (ushort) (entry.etype.entry_32bit >> 16);
                ushort name_and_type_index = 
                    (ushort) (entry.etype.entry_32bit & 0xFFFF);
                io::printfn("\tValue: Class Index (%d), Name and Type Index (%d)", 
                            class_index, name_and_type_index);
            case ConstantType.TYPE_NAMEANDTYPE:
                ushort name_index = 
                    (ushort) (entry.etype.entry_32bit >> 16);
                ushort descriptor_index =
                    (ushort) (entry.etype.entry_32bit & 0xFFFF);
                io::printfn("\tValue: Name Index (%d), Descriptor Index (%d)", 
                            name_index, descriptor_index);
            case ConstantType.TYPE_DYNAMIC:
            case ConstantType.TYPE_INVOKEDYNAMIC:
                ushort bootstrap_method_attr_index = (ushort) (entry.etype.entry_32bit >> 16);
                ushort name_and_type_index = (ushort) (entry.etype.entry_32bit & 0xFFFF);
                io::printfn("\tValue: Bootstrap Method Attribute Index (%d), Name and Type Index (%d)", 
                            bootstrap_method_attr_index, name_and_type_index);
            case ConstantType.TYPE_INTEGER:
            case ConstantType.TYPE_FLOAT:                
                io::printfn("\tValue: %d", entry.etype.entry_32bit);
            case ConstantType.TYPE_LONG:
            case ConstantType.TYPE_DOUBLE:
                io::printfn("\tValue: %d", entry.etype.entry_64bit);
            case ConstantType.TYPE_STRING:
                io::printfn("\tValue: String Index (%d)", entry.etype.entry_16bit);
            case ConstantType.TYPE_METHODTYPE:
                io::printfn("\tValue: Descriptor Index (%d)", entry.etype.entry_16bit);
            case ConstantType.TYPE_MODUL:
            case ConstantType.TYPE_CLASS:
            case ConstantType.TYPE_PACKAGE:
                io::printfn("\tValue: Name Index (%d)", entry.etype.entry_16bit);
            case ConstantType.TYPE_METHODHANDLE:
                io::printfn("\tValue: Reference Kind (%d), Reference Index (%d)",
                            entry.etype.entry_method_handle.ref_kind,
                            entry.etype.entry_method_handle.ref_index);
            default: io::printfn("Value: None (Special Constant)");

        }
    }
    io::printfn("============");
}


fn void Organized.read_fields(&self) {
    io::printfn("FIELDS");
    io::printfn("============");
    if (self.cf.fields.len == 0) io::printfn("No fields");
foreach(i, Field field : self.cf.fields) {
        io::printfn("\tFIeld %d:", i);
        io::printfn("\tField name index: %d", field.name_index);
        io::printfn("\tField descriptor count: %d", field.descriptor_count);
        io::printfn("\tField attribute count: %d", field.attribute_count);
        io::printfn("\tField attributes: ");
        self.read_attributes(field.attributes);
        io::printfn("\tField Access Flags:");
        ushort val = (ushort) self.cf.fields[i].access_flags;
        String[16] names = @flag_names(FieldAccessFlags);
        for (ushort name_ind = 0; name_ind < 16; name_ind++) {
            if (val & (1 << name_ind)) io::printfn("\t\t%s", names[name_ind]);
        }


    }
    io::printfn("============");
}

fn void Organized.read_attributes(&self, Attribute[] attributes) @local {
    foreach(i, Attribute attr : attributes) {
        io::printfn("\t\tAttribute name index: %d", attr.name_index);
        io::printfn("\t\tAttribute length: %d", attr.length);
        io::printfn("\t\tAttribute info: %s", (String)attr.info);
    }
}







