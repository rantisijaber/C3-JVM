# c3-jvm

A work-in-progress JVM written in [C3](https://c3-lang.org), built to learn how the Java Virtual Machine works from the ground up.

## Status

**Current stage: class file parsing.**

- [x] Read a `.class` file into memory
- [x] Parse the header (magic, minor/major version, constant pool count)
- [ ] Parse the constant pool (in progress)
- [ ] Parse access flags, `this_class`, `super_class`, interfaces
- [ ] Parse fields and methods
- [ ] Parse attributes (`Code`, `SourceFile`, etc.)
- [ ] Bytecode interpreter
- [ ] Object heap and memory management
- [ ] Minimal standard library (`System.out.println`, etc.)

## Goals

- Parse and run real `.class` files produced by `javac`, following the JVM spec for the class file format and opcode semantics.
- Keep the internals my own: custom memory layout, allocator strategy, and execution model.
- Learn C3's allocators, optionals/faults, and slices along the way.

## References

- [JVM Specification, Chapter 4: The class File Format](https://docs.oracle.com/javase/specs/jvms/se21/html/jvms-4.html)
- [C3 language docs](https://c3-lang.org)
