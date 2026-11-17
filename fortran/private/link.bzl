"""Native archives and final links through the selected C/C++ toolchain."""

load("@rules_cc//cc:find_cc_toolchain.bzl", find_rules_cc_toolchain = "find_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

def find_cc_toolchain(ctx):
    """Return the required CC toolchain and its feature configuration."""
    cc_toolchain = find_rules_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    return cc_toolchain, feature_configuration

def library_link(ctx, compilation_outputs, toolchain):
    """Build an archive or merge the linking closure of an empty library.

    Args:
        ctx: Rule analysis context.
        compilation_outputs: PIC object compilation outputs.
        toolchain: Resolved FortranToolchainInfo.

    Returns:
        A pair of CcInfo and default output files.
    """
    dep_cc_infos = [dep[CcInfo] for dep in ctx.attr.deps]
    if ctx.files.srcs:
        cc_toolchain, feature_configuration = find_cc_toolchain(ctx)
        linking_context, linking_outputs = cc_common.create_linking_context_from_compilation_outputs(
            actions = ctx.actions,
            name = ctx.label.name,
            feature_configuration = feature_configuration,
            cc_toolchain = cc_toolchain,
            compilation_outputs = compilation_outputs,
            user_link_flags = ctx.attr.linkopts,
            additional_inputs = ctx.files.additional_linker_inputs,
            alwayslink = ctx.attr.alwayslink,
            disallow_dynamic_library = True,
        )
        library = linking_outputs.library_to_link
        files = [file for file in [library.static_library, library.pic_static_library] if file != None]
        merged = cc_common.merge_cc_infos(cc_infos = [CcInfo(linking_context = linking_context)] + dep_cc_infos + [toolchain.runtime])
        return merged, files

    if ctx.attr.alwayslink:
        fail("alwayslink requires at least one Fortran source")
    own_input = cc_common.create_linker_input(
        owner = ctx.label,
        user_link_flags = ctx.attr.linkopts,
        additional_inputs = depset(ctx.files.additional_linker_inputs),
    )
    own_context = cc_common.create_linking_context(linker_inputs = depset([own_input]))
    merged = cc_common.merge_cc_infos(cc_infos = [CcInfo(linking_context = own_context)] + dep_cc_infos)
    return merged, []

def executable_link(ctx, compilation_outputs, toolchain):
    """Link Fortran objects and CcInfo dependencies with the CC toolchain.

    Args:
        ctx: Rule analysis context.
        compilation_outputs: PIC object compilation outputs.
        toolchain: Resolved FortranToolchainInfo.

    Returns:
        The declared executable File.
    """
    cc_toolchain, feature_configuration = find_cc_toolchain(ctx)
    output = ctx.actions.declare_file(ctx.label.name)
    cc_common.link(
        actions = ctx.actions,
        name = ctx.label.name,
        main_output = output,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        output_type = "executable",
        link_deps_statically = True,
        compilation_outputs = compilation_outputs,
        linking_contexts = [dep[CcInfo].linking_context for dep in ctx.attr.deps] + [toolchain.runtime.linking_context],
        user_link_flags = ctx.attr.linkopts,
        additional_inputs = ctx.files.additional_linker_inputs,
    )
    return output
