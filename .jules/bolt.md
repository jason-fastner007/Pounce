# Bolt's Journal - Critical Learnings

## 2025-05-18 - Fast Enum Lookups in CamelotKey
**Learning:** In Dart, iterating over `enum.values` in hot paths (like key detection and harmonic scoring across hundreds of DJ tracks) creates repeated linear array scans ($O(n)$) and string allocations. Pre-computing lookup maps (`Map<String, Enum>`) and fixed-index arrays (`List<Enum>`) reduces lookups to $O(1)$ constant time with zero dynamic allocation.
**Action:** When working with enum lookups by string code or index property, always pre-compute static maps or index arrays in a static lazy field or initializer.
