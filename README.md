Routing: a libnl-route binding for python
=========================================

[libnl3]:http://www.infradead.org/~tgr/libnl/
[Cython]:http://cython.org/


*Routing* is a python binding for [libnl3] writing in [Cython].
From the best of my knowledge, two python bindings already exists:

* the official binding, that sits in the python directory of libnl3 sources
* [an unofficial binding](https://github.com/socketpair/python-libnl3-ctypes) from the hacker socketpair, based on ctypes

However, none of these bindings seem to encompass the "route" module that I needed, so I set out to write yet another python binding for [libnl3].

How to install
--------------

This project comes with one Makefile that contains two targets:

* *build-module*: build a standard python module (and leave it in the current directory)
* *build-rpm*: build a RPM for easier deployment

I'm not very sure what is the proper way to install Cython packages because I
use exclusively the RPM built for my own needs. My best guess is that the
following line should suffice:

    python setup.py install

Dependencies
------------

* [libnl3] (including the development headers)
* [Cython]

What's in it?
-------------

Before I start, keep in mind that the following section does not provide an
exhaustive documentation for the library. The complete documentation will be
written at a later time. In the meantime, the main source of information should
be the source code.

### Route interface ###


```python
from Routing import Routing
r = Routing()
r.set_family("inet6")

# remove default route via fe80::1 through eth0
r.remove("default", ("fe80::1", "eth0"), table="local")  
# well, this route was fine actually
r.add("default", ("fe80::1", "eth0"), table="local")

print r
# outputs the routes:
# >> inet 127.0.0.0 table local type broadcast via dev lo
# >> inet 127.0.0.1 table local type local via dev lo
# >> inet 127.0.0.0/8 table local type local via dev lo

r.set_family("inet6")
# display only IPv6 routes
print r
```

There is currently a few issue. Namely, adding a default IPv6 route (require
the address family to be set through the *set_family* method).

### Address interface ###

```python
from Routing import Addressing
a = Addressing()
print a
# ouputs
# >> 127.0.0.1/8 inet dev lo scope host <permanent>
# >> 192.168.1.1/24 inet dev eth0 scope global <permanent>
a.set_family("inet6")

# add the address 2000::/3 on eth0
a.add("2000::/3", "eth0")
# add address "fe80::1/64"
# set preferred and valid lifetime to 1000 seconds
a.add("fe80::1/64", "em1", "1000000", "1000000")
# reset the previous lifetimes values
a.add("fe80::1/64", "em1", "2000000", "2000000", replace=True)
# or, for permanent registration
a.add("fe80::1", "eth0", str(0xffff), str(0xffff), replace=True)
```

### Link interface ###

Currently, this part of the module doesn't do much aside from extracting link
addresses.

```python
from Routing import Link
l = Link()

# retrieve the link local addresses
l.get_lladdr("eth0")
```

Caveats
-------

The current implementation let libnl do the heavy lifting and makes direct call
to the command line interface (CLI) from libnl API. When libnl fails to process
a request, it calls *nl_cli_fatal()* which it turns calls *exit()*. This
effectively makes your python code exist.


Authors
-------

* Tony Cheneau (tony.cheneau@nist.gov or tony.cheneau@amnesiak.org)

Acknowledgment
--------------

This work was supported by the Secure Smart Grid project at the Advanced
Networking Technologies Division, NIST.

Conditions Of Use
-----------------

<em>This software was developed by employees of the National Institute of
Standards and Technology (NIST), and others.
This software has been contributed to the public domain.
Pursuant to title 15 Untied States Code Section 105, works of NIST
employees are not subject to copyright protection in the United States
and are considered to be in the public domain.
As a result, a formal license is not needed to use this software.

This software is provided "AS IS."
NIST MAKES NO WARRANTY OF ANY KIND, EXPRESS, IMPLIED
OR STATUTORY, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTY OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT
AND DATA ACCURACY.  NIST does not warrant or make any representations
regarding the use of the software or the results thereof, including but
not limited to the correctness, accuracy, reliability or usefulness of
this software.</em>
