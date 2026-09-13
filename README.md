# Achlys

**A systems programming language, native performance, and zero-dependency distribution.**

---

## What is Achlys?

Achlys is a compiled, self-hosting programming language with a Latin-derived syntax and an LLVM backend. It targets the intersection of security tooling, systems programming, and native performance — with a distribution model that produces single, standalone executables requiring no runtime, no VM, and no external dependencies.

The compiler is written in Achlys itself. The language compiles itself.

---

## Core Properties

- **Compiled to native code** via LLVM — no interpreter, no garbage collector, no runtime overhead
- **Self-hosting** — the Achlys compiler is written in Achlys
- **Single-binary distribution** — ship one file, run anywhere
- **Direct memory access** — raw pointer arithmetic, hardware port I/O, MMIO, inline syscalls
- **No dependencies** — the compiler binary is under 2MB
- **Latin syntax** — terse, expressive, and consistent

---

## Built-in Capabilities

| Domain | What's included |
|---|---|
| Systems | Direct memory access, hardware port I/O, inline x86 syscalls, bare-metal support |
| Networking | Socket primitives, packet construction, raw network I/O |
| Graphics | Raylib integration for 2D/3D rendering and GUI tools |
| File I/O | Full read/write, file streaming |
| Interop | C FFI via LLVM IR — call any C library directly |
| Compiler | Self-hosting — `Achlys.nox` compiles itself |

---

## The Ouroboros Model

Most interpreted languages distribute as source + runtime. Achlys uses a different model:

```
your_tool.nox
  → Achlys compiler reads and compiles it
  → Produces native binary via LLVM + clang
  → Binary is standalone — no Achlys installation required on the target
```

One file. No dependencies. Runs on any compatible system. This makes Achlys-built tools genuinely portable in a way that Python, Ruby, or Lua tools are not.

---

## What You Can Build

- Port scanners and network reconnaissance tools
- Custom exploit frameworks and proof-of-concept utilities
- Packet crafters and protocol fuzzers
- HTTP servers and reverse proxies
- GUI  dashboards (via Raylib)
- System utilities and automation scripts
- 2D/3D games and simulations
- Bare-metal OS components

---

## Why Achlys?

**For security professionals:** Most languages treat networking and low-level access as afterthoughts, bolted on through libraries. Achlys exposes syscalls, sockets, and memory directly — the same primitives exploit developers need — without requiring you to drop into C.

**For systems programmers:** Simpler than C for most tasks. More direct than Rust when you know what you're doing. Full control over memory and hardware with a cleaner syntax.

**For students and educators:** The Latin syntax is not a gimmick. Classical Latin is precise, minimal, and consistent — the same properties that make good programming languages. Achlys makes that connection explicit.

**For tool builders:** The single-binary output means your tool is exactly one file. No `pip install`, no `cargo install`, no version conflicts on the target machine.

---

## Syntax Sample

```nox
// Read a file and print its length
vas path : str -> "target.txt" ^
vas content : str -> revelare(path) ^
vas size : int -> mensura(content) ^
insusurro("File size: " + size) ^
```

```nox
// Define and call a function
opus add(a, b) {
    reddo a + b ^
}

vas result : int -> add(10, 20) ^
insusurro(result) ^
```

---

## Language Keywords

| Latin | Meaning |
|---|---|
| `vas` | variable declaration |
| `opus` | function definition |
| `reddo` | return |
| `si` / `aliter` | if / else |
| `dum` | while loop |
| `insusurro` | print |
| `revelare` | read file |
| `inscribo` | write file |
| `mensura` | length/size |

---

## Status

Achlys is under active development. The compiler is self-hosting and produces working LLVM IR. Networking, file I/O, and basic graphics are functional. The following are on the roadmap:

- Float/decimal type support
- Static type checker
- Module system with proper namespacing
- Standard library (strings, collections, math, crypto)
- Package manager
- VS Code language extension (syntax highlighting, LSP)
- Async/concurrency primitives

---

## Get Started

```bash
# Compile any .nox file
./achlys your_program.nox

# Output: standalone native binary
./out
```

---

*Achlys — From the void, native binaries.*
