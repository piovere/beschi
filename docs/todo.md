* functionality
    - defaults as part of protocol? 
        - override objects for each struct/message
        - part of protocol validation: defaults match type
    - have all the frombytes maybe return null?
        - frombytes resets offset if returning null?
    - bool passed to WriteBytes to tag the output?
    - multiple messages from single byte buffer
        - process raw bytes should return a list
    - typescript needs (and probably all of them should have) a way of measuring size in bytes of message object (for allocating buffer, etc.)

* testing framework
    - harness fixes
        - new makefiles
        - make clean; make {basic, broken, etc [test names]}
    - protocol validation
    - graceful handling of broken messages
    - can specify to only test a single language or only run a single test?
    - set up github actions
    - network read/write in each language? yikes.
        - Golang <-> TypeScript
        - Python <-> C#
    - is there some way to test it with big-endian architecture too so we can be sure it's consistent? 
        - qemu or something?
        - how many yaks can be shaved in this project?
    - Japanese/Arabic lorem ipsum

* more writers
    * python
    * C
    * swift?
    * rust? ugh

* command-line flags
    - ignoring messages? (regex match?)
    - indentation as a flag?
    - typescript namespacing?

* generic example protocol (rename "WireMessage")

* redo readme
    - also setup.py
    - note
        - made efforts to follow best practices of target languages as much as possible
        - TS doesn't use namespace by default https://www.typescriptlang.org/docs/handbook/namespaces-and-modules.html
        - TS requires "experimentalDecorators" on
        - TS 64-bit -> bigint (might need es2020, browser support, caniuse)
        - all numbers stored little-endian
        - to make new writer:
            - str and list lengths are uint32 (enough to store more than 4 GB of text in a string -- if that's more than you need, you probably outgrew this system long ago)
            - make sure to count bytes after encoding to utf-8
        - each language has an unattached function that processes a stream of bytes
            - that stream has to be tagged; the first byte is a flag saying what kind of message
            - it will return both the type of message and the decoded message itself, or nulls if it couldn't read it
        - then each type has a static function (or whatever the language can support) that decodes an *untagged" stream, where the first byte starts the message
            - useful if you already know what you'll be receiving and don't need to bother labeling on the sending side
            - returns either the decoded message or null if it couldn't read
    - justification
        - this a custom bit-packing and unpacking code generator for C#, Go, TypeScript, and Python. 
        - cap'n proto and flatbuffers are great, but have functionality I wasn't using and add some overhead as a result
        - simple code -- each generator is only around 200-300 lines of fairly readable imperative code; no mysterious redirections through layers of templates
        - few dependencies -- only toml so far! (maybe could even cut that out and just have a JSON specification? I prefer TOML for lots of reasons)
        - it was kind of fun to write a code generator 😝
    - handles: 
        - protocol definition
        - creation of code in target languages for writing and reading messages <-> sequences of bytes
    - does not handle: 
        - more than 255 types of messages because it uses a byte as the message type flag and 0 is reserved
            - this could obviously be expanded if ever needed
        - checking for variable names that will cause compilation errors
            - if you call a message member "int" you probably won't be happy; don't do that
        - error handling / verification of messages; it would not be too hard to create a checksum message type and do the verifications one level up
        - partial deserialization; for the use case that inspired this library, (a) most messages are very small and (b) I basically *always* want *all* the data. If either of those two things change, I'll re-evaluate the capabilities of this, but honestly, would probably just move to flatbuffers at that point.
        - actual network communication; you have to get the bytes from somewhere and send them somewhere yourself (basic example code is availabe in each language in the example directory)
        - versionining of messages; this is meant for situations where the client and server evolve in lockstep and messages only exist in-flight. if there's any chance these are going to be persisted and have to handle versioning, you're better off using flatbuffers or Cap'n Proto or something like that. 
    - the existing generators are not terribly clever; there's no AST or interesting data structures happening. it just iterates over the structures and writes out code to serialize/deserialize
    - NB: each generator produces valid code in each of the languages, but it may not be the most prettily formatted. If you have strong opinions on that sort of thing, you should run it through a code formatter after it generates. 
    - who beschi?
