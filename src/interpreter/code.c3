module jvm::interp;

import jvm::parser;

struct ExceptionTable @packed /* keeping packed even though it wont add any value. was meant for when i was using ushor. but since most machines are little-endian, using shorts will break how bytes are read. */
{
    char[2] start_pc;
    char[2] end_pc;
    char[2] catch_type;
}

struct CodeAttribute {
    ushort max_stack;
    ushort max_locals;
    uint code_length;
    char[] code_bytes;
    ushort exception_table_length;
    ExceptionTable[] tables;
}

fn bool is_code(ClassFile* cf, Attribute attribute) {
    return cf.conpool[attribute.name_index].etype.entry_utf8 == "Code"; 
}

fn void CodeAttribute.parse_code(&self, Attribute attr) {
    self.max_stack = attr.info[0:1];
    self.max_locals = attr.info[2:3];
    self.code_length = attr.info[4:7];
    ushort clength_end = 8 + self.code_length;
    self.code_bytes = attr.info[8:clength_end];
    self.exception_table_length = attr.info[clength_end:clength_end+8];
    ushort etable_start = clength_end + 9; 
    for (usz i = 0; i < self.exception_table_length; i++) {
        self.exception_tables[i] = attr.info[etable_start:etable_start+5];
    }
}



