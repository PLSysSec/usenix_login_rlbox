## Applications beyond sandboxing

Although RLBox focusses on sandboxing, RLBox tackles a more general
problem---enabling the interaction of trusted and untrusted code while handling
associated problems such as enforcing invariants on control flow and shared data
structure, handling confused deputy attacks, ABI related incompatibilities etc.
Thus, we believe RLBox's techniques can be used in many additional scenarios and
we discuss a few of these below.

TEE runtimes: Applications running on the trusted execution environments such as
Intel SGX must frequently interface with untrusted code; indeed code from the
host OS is also untrusted in this context. In fact, when reviewing a variety of
TEE runtimes that facilitate communication with the untrusted OS, Van Bulck et
al.!!!\cite{two-worlds-sgx}!!! discovered that almost all frameworks have bugs
pertaining to use of unchecked data---bugs that RLBox would prevent by
construction. In face we believe, that RLBox may be used to help solve these
problems in TEE runtimes with little to no modification.

OS kernels: Operating system kernel code frequently handles userspace pointers,
but must be careful to never dereference them before checking. In fact, prior
work !!!cite{cqual-kernel-ptr}!!! has extended compiler support for C's
attributes to achieve the same affect of having a wrapped type.

Browser IPC layers: Modern browsers employ multiple processes to reduce their
security surface and to employ features such as site-isolation. This
architecture means that data often has to be transferred back and forth between
various processes some of which are potentially compromised. Thus RLBox can be
used to mark this data as tainted. Additionally, use of RLBox also automatically
provides lazy marshalling of data, which in turn eliminates marshalling of any
unused data.

Handling untrusted user inputs: Even more generally, there is a large class of
bugs that stem for unsanitized data being used without validation. RLBox
addresses this challenge in the context of sandboxing with tainted types and
required validators before data use. Similar solutions employing wrapper types
are possible and have been explored for some of these domains. For example,
trusted types are used in JavaScript to prevent XSS. Similarly, these same
techniques can also help with SQL injection bugs, printf unchecked format string
bugs etc.


The Rust build system could then compile this dependency to WebAssembly
(something that is already supported), and automatically wrap the data returned
by functions these dependencies with tainted types. By doing this, Rust can
offer a single configuration that allows users to sandbox dependencies.

The Rust
build system (Cargo) could naturally be extended with an additional flag in the
Cargo.toml file, to to indicate when a dependency should be sandboxed, and
automatically augment function return values with tainted types. 

Of course developers would still responsible for modifying their code to add
validators where needed, however this would encourage developers to consider
sandboxing as an important tool for dependencies.


