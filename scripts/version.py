#!/usr/bin/env python3
"""Reads or sets the app version in project.yml (the Xcode project is
generated from it by XcodeGen).

  version.py get             prints "<marketing> <build>", e.g. "1.0 1"
  version.py set 1.1 5       writes both
"""
import pathlib
import re
import sys

PROJECT = pathlib.Path(__file__).resolve().parent.parent / "project.yml"


def main():
    text = PROJECT.read_text()
    if sys.argv[1:2] == ["get"]:
        version = re.search(r'MARKETING_VERSION: "([^"]+)"', text).group(1)
        build = re.search(r'CURRENT_PROJECT_VERSION: "([^"]+)"', text).group(1)
        print(f"{version} {build}")
    elif sys.argv[1:2] == ["set"] and len(sys.argv) == 4:
        version, build = sys.argv[2], sys.argv[3]
        if not re.fullmatch(r"\d+(\.\d+)*", version) or not build.isdigit():
            sys.exit("usage: version.py set <marketing like 1.1> <build integer>")
        text = re.sub(r'MARKETING_VERSION: "[^"]+"', f'MARKETING_VERSION: "{version}"', text)
        text = re.sub(r'CURRENT_PROJECT_VERSION: "[^"]+"', f'CURRENT_PROJECT_VERSION: "{build}"', text)
        PROJECT.write_text(text)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
