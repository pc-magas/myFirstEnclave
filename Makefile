SGX_SDK ?= /opt/intel/sgxsdk
SGX_MODE ?= SIM
SGX_ARCH ?= x64

KEY_STORAGE_PATH ?= ~/.sgx
KEY_PRIVATE_FILE=$(KEY_STORAGE_PATH)/MyFirstEnclave_private.pem
KEY_PUBLIC_FILE=$(KEY_STORAGE_PATH)/MyFirstEnclave_public.pem

SGX_HEX=./bin/MyFirstEnclave.hex

ifeq ($(shell getconf LONG_BIT), 32)
	SGX_ARCH := x86
else ifeq ($(findstring -m32, $(CXXFLAGS)), -m32)
	SGX_ARCH := x86
endif

ifeq ($(SGX_ARCH), x86)
	SGX_COMMON_CFLAGS := -m32
	SGX_LIBRARY_PATH := $(SGX_SDK)/lib
	SGX_ENCLAVE_SIGNER := $(SGX_SDK)/bin/x86/sgx_sign
	SGX_EDGER8R := $(SGX_SDK)/bin/x86/sgx_edger8r
else
	SGX_COMMON_CFLAGS := -m64
	SGX_LIBRARY_PATH := $(SGX_SDK)/lib64
	SGX_ENCLAVE_SIGNER := $(SGX_SDK)/bin/x64/sgx_sign
	SGX_EDGER8R := $(SGX_SDK)/bin/x64/sgx_edger8r
endif

ifeq ($(SGX_DEBUG), 1)
ifeq ($(SGX_PRERELEASE), 1)
$(error Cannot set SGX_DEBUG and SGX_PRERELEASE at the same time!!)
endif
endif

ifeq ($(SGX_DEBUG), 1)
		SGX_COMMON_CFLAGS += -O0 -g
else
		SGX_COMMON_CFLAGS += -O2
endif


ifneq ($(SGX_MODE), HW)
	Trts_Library_Name := sgx_trts_sim
	Service_Library_Name := sgx_tservice_sim
else
	Trts_Library_Name := sgx_trts
	Service_Library_Name := sgx_tservice
endif
Crypto_Library_Name := sgx_tcrypto

######## App Settings ########

ifneq ($(SGX_MODE), HW)
	Urts_Library_Name := sgx_urts_sim
else
	Urts_Library_Name := sgx_urts
endif

# App_Cpp_Files := App/App.cpp $(wildcard App/Edger8rSyntax/*.cpp) $(wildcard App/TrustedLibrary/*.cpp)
App_Cpp_Files := App/App.cpp App/sgx_utils/sgx_utils.cpp
# App_Include_Paths := -IInclude -IApp -I$(SGX_SDK)/include
App_Include_Paths := -IApp -I$(SGX_SDK)/include

App_C_Flags := $(SGX_COMMON_CFLAGS) -fPIC -Wno-attributes $(App_Include_Paths)

# Three configuration modes - Debug, prerelease, release
#   Debug - Macro DEBUG enabled.
#   Prerelease - Macro NDEBUG and EDEBUG enabled.
#   Release - Macro NDEBUG enabled.
ifeq ($(SGX_DEBUG), 1)
		App_C_Flags += -DDEBUG -UNDEBUG -UEDEBUG
else ifeq ($(SGX_PRERELEASE), 1)
		App_C_Flags += -DNDEBUG -DEDEBUG -UDEBUG
else
		App_C_Flags += -DNDEBUG -UEDEBUG -UDEBUG
endif

App_Cpp_Flags := $(App_C_Flags) -std=c++11
App_Link_Flags := $(SGX_COMMON_CFLAGS) -L$(SGX_LIBRARY_PATH) -l$(Urts_Library_Name) -lpthread

ifneq ($(SGX_MODE), HW)
	App_Link_Flags += -lsgx_uae_service_sim
else
	App_Link_Flags += -lsgx_uae_service
endif

App_Cpp_Objects := $(App_Cpp_Files:.cpp=.o)

App_Name := app

######## Enclave Settings ########


Enclave_Cpp_Files := ./Enclave/Enclave.cpp

Enclave_Include_Paths := -IEnclave -I$(SGX_SDK)/include -I$(SGX_SDK)/include/tlibc -I$(SGX_SDK)/include/stlport

Enclave_C_Flags := $(SGX_COMMON_CFLAGS) -nostdinc -fvisibility=hidden -fpie -fstack-protector $(Enclave_Include_Paths)
Enclave_Cpp_Flags := $(Enclave_C_Flags) -std=c++03 -nostdinc++
Enclave_Link_Flags := $(SGX_COMMON_CFLAGS) -Wl,--no-undefined -nostdlib -nodefaultlibs -nostartfiles -L$(SGX_LIBRARY_PATH) \
	-Wl,--whole-archive -l$(Trts_Library_Name) -Wl,--no-whole-archive \
	-Wl,--start-group -lsgx_tstdc -lsgx_tstdcxx -l$(Crypto_Library_Name) -l$(Service_Library_Name) -Wl,--end-group \
	-Wl,-Bstatic -Wl,-Bsymbolic -Wl,--no-undefined \
	-Wl,-pie,-eenclave_entry -Wl,--export-dynamic  \
	-Wl,--defsym,__ImageBase=0
	# -Wl,--version-script=Enclave/Enclave.lds

Enclave_Cpp_Objects := $(Enclave_Cpp_Files:.cpp=.o)

Enclave_Name := ./bin/enclave.so
Signed_Enclave_Name := ./bin/enclave.signed.so
Enclave_Config_File := ./bin/Enclave.config.xml

ifeq ($(SGX_MODE), HW)
ifneq ($(SGX_DEBUG), 1)
ifneq ($(SGX_PRERELEASE), 1)
Build_Mode = HW_RELEASE
endif
endif
endif

ifeq ($(Build_Mode), HW_RELEASE)
all: $(Enclave_Name) $(App_Name)
	@echo "The project has been built in release hardware mode."
	@echo "Please sign the $(Enclave_Name) first with your signing key before you run the $(App_Name) to launch and access the enclave."
	@echo "To sign the enclave use the command:"
	@echo "   $(SGX_ENCLAVE_SIGNER) sign -key <your key> -enclave $(Enclave_Name) -out <$(Signed_Enclave_Name)> -config $(Enclave_Config_File)"
	@echo "You can also sign the enclave using an external signing tool. See User's Guide for more details."
	@echo "To build the project in simulation mode set SGX_MODE=SIM. To build the project in prerelease mode set SGX_PRERELEASE=1 and SGX_MODE=HW."
else
all: $(Signed_Enclave_Name)  $(App_Name)
endif

######################## Application build steps ##########################

App/Enclave_u.c: $(SGX_EDGER8R) Enclave/Enclave.edl
	@cd App && $(SGX_EDGER8R) --untrusted ../Enclave/Enclave.edl --search-path ../Enclave --search-path $(SGX_SDK)/include
	@echo "Generating App's untrusted functions  =>  $@"

App/Enclave_u.o: App/Enclave_u.c
	@$(CC) $(App_C_Flags) -c $< -o $@
	@echo "Compile apps untrusted functions   <=  $<"


App/%.o: App/%.cpp
	@$(CXX) $(App_Cpp_Flags) -c $< -o $@
	@echo "Compile the App  <=  $<"

$(App_Name): App/Enclave_u.o $(App_Cpp_Objects)
	@$(CXX) $^ -o $@ $(App_Link_Flags)
	@echo "LINKING ALL THE BINARIES =>  $@"

####################### Enclave build Steps ###############################

./Enclave/Enclave_t.c: $(SGX_EDGER8R) ./Enclave/Enclave.edl
	@cd Enclave && $(SGX_EDGER8R) --trusted ../Enclave/Enclave.edl --search-path ../Enclave --search-path $(SGX_SDK)/include
	@echo "GENERATING EDGE FUNCTIONS  =>  $@"

./bin/Enclave_t.o: ./Enclave/Enclave_t.c
	@$(CC) $(Enclave_C_Flags) -c $< -o $@
	@echo "BUILD EDGE FUNCTIONS   <=  $<"

./bin/Enclave.o: ./Enclave/Enclave.cpp
	@$(CXX) $(Enclave_Cpp_Flags) -c $< -o $@
	@echo "BUILD C++ SOURCE  <=  $<"

$(Enclave_Name): ./bin/Enclave_t.o ./bin/Enclave.o
	@$(CXX) $^ -o $@ $(Enclave_Link_Flags)
	@echo "LINK =>  $@"

$(KEY_STORAGE_PATH):
	@mkdir -p $(KEY_STORAGE_PATH)
	@echo "Generating Key storage Directory => $(KEY_STORAGE_PATH)"

$(KEY_PRIVATE_FILE): $(KEY_STORAGE_PATH)
	@openssl genrsa -out $(KEY_PRIVATE_FILE) -3 3072
	@echo "Generating the private key => $(KEY_PRIVATE_FILE)"

$(KEY_PUBLIC_FILE): $(KEY_PRIVATE_FILE)
	@openssl rsa -in $(KEY_PRIVATE_FILE) -pubout -out $(KEY_PUBLIC_FILE)
	@echo "Generating the public key => $(KEY_PUBLIC_FILE)"

$(Signed_Enclave_Name): $(KEY_PUBLIC_FILE) $(Enclave_Name)
	@$(SGX_ENCLAVE_SIGNER) sign -key $(KEY_PRIVATE_FILE) -enclave $(Enclave_Name) -out $@ -config $(Enclave_Config_File)
	@echo "SIGNING THE ENCLAVE =>  $@"

.PHONY: clean

clean:
	@rm -rf ./Enclave/*.o ./Enclave/*_t.c /Enclave/*_t.h ./bin/*.o ./App/*.o ./App/*/*.o ./App/Enclave_u.c ./App/Enclave_u.o
