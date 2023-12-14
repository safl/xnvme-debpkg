xNVMe packaged for Debian
=========================

These are notes for updating the **xNVMe** Debian package using the
Makefile-helper, config-files, and scripts provided here as a supplement to the
``DEBIAN`` source-package content. The content include:

* Makefile with pseudo-targets for conveniently manually updating / testing
  the package
* Makefile for inclusion in the **xNVMe** CI, to verify that the
  package build process is not regressing during **xNVMe** development.
* ``dput.cf``: use by ``make upload`` to send the package to
  ``mentors.debian.net``
* ``make docker``: Drops into a docker-container with all the tools needed.
* ``symbols.py``: update the auto-generated ``.symbols`` file, marking ``g_*``
  and ``xnvme_be*`` symbols are optional

Once, I get an account on salsa, then this repository will be archived on github
and moved to salsa.

Prerequisites
-------------

* An account on https://mentors.debian.net/
* A GPG key, for **signing** the package
* The **xNVMe** source cloned, or archive extracted at $HOME/git/xnvme

 - The source is utilized to create an upstream source-archive, if you already
   have an archive, then place it in the ``input/`` dir
 - This can be overridden by setting env. var. ``REPOS=/path/to/src```

Usage
-----

With those things in place, then the ``Makefile`` provides the commands needed.
The usage-flow is::

  # Build and generate symbols
  make default symbols

  # Build, without generating symbols, since we now have the latest
  make

  # With no build or linting errors, proceed with
  make sign
  make upload

After a while it will appear on mentors.debian.net and the package-maintainer
should receive an email with the status of the package. This should be
**"ACCEPTED"**, unless something broke.

Branches
--------

The **xNVMe** CI consumes this repository when verifying pull-requests, that
is, to avoid packaging regressions. Specifically, when a **PR** is setup on
**xNVMe**, then the name of the target-branch is used as the name of the branch
of **this** repository to checkout.

Example: a **PR** targeting the ``next`` branch of the **xNVMe** repositry, then
the ``next`` branch of **this** repository is checked out.