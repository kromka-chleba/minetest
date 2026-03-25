# C++ Learning Guide for New Minetest Contributors

> Aimed at developers who know Lua but are new to C++.

---

## C++ Standard & Compiler Requirements

Minetest targets **C++17** (`CMakeLists.txt`):

```cmake
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)
```

Minimum compilers: **GCC 7.5** or **Clang 7.0.1**.

---

## C++ Features to Learn (Prioritized)

### Priority 1 — Core Concepts (Start Here)

| Feature | Why Minetest Uses It | Example in Codebase |
|---|---|---|
| **Classes & Inheritance** | Every subsystem is a class hierarchy | `IGameDef` in `src/gamedef.h` |
| **Virtual functions** | Server and Client both implement the same interface (`IGameDef`) | `virtual void step(f32 dtime) = 0` in `src/environment.h` |
| **`override` / `final` keywords** | Safely overriding base class methods | 500+ uses in headers, e.g. `src/server.h` |
| **Headers (`.h`) vs Implementation (`.cpp`)** | All classes split across two files | Every `.h`/`.cpp` pair in `src/` |
| **Namespaces** | Grouping related code | `namespace server`, `namespace client` |
| **`const` correctness** | Methods that don't mutate state are marked `const` | Everywhere |
| **References (`&`) and pointers (`*`)** | Passing objects without copying | Function arguments throughout |

> **Lua analogy:** C++ classes with virtual methods are like Lua objects using `__index` metatables, but checked at compile time.

---

### Priority 2 — Memory Management (Critical for C++)

| Feature | Why Minetest Uses It | Example |
|---|---|---|
| **`std::unique_ptr`** | Single-owner pointers (most common) | `std::make_unique<MetricsBackend>()` in `src/server.cpp` |
| **`std::shared_ptr`** | Shared ownership (less common) | `std::make_shared<NodeBoxConnected>()` in `src/nodedef.h` |
| **RAII** | Resources tied to object lifetime | `MutexAutoLock lock(m_mutex)` in `src/util/container.h` — lock auto-releases when scope ends |
| **Move semantics (`std::move`)** | Transferring ownership without copying | `std::make_unique<SSCSMController>(std::move(thread), channel)` |

> **Lua analogy:** Lua manages memory for you via GC. In C++, you do it via RAII and smart pointers. `unique_ptr` = "I own this, nobody else does."

---

### Priority 3 — STL (Standard Template Library)

These containers replace Lua's tables:

| Container | Lua Equivalent | Minetest Usage |
|---|---|---|
| `std::vector<T>` | Array-like table `{1,2,3}` | Lists of objects, render queues |
| `std::unordered_map<K,V>` | Hash table `{key=value}` | Player lookup, node registry (`src/server.h`) |
| `std::map<K,V>` | Sorted hash table | Ordered registries |
| `std::unordered_set<K>` | Set of unique values | Tracking active connections |
| `std::string` | Lua string | Everywhere |
| `std::string_view` | Non-owning string ref | `src/serialization.h`, `src/metadata.h` |
| `std::optional<T>` | `nil`-able value | `std::optional<float> getTime(int rating)` in `src/tool.h` |

---

### Priority 4 — Templates

Minetest uses templates extensively for generic, reusable data structures:

```cpp
// src/activeobjectmgr.h
template <typename T>
class ActiveObjectMgr { ... };

// src/util/container.h
template<typename Key, typename Value>
class MutexedMap { ... };
```

**What to learn:**
- Function templates: `template<typename T> T foo(T x)`
- Class templates
- `auto` keyword and type deduction
- Range-based `for` loops: `for (auto &item : container)`

---

### Priority 5 — Lambdas & `std::function`

Used heavily for callbacks, especially in the Lua API and active object stepping:

```cpp
// src/script/lua_api/l_env.cpp
auto include_obj_cb = [](ServerActiveObject *obj){ return !obj->isGone(); };

// src/activeobjectmgr.h
virtual void step(float dtime, const std::function<void(T *)> &f) = 0;
```

> **Lua analogy:** Lambdas are essentially anonymous functions, just like `function() ... end` in Lua.

---

### Priority 6 — Multithreading

Minetest is heavily multithreaded (server, mapgen, emerge, async scripting all run on separate threads):

| Primitive | Purpose | Where Used |
|---|---|---|
| `std::mutex` | Mutual exclusion lock | `src/threading/thread.h` |
| `std::unique_lock` / `MutexAutoLock` | RAII lock guard | `src/util/container.h` |
| `std::atomic<T>` | Lock-free thread-safe variables | `src/server.h` |
| `std::condition_variable` | Thread signaling | `src/server.h` |
| `std::shared_mutex` | Reader-writer lock | `src/server.h` |
| `std::thread` | Raw thread | `src/threading/thread.h` |

---

### Priority 7 — C++17 Specific Features

| Feature | Minetest Usage |
|---|---|
| `std::optional<T>` | `src/environment.h` — optional pointabilities |
| `std::string_view` | `src/server.h` — non-owning strings |
| `std::shared_mutex` | `src/server.h` — read-write locking |
| `if constexpr` | Template metaprogramming |
| Structured bindings (`auto [a, b] = pair`) | Iterating maps |
| `constexpr` | `constexpr u8 SER_FMT_VER_INVALID = 255` in `src/serialization.h` |

---

### Priority 8 — Design Patterns Used

| Pattern | Where | Description |
|---|---|---|
| **Abstract Interface** | `src/gamedef.h` (`IGameDef`) | Both Client & Server implement the same interface |
| **Observer** | `src/map.h` (`MapEventReceiver`) | Server listens for map edit events |
| **Factory** | `src/client/render/factory.cpp` | Creates render pipelines |
| **Singleton** | `src/client/sound/sound_singleton.h` | Sound manager |
| **RAII Wrapper** | `src/threading/mutex_auto_lock.h` | Locks auto-release on scope exit |
| **Strategy** | `src/serialization.h` | Pluggable compression (zlib/zstd) |
| **State Machine** | `src/client/client.h` (`LocalClientState`) | Client lifecycle states |

---

## Most Used Frameworks & Libraries

| Library | Purpose | Type |
|---|---|---|
| **IrrlichtMt** | 3D graphics engine (custom Irrlicht fork) | Core — Rendering |
| **Lua / LuaJIT** | Mod scripting engine | Core — Scripting |
| **SQLite3** | Default world/player database | Core — Storage |
| **zlib** | Map data compression | Core |
| **zstd** (Zstandard) | Faster map compression | Core |
| **nlohmann/JSON** | JSON parsing | Core — Config & API |
| **GMP** | Big integer math | Core |
| **cURL** | HTTP for server list, content browser | Client |
| **OpenAL** | 3D positional audio | Client |
| **libvorbis/libogg** | OGG audio format | Client |
| **FreeType** | Font rendering in GUI | Client |
| **OpenSSL** | SHA hashing, TLS | Server |
| **PostgreSQL** | Advanced database backend | Optional |
| **LevelDB** | High-performance DB backend | Optional |
| **Redis** | Cache/storage backend | Optional |
| **ncurses** | Server terminal UI | Optional |
| **Tracy** | Performance profiler | Optional |
| **Catch2** | Unit testing framework | Tests (`src/unittest/`) |
| **Prometheus** | Metrics/monitoring | Optional |
| **tiniergltf** | glTF 3D model loading | Core — Models |

---

## Which Subsystem to Start With (by Difficulty)

| Subsystem | Folder | Difficulty | C++ Knowledge Needed |
|---|---|---|---|
| **Content Definitions** | `src/itemdef.h`, `src/nodedef.h` | ⭐ Easy | Classes, STL, `std::optional` |
| **Scripting / Lua API** | `src/script/lua_api/` | ⭐⭐ Medium | Lua C API, templates, callbacks |
| **Map/Voxel System** | `src/map.h`, `src/mapblock.h` | ⭐⭐ Medium | Serialization, STL, threads |
| **Active Objects/Entities** | `src/activeobjectmgr.h` | ⭐⭐ Medium | Templates, smart pointers |
| **Networking** | `src/network/` | ⭐⭐⭐ Hard | Sockets, binary serialization, threads |
| **Mapgen** | `src/mapgen/` | ⭐⭐⭐ Hard | Math, algorithms, threading |
| **Rendering** | `src/client/render/` | ⭐⭐⭐⭐ Expert | OpenGL, Irrlicht, shaders |

---

## Recommended Learning Path (Lua → C++)

1. **C++ basics** — variables, functions, loops (same concepts as Lua, different syntax)
2. **Classes and objects** — `class`, constructors, destructors
3. **Pointers and references** — the biggest conceptual leap from Lua
4. **`std::string`, `std::vector`, `std::map`** — your new Lua tables
5. **Smart pointers** — `unique_ptr` and `shared_ptr` before touching any Minetest code
6. **Virtual functions and inheritance** — how `IGameDef` works
7. **Templates** — generic programming, used everywhere
8. **Lambdas** — you already know anonymous functions from Lua!
9. **Multithreading** — mutex, atomic, condition_variable
10. **Lua C API** — since you know Lua, the `src/script/` layer will feel familiar

**Recommended books:**
- *A Tour of C++* by Bjarne Stroustrup — concise modern C++ overview
- *Effective Modern C++* by Scott Meyers — C++11/14/17 idioms and best practices
