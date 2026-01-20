# Modular Code Structure Guidelines

## File Size Principles
- **Maximum 200-300 lines per file** - Beyond this, consider splitting
- **Single responsibility per file** - Each file should have one clear purpose
- **Cohesive grouping** - Related functionality belongs together
- **Clear naming** - File names should immediately indicate content

## When to Split Files
**Split immediately when:**
- File exceeds 300 lines
- Multiple unrelated concepts are mixed
- You need to scroll to understand the file's purpose
- Tests become difficult to organize
- The file has multiple distinct responsibilities

**Keep together when:**
- Code is tightly coupled and makes no sense separated
- The file is under 100 lines with a single clear purpose
- Splitting would create circular dependencies
- The components are always used together

## Example Organization Pattern
```
src/my-project/
├── main.py                   # Entry point
├── core/                     # Core data structures
│   ├── models.py            # domain models
│   ├── config.py            # configuration handling
│   └── types.py             # shared type definitions
├── services/                 # Business logic
│   ├── processor.py         # main processing pipeline
│   ├── validator.py         # input validation
│   └── transformer.py       # data transformations
├── api/                      # API layer
│   ├── routes.py            # route definitions
│   ├── handlers.py          # request handlers
│   └── middleware.py        # middleware components
└── utils/                    # Shared utilities
    ├── serialization.py     # save/load functionality
    └── debugging.py         # debugging helpers
```

## Package Structure Guidelines
- **Export deliberately** - Only export what's needed by other modules
- **Import specifically** - Use `:use` and `:import-from` with explicit symbols
- **Avoid intern leakage** - Keep internal symbols internal
- **Document interfaces** - Use docstrings for all exported symbols

## Module Communication Patterns
- **Protocol-based design** - Define clear interfaces between modules
- **Dependency injection** - Pass dependencies rather than hard-coding them
- **Event-driven communication** - Use protocols for loose coupling where appropriate
- **Minimal state sharing** - Prefer immutable data and explicit state passing