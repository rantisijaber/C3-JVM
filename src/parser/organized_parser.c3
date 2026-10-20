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







