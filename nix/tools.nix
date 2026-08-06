# Explicit registry of non-nixpkgs tool packages.
#
# Keep each tool's manifest, lockfile, README, and package.nix together under
# tools/<language>/<tool>. Add an entry here only after its Nix package has been
# evaluated and a cache/build decision has been made.
_:

[
  # Example:
  # (import ../tools/python/example-tool/package.nix { inherit pkgs; })
]
