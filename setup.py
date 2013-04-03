from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

import commands
def pkgconfig(*packages, **kw):
    flag_map = {'-I': 'include_dirs', '-L': 'library_dirs', '-l': 'libraries'}
    for token in commands.getoutput("pkg-config --libs --cflags %s" % ' '.join(packages)).split():
        kw.setdefault(flag_map.get(token[:2]), []).append(token[2:])
    return kw

ext_modules=[
    Extension("Routing",
              ["Routing.pyx", "NLTypes.pxd", "NLUtils.pxd"],
              **pkgconfig("libnl-3.0 libnl-cli-3.0"))  # Unix-like specific
			      ]

setup(
  name = "Routing",
  cmdclass = {"build_ext": build_ext},
  ext_modules = ext_modules
)