module jvm;

import jvm::parser;
import std::io;

fn bool view(String[] args) {
    foreach (String str : args) {
        if (str == "v") return true;
    }

    return false;
}

fn int main(String[] args)
{
    if (args.len < 2 || args.len > 4) {
        io::eprintn("Error: Invalid argument count");
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
    
    /* This snippet is just testing the code attribute 
    i know its not supposed to be here 
    */
    
    if (view(args)) {        
        Organized og = { .cf = &cf };
        og.read_header();
        og.read_conpool();
        og.read_class_flags((ushort) og.cf.class_access_flags);
        og.read_fields();
        og.read_methods();
    defer mem::free(bytecode);
    cf.destroy();
    }
	return 0;
}
