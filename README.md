# My First Simple enclave

This is my first enclave for testing and educational purpoce.
It is supposed to generate a library that does a simple adding into an intel SGX environment.

## Compile

### How to Compile

You will need to run the following command:

```bash
make
```

### Key generation for enclave signing:

The makefile generates the keys for enclave signing in `~/.sgx` directory. By default it will generate the `~/.sgx/MyFirstEnclave.pem` key. You can modify the path where the key will be stored by modifying the `KEY_STORAGE_PATH` and `KEY_FILE` accorditly. The following table explains the valies of the variables.

Variable | Use
--- | ---
`KEY_STORAGE_PATH` | The directory where the keys will be stored.
`KEY_FILE` | The file where the key will be generated.

### The `Makefile` in Simple terms

As far I discovered the application you can compile an enclave by doing the following compile chain:

![In what order to compile the files](https://media.githubusercontent.com/media/pc-magas/myFirstEnclave/master/doc/SGX%20Compile%20workflow.png)
