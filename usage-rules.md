<!--
SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Rules for working with Diffo

## What Diffo is

Diffo is an Ash Framework layer that models [TM Forum](https://www.tmforum.org/) (TMF) Service
and Resource Management domains on top of a Neo4j graph database. It provides three base
fragments — `BaseInstance`, `BaseParty`, `BasePlace` — plus the `Diffo.Provider.Instance.Extension`
and `Diffo.Provider.Party.Extension` DSLs. Read these rules and the Ash/AshNeo4j usage rules
**before** writing any domain code.

## The three kinds of domain resource

| Kind | Base fragment | DSL extension |
|---|---|---|
| Instance (service or resource) | `Diffo.Provider.BaseInstance` | `Diffo.Provider.Instance.Extension` |
| Party (organisation, person, entity) | `Diffo.Provider.BaseParty` | `Diffo.Provider.Party.Extension` |
| Place (site, address, location) | `Diffo.Provider.BasePlace` | `Diffo.Provider.Party.Extension` |

Do **not** use plain `Ash.Resource` + `AshNeo4j.DataLayer` directly for domain resources.
Always start from the appropriate base fragment:

```elixir
defmodule MyApp.BroadbandService do
  use Ash.Resource, fragments: [Diffo.Provider.BaseInstance], domain: MyApp.Domain
  ...
end
```

## Instance Extension DSL

Every resource using `BaseInstance` gains two top-level DSL sections: `structure do` and
`behaviour do`.

### structure

`specification do` — declares the TMF Specification for this Instance kind. The `id` is a
**stable UUID4 that must be the same in every environment** — generate it once and never
change it. A new major version requires a new module with a new `id`.

```elixir
structure do
  specification do
    id "da9b207a-26c3-451d-8abd-0640c6349979"
    name "DSL Access Service"
    type :serviceSpecification
    major_version 1
    description "An access network service connecting a subscriber premises to an NNI via DSL"
    category "Network Service"
  end
end
```

`characteristics do` — declares typed value slots. Each characteristic is backed by an
`Ash.TypedStruct`. Do **not** add plain Ash attributes for data that belongs in a characteristic.

```elixir
characteristics do
  characteristic :downstream_speed, MyApp.Speed
  characteristic :access_technology, MyApp.AccessTechnology
end
```

`features do` — declares optional capabilities, each with an enabled/disabled default and
optionally its own typed characteristic payload:

```elixir
features do
  feature :voice, is_enabled?: false
  feature :static_ip, is_enabled?: false do
    characteristic :ip_address, MyApp.IpAddress
  end
end
```

`parties do` — declares party roles. Use `party` for singular (at most one) and `parties`
for plural relationships:

```elixir
parties do
  party :provider, MyApp.RSP
  parties :installer, MyApp.Engineer, constraints: [min: 1, max: 3]
  party :owner, MyApp.Organization, reference: true
  party :operator, MyApp.RSP, calculate: :derive_operator
end
```

- `reference: true` — no direct `PartyRef` edge is created; the party is reachable by graph
  traversal. Do not add a `PartyRef` relationship manually when `reference: true` is set.
- `calculate:` — names an Ash calculation on this resource that produces the party struct at
  build time. The calculation runs inside `build_before/1`; do not call it manually.

`places do` — mirrors `parties do` in structure and options:

```elixir
places do
  place :installation_site, MyApp.GeographicSite
  places :coverage_areas, MyApp.GeographicLocation, constraints: [min: 1]
end
```

### behaviour

`behaviour do actions do create :name end end` — marks a named create action for build
wiring. This injects the `:specified_by`, `:features`, and `:characteristics` Ash action
arguments automatically. Do **not** declare these arguments in the action body.

```elixir
behaviour do
  actions do
    create :build
  end
end
```

## Generated functions on Instance resources

Every resource with a complete `specification do` block gets these compile-time generated
functions:

- `specification/0`, `characteristics/0`, `features/0`, `parties/0`, `places/0`
- `characteristic/1`, `feature/1`, `feature_characteristic/2`, `party/1`, `place/1`
- `build_before/1` — upserts the Specification node; creates Feature, Characteristic, and
  Party nodes; sets action argument ids. Called automatically before every create action.
- `build_after/2` — relates the created TMF entities to the new instance node. Called
  automatically after every create action.

**Never call `build_before/1` or `build_after/2` manually** in action bodies or changesets.
They are wired to every create action via global `BuildBefore` and `BuildAfter` changes on
`BaseInstance`.

## Instance versioning

- **Minor/patch version bumps** — update `minor_version` or `patch_version` in `specification do`.
  The existing Specification node is updated in place. No instance changes required.
- **Major version bump** — create a new module (e.g. `BroadbandServiceV2`) with a new `id`
  and `major_version 2`. The original module and all its instances remain untouched.
- **Never change the `id`** of an existing specification. It is a stable cross-environment
  identity; changing it orphans existing instances.

## Party and Place resources

Party and Place resources use `BaseParty`/`BasePlace` and the Party Extension DSL to declare
the Instance and Party roles they participate in:

```elixir
defmodule MyApp.RSP do
  use Ash.Resource, fragments: [Diffo.Provider.BaseParty], domain: MyApp.Domain

  instances do
    role :provider, MyApp.BroadbandService
    role :provider, MyApp.VoiceService
  end

  parties do
    role :employer, MyApp.Organization
  end
end
```

Role names are domain nouns from the party's perspective — timeless, `camelCase` when
multi-word (e.g. `:dataCentre`, not `:data_centre`).

## Common mistakes

- **Do not add raw Ash attributes for TMF-modelled data** — use `characteristics`, `features`,
  `parties`, and `places` in the DSL instead.
- **Do not declare `:specified_by`, `:features`, or `:characteristics` Ash action arguments**
  — the `behaviour do` block injects them automatically.
- **Do not call `build_before/1` / `build_after/2` yourself** — they run automatically.
- **Do not create a separate Specification resource manually** — the Specification node is
  managed entirely by the `build_before/1` generated function.
- **Do not use `party/1` in place of `parties/3`** (and vice versa) — `party` declares a
  singular role; `parties` declares a plural role. Mismatching causes compile-time errors.
- **Do not set a `referred_type` without also setting `type: :PartyRef`** — TMF requires
  both fields when using a party reference.
