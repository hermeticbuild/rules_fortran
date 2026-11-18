# Adapted from the rules_ml_toolchain source overlays at e5c395b948974af5fc7498fe93e7a6807ba4f7d5.
# https://github.com/google-ml-infra/rules_ml_toolchain/tree/e5c395b948974af5fc7498fe93e7a6807ba4f7d5/third_party/rules_fortran/examples

"""C interfaces to the reference LAPACK libraries by precision."""

load("@bazel_skylib//rules:expand_template.bzl", "expand_template")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

# ADD_ selects lower-case Fortran symbols with a trailing underscore.
expand_template(
    name = "generate_mangling_h",
    out = "include/lapacke_mangling.h",
    substitutions = {},
    template = "include/lapacke_mangling_with_flags.h.in",
)

# Header files
LAPACKE_HEADERS = [
    "include/lapacke.h",
    "include/lapacke_config.h",
    "include/lapacke_utils.h",
    "include/lapack.h",
]

# LAPACKE ships wrappers for deprecated, XBLAS, and test-matrix routines
# that are outside the default reference LAPACK build.
OPTIONAL_ROUTINES = [
    "gbrfsx",
    "gbsvxx",
    "geqpf",
    "gerfsx",
    "gesvxx",
    "ggsvd",
    "ggsvp",
    "herfsx",
    "hesvxx",
    "lagge",
    "laghe",
    "lagsy",
    "latms",
    "porfsx",
    "posvxx",
    "syrfsx",
    "sysvxx",
]

cc_library(
    name = "common",
    srcs = [
        "src/lapacke_ilaver.c",
        "src/lapacke_nancheck.c",
        "utils/lapacke_lsame.c",
        "utils/lapacke_make_complex_double.c",
        "utils/lapacke_make_complex_float.c",
        "utils/lapacke_xerbla.c",
    ],
    hdrs = LAPACKE_HEADERS + ["generate_mangling_h"],
    defines = ["ADD_"],
    includes = ["include"],
)

[
    cc_library(
        name = precision,
        srcs = glob(
            [
                "src/lapacke_" + prefix + "*.c",
                "utils/lapacke_" + prefix + "*.c",
            ],
            exclude = [
                "src/lapacke_" + prefix + routine + suffix + ".c"
                for routine in OPTIONAL_ROUTINES
                for suffix in [
                    "",
                    "_work",
                ]
            ],
        ),
        deps = [
            "common",
            "@lapack//:" + precision,
        ],
    )
    for precision, prefix in {
        "single": "s",
        "double": "d",
        "complex": "c",
        "complex16": "z",
    }.items()
]

cc_library(
    name = "lapacke",
    deps = [
        "complex",
        "complex16",
        "double",
        "single",
    ],
)
