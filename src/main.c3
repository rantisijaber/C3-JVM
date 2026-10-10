module jvm;

import jvm::parser;
import std::io;


fn int main(String[] args)
{
    if (args.len != 2) {
        io::printn("TEST");
        return 1;
    }


    io::printn("TEST PASSED");



    char[]? load_file = file::load(mem, args[1]);
    
    if (catch error = load_file) {
        io::eprintfn("Error: Could not load file - %s", error);
        return 1;
    }
    
    char[] bytecode = load_file;
    
    ClassFile cf = {};

    if (catch error = cf.init_cf(bytecode)) {
        io::eprintfn("Error: Could not initialize class file - %s", error);
    }
    


    Organized og = { .cf = &cf };
    og.read_header();
    og.read_conpool();
    defer mem::free(bytecode);
    
	return 0;
}
