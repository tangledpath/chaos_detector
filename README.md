# chaos_detector
---
Detect and graph dependencies between ruby modules using [TracePoint](https://ruby-doc.org/core-2.7.2/TracePoint.html)

Infers dependencies during execution rather than source code analysis, which is prohibively difficult due to Ruby's numerous metaprogramming features.

Techniques inspired and borrowed from [rubydeps](https://github.com/tangledpath/rubydeps) and earlier ruby gems that use native code rather than TracePoint (Daniel Cadenas, other contribs)

# TODO
Doc usage
