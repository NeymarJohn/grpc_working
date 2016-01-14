# Copyright 2015-2016, Google Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""A setup module for the GRPC Python package."""

import os
import os.path
import shutil
import sys

from distutils import core as _core
from distutils import extension as _extension
import setuptools
from setuptools.command import egg_info

# Redirect the manifest template from MANIFEST.in to PYTHON-MANIFEST.in.
egg_info.manifest_maker.template = 'PYTHON-MANIFEST.in'

PYTHON_STEM = './src/python/grpcio/'
CORE_INCLUDE = ('./include', './',)
BORINGSSL_INCLUDE = ('./third_party/boringssl/include',)

# Ensure we're in the proper directory whether or not we're being used by pip.
os.chdir(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PYTHON_STEM)

# Break import-style to ensure we can actually find our in-repo dependencies.
import commands
import grpc_core_dependencies

# Environment variable to determine whether or not the Cython extension should
# *use* Cython or use the generated C files. Note that this requires the C files
# to have been generated by building first *with* Cython support.
BUILD_WITH_CYTHON = os.environ.get('GRPC_PYTHON_BUILD_WITH_CYTHON', False)

# Environment variable to determine whether or not to enable coverage analysis
# in Cython modules.
ENABLE_CYTHON_TRACING = os.environ.get(
    'GRPC_PYTHON_ENABLE_CYTHON_TRACING', False)

# Environment variable to determine whether or not to include the test files in
# the installation.
INSTALL_TESTS = os.environ.get('GRPC_PYTHON_INSTALL_TESTS', False)

CYTHON_EXTENSION_PACKAGE_NAMES = ()

CYTHON_EXTENSION_MODULE_NAMES = ('grpc._cython.cygrpc',)

EXTENSION_INCLUDE_DIRECTORIES = (
    (PYTHON_STEM,) + CORE_INCLUDE + BORINGSSL_INCLUDE)

EXTENSION_LIBRARIES = ()
if not "darwin" in sys.platform:
    EXTENSION_LIBRARIES += ('rt',)

EXTRA_COMPILE_ARGS = ()
if not "win" in sys.platform:
  EXTRA_COMPILE_ARGS = ('-pthread',)

DEFINE_MACROS = (('OPENSSL_NO_ASM', 1),)

def cython_extensions(package_names, module_names, include_dirs, libraries,
                      define_macros, extra_compile_args,
                      build_with_cython=False):
  if ENABLE_CYTHON_TRACING:
    define_macros = define_macros + [('CYTHON_TRACE_NOGIL', 1)]
  file_extension = 'pyx' if build_with_cython else 'c'
  module_files = [os.path.join(PYTHON_STEM,
                               name.replace('.', '/') + '.' + file_extension)
                  for name in module_names]
  extensions = [
      _extension.Extension(
          name=module_name,
          sources=[module_file] + grpc_core_dependencies.CORE_SOURCE_FILES,
          include_dirs=include_dirs, libraries=libraries,
          extra_compile_args=extra_compile_args,
          define_macros=define_macros,
      ) for (module_name, module_file) in zip(module_names, module_files)
  ]
  if build_with_cython:
    import Cython.Build
    return Cython.Build.cythonize(
        extensions,
        include_path=include_dirs,
        compiler_directives={'linetrace': bool(ENABLE_CYTHON_TRACING)})
  else:
    return extensions

CYTHON_EXTENSION_MODULES = cython_extensions(
    list(CYTHON_EXTENSION_PACKAGE_NAMES), list(CYTHON_EXTENSION_MODULE_NAMES),
    list(EXTENSION_INCLUDE_DIRECTORIES), list(EXTENSION_LIBRARIES),
    list(DEFINE_MACROS), list(EXTRA_COMPILE_ARGS), bool(BUILD_WITH_CYTHON))

PACKAGE_DIRECTORIES = {
    '': PYTHON_STEM,
}

INSTALL_REQUIRES = (
    'enum34>=1.0.4',
    'futures>=2.2.0',
)

SETUP_REQUIRES = (
    'sphinx>=1.3',
) + INSTALL_REQUIRES

COMMAND_CLASS = {
    'doc': commands.SphinxDocumentation,
    'build_proto_modules': commands.BuildProtoModules,
    'build_project_metadata': commands.BuildProjectMetadata,
    'build_py': commands.BuildPy,
    'gather': commands.Gather,
    'run_interop': commands.RunInterop,
}

# Ensure that package data is copied over before any commands have been run:
credentials_dir = os.path.join(PYTHON_STEM, 'grpc/_adapter/credentials')
try:
  os.mkdir(credentials_dir)
except OSError:
  pass
shutil.copyfile('etc/roots.pem', os.path.join(credentials_dir, 'roots.pem'))

TEST_PACKAGE_DATA = {
    'tests.interop': [
        'credentials/ca.pem',
        'credentials/server1.key',
        'credentials/server1.pem',
    ],
    'tests.protoc_plugin': [
        'protoc_plugin_test.proto',
    ],
    'tests.unit': [
        'credentials/ca.pem',
        'credentials/server1.key',
        'credentials/server1.pem',
    ],
    'grpc._adapter': [
        'credentials/roots.pem'
    ],
}

TESTS_REQUIRE = (
    'oauth2client>=1.4.7',
    'protobuf>=3.0.0a3',
    'coverage>=4.0',
) + INSTALL_REQUIRES

TEST_SUITE = 'tests'
TEST_LOADER = 'tests:Loader'
TEST_RUNNER = 'tests:Runner'

PACKAGE_DATA = {}
if INSTALL_TESTS:
  PACKAGE_DATA = dict(PACKAGE_DATA, **TEST_PACKAGE_DATA)
  PACKAGES = setuptools.find_packages(PYTHON_STEM)
else:
  PACKAGES = setuptools.find_packages(
      PYTHON_STEM, exclude=['tests', 'tests.*'])

setuptools.setup(
    name='grpcio',
    version='0.12.0b1',
    ext_modules=CYTHON_EXTENSION_MODULES,
    packages=list(PACKAGES),
    package_dir=PACKAGE_DIRECTORIES,
    package_data=PACKAGE_DATA,
    install_requires=INSTALL_REQUIRES,
    setup_requires=SETUP_REQUIRES,
    cmdclass=COMMAND_CLASS,
    tests_require=TESTS_REQUIRE,
    test_suite=TEST_SUITE,
    test_loader=TEST_LOADER,
    test_runner=TEST_RUNNER,
)
