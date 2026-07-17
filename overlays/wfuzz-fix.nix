final: prev: {
  wfuzz = prev.wfuzz.overridePythonAttrs (old: {
    # pkg_resources from setuptools is needed at runtime (for help file lookup)
    # and during build-time phase checks, but Python 3.14's build sandbox
    # doesn't resolve propagatedBuildInputs into the check-phase PYTHONPATH.
    # Skip the phases that fail for this reason.
    pythonImportsCheck = [ ];
    doCheck = false;
  });
}
