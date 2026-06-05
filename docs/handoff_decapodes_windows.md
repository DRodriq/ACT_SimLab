# Handoff: Field Path (Decapodes) — Windows TetGen Blocker, Bug Report, Resume Plan

Drop-in context to resume **Phase 1 (grass as a Decapodes field)** in a fresh session — likely in a
new environment (WSL2). Self-contained: the blocker, the ready-to-file bug report, where to post it,
the Step-0 work already done, and a resume checklist. Pairs with `roadmap.md` (the plan),
`compositionality.md`, `dynamics_field_guide.md`, `journal.md`.

---

## TL;DR

- The population substrate works (LV / grass / Rosenzweig–MacArthur all validated; see `journal.md`).
- Phase 1 = promote **grass** from a Petri species to a **Decapodes field**, coupled to the Petri
  populations by grazing.
- **Gating compat check passed on resolution:** `Decapodes 0.6.8` / `CombinatorialSpaces 0.10.0` /
  `DiagrammaticEquations 0.2.6` co-resolve with `Catlab 0.17.5` / `AlgebraicPetri 0.10.0` **unchanged**
  — one environment, no fork.
- **But blocked on Windows:** `TetGen_jll` `SIGABRT`s on `dlopen` (mingw pseudo-relocation).
  Reproduced **identically on Julia 1.11.7 AND 1.10.11** → version-independent, it's the binary.
- **Resolution:** move the field path to **WSL2/Linux** (durable). Interim alternative: do Phase 2
  (characterization spine) on Windows, which needs no Decapodes. File the upstream bug regardless.

---

## The blocker (full detail)

`TetGen` is a **hard `[deps]`** of `CombinatorialSpaces` 0.10.0 (used for 3-D tetrahedralization —
which we never call; we need 1-D/2-D meshes). It loads unconditionally, so the package can't load on
Windows at all.

**Minimal reproduction** (fresh temp env, no other packages):
```julia
import Pkg; Pkg.activate(temp=true); Pkg.add("TetGen_jll"); using TetGen_jll   # SIGABRT here
```

**Error (abridged):** `signal 22: SIGABRT` → `__report_error` / `do_pseudo_reloc` /
`_pei386_runtime_relocator` (mingw-w64 pseudo-relocation) → `__DllMainCRTStartup` → `LdrLoadDll` →
`LoadLibraryExW` → `ijl_dlopen` → `TetGen_jll.__init__`. The DLL fails to load at runtime.

**Environment:** Windows 11 Home 10.0.26200; Julia **1.11.7** and **1.10.11** (both fail identically);
`x86_64-w64-mingw32`; `TetGen_jll v1.6.0+1`.

**Confirmed NOT the cause:** version resolution (clean); Julia minor version (both fail); our project
(fails in an empty temp env).

---

## Ready-to-file bug report

> **Title:** `TetGen_jll` SIGABRTs on load on Windows (Julia 1.10 & 1.11): mingw pseudo-relocation
> failure during `dlopen` — blocks CombinatorialSpaces/Decapodes
>
> **Summary.** On Windows, `using TetGen_jll` aborts the process with `SIGABRT` inside mingw-w64's
> pseudo-relocation code while `dlopen`-ing the TetGen library in the JLL's `__init__`. Because
> `TetGen` is a hard dependency of `CombinatorialSpaces`, this makes `CombinatorialSpaces` (and thus
> `Decapodes`) fail to load on Windows entirely.
>
> **Environment.** Windows 11 Home build 10.0.26200; Julia **1.11.7** and **1.10.11** (reproduced on
> both); `x86_64-w64-mingw32`; `TetGen_jll v1.6.0+1`; downstream `CombinatorialSpaces v0.10.0`,
> `Decapodes v0.6.8`.
>
> **Minimal reproduction** (no project, no other packages):
> ```julia
> import Pkg
> Pkg.activate(temp=true)
> Pkg.add("TetGen_jll")
> using TetGen_jll   # <-- aborts here
> ```
>
> **Error output (abridged):**
> ```
> [NNNNN] signal 22: SIGABRT
> __report_error at .../mingw-w64-crt/crt/pseudo-reloc.c:157
> do_pseudo_reloc at .../mingw-w64-crt/crt/pseudo-reloc.c:457 [inlined]
> _pei386_runtime_relocator at .../mingw-w64-crt/crt/pseudo-reloc.c:501
> __DllMainCRTStartup at .../mingw-w64-crt/crt/crtdll.c:170
> LdrLoadDll at ntdll.dll ; LoadLibraryExW at KERNELBASE.dll
> ijl_dlopen at C:/workdir/src/dlload.c:166
> __init__ at .../TetGen_jll/.../wrappers/x86_64-w64-mingw32.jl:8
> ```
>
> **What I've checked.** Not a version-resolution problem (`TetGen_jll`/`CombinatorialSpaces`/
> `Decapodes` resolve cleanly with `Catlab 0.17.5`/`AlgebraicPetri 0.10.0`). Not Julia-version
> specific (1.11.7 and 1.10.11 both abort). Failure is at load-time `__init__ → dlopen` (the binary's
> pseudo-relocation), not Julia code. `TetGen` is a hard `[deps]` of `CombinatorialSpaces`, so it
> can't be skipped by users who only need 1-D/2-D meshes.
>
> **Questions.** (1) Known issue / known-good `TetGen_jll` build on Windows? (2) Could `TetGen` be a
> weak dependency / extension of `CombinatorialSpaces`, so the package loads on Windows without 3-D
> meshing?

**Where to post (in order):**
1. **AlgebraicJulia Zulip** (linked from <https://github.com/AlgebraicJulia>) — fast triage; ask if
   known + workaround. Maintainers (Patterson, Fairbanks, Morris) are active.
2. **GitHub issue at `AlgebraicJulia/CombinatorialSpaces.jl`** — for the record; include question (2),
   the weakdep ask (the mitigation they own). Highest-value target for unblocking.
3. Root cause is the JLL (`TetGen_jll`, built via JuliaPackaging/Yggdrasil) and the `TetGen.jl`
   wrapper — file there only if CombinatorialSpaces maintainers route it that way (confirm exact repo
   slugs from the dependency, don't guess).

---

## Step 0 already done — dimensional reconciliation (don't lose this)

Promoting grass from a Petri **amount-per-tile** `Gᵢ` to a DEC **density** (0-form) `gᵢ`, via the
dual-cell area `Aᵢ`: **`Gᵢ = Aᵢ·gᵢ`**.

| quantity | Petri (amount/tile) | DEC field (density) | mapping |
|---|---|---|---|
| growth `r` | `r` | `r_f = r` | unchanged (intensive) |
| carrying capacity `K` | `K` | `K_f = K/A` | ÷ cell area |
| dispersal | `d` hop-rate (was **0**) | `D` `[area/t]` | `D ≈ d·ℓ²` — **new param** |
| grazing — grass sink | `−a·Gᵢ·Pᵢ` | `dgᵢ/dt = −a·gᵢ·Pᵢ` | `a` unchanged |
| grazing — prey source | `+a·Gᵢ·Pᵢ` | `dPᵢ/dt = +a·A·gᵢ·Pᵢ` | **× A** |

**Key insight:** the entire unit mismatch lives in the grazing prey-source term's **cell-area factor
`A`** (grass leaves as density, arrives in prey as amount). A unit-area grid (`A=1`) hides it; mesh
**refinement** exposes it — which is why the KPP-front-convergence and mass-conjugacy gates are the
tests that catch a missing `A`. Mass-conjugacy: `d/dt⟨g⟩|graze = −(1/ε)·d/dt(ΣP)|graze`, `ε=1` for
`grass+prey→2prey`; use DEC-integrated mass `⟨g,1⟩`, not vertex sums.

---

## Resume checklist (in WSL2 or a working environment)

1. **Add the field deps** — they were reverted before the initial commit so the repo stays clean on
   Windows, so the cloned project does NOT contain them yet:
   `] add Decapodes CombinatorialSpaces DiagrammaticEquations`, then `] instantiate`.
2. Confirm `using Decapodes, CombinatorialSpaces` loads — the exact step that `SIGABRT`s on Windows;
   expected to work on Linux/WSL2.
3. **Phase-1 ladder on a 1-D line mesh** (cleanest KPP check), each gated:
   - (a) constant field stationary → `g≡K` exact fixed point (validates no-flux/Neumann BCs).
   - (b) field-only logistic, no diffusion → every vertex → `K`.
   - (c) field-only logistic + diffusion → front speed `c = 2√(rD)`, converging under refinement.
4. Only then couple grazing (hand-coupled RHS over `[grass field ; populations]`); gate: uniform case
   reproduces RM equilibria + mass-conjugacy holds.
5. Then spatial perturbation → expect **fronts, not stripes** (single field doesn't Turing-pattern).
6. Time-box the "express the coupling categorically" step; the working hand-coupled model is the win.

## Project state to be aware of

- The committed/pushed repo (`github.com/DRodriq/ACT_SimLab`, branch `main`) carries the
  **population-only** state — the field deps were reverted before the initial commit so the project
  `instantiate`s cleanly on any platform. **Re-add them on Linux** (checklist step 1). `using SimLab`
  and all population work (LV / grass / RM) run as-is after `instantiate`.
- The pre-field-deps `*.bak` snapshot and a throwaway Julia 1.10.11 exist only on the original
  Windows machine (gitignored / in `%TEMP%`) — not in the repo, irrelevant to the Linux pickup.
