# Adapted from the rules_ml_toolchain source overlays at e5c395b948974af5fc7498fe93e7a6807ba4f7d5.
# https://github.com/google-ml-infra/rules_ml_toolchain/tree/e5c395b948974af5fc7498fe93e7a6807ba4f7d5/third_party/rules_fortran/examples

"""Reference BLAS libraries by precision."""

load("@rules_fortran//fortran:fortran_library.bzl", "fortran_library")
load("@rules_fortran//fortran:fortran_test.bzl", "fortran_test")

# Auxiliary BLAS routines (required by all precisions)
ALLBLAS_SRCS = [
    "SRC/lsame.f",
    "SRC/xerbla.f",
    "SRC/xerbla_array.f",
]

# Single precision BLAS Level 1 routines
SBLAS1_SRCS = [
    "SRC/isamax.f",
    "SRC/sasum.f",
    "SRC/saxpy.f",
    "SRC/scopy.f",
    "SRC/sdot.f",
    "SRC/snrm2.f90",
    "SRC/srot.f",
    "SRC/srotg.f90",
    "SRC/sscal.f",
    "SRC/sswap.f",
    "SRC/sdsdot.f",
    "SRC/srotmg.f",
    "SRC/srotm.f",
]

# Single precision BLAS Level 2 routines
SBLAS2_SRCS = [
    "SRC/sgemv.f",
    "SRC/sgbmv.f",
    "SRC/ssymv.f",
    "SRC/ssbmv.f",
    "SRC/sspmv.f",
    "SRC/strmv.f",
    "SRC/stbmv.f",
    "SRC/stpmv.f",
    "SRC/strsv.f",
    "SRC/stbsv.f",
    "SRC/stpsv.f",
    "SRC/sger.f",
    "SRC/ssyr.f",
    "SRC/sspr.f",
    "SRC/ssyr2.f",
    "SRC/sspr2.f",
]

# Single precision BLAS Level 3 routines
SBLAS3_SRCS = [
    "SRC/sgemm.f",
    "SRC/ssymm.f",
    "SRC/ssyrk.f",
    "SRC/ssyr2k.f",
    "SRC/strmm.f",
    "SRC/strsm.f",
    "SRC/sgemmtr.f",
]

# Double precision BLAS Level 1 routines
DBLAS1_SRCS = [
    "SRC/idamax.f",
    "SRC/dasum.f",
    "SRC/daxpy.f",
    "SRC/dcopy.f",
    "SRC/ddot.f",
    "SRC/dnrm2.f90",
    "SRC/drot.f",
    "SRC/drotg.f90",
    "SRC/dscal.f",
    "SRC/dsdot.f",
    "SRC/dswap.f",
    "SRC/drotmg.f",
    "SRC/drotm.f",
]

# Double precision BLAS Level 2 routines
DBLAS2_SRCS = [
    "SRC/dgemv.f",
    "SRC/dgbmv.f",
    "SRC/dsymv.f",
    "SRC/dsbmv.f",
    "SRC/dspmv.f",
    "SRC/dtrmv.f",
    "SRC/dtbmv.f",
    "SRC/dtpmv.f",
    "SRC/dtrsv.f",
    "SRC/dtbsv.f",
    "SRC/dtpsv.f",
    "SRC/dger.f",
    "SRC/dsyr.f",
    "SRC/dspr.f",
    "SRC/dsyr2.f",
    "SRC/dspr2.f",
]

# Double precision BLAS Level 3 routines
DBLAS3_SRCS = [
    "SRC/dgemm.f",
    "SRC/dsymm.f",
    "SRC/dsyrk.f",
    "SRC/dsyr2k.f",
    "SRC/dtrmm.f",
    "SRC/dtrsm.f",
    "SRC/dgemmtr.f",
]

# Complex precision BLAS Level 1 routines
CBLAS1_SRCS = [
    "SRC/scabs1.f",
    "SRC/scasum.f",
    "SRC/scnrm2.f90",
    "SRC/icamax.f",
    "SRC/caxpy.f",
    "SRC/ccopy.f",
    "SRC/cdotc.f",
    "SRC/cdotu.f",
    "SRC/csscal.f",
    "SRC/crotg.f90",
    "SRC/cscal.f",
    "SRC/cswap.f",
    "SRC/csrot.f",
]

# Complex precision BLAS Level 2 routines
CBLAS2_SRCS = [
    "SRC/cgemv.f",
    "SRC/cgbmv.f",
    "SRC/chemv.f",
    "SRC/chbmv.f",
    "SRC/chpmv.f",
    "SRC/ctrmv.f",
    "SRC/ctbmv.f",
    "SRC/ctpmv.f",
    "SRC/ctrsv.f",
    "SRC/ctbsv.f",
    "SRC/ctpsv.f",
    "SRC/cgerc.f",
    "SRC/cgeru.f",
    "SRC/cher.f",
    "SRC/chpr.f",
    "SRC/cher2.f",
    "SRC/chpr2.f",
]

# Complex precision BLAS Level 3 routines
CBLAS3_SRCS = [
    "SRC/cgemm.f",
    "SRC/csymm.f",
    "SRC/csyrk.f",
    "SRC/csyr2k.f",
    "SRC/ctrmm.f",
    "SRC/ctrsm.f",
    "SRC/chemm.f",
    "SRC/cherk.f",
    "SRC/cher2k.f",
    "SRC/cgemmtr.f",
]

# Double complex precision BLAS Level 1 routines
ZBLAS1_SRCS = [
    "SRC/dcabs1.f",
    "SRC/dzasum.f",
    "SRC/dznrm2.f90",
    "SRC/izamax.f",
    "SRC/zaxpy.f",
    "SRC/zcopy.f",
    "SRC/zdotc.f",
    "SRC/zdotu.f",
    "SRC/zdscal.f",
    "SRC/zrotg.f90",
    "SRC/zscal.f",
    "SRC/zswap.f",
    "SRC/zdrot.f",
]

# Double complex precision BLAS Level 2 routines
ZBLAS2_SRCS = [
    "SRC/zgemv.f",
    "SRC/zgbmv.f",
    "SRC/zhemv.f",
    "SRC/zhbmv.f",
    "SRC/zhpmv.f",
    "SRC/ztrmv.f",
    "SRC/ztbmv.f",
    "SRC/ztpmv.f",
    "SRC/ztrsv.f",
    "SRC/ztbsv.f",
    "SRC/ztpsv.f",
    "SRC/zgerc.f",
    "SRC/zgeru.f",
    "SRC/zher.f",
    "SRC/zhpr.f",
    "SRC/zher2.f",
    "SRC/zhpr2.f",
]

# Double complex precision BLAS Level 3 routines
ZBLAS3_SRCS = [
    "SRC/zgemm.f",
    "SRC/zsymm.f",
    "SRC/zsyrk.f",
    "SRC/zsyr2k.f",
    "SRC/ztrmm.f",
    "SRC/ztrsm.f",
    "SRC/zhemm.f",
    "SRC/zherk.f",
    "SRC/zher2k.f",
    "SRC/zgemmtr.f",
]

# Build reference BLAS with optimization and suppress upstream warnings.
BLAS_COPTS = [
    "-O2",
    "-w",
]

# Auxiliary library with error handlers (shared by all precisions)
fortran_library(
    name = "aux",
    srcs = ALLBLAS_SRCS,
    copts = BLAS_COPTS,
)

# Complete BLAS libraries with error handlers
# For normal use - includes default xerbla implementation
fortran_library(
    name = "single",
    srcs = SBLAS1_SRCS + SBLAS2_SRCS + SBLAS3_SRCS,
    copts = BLAS_COPTS,
    visibility = ["//visibility:public"],
    deps = [":aux"],
)

fortran_library(
    name = "double",
    srcs = DBLAS1_SRCS + DBLAS2_SRCS + DBLAS3_SRCS,
    copts = BLAS_COPTS,
    visibility = ["//visibility:public"],
    deps = [":aux"],
)

fortran_library(
    name = "complex",
    srcs = CBLAS1_SRCS + CBLAS2_SRCS + CBLAS3_SRCS,
    copts = BLAS_COPTS,
    visibility = ["//visibility:public"],
    deps = [
        ":aux",
        ":single",
    ],
)

fortran_library(
    name = "complex16",
    srcs = ZBLAS1_SRCS + ZBLAS2_SRCS + ZBLAS3_SRCS,
    copts = BLAS_COPTS,
    visibility = ["//visibility:public"],
    deps = [
        ":aux",
        ":double",
    ],
)

# Complete BLAS library with all precisions
fortran_library(
    name = "blas",
    visibility = ["//visibility:public"],
    deps = [
        ":complex",
        ":complex16",
        ":double",
        ":single",
    ],
)

fortran_test(
    name = "dblat1",
    size = "small",
    srcs = ["TESTING/dblat1.f"],
    copts = BLAS_COPTS,
    deps = ["double"],
)
