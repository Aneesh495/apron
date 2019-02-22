cmake_minimum_required(VERSION 3.16)
project(apron VERSION 1.0.0 LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Optimization and warning flags
if(MSVC)
    add_compile_options(/W4 /O2)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -O3 -g -D_GNU_SOURCE)
endif()

include_directories(include)

# Fastpath core library (C11 acceleration for geodesy, spatial R-tree, Asterix decoding)
set(FASTPATH_SRCS
    src/fastpath/geo.c
    src/fastpath/rtree.c
    src/fastpath/asterix.c
)

# Oz Virtual Machine and Kernel Execution Engine
set(VM_SRCS
    src/vm/oz_vm.c
    src/vm/oz_store.c
    src/vm/oz_unify.c
    src/vm/oz_scheduler.c
    src/vm/oz_space.c
    src/vm/oz_builtins.c
    src/vm/oz_lexer.c
    src/vm/oz_parser.c
    src/vm/oz_compiler.c
    src/vm/oz_disasm.c
)

# Fastpath static library
add_library(fastpath STATIC ${FASTPATH_SRCS})
if(NOT MSVC)
    target_link_libraries(fastpath PRIVATE m)
endif()

# Oz VM static library
add_library(ozvm_lib STATIC ${VM_SRCS})
target_link_libraries(ozvm_lib PUBLIC fastpath)
if(NOT MSVC)
    target_link_libraries(ozvm_lib PUBLIC m)
endif()

# Standalone Oz Virtual Machine executable
add_executable(ozvm src/vm/oz_main.c)
target_link_libraries(ozvm PRIVATE ozvm_lib)

# Apron airport surface management executive CLI
add_executable(apron src/main.c)
target_link_libraries(apron PRIVATE ozvm_lib)

# Enable CTest
enable_testing()

# Unit tests
add_executable(test_oz_store test/c/test_oz_store.c)
target_link_libraries(test_oz_store PRIVATE ozvm_lib)
add_test(NAME OzStoreTest COMMAND test_oz_store)

add_executable(test_oz_unify test/c/test_oz_unify.c)
target_link_libraries(test_oz_unify PRIVATE ozvm_lib)
add_test(NAME OzUnifyTest COMMAND test_oz_unify)

add_executable(test_oz_space test/c/test_oz_space.c)
target_link_libraries(test_oz_space PRIVATE ozvm_lib)
add_test(NAME OzSpaceTest COMMAND test_oz_space)

add_executable(test_oz_vm test/c/test_oz_vm.c)
target_link_libraries(test_oz_vm PRIVATE ozvm_lib)
add_test(NAME OzVMTest COMMAND test_oz_vm)

add_executable(test_fastpath_geo test/c/test_fastpath_geo.c)
target_link_libraries(test_fastpath_geo PRIVATE fastpath)
add_test(NAME FastpathGeoTest COMMAND test_fastpath_geo)

add_executable(test_fastpath_rtree test/c/test_fastpath_rtree.c)
target_link_libraries(test_fastpath_rtree PRIVATE fastpath)
add_test(NAME FastpathRTreeTest COMMAND test_fastpath_rtree)
