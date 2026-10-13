public interface TestInterface {
    int    INT_CONST    = 42;
    long   LONG_CONST   = 123456789012345L;
    float  FLOAT_CONST  = 3.5f;
    double DOUBLE_CONST = 2.718281828;
    String STRING_CONST = "hello, class file";

    int    getValue();
    void   setValue(int value);
    String describe(String prefix, long id);

    default String name() {
        return "TestInterface";
    }

    static int twice(int x) {
        return x * 2;
    }
}
