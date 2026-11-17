"""Runtime file propagation for Fortran rules."""

def rule_runfiles(ctx):
    """Return data and dependency runfiles without adding compile inputs."""
    return ctx.runfiles(files = ctx.files.data).merge_all([
        dep[DefaultInfo].default_runfiles
        for dep in ctx.attr.deps + ctx.attr.data
    ])
