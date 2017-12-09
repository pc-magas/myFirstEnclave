#include <iostream>
#include "Enclave_u.h"
#include "sgx_urts.h"
#include "sgx_utils/sgx_utils.h"

/* Global EID shared by multiple threads */
sgx_enclave_id_t global_eid = 0;

int main(int argc, char const *argv[]) {
    if (initialize_enclave(&global_eid, "enclave.token", "enclave.signed.so") < 0) {
        std::cerr << "Fail to initialize enclave." << std::endl;
        return 1;
    }

    int result=0,a=1,b=2;

    std::cout << "Calling secure ad" << std::endl;
    sgx_status_t status = sum(global_eid, &a,&b,&result);

    std::cout << "Enclave Returned status: " << status << std::endl;

    if (status != SGX_SUCCESS) {
        std::cerr << "Enclave have not called sucessfully" << std::endl;
        return 1;
    }

    std::cout << "Sum result: " << result << std::endl;
    return 0;
}
