#!/usr/bin/env python3
"""
    The management of .symbols should be done manually, however, much of it is
    repetitive, so, leaving it to this script to do the work.

    In case .symbols are created by 'dpkg-gensymbols' during the build-process,
    which leads to a diff on .symbols, then we have an error and can go in and
    fix .symbols.

    This will happen if something is added that does not follow the conventions
    below.

    This modifies the .symbols file generated by "dpkg-gensymbols" by:

    * Mark symbols starting with "g_" as optional

      - these are data / structures that behave/exists conditionally based on
        platform and build-options

    * Mark symbols starting with "xnvme_be" as optional

      - these are backend specific helper-functions that behave conditionally
        based on platform and build-options

    * Remove the trailing debian-package-revision from the symbol-version
      - FROM: '0.7.3-1' TO '0.7.3'
      - dpkg-gensymbols adds with revision and it is the package-maintainers
        job to set it to the correct upstream version. The correct upstream is
        simply the version, thus stripping the revision.

    * Remove symbols that does not start with "xnvme_"
      - These are unintentional scope-leaks, not wanted / managed by the xNVMe
        package, thus removed
"""
import argparse
import logging as log
import re
from pathlib import Path

REGEX_REVISION = r"(?P<without_rev> (?P<gdata>g_)?xnvme(?P<be>_be)?.* (?P<ver>\d\.\d\.\d))(?P<rev>-\d)?"


def parse_args():
    """Parse command-line arguments"""

    parser = argparse.ArgumentParser(description="Clean out symboltable")

    parser.add_argument("path", type=Path, help="Path to symboltable")

    return parser.parse_args()


def main(args):
    log.basicConfig(level=log.INFO)

    with args.path.open("r") as content:  # Read the current symboltable
        lines = content.readlines()

    with args.path.open("w") as content:  # Inject and manipulate it
        for ln, line in enumerate((line.rstrip() for line in lines)):
            if not ln:
                content.write("# Build-Depends-Package: libxnvme-dev\n")

            match = re.match(REGEX_REVISION, line)
            if match:
                mod = match.group("without_rev")
                rev = match.group("rev")

                if rev:
                    log.info(f"Removed revision({rev}); line {ln}: '{line}'")

                if match.group("gdata") or match.group("be"):
                    mod = f"{mod} optional"
                    log.info(f"Marked optional; line {ln}: '{line}'")

                content.write(mod)
            elif line.startswith(" ") and (not line.startswith(" xnvme")):
                log.info(f"Removed; line {ln}: '{line}'")
                continue
            else:
                content.write(line)

            content.write("\n")


if __name__ == "__main__":
    main(parse_args())