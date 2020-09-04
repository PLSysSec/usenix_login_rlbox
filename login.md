-- Title: Lowering the barrier to in-process sandboxing

# Introduction

Modern software makes heavy use of third-party libraries. While this is critical
for developer productivity, it is also a security nightmare. Third party
libraries, today, are completely trusted. Unfortunately, this means that
bugs in any library can be easily exploited to compromise the entire
application. Further, attacks on software supply chains are
becoming more prevalent: attackers are compromising (and sometimes buying)
the accounts of software maintainers to slip backdoored code into popular
libraries.

There is a practical alternative to today's trust-everything model: we can
enforce least privilege by sandboxing libraries. Thus, minimizing the damage
inflicted by buggy or malicous libraries.  While this may sound radical at
first glance, it is often not a significant departure from how we use libraries
today.

As a result of basic principles of modularity and good interface design, most
libraries do not require unfettered access to the processes entire address
space, and as a practical matter, also require only a limited set of OS
privileges to accomplish their task. Thus, they often lend themselves to
running in a de-privileged and memory isolated context.

For example, image decoders like libjpeg and libpng don't need access to
anything but the image buffers they operate on, OpenSSL doesn't need access to
anything but the socket it's reading from and the bytestream it's writing the
decrypted HTTP stream to, and spell checkers like Hunspell don't need access to
anything but dictionary files and the string it's spell checking.

These are just a few examples, however, we believe other examples abound.
Unfortunately, library sandboxing has suffered from a chicken and
egg problem. Without practical tools for securely sandboxing libraries with minimal
performance overhead and engineering effort, developers and security engineers
are not looking for these opportunities.

We believe it is time for a shift in this perspective.  Over the past two years
we have worked with a team at Mozilla to migrate Firefox to a model where a
variety of different third party libraries run sandboxed. This new approach has
been shipping in Firefox since XXX. Our experience suggests that once their is
sufficient tooling support that engineers can easily sandbox libraries, they
become increasingly comfortable with and excited by the opportunities this
offers.

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

Recent advances in the compiler and processor architecture space have made
efficient in-process isolation increasingly practical in a wide range of use
cases.  However, to make library sandboxing a goto tool in more software
engineering environments, an essential missing element has been a common
framework support to make it easy to sandbox libraries in a manner that is
secure, i.e., by correctly enforcing a secure interface between the now
untrusted library and the library consumer, efficient i.e., that minimizes
changes to the library and consuming application, and efficient i.e., able to
isolate library code and share data across the library boundry with minimal
added overhead.

Our own experience sandboxing libraries in Firefox reflects this. Our initial
attempts to manually sandbox third party libraries were labor intensive,
and very prone to security bugs. In contrast, once we developed a mature
framework---RLBox---to support this activity, the incremental work to sandbox
new libraries became minimal, and more opportunities to sandbox additional
parts of the application became apparent.

Next section, how RLBox works and how it leverages the C++ type systems to make
sandboxing practical. Then we outline what we need to do to bring sandboxing
to other languages. Finally, we end with a vision of what software development
could look like with broader first-class support for sandboxing.



# Library Sandboxing in Firefox


Our perspective has been informed by our efforts over the past two years in
collaboration with a team at Mozilla to sandbox third-party libraries in
Firefox. In brief, third party media handling libraries for rendering images,
video, and audio have been a significant source of vulnerabilities in the
browser. 




Making this practical poses three significant challenges across three
dimensions.
%
First, {\it engineering effort}---we need to minimize the upfront work required
to change the renderer to use sandboxing, especially as this is multiplied
across dozens of libraries;
%
minimizing changes to libraries is also important as this can
significantly increase the burden of tracking upstream changes.
%
Second, {\it security}---the renderer was not built
to protect itself from libraries; thus, we have to sanitize all data and regulate control
flow between the library and renderer to prevent libraries from breaking out of
the sandbox.
%
In our experience, bugs at the library-renderer boundary are not only easy to
overlook, but can nullify any sandboxing effort---and other developers,
not just us, must be able to securely sandbox new libraries.
%
Finally, {\it efficiency}---the renderer is performance critical, so adding
user-visible latency is not acceptable.

To help us address these challenges, we develop a framework called \sys that
makes data- and control-flow at the library-renderer interface explicit, using
types. Unlike prior approaches to sandbox automation that rely on extensive
custom analysis frameworks~(\S\ref{sec:related}), \sys is simply a
library\footnote{
Our only external tooling is a \textasciitilde{}100LOC Clang
plugin, described in Section~\ref{subsec:impl_taint}, that makes up for C++'s
currently limited  support for reflection on structs.
}
that leverages the C++ type system and is easy to incorporate into \ff's
predominantly C++ codebase.

Using type information, \sys can identify where security checks are needed,
automatically insert dynamic checks when possible, and force compiler errors
for any security checks that require additional user intervention.  Our
type-driven approach enables a systematic way to migrate \ff's renderer to use
sandboxed libraries and allows \sys to support secure and
efficient sharing of data structures between the renderer and library (e.g., by
making shared memory operations safe and by lazily copying data out of the sandbox).






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
underlying principles translate to other languages. Additionally we also make
the case for first class support for RLBox in languages and their tooling.

## RLBox's use of language features

RLBox is a C++ library built on the idea of using tainted types (implemented via
generics) and leveraging compiler type checking to enforce security properties.
When RLBox wishes to permitting safe operations on tainted types under certain
constraints, this involves implementing the appropriate operator overloads on
the tainted type while enforcing the constraints using C++ metaprogramming
techniques.

While at first glance this approach looks extremely tied to C++, the concepts
behind RLBox are general and may be implemented in other languages as well. For
instance, the core technique behind RLBox is the use of the wrapper types
tainted and tainted_volatile. Most statically types languages offer some form of
generics or templates that allow this. A notable exception here is C, which does
not offer such as system. In such an environment, implementing an RLBox like
library comes with two caveats. First, we would need to use extra code
generation utilities that generate tainted types that use composition instead of
generics i.e. we generate types for tainted_int, tainted_float, tainted_foo etc
instead of providing one generic tainted<T> type. Next, 

 even in such an environment RLBox can be
implemented with two first caveats. First wrapper types such as tainted<int> can
be replaced with simple types tainted_int that use composition to hold tainted
data; however we need to generate all necessary instantiations of these types
that are used such as tainted_float, tainted_these simple types must be generate

metaprogramming for security checks
generics or code generation for wrapper tyo
contracts/interface types

## Why we want first-class support?

- can include libraries sandboxed from the start
- ffi-layer should do sandboxing from the start this

# Conclusions

