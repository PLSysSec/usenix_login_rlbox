-- Title: Lowering the barrier to in-process sandboxing

# Introduction

Modern software makes heavy use of third-party libraries. While this is key
for developer productivity, this is also a security nightmare. Third party
libraries, today, are completely trusted and, unfortunately, this means that
bugs in any library can be easily exploited to compromise the entire
application. Even more worrisome, attacks on software supply chains are
becoming more prevealent: attackers are compromising (and sometimes buying)
the accounts of software maintainers to slip backdoored code into popular
libraries.

There is a practical alternative to today's trust-everything model: we can
sandbox libraries and, in turn, minimize the damage due to library bugs and
exploits. Many libraries do not require complete trust for applications to
safely use their functionality. For example, image decoders like libjpeg and
libpng don't need access to anything but the image buffers they operates on,
OpenSSL doesn't need access to anything but the socket it's reading from and
the bytstream it's writing the decrypted HTTP stream to, and spell checkers
like Hunspell don't need access to anything but dictionary files and the
string it's spell checking. (These are just a few examples, however, we
believe many other examples abound.) This implicit separation of privilege
makes libraries especially well suited for sandboxing.

Unfortunately, library sandboxing has suffered from a chicken and egg
problem. Without practical tools for sandboxing libraries with minimal
performance overhead and engineering effort, developers and security
engineers are not looking for these opportunities. Our own experience
sandboxing libraries in Firefox reflects this. Our initial
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
checking, and aumated text completion. Frameworks like RLBox can help these
applications eliminate such libraries from their trusted computing base.

In the rest of this article we will lay out the path to making library
sandboxing a goto tool in more software engineering environments. We start
with how RLBox works and how it leverages the C++ type systems to make
sandboxing practical. Then we outline what we need to do to bring sandboxing
to other languages, and how our lessons apply to other domains (e.g., trusted
execution environments and OS kernels). Finally, we end with a vision of what
software development could look like if we have first-class support for
sandboxing.

# Sandboxing libraries with RLBox

RLBox is a C++ framework for ...

## Why do we need a framework?

The applications-library boundary is tighly coupled and, as a result, it's
easy to introduce security bugs when breaking this boundary to now consider
the sandbox untrusted. + motivation for engineering effort

### Address confused deputy attacks
### Address sandboxing engineering effort 
- noop sandbox for porting and downstream
- incremental porting
- ABI compat

### Leveraging advances in hardware isolation

- perf profiles for differnet things
- experiment with new hardware features - mpk, cheri; make this fit:
Trends in compiler toolchains and processors architectures make efficient
in-process isolation increasingly practical without resorting to exotic
techniques e.g. WebAssembly is becoming a defacto standard tool chain for
software based fault isolation, multi-core and even minion processors support
the use of multiple protection domains without prohibitive overheads, and
emerging architecture features such as Intel MPK and ARM-Cheri allow
in-process isolation with very low overhead.

## Beyond sandboxing

These problems are not exclusive to sandboxing.

- SGX
- Kernels
- IPC layer in FF

Moreover, RLBox's tainted types can used anywhere we handle untrusted content.
- SQLi
- XSS (TrustedTypes)

# First-class support for tainted types and sandboxing

Though we implemented RLBox in C++ to sandbox C libraries, we believe the
underlying principles translate to other languages.

## What existing langauge features can we reuse?

metaprogramming for secuirity checks
generics or code generation for wrapper tyo
contracts/interface types

## Why we want first-class support?

- can include libraries sandboxed from the start
- ffi-layer should do sandboxing from the start this

# Conclusions


----
---- OLD STUFF
----


# Why now?

Sandboxing third party libraries is not a novel idea. These concepts have
been explored for years in academia, and has now crossed critical milestones
that make them practical. Trends in compiler toolchains and processors
architectures make efficient in-process isolation increasingly practical
without resorting to exotic techniques e.g. WebAssembly is becoming a defacto
standard tool chain for software based fault isolation, multi-core and even
minion processors support the use of multiple protection domains without
prohibitive overheads, and emerging architecture features such as Intel MPK
and ARM-Cheri allow in-process isolation with very low overhead.

Next, as our own work on Firefox in collabortation with colleuages at Mozilla
has illustrated, the software engineering problems of sandboxing, including
efficienty porting libraries into a sandboxed environment, and ensuring that
interactions between the sandboxed library and trusted application can be
secured without expert knowledge, are practical.

Finally, languages like Rust offer the ability to greatly reduce or eliminate memory
safety bugs in new code, however, this code may still use dependencies written in C,
potentially negating the memory safety benefits of Rust.


# Vision
---------


In this article we argue that this perspective needs to be updated, its time
to make compartmentalization mainstream. Much as one would ask today, "why
does this need to be running in the OS kernel", we hope in the future developers
will ask, "why does this module or dependency need to run in the applications
trusted computing base".


-------
# RLBox framework

# Sandboxing for everyone: what we need and why



What do we need to make this possible. Need sufficient language support--
meta-programming or DSL and need standardized framework that uses this stuff.


Similar opportunities exist in any any messaging (e.g. signal, telegram,
whatsapp) or social media application (facebook, instagram), will rely on a
similar collection of third party libraries for media rendering, as well as
functionality like spell checking and autocomplete.

Once the sandboxing hammer widely available, developers will start looking
for other nails.

In the rest of this article we will lay out the path to making library sandboxing
a goto tool in more software engineering environments. 

How RLbox works, and how it leverages the C++ type systems.
What we need to do this in other languages.

How this could change the way we develop software.
    -designing with sandboxing at start (trusted core, less trusted periphery)
    -package ecosystems with sandboxing built in (wasm ecosystem example)


\paragraph{Sandboxing in Firefox: Third Party code and Beyond}

The Firefox renderer, like that of every other browser has until recently
been built as a trusted monolith, with all modules and third party libraries
being totally trusted. As a consequence a vulnerability e.g. a memory safety
bug, in any one of these compromises the entire renderer i.e. the entire web
application being rendered.

In collaboration with colleauges at Mozilla, we have been moving Firefox away
from this model, and towards a model where third party libraries e.g., image,
audio, and video decoders, as well as other modules e.g. the spell checker
are run in isolated sandboxes. This effectively partitions the renderer into
two parts, a more trusted core, and a less trusted periphery consisting of
many modules who simply don’t need the same level of privilege, nor to live
in the same address space as the the trusted core.

We believe this approach has relevance far beyond Firefox, and that many
modern applications can benefit from a similar approach.

Obvious first examples include mobile applications whose structure in simple
ways mirrors that of the renderer. For example, any messaging (e.g. signal,
telegram, whatsapp) or social media application (facebook, instagram), will
rely on a similar collection of third party libraries for media rendering, as
well as functionality like spell checking and autocomplete.

However, we believe additional examples will abound if more developers embrace this pattern. 

In modern applications all code is trusted by default.  This makes them excessively fragile,
especially as a large fraction of this code consists of third-party dependencies, written by different developers, of different trustworthiness. Security vulnerabilities in dependencies today often manifest as security vulnerabilities in the application using the dependencies.

This also creates a tension between developer productivity and security, since as new features are added to an application, the trusted computing base grows larger. Inevitably the need for greater functionality and productivity trumps 

This is a dumb way to build modern software, because it makes application unnecessarily fragile


 An enormous amount of software
is written in C/C++, including the native code underlying many modules in ``safe''
languages such as Python. In these settings a vulnerability in any part
of the application, or its libraries often compromises the entire application.


Code bases evolve.
We have come to view this tension between security and functionality or even
productivity, and this is not fundamental, its an artifact of monolithic
application architectures. <Example showing how functionality can be
added without diminishing security>

Why your code should be sandboxed.

-because third party libraries
-because code quality varies e.g., outsource, legacy code, blah. and
 shouldn't be security critical.
-because securing code is difficult/to impossible, slows down feature
velocity, and is expensive, and lots of people just don't do it.

\section{Why now is the time for more sandboxing?}



\section{Secure Sandboxing for Everyone}
-existing approaches coarse grain/manaul
-security is hard blah (some code examples from rlbox paper section 3?)
-porting is hard blah (want to minimize changes to libraries and application)
-leverage C++ types/compiler/etc. support to make this usable.

\section{The beautiful future}
-common framwork for sandboxing as part of language ecosystem
-other languages?


\section{}