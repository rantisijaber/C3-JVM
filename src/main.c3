module jvm;
import std::io;
import jvm::parser;


fn int main(String[] args)
{
    if (args.len != 2) {
        return 1;
    }

    char[]? load_file = file::load(mem, args[1]);

    if (catch error = load_file) {
        io::eprintf("Error: Could not load file - %s", error);
        return 1;
    }
    
    char[] bytecode = load_file;
    
    defer mem::free(bytecode);
    
	return 0;
}
