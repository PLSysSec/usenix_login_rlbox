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

# How sandboxing changes the way we build software

We know an enormous amount code in used today is written in unsafe languages
i.e.~C/C++, a fact that we believe is unlikely to change for the forseable
future. Trying to hold all the C/C++ code in our systems to a high security
standard is not reasonable, it hasn't worked and is not going to work.

Thus, in spite of the admonitions of security researchers. Real developers
everywhere are daily faced with difficult choices vis-a-vis security, do I
totally trust this third-party library to implement this feature, do I totally
trust this legacy code, or code by another team,  or even my own code to
implement this feature. Or do I forgoe this feature. Of course, if you give
people choice of assurance or functionality they will almost always choose the
later.

Sandboxing offers the potential to give developers another options. Developers
can instead choose wether code belongs in the trusted kernel of their
application, or instead should be run in a less privileged sandbox, where the
effects of a compromise can be largely mitigated.

Once the option run code in a less privileged sandbox is available, this takes
takes enormous pressure off developers.

XXX tie this back to mozilla example
XXX maybe throw in Qualcom example.



<!--

- Why third party code is sketchy - every time you add a feature pulling more
stuff into your tcb.

-hard choice: do -Trying to hold C/C++ to a high security standard is not reasonable, it hasn't
worked and is not going to work, so we need to do something else.

-How do we build secure systems with average programmers. Even greater programmers
have limitations.

-legacy code in our code base
-long tail of libraries that we depend on that won't be maintained or audited.
- Memory safety is a real bad thing.
- Your developers write code that should be sandboxed also.
- You don't want to either have to write high assurance code
- You don't want to rewrite your code in Rust.
- You don't want to write your code in Rust, C/C++ is what your team/company/project/industry
  does. 
-There will be C/C++, memory safety is a big problem, this is cheaper than 
- Samsung example
-->



