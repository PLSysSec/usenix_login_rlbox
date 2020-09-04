-- Title: Lowering the barrier to in-process sandboxing

# Introduction

Modern software makes heavy use of third-party libraries. While this is key
for developer productivity, this is also a security nightmare. Third party
libraries, today, are completely trusted and, unfortunately, this means that
bugs in any library can be easily exploited to compromise the entire
application. Even more worrisome, attacks on software supply chains are
becoming more prevalent: attackers are compromising (and sometimes buying)
the accounts of software maintainers to slip backdoored code into popular
libraries.

There is a practical alternative to today's trust-everything model: we can
sandbox libraries and, in turn, minimize the damage due to library bugs and
exploits. Many libraries do not require complete trust for applications to
safely use their functionality. For example, image decoders like libjpeg and
libpng don't need access to anything but the image buffers they operates on,
OpenSSL doesn't need access to anything but the socket it's reading from and
the bytestream it's writing the decrypted HTTP stream to, and spell checkers
like Hunspell don't need access to anything but dictionary files and the
string it's spell checking. (These are just a few examples, however, we
believe many other examples abound.) This implicit separation of privilege
makes libraries especially well suited for sandboxing.

Unfortunately, library sandboxing has suffered from a chicken and egg
problem. Without practical tools for sandboxing libraries with minimal
performance overhead and engineering effort, developers and security
engineers are not looking for these opportunities.


Our own experience sandboxing libraries in Firefox reflects this. Our initial
attempts to manually sandbox third party libraries were labor intensive,
and extremely error prone. In contrast, once we developed a mature
framework---RLBox---to support this activity, the incremental work to sandbox
new libraries became minimal, and more opportunities to sandbox additional
parts of the application became apparent.

For example, while we began with third party font shaping libraries, now
Firefox developers and security engineers are using RLBox for media decoding,
spell checking, even speech synthesis. Similar opportunities exist in many
other application domains. For example, secure messaging apps (e.g., Signal,
WhatsApp, and iMessage), servers and runtimes (e.g., Apache and Node.js,),
and enterprise tools (e.g., Zoom, Slack, and VS Code) also rely on third
party libraries for various tasks---from media rendering, to parsing network
protocols like HTTP, to image processing (e.g., to blur faces), spell
checking, and automated text completion. Frameworks like RLBox can help these
applications eliminate such libraries from their trusted computing base.

To make library sandboxing a goto tool in more software engineering
environments. There are three critical challenges to be address. 


_engineering effort_ we to minimize the upfront work required
to change our application to use sandboxing, especially as this is multiplied
across many libraries, minimizing changes to libraries is also important as this can
significantly increase the burden of tracking upstream changes.

_security_ applications are not built
to protect themselves from libraries; thus, we have to sanitize all data and regulate control
flow between the library and application to prevent libraries from breaking out of
the sandbox.

In our experience, bugs at the library-renderer boundary are not only easy to
overlook, but can nullify any sandboxing effort---and other developers,
not just us, must be able to securely sandbox new libraries.

_efficiency_the renderer is performance critical, so adding
user-visible latency is not acceptable.


We start
with how RLBox works and how it leverages the C++ type systems to make
sandboxing practical. Then we outline what we need to do to bring sandboxing
to other languages. Finally, we end with a vision of what software development
could look like if we have first-class support for sandboxing.

# Sandboxing libraries with RLBox

RLBox is a C++ framework that helps developers migrate and maintain code in
application to safely use sandboxed libraries.

## Why do we need a framework?

The applications-library boundary is tightly coupled and by default application
code is written assuming libraries are trusted. To benefit from sandboxing
requires changing our threat model to assume libraries are untrusted, and modify
the renderer-library interface accordingly (e.g, to sanitize untrusted inputs).

While migrating to this model we made numerous mistakes—overlooking attack
vectors and discovering many bugs only after building RLBox to help detect them.
We present a few illustrative examples below.

!!!!TODO!!!!

We built the RLBox framework to tackle these challenges. RLBox is a pure C++
library that helps developers migrate and maintain code in application to safely
use sandboxed libraries. RLBox does this by providing APIs to invoke sandboxed
functions, permit callbacks into the host application and more generally
exchange data between the sandbox and application. These APIs are built around
tainted types---these are wrapper types used to mark data received from the
sandboxed library and impose a simple static information flow control (IFC)
discipline.

Thus, to migrate application code from use of an unsandboxed library, to a
sandboxed library we must simply use the RLBox API for all interactions with the
sandboxed library.

This simple design for RLBox allows us to provide several features including

- Ensuring the resulting code has security checks in appropriate locations
- Providing a systematic approach to migrating application code to the RLBox API
  accounting for ABI differences, data marshalling etc. automatically
- Easily enabling or disabling different isolation technologies.

### Eliminating confused deputy attacks

!!!!TODO!!!!

### Minimizing sandboxing engineering effort

RLBox is also explicitly designed to minimize engineering effort. For instance,
when using the RLBox API automatically...


!!!!! Swizzling operations, per-
forming checks that ensure sandbox-supplied pointers point
to sandbox memory, and identifying locations where tainted
data must be validated is done automatically. !!!!

!!!!! Talk about how we later added ABI compat here - powered by the combination
of tainted and tainted_volatile!!!!!!

RLBox allows us to migrate application code to use the RLBox API one line at a
time. Between each change, the application can be compiled and run as before.
While the precise approach is explained in detail in our paper, the key parts of
RLBox that allow for is the concept of escape hatches---techniques that let us
disable RLBox's checks for a piece of code.

RLBox offers two important escape hatches.

1) The UNSAFE_unverified API may be used on any tainted data to remove the
  tainted wrapper. This allows the application code to disable tainting of data
  when data must be passed to code that cannot handle tainted data. However, as
  the API name indicates, the use of this API would not enforce the required
  security checks, and is to be used only in the context of migrating code.
  After migration is complete, calls to UNSAFE_unverified APIs must be removed
  or replaced with validator functions that sanitize the given data.

2) The RLBox API allows the application code to choose the underlying isolation
  mechanism including a noop sandbox option. This option simply redirects
  function calls back to the application but wraps data as if it were received
  from a sandboxed library. This allows us to test the data validation without
  having to actually use a sandboxed library. But the noop sandbox plays an even
  more important role! Since, sandboxing mechanisms such as WebAssembly have a
  different ABI, incremental porting cannot be supported as there is no way to
  apply ABI conversions when escape hatches such as UNSAFE_unverified were used.
  Instead the incremental migration approach would be to use the noop sandbox
  during incremental migration and switch to Wasm enforcement once this
  migration is complete.


While these features were designed with the above use cases in mind, we also
discovered several unexpected practical benefits from the above feature set,
including their interactions after the publication as we incorporated this more
in production code. We discuss these below

First the incremental porting greatly simplifies the code review process. For
instance, we could commit and get reviews for partial migrations to the RLBox
API as this do not the Firefox browser continued to build and run as before.
Additionally, in the initial migration we simply omitted the validators for use
of UNSAFE_unverified APIs. This allowed to test and deploy the partial migration
on Firefox nightly builds. We then included the data validators in a separate
code review with additional security reviews as part of this change.

Next we discovered that the noop sandbox is critical for downstream projects.
When speaking with developers of the Tor browser, a downstream fork of the
Firefox browser that allows anonymous browsing in the web, we found that Tor was
open to sandbox more libraries than Firefox despite additional performance
overhead due to their higher security requirements. However, the burden of
maintaining a large fork of Firefox with sandboxed libraries was not an
acceptable option. Instead, the RLBox API provides a simple option; Tor
developers could migrate code to use the RLBox API but contribute upstream using
the noop sandbox. They could then switch the configuration in the Tor browser to
use an isolation mechanism that provides enforcement. Since using the noop
sandbox little to no overherad (< 1%), this is a reasonable option.

Indeed this flexibility in switching between memory isolation also allows easy
experimentation with many new hardware features. We discuss this next.

### Leveraging advances in SFI and hardware isolation

As discussed RLBox's design allows it to be agnostic to the memory isolation
technique. For example, consider Intel's Memory Protection Key features (MPK)
which allow very efficient sandboxing of components. It would straightforward to
implement RLBox support to use MPK as the isolation mechanism.

RLBox, also allows leveraging more complicated hardware security mechanisms. For
instance consider ARM Cheri, which is a hardware feature that converts pointers
into capabilities that apply bounds checks. Since this feature expands the size
of pointers it may not be easy to deploy for all applications especially if the
increased pointer size introduces incompatibilities. Furthermore it would not be
easy to apply this to just a portion of the code as any data-structures from
this portion of code would have ABI incompatibilities with the rest of the
application. However, since the RLBox can automatically adjust for ABI
differences, applications can straightforwardly use Cheri to secure a single
component in an application.

Finally, consider Intel TSX which provides hardware support for transactional
memory. RLBox can leverage this feature to prevent time-of-check-time-of-use and
double-fetch attacks. This would potentially allow some speedup over the current
approach, which makes a copy of data before performing any validation.

Readers may have spotted that the problems addressed by RLBox are in no
way exclusive to the sandboxing space. We discuss this next.

# First-class support for tainted types and sandboxing

Though we implemented RLBox in C++ to sandbox C libraries, we believe the
underlying principles translate to other languages. Going even further, we
propose first class support for RLBox in languages and their tooling, so that
!!!!TODO!!!!

## RLBox's use of language features

To understand how to bring RLBox to other languages, we need to first
understand which C++ features RLBox relies on. Primarily, RLBox uses tainted
types (implemented via C++ generics) and leverages compiler type checking to
enforce security properties. RLBox also permits safe operations on tainted
types under certain constraints by taking advantage of operator overloading,
and enforces constraints on these operations using C++ metaprogramming
techniques.

Many other languages include features which can be used to implement the same
general RLBox principles. For instance, many statically-typed languages offer
some form of generics or templates which could be used to implement RLBox's
tainted and tainted_volatile types. A notable exception here is
C---supporting RLBox in C would require some tool for code generation.
Similarly, many languages allow operator overloading, which RLBox uses to
provide safe operations on tainted types while preserving the original
syntax of the language. (For instance, in C++, RLBox allows dereferencing
a tainted<int*> via the natural '->' and '*' operators, but with automatically
inserted bounds checks.)

Frameworks like RLBox can also be used to enforce security in dynamically
typed languages like JavaScript. However, without compiler assistance, RLBox
cannot provide helpful compile-time assistance, which is especially important
during incremental porting. Instead, the errors would manifest as runtime
errors. Thus, while the usability of RLBox would be reduced, the security
guarantees would be the same.

This is just the beginning! We envision a future where RLBox could leverage
many additional language features as well. For instance, RLBox could take
advantage of Rust's affine types to automatically prevent
time-of-check-time-of-use attacks and double fetch attacks. RLBox could also
leverage contracts --- as recently proposed for C++, or for Wasm's interface
types --- to automatically validate tainted data prior to use.

<!-- RLBox currently requires extra user specification (in the form of macros)
to fully support structs. However, C++ metaclasses and reflection support will
allow RLBox to support this automatically.-->

## First-class support for RLBox

In the further future, we envision first-class support in languages and their
tooling for RLBox, and for sandboxing more broadly. First-class support in a
language module system or in a package manager could allow users to
seamlessly choose to sandbox libraries when importing dependencies, and could
also automatically apply tainted types to all of the values coming out of the
library. First-class support could also ensure that the syntax for using
RLBox is as natural as possible -- for instance, invoking sandbox functions
could share the same syntax as ordinary function calls. Language tooling
could automatically adjust its build system to appropriately switch to a
sandboxing compiler for libraries which the user wants to sandbox. The
language could potentially even automatically pull in contract definitions
for each library's interface, using a system similar to what we see today for
TypeScript. In short, first-class support for RLBox could make sandboxing
even more seamless for users, resulting in greater security in the greater
software ecosystem.

Most languages support FFI to libraries written in other languages, particularly
C. Integrating RLBox into the natural FFI support for a language would help
automatically ensure that C-language libraries do not violate the invariants
expected by higher-level constructs in the source language. It would also
provide greater security in general, as memory safety bugs in the C-language
library would be prevented from compromising the larger application; an effort
explored by multiple academic papers -- !!!tocite{robusta, sandcrust, some node
thing?, lookup language sandboxes}!!!!.

Case study of Rust:
- has generics
- has a powerful macro system for code generation
- typeclasses allow some operator definitions
- affine types
- has support for direct wasm compilation in the build system
- well defined dependency management toolchain

# Conclusions
