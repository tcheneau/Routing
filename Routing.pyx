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

# Tony Cheneau <tony.cheneau@nist.gov>

from NLTypes cimport nl_sock
from NLUtils cimport *
from libc.stdio cimport stdout
from libc.stdlib cimport free
from libc.string cimport memset

# TODO:
# - add table support
# - fix bug for removing default route

# constant values

NETLINK_ROUTE =  0

NL_DUMP_LINE = 0


cdef void delete_route_cb(nl_object * obj, void * arg):
        cdef rtnl_route * route = <rtnl_route *> obj
        cdef nl_sock * sock = <nl_sock *> arg
        cdef int err = 1

        err = rtnl_route_delete(sock, route, 0)
        if (err < 0): raise Exception(nl_geterror(err))

cdef void delete_addr_cb(nl_object * obj, void * arg):
        cdef rtnl_addr * addr = <rtnl_addr *> obj
        cdef nl_sock * sock = <nl_sock *> arg
        cdef int err = 1

        err = rtnl_addr_delete(sock, addr, 0)
        if (err < 0): raise Exception(nl_geterror(err))


def need_clean_route_obj(method_to_decorate):
    def wrapper(self, * args, **kwargs):
        self.__alloc_route()
        method_to_decorate(self, *args, **kwargs)

    return wrapper

def need_clean_addr_obj(method_to_decorate):
    def wrapper(self, * args, **kwargs):
        self.__alloc_addr()
        method_to_decorate(self, *args, **kwargs)

    return wrapper


def sync_cache(method_to_decorate):
    def wrapper(self, * args, **kwargs):
        self.__resync_caches()
        ret = method_to_decorate(self, *args, **kwargs)
        self.__resync_caches()
        return ret
    return wrapper


cdef class Routing:
    """Routing provides access to the (current) routing cache.

    Example of usage:
    >>> r = Routing()
    >>> print r
    inet 127.0.0.0 table local type broadcast via dev lo
    inet 127.0.0.1 table local type local via dev lo
    inet 127.0.0.0/8 table local type local via dev lo
    >>> r.set_family("inet6")  # work with IPv6 addresses
    >>>
    """
    cdef nl_sock * sock
    cdef nl_cache * link_cache
    cdef nl_cache * route_cache
    cdef rtnl_route * __route
    cdef nl_dump_params params
    cdef str family
    cdef char buff[2048]

    def __cinit__(self):
        # self.params.dp_fd = stdout
        self.params.dp_buf = self.buff
        self.params.dp_buflen = len(self.buff)
        self.params.dp_type = NL_DUMP_LINE

        self.sock = nl_socket_alloc()

        if self.sock is NULL:
            raise MemoryError()

        err = nl_connect(self.sock, NETLINK_ROUTE)

        if err < 0:
            raise "Unable to connect netlink socket: %s" % nl_geterror(err)

        self.link_cache = nl_cli_link_alloc_cache(self.sock)

        self.route_cache = nl_cli_route_alloc_cache(self.sock, 0)
        if self.route_cache is NULL:
            raise MemoryError()

    def __alloc_route(self):
        if self.__route is not NULL:
            rtnl_route_put(self.__route)
        self.__route = nl_cli_route_alloc()
        if self.__route is NULL:
            raise MemoryError()

    def __resync_caches(self):
        """decorator: synchronize/refill the link and the routing caches"""
        nl_cache_refill(self.sock, self.link_cache)
        nl_cache_refill(self.sock, self.route_cache)

    def set_family(self, family):
        """set the family for the displayed routes (inet, inet6)
        """
        if family is None:
            self.family = None
        else:
            self.family = family

    def __set_family(self, arg):
        nl_cli_route_parse_family(self.__route, arg)

    def __repr__(self):
        self.__alloc_route()
        self.__resync_caches()

        if self.family:
            self.__set_family(self.family)

        memset(self.buff, 0, len(self.buff))
        nl_cache_dump_filter(self.route_cache,
                             &self.params,
                             <nl_object *>self.__route)
        return self.buff


    @need_clean_route_obj
    @sync_cache
    def add(self, destination=None, nexthop=None, source=None, table=None):
        """
        - nexthop is a tuple of address and interface.
        It can also be a list of such tuples.

        Example of usage:
        >>> r = Routing()
        >>> r.add("2000::/3", ("fe80::a2","eth0"))
        Adding a default route (require the address family to be set):
        >>> r = Routing.Routing()
        >>> r.set_family("inet6")
        >>> r.add("default", ("fe80::a2", "em1"))
        """

        err = 1

        # ./nl-route-add --family=inet6 -d 2000::/3 -n via=fe80::a2,dev=eth0
        NH_ARGS = ["via", "dev"]

        if self.family:
            self.__set_family(self.family)

        if destination:
            nl_cli_route_parse_dst(self.__route, destination)

        if source:
            nl_cli_route_parse_src(self.__route, source)

        if table:
            nl_cli_route_parse_table(self.__route, table)

        if isinstance(nexthop, list):
            for hop in nexthop:
                hop = ",".join([ "=".join(arg) for arg in zip(NH_ARGS, hop) ])

                nl_cli_route_parse_nexthop(self.__route, hop, self.link_cache)
        elif nexthop:
            nh = ",".join([ "=".join(arg) for arg in zip(NH_ARGS, nexthop) ])
            nl_cli_route_parse_nexthop(self.__route, nh, self.link_cache)

        err = rtnl_route_add(self.sock, self.__route, 0)
        if (err < 0): raise(Exception(nl_geterror(err)))


    @need_clean_route_obj
    @sync_cache
    def remove(self, destination=None, nexthop=None, source=None, table=None):
        """Remove a route from the node

        Caveat: it seems that default routes cannot be removed for the moment

        Equivalent libnl CLI command:
        # ./nl-route-delete -d 2000::/3 -n via=fe80::a2,dev=eth0
        """
        NH_ARGS = ["via", "dev"]

        if self.family:
            self.__set_family(self.family)

        if destination:
            nl_cli_route_parse_dst(self.__route, destination)

        if source:
            nl_cli_route_parse_src(self.__route, source)

        if table:
            nl_cli_route_parse_table(self.__route, table)

        if isinstance(nexthop, list):
            for hop in nexthop:
                hop = ",".join([ "=".join(arg) for arg in zip(NH_ARGS, hop) ])

                nl_cli_route_parse_nexthop(self.__route, hop, self.link_cache)
        elif nexthop:
            nh = ",".join([ "=".join(arg) for arg in zip(NH_ARGS, nexthop) ])
            nl_cli_route_parse_nexthop(self.__route, nh, self.link_cache)

        nl_cache_foreach_filter(self.route_cache, <nl_object *> self.__route, &delete_route_cb, self.sock)


    def __dealloc__(self):
        if self.sock is not NULL:
            nl_close(self.sock)
            nl_socket_free(self.sock)
        if self.__route is not NULL:
            rtnl_route_put(self.__route)
        if self.link_cache is not NULL:
            nl_cache_free(self.link_cache)
        if self.route_cache is not NULL:
            nl_cache_free(self.route_cache)


cdef class Addressing:
    """Address provides access to address assigned on the node.

    Example of usage:
    >>> a = Addressing()
    >>> print a
    127.0.0.1/8 inet dev lo scope host <permanent>
    192.168.1.1/24 inet dev eth0 scope global <permanent>
    >>> a.set_family("inet6")
    >>>
    """
    cdef nl_sock * sock
    cdef nl_cache * link_cache
    cdef nl_cache * addr_cache
    cdef rtnl_addr * __addr
    cdef nl_dump_params params
    cdef str family
    cdef char buff[2048]

    def __cinit__(self):
        # self.params.dp_fd = stdout
        self.params.dp_buf = self.buff
        self.params.dp_buflen = len(self.buff)
        self.params.dp_type = NL_DUMP_LINE

        self.sock = nl_socket_alloc()
        if self.sock is NULL:
            raise MemoryError()

        err = nl_connect(self.sock, NETLINK_ROUTE)

        if err < 0:
            raise "Unable to connect netlink socket: %s" % nl_geterror(err)

        self.link_cache = nl_cli_link_alloc_cache(self.sock)
        self.addr_cache = nl_cli_alloc_cache(self.sock, "address", rtnl_addr_alloc_cache)

        if self.addr_cache is NULL:
            raise MemoryError()

    def __alloc_addr(self):
        if self.__addr is not NULL:
            rtnl_addr_put(self.__addr)

        self.__addr = nl_cli_addr_alloc()
        if self.__addr is NULL:
            raise MemoryError()

    def __resync_caches(self):
        """decorator: synchronize/refill the link and the routing caches"""
        nl_cache_refill(self.sock, self.link_cache)
        nl_cache_refill(self.sock, self.addr_cache)

    def set_family(self, family):
        """set the family for the displayed routes (inet, inet6)
        """
        if family is None:
            self.family = None
        else:
            self.family = family

    def __set_family(self, arg):
        nl_cli_addr_parse_family(self.__addr, arg)

    def __repr__(self):
        self.__alloc_addr()
        self.__resync_caches()

        if self.family is not None:
            self.__set_family(self.family)

        memset(self.buff, 0, len(self.buff))
        nl_cache_dump_filter(self.addr_cache,
                             &self.params,
                             <nl_object *>self.__addr)
        return self.buff


    @need_clean_addr_obj
    @sync_cache
    def add(self, address, interface, preferred=0, valid=0, replace=False):
        """Add an address to an interface.
        - address: adress that should be added
        - interface: interface on which the address should be assigned
        - preferred: preferred lifetime, in milliseconds (IPv6 only)
        - valid: valid lifetime, in milliseconds (IPv6 only)
        - replace: update an existing address (can reset preferred and valid lifetime)

        Example of usage:
        >>> a = Addressing()
        >>> a.add("2000::/3", "eth0")
        >>> # set preferred and valid lifetime to 1000 seconds
        >>> a.add("fe80::1/64", "em1", "1000000", "1000000")
        >>> a.add("fe80::1/64", "em1", "2000000", "2000000", replace=True)
        """

        cdef int nlflags = NLM_F_CREATE

        err = 1

        if preferred:
            nl_cli_addr_parse_preferred(self.__addr, preferred)

        if valid:
            nl_cli_addr_parse_valid(self.__addr, valid)

        if replace:
            nlflags |= NLM_F_REPLACE

        nl_cli_addr_parse_dev(self.__addr, self.link_cache, interface)

        nl_cli_addr_parse_local(self.__addr, address)

        err = rtnl_addr_add(self.sock, self.__addr, nlflags)

        if (err < 0): raise(Exception(nl_geterror(err)))


    @need_clean_addr_obj
    @sync_cache
    def remove(self, address, interface):
        nl_cli_addr_parse_dev(self.__addr, self.link_cache, interface)
        nl_cli_addr_parse_local(self.__addr, address)
        nl_cache_foreach_filter(self.addr_cache, <nl_object *> self.__addr, &delete_addr_cb, self.sock)


    def __dealloc__(self):
        if self.sock is not NULL:
            nl_close(self.sock)
            nl_socket_free(self.sock)
        if self.__addr is not NULL:
            rtnl_addr_put(self.__addr)
        if self.link_cache is not NULL:
            nl_cache_free(self.link_cache)
        if self.addr_cache is not NULL:
            nl_cache_free(self.addr_cache)


cdef class Link:
    """
    Provide an interface to the Link Layer address management

    Example of usage:
    >>> l = Link()
    >>> l.get_ll("wlan0")
    """
    cdef nl_sock * sock
    cdef nl_cache * link_cache
    cdef rtnl_link * __link
    cdef nl_dump_params params
    cdef char buff[2048]

    def __cinit__(self):
        self.params.dp_buf = self.buff
        self.params.dp_buflen = len(self.buff)
        self.params.dp_type = NL_DUMP_LINE

        self.sock = nl_socket_alloc()
        if self.sock is NULL:
            raise MemoryError()

        err = nl_connect(self.sock, NETLINK_ROUTE)

        if err < 0:
            raise "Unable to connect netlink socket: %s" % nl_geterror(err)


        self.__link = nl_cli_link_alloc()
        if self.__link is NULL:
            raise MemoryError()

        self.link_cache = nl_cli_link_alloc_cache_family(self.sock,
                                                         rtnl_link_get_family(self.__link))

        if self.link_cache is NULL:
            raise MemoryError()

    def get_lladdr(self, ifaces):
        """
        Retrieve the Link-Layer addresses associated to an interface
        """
        if self.__link is not NULL:
            rtnl_link_put(self.__link)

        self.__link = nl_cli_link_alloc()
        if self.__link is NULL:
            raise MemoryError()

        nl_cache_refill(self.sock, self.link_cache)

        if isinstance(ifaces, str):
            nl_cli_link_parse_name(self.__link, ifaces)
        elif isinstance(ifaces, list):
            for iface in ifaces:
                nl_cli_link_parse_name(self.__link, iface)

        memset(self.buff, 0, len(self.buff))

        nl_cache_dump_filter(self.link_cache,
                             &self.params, 
                             <nl_object *>self.__link)
        try:
            return self.buff.split()[2]
        except AttributeError, IndexError:
            return ""

    def __dealloc__(self):
        if self.sock is not NULL:
            nl_close(self.sock)
            nl_socket_free(self.sock)
        if self.__link is not NULL:
            rtnl_link_put(self.__link)
        if self.link_cache is not NULL:
            nl_cache_free(self.link_cache)
