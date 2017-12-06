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

The makefile generates the keys for enclave signing in `~/.sgx` directory. By default it will generate the `~/.sgx/MyFirstEnclave.pem` key. You can modify the path where the key will be stored by modifying the `KEY_STORAGE_PATH` and `KEY_PRIVATE_FILE` and `KEY_PUBLIC_FILE` accorditly. The following table explains the valies of the variables.

Variable | Use
--- | ---
`KEY_STORAGE_PATH` | The directory where the keys will be stored.
`KEY_PRIVATE_FILE` | The private key that will be generated and will be used to sign the enclave.
`KEY_PUBLIC_FILE` | The public key that will be used from others to verify the signed enclave.

### The `Makefile` in Simple terms

As far I discovered the application you can compile an enclave by doing the following compile chain:

![In what order to compile the files](https://media.githubusercontent.com/media/pc-magas/myFirstEnclave/master/doc/SGX%20Compile%20workflow.png)


## Requirements

* A GNU\Linux Distribution with the [sgx driver](https://github.com/01org/linux-sgx-driver) and the [sdk & psw libraries](https://github.com/01org/linux-sgx)
* The `gcc` , `g++`, `make` and `openssl` tools.
* [Git lfs](https://git-lfs.github.com/) for documentation (optionally)
