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

from NLTypes cimport *

cdef extern from "netlink/cli/utils.h":
    nl_cache * nl_cli_alloc_cache(nl_sock * sock, char * cache_type,
                             int (*ac) (nl_sock *, nl_cache **))


cdef extern from "netlink/cli/link.h":
    nl_cache * nl_cli_link_alloc_cache(nl_sock * sock)
    rtnl_link * nl_cli_link_alloc()
    nl_cache * nl_cli_link_alloc_cache_family(nl_sock *, int)
    void nl_cli_link_parse_name(rtnl_link *, char *)


cdef extern from "netlink/cli/route.h":
    rtnl_route * nl_cli_route_alloc()
    nl_cache * nl_cli_route_alloc_cache(nl_sock * sock, int print_content)
    void nl_cli_route_parse_family(rtnl_route *, char * family)
    void nl_cli_route_parse_src( rtnl_route *, char * source)
    void nl_cli_route_parse_nexthop( rtnl_route *, char *, nl_cache *)
    void nl_cli_route_parse_dst(rtnl_route *, char * destination)
    void nl_cli_route_parse_table(rtnl_route *, char *)


cdef extern from "netlink/cli/addr.h":
    rtnl_addr *nl_cli_addr_alloc()
    void nl_cli_addr_parse_family(rtnl_addr * addr, char * family)
    void nl_cli_addr_parse_local(rtnl_addr * addr, char * address)
    void nl_cli_addr_parse_dev(rtnl_addr * addr, nl_cache * link_cache, char * device_name)
    void nl_cli_addr_parse_preferred(rtnl_addr * addr, char * preferred_lifetime)
    void nl_cli_addr_parse_valid(rtnl_addr *, char * valid_lifetime)


cdef extern from "netlink/route/link.h":
    int rtnl_link_get_family(rtnl_link *)
    void rtnl_link_put(rtnl_link *)


cdef extern from "netlink/route/route.h":
    int rtnl_route_add(nl_sock * sock, rtnl_route * route, int flags)
    int rtnl_route_delete(nl_sock * sock, rtnl_route * route, int flags)
    void rtnl_route_put(rtnl_route *)
    

cdef extern from "netlink/route/addr.h":
    int rtnl_addr_alloc_cache(nl_sock * sock, nl_cache ** addr_cache)
    int rtnl_addr_add(nl_sock * sock, rtnl_addr * addr, int flags)
    int rtnl_addr_delete(nl_sock * sock, rtnl_addr * addr, int flags)
    void rtnl_addr_put(rtnl_addr *)


cdef extern from "netlink/cache.h":
    void nl_cache_dump_filter(nl_cache * cache, nl_dump_params * params, nl_object * obj)
    void nl_cache_free(nl_cache *)
    void nl_cache_foreach_filter(nl_cache *,
                                 nl_object *,
                                 void (*cb) (nl_object *, void *),
                                 void *arg)
    int nl_cache_refill(nl_sock * sock, nl_cache * cache)


cdef extern from "netlink/netlink.h":
    void nl_close(nl_sock * sock)
    int nl_connect(nl_sock * sock, int module)

cdef extern from "netlink/socket.h":
    nl_sock * nl_socket_alloc()
    void nl_socket_free(nl_sock * sock)

cdef extern from "netlink/errno.h":
    char * nl_geterror(int error)
