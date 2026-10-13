module jvm::parser;
import std::io;


macro String[16] @class_flag_names($Type) {
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
    String[16] names = @class_flag_names(ClassAccessFlags);
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
        io::printfn("Interface %d: %s", index, self.cf.conpool[index].etype.entry_utf8);
    }
}

fn void Organized.init_organized(&self, ClassFile* cf) {
    self.cf = cf;

}

fn void Organized.read_header(&self) {
    Header hdr = self.cf.hdr;
    io::printfn("Magic: 0x%08x", hdr.magic);
    io::printfn("Minor Version: %d", hdr.minor);
    io::printfn("Major Version: %d", hdr.major);
    io::printfn("Constant Pool Counter: %d", hdr.conpool_count);
}

fn void Organized.read_conpool(&self) {
    foreach (i, ConPoolEntry entry : self.cf.conpool.map) {
        io::printfn("Index: %d <-> Tag: %s" , i, entry.tag);
    } 
}








