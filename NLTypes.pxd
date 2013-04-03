# This software was developed by employees of the National Institute of
# Standards and Technology (NIST), and others.
# This software has been contributed to the public domain.
# Pursuant to title 15 Untied States Code Section 105, works of NIST
# employees are not subject to copyright protection in the United States
# and are considered to be in the public domain.
# As a result, a formal license is not needed to use this software.
# 
# This software is provided "AS IS."
# NIST MAKES NO WARRANTY OF ANY KIND, EXPRESS, IMPLIED
# OR STATUTORY, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTY OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT
# AND DATA ACCURACY.  NIST does not warrant or make any representations
# regarding the use of the software or the results thereof, including but
# not limited to the correctness, accuracy, reliability or usefulness of
# this software.

cimport libc.stdio as stdio

cdef enum:
    NLM_F_REPLACE = 0x100
    NLM_F_CREATE = 0x400

cdef extern from "netlink/handlers.h":
    cdef struct nl_sock:
        pass

cdef extern from "netlink/cache.h":
    cdef struct nl_cache:
        pass

cdef extern from "netlink/route/route.h":
    cdef struct nl_route:
        pass
    cdef struct rtnl_route:
        pass

cdef extern from "netlink/route/addr.h":
    cdef struct rtnl_addr:
        pass

cdef extern from "netlink/route/link.h":
    cdef struct rtnl_link:
        pass

cdef extern from "netlink/types.h":
    cdef struct nl_dump_parent:
        pass
    cdef struct nl_dump_params:
        stdio.FILE * dp_fd
        char * dp_buf
        size_t dp_buflen
        int dp_type

cdef extern from "netlink/object.h":
    cdef struct nl_object:
        pass
