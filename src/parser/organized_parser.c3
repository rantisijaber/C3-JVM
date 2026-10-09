module jvm::parser;
import std::io;

struct Organized {
    ClassFile* cf;
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

