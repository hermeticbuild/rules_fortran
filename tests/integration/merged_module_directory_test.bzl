"""Regression test for module search path growth in multi-source libraries."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_fortran//fortran/common:fortran_info.bzl", "FortranInfo")

def _merged_module_directory_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    own_dirs = [output for output in target.files.to_list() if output.is_directory]
    module_dirs = target[FortranInfo].module_dirs.to_list()
    asserts.equals(env, 1, len(own_dirs), "The library exposes one merged directory for its two sources")
    asserts.equals(env, 2, len(module_dirs), "The consumer receives the merged directory and the base dependency's directory")
    asserts.equals(env, own_dirs, module_dirs[:1], "The merged directory precedes the dependency's directory")
    return analysistest.end(env)

merged_module_directory_test = analysistest.make(_merged_module_directory_test_impl)
