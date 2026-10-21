module jvm;

import jvm::parser;
import std::io;


fn int main(String[] args)
{
    if (args.len != 2) {
        io::eprintn("Error: Arg count needs to be 2");
        return 1;
    }


    String filename = args[1];
    char[]? load_file;

    if (!filename.ends_with(".class")) {
        if (filename.contains(".")) {
            io::eprintfn("Error: Invaid file type");
            return 1;
        }
        String full_filename = filename.tconcat(".class");
        io::printfn(full_filename);
        if (file::is_file(full_filename)) {
            load_file = file::load(mem, full_filename);
        } else {
            io::eprintfn("Error: No such class file exists in this directory");
            return 1;
        } 

    } else {
        load_file = file::load(mem, filename);
    }

    if (catch error = load_file) {
        io::eprintfn("Error: Could not load file - %s", error);
        return 1;
    }
    
    char[] bytecode = load_file;
    
    ClassFile cf = {};

    if (catch error = cf.init_cf(bytecode)) {
        io::eprintfn("Error: Could not initialize class file - %s", error);
        return 1;
    }
    
    if (catch error = cf.parse_classfile()) {
        io::printfn("Error: Could not parse class file - %s", error);
        return 1;
    }

    Organized og = { .cf = &cf };
    og.read_header();
    og.read_conpool();
    og.read_class_flags((ushort) og.cf.class_access_flags);
    og.read_fields();
    defer mem::free(bytecode);
    og.cf.destroy();
    
	return 0;
}
