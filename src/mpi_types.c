#include "mpi_internal.h"
#include <complex.h>
#include <float.h>
#include <limits.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static int logical_bytes;
static unsigned char logical_true[16], logical_false[16];
static int owned_ops;
static int cleanup_keyval = MPI_KEYVAL_INVALID;
static int cleanup_attached;

#if defined(MPI_ABI)
static int register_fortran(int bytes)
{
    const char *keys[] = {"mpi_logical_size", "mpi_integer_size", "mpi_real_size",
                         "mpi_double_precision_size", "mpi_integer8_supported",
                         "mpi_real4_supported", "mpi_real8_supported", "mpi_double_complex_supported"};
    char logical_size[16];
    snprintf(logical_size, sizeof(logical_size), "%d", bytes);
    const char *values[] = {logical_size, "4", "4", "8", "true", "true", "true", "true"};
    MPI_Info info = MPI_INFO_NULL;
    int rc = MPI_Abi_get_fortran_info(&info);
    if (rc != MPI_SUCCESS) return rc;
    int is_new = info == MPI_INFO_NULL;
    if (is_new) {
        rc = MPI_Info_create(&info);
        if (rc != MPI_SUCCESS) return rc;
        /* C-only implementations may also need CHARACTER's compiler size.
         * Do not require this additional key in an existing registration. */
        rc = MPI_Info_set(info, "mpi_character_size", "1");
    }
    for (size_t i = 0; i < sizeof(keys)/sizeof(keys[0]) && rc == MPI_SUCCESS; ++i) {
        if (is_new) {
            rc = MPI_Info_set(info, keys[i], values[i]);
        } else {
            char value[MPI_MAX_INFO_VAL + 1];
            int present = 0;
            rc = MPI_Info_get(info, keys[i], MPI_MAX_INFO_VAL, value, &present);
            if (rc == MPI_SUCCESS && (!present || strcmp(value, values[i]) != 0)) {
                fprintf(stderr, "fortran_mpi: registered %s is %s, compiler requires %s\n",
                        keys[i], present ? value : "absent", values[i]);
                rc = MPI_ERR_ABI;
            }
        }
    }
    if (rc == MPI_SUCCESS && is_new) rc = MPI_Abi_set_fortran_info(info);
    int free_rc = MPI_Info_free(&info);
    if (rc != MPI_SUCCESS) return rc;
    if (free_rc != MPI_SUCCESS) return free_rc;

    union { max_align_t alignment; unsigned char bytes[16]; } truth = {0}, falsity = {0};
    int is_set = 0;
    rc = MPI_Abi_get_fortran_booleans(bytes, truth.bytes, falsity.bytes, &is_set);
    if (rc != MPI_SUCCESS) return rc;
    if (is_set) {
        if (memcmp(truth.bytes, logical_true, bytes) != 0 ||
                memcmp(falsity.bytes, logical_false, bytes) != 0) {
            fprintf(stderr, "fortran_mpi: registered logical literals differ from this compiler\n");
            return MPI_ERR_ABI;
        }
    } else {
        memcpy(truth.bytes, logical_true, bytes);
        memcpy(falsity.bytes, logical_false, bytes);
        rc = MPI_Abi_set_fortran_booleans(bytes, truth.bytes, falsity.bytes);
    }
    return rc;
}
#else
static void logical_reduce(void *input, void *output, int count, int op)
{
    unsigned char *in = input, *inout = output;
    for (int i = 0; i < count; ++i) {
        int left = memcmp(in, logical_true, logical_bytes) == 0;
        int right = memcmp(inout, logical_true, logical_bytes) == 0;
        int result = op == 0 ? left && right : op == 1 ? left || right : left != right;
        memcpy(inout, result ? logical_true : logical_false, logical_bytes);
        in += logical_bytes;
        inout += logical_bytes;
    }
}

static void logical_and(void *in, void *out, int *count, MPI_Datatype *type)
{
    (void)type;
    logical_reduce(in, out, *count, 0);
}

static void logical_or(void *in, void *out, int *count, MPI_Datatype *type)
{
    (void)type;
    logical_reduce(in, out, *count, 1);
}

static void logical_xor(void *in, void *out, int *count, MPI_Datatype *type)
{
    (void)type;
    logical_reduce(in, out, *count, 2);
}
#endif

static int release_types(void)
{
    while (owned_ops) {
        int rc = MPI_Op_free(&c_logical_op_table[owned_ops - 1]);
        if (rc != MPI_SUCCESS) return rc;
        --owned_ops;
    }
    if (cleanup_keyval != MPI_KEYVAL_INVALID) return MPI_Comm_free_keyval(&cleanup_keyval);
    return MPI_SUCCESS;
}

int fortran_mpi_types_finalize(void)
{
    /* Initialization rollback removes the attribute through its callback. */
    if (cleanup_attached) return MPI_Comm_delete_attr(MPI_COMM_SELF, cleanup_keyval);
    return release_types();
}

#if !defined(MPI_ABI)
static int delete_types(MPI_Comm comm, int keyval, void *attribute, void *extra)
{
    (void)comm;
    (void)keyval;
    (void)attribute;
    (void)extra;
    int rc = release_types();
    if (rc == MPI_SUCCESS) cleanup_attached = 0;
    return rc;
}
#endif

int fortran_mpi_types_init(const int *model, int bytes, const void *truth, const void *falsity)
{
    /* ISO_C_BINDING kind equality is checked in Fortran. Verify the numeric
     * models as well: size equality alone does not establish a datatype. */
    const int expected[] = {
        sizeof(int), 2, CHAR_BIT * sizeof(int) - 1, sizeof(int64_t), 63,
        sizeof(float), FLT_RADIX, FLT_MANT_DIG, FLT_MIN_EXP, FLT_MAX_EXP,
        sizeof(double), FLT_RADIX, DBL_MANT_DIG, DBL_MIN_EXP, DBL_MAX_EXP,
        sizeof(double complex), sizeof(char)
    };
    const char *properties[] = {
        "integer size", "integer radix", "integer digits", "integer(8) size", "integer(8) digits",
        "real size", "real radix", "real digits", "real minimum exponent", "real maximum exponent",
        "double size", "double radix", "double digits", "double minimum exponent", "double maximum exponent",
        "double complex size", "character size"
    };
    for (size_t i = 0; i < sizeof(expected)/sizeof(expected[0]); ++i) {
        if (model[i] != expected[i]) {
            fprintf(stderr, "fortran_mpi: compiler %s is %d, C requires %d\n",
                    properties[i], model[i], expected[i]);
            return MPI_ERR_TYPE;
        }
    }
    if (sizeof(float) != 4 || sizeof(double) != 8 || sizeof(int64_t) != 8 ||
            (bytes != 1 && bytes != 2 && bytes != 4 && bytes != 8 && bytes != 16) ||
            memcmp(truth, falsity, bytes) == 0) return MPI_ERR_TYPE;
    logical_bytes = bytes;
    memcpy(logical_true, truth, bytes);
    memcpy(logical_false, falsity, bytes);

#if defined(MPI_ABI)
    int rc = register_fortran(bytes);
    if (rc != MPI_SUCCESS) return rc;
#else
    switch (bytes) {
    case 1: c_datatype_table[4] = MPI_INT8_T; break;
    case 2: c_datatype_table[4] = MPI_INT16_T; break;
    case 4: c_datatype_table[4] = MPI_INT32_T; break;
    case 8: c_datatype_table[4] = MPI_INT64_T; break;
    default: return MPI_ERR_TYPE;
    }
    MPI_User_function *callbacks[] = {logical_and, logical_or, logical_xor};
    for (int i = 0; i < 3; ++i) {
        int rc = MPI_Op_create(callbacks[i], 1, &c_logical_op_table[i]);
        if (rc != MPI_SUCCESS) {
            fortran_mpi_types_finalize();
            return rc;
        }
        ++owned_ops;
    }
#endif
    const int sizes[] = {0, sizeof(int), sizeof(float), sizeof(double), bytes, sizeof(int),
                        sizeof(float), sizeof(double), sizeof(double complex), sizeof(char),
                        sizeof(int32_t), sizeof(int64_t), 4, 8, 8};
    for (int i = 1; i < 15; ++i) {
        int size;
        MPI_Aint lower, extent;
        int rc = MPI_Type_size(c_datatype_table[i], &size);
        if (rc == MPI_SUCCESS) rc = MPI_Type_get_extent(c_datatype_table[i], &lower, &extent);
        if (rc == MPI_SUCCESS && (size != sizes[i] || lower != 0 || extent != sizes[i])) rc = MPI_ERR_TYPE;
        if (rc != MPI_SUCCESS) {
            fortran_mpi_types_finalize();
            return rc;
        }
    }
#if !defined(MPI_ABI)
    /* SELF attributes are deleted in reverse set order during MPI_Finalize.
     * Register before Init/Init_thread returns, so application callbacks can
     * still use these operations. Keep the key live for initialization rollback. */
    int keyval;
    int rc = MPI_Comm_create_keyval(MPI_COMM_NULL_COPY_FN, delete_types, &keyval, NULL);
    if (rc == MPI_SUCCESS) {
        cleanup_keyval = keyval;
        rc = MPI_Comm_set_attr(MPI_COMM_SELF, cleanup_keyval, &owned_ops);
        if (rc == MPI_SUCCESS) cleanup_attached = 1;
    }
    if (rc != MPI_SUCCESS) {
        fortran_mpi_types_finalize();
        return rc;
    }
#endif
    return MPI_SUCCESS;
}
