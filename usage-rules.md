<!--
SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Rules for working with Diffo

## What Diffo is

Diffo is an Ash Framework layer that models [TM Forum](https://www.tmforum.org/) (TMF) Service
and Resource Management domains on top of a Neo4j graph database. It provides three base
fragments — `BaseInstance`, `BaseParty`, `BasePlace` — plus the unified `Diffo.Provider.Extension`
DSL. Read these rules and the Ash/AshNeo4j usage rules **before** writing any domain code.

## The three kinds of domain resource

| Kind | Base fragment | Marker extension |
|---|---|---|
| Instance (service or resource) | `Diffo.Provider.BaseInstance` | `Diffo.Provider.Instance.Extension` |
| Party (organisation, person, entity) | `Diffo.Provider.BaseParty` | `Diffo.Provider.Party.Extension` |
| Place (site, address, location) | `Diffo.Provider.BasePlace` | `Diffo.Provider.Place.Extension` |

All three kinds use the same unified `Diffo.Provider.Extension` DSL with a single `provider do`
section. The marker extensions are zero-section extensions used only for kind identification
via `Ash.Resource.Info.extensions/1` — they carry no DSL of their own.

Do **not** use plain `Ash.Resource` + `AshNeo4j.DataLayer` directly for domain resources.
Always start from the appropriate base fragment:

```elixir
defmodule MyApp.BroadbandService do
  use Ash.Resource, fragments: [Diffo.Provider.BaseInstance], domain: MyApp.Domain
  ...
end
```

## The unified `provider do` DSL

All DSL declarations live inside a single `provider do` block. The sections available
depend on the resource kind:

- **Instance** — `specification`, `characteristics`, `features`, `pools`, `parties`, `places`, `behaviour`
- **Party** — `instances`, `parties`, `places`
- **Place** — `instances`, `parties`, `places`

Verifiers enforce that each kind uses only the sections relevant to it.

### `specification do` — Instance only

Declares the TMF Specification for this Instance kind. The `id` is a **stable UUID4 that
must be the same in every environment** — generate it once and never change it. A new major
version requires a new module with a new `id`.

```elixir
provider do
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

### `characteristics do` — Instance only

Declares typed value slots. Each characteristic is a `Diffo.Provider.BaseCharacteristic`-derived
Ash resource with direct typed attributes. A companion `<Module>.Value` TypedStruct (using
`AshJason.TypedStruct`) drives ordered JSON encoding via a `:value` calculation. Do **not**
add plain Ash attributes for data that belongs in a characteristic.

```elixir
provider do
  characteristics do
    characteristic :downstream_speed, MyApp.SpeedCharacteristic
    characteristic :access_technology, MyApp.AccessTechnologyCharacteristic
    characteristic :ports, {:array, MyApp.PortCharacteristic}
  end
end
```

Each characteristic module uses `Diffo.Provider.BaseCharacteristic` as a fragment and declares
its own attributes, a `:value` calculation, and create/update actions:

```elixir
defmodule MyApp.SpeedCharacteristic do
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: MyApp.Domain

  attributes do
    attribute :downstream_mbps, :integer, public?: true
    attribute :upstream_mbps, :integer, public?: true
  end

  calculations do
    calculate :value, Diffo.Type.CharacteristicValue,
              Diffo.Provider.Calculations.CharacteristicValue do
      public? true
    end
  end

  actions do
    create :create do
      accept [:name, :downstream_mbps, :upstream_mbps]
      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [:downstream_mbps, :upstream_mbps]
    end
  end

  preparations do
    prepare build(load: [:value])
  end

  jason do
    pick [:name, :value]
    compact true
  end
end

defmodule MyApp.SpeedCharacteristic.Value do
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  typed_struct do
    field :downstream_mbps, :integer
    field :upstream_mbps, :integer
  end

  jason do
    pick [:downstream_mbps, :upstream_mbps]
    compact true
  end
end
```

### `features do` — Instance only

Declares optional capabilities, each with an enabled/disabled default and optionally its
own typed characteristic payload.

```elixir
provider do
  features do
    feature :voice, is_enabled?: false
    feature :static_ip, is_enabled?: false do
      characteristic :ip_address, MyApp.IpAddress
    end
  end
end
```

### `parties do` — all kinds, different keywords per kind

**For Instance kinds** use `party`, `parties`, and `party_ref`:

```elixir
provider do
  parties do
    party :provider, MyApp.RSP              # singular, direct edge
    parties :installer, MyApp.Engineer, constraints: [min: 1, max: 3]  # plural
    party_ref :owner, MyApp.Organization    # reference — no direct edge
    party :operator, MyApp.RSP, calculate: :derive_operator  # calculated
  end
end
```

- `party` — singular (at most one); creates a `PartyRef` edge on build.
- `parties` — plural; accepts `constraints: [min: n, max: m]`.
- `party_ref` — no direct `PartyRef` edge is created; the party is reachable by graph
  traversal. Do not add a `PartyRef` relationship manually when `party_ref` is declared.
- `calculate:` — names an Ash calculation on this resource that produces the party struct at
  build time. Runs inside `build_before/1`; do not call it manually.

**For Party and Place kinds** use `role`:

```elixir
provider do
  parties do
    role :employer, MyApp.Organization
  end
end
```

### `places do` — all kinds, different keywords per kind

Mirrors `parties do` in structure. For Instance kinds: `place`, `places`, `place_ref`.
For Party/Place kinds: `role`.

```elixir
# Instance
provider do
  places do
    place :installation_site, MyApp.GeographicSite
    places :coverage_areas, MyApp.GeographicLocation, constraints: [min: 1]
    place_ref :billing_address, MyApp.GeographicAddress
  end
end

# Party or Place
provider do
  places do
    role :headquarters, MyApp.GeographicSite
  end
end
```

### `instances do` — Party and Place only

Declares the Instance kinds this Party or Place kind plays a role with respect to.
Use `role` for a direct relationship, `instance_ref` for a reference (no direct edge).

```elixir
provider do
  instances do
    role :provider, MyApp.BroadbandService
    role :provider, MyApp.VoiceService
    instance_ref :manages, MyApp.InternalService
  end
end
```

Role names are domain nouns from the party's/place's perspective — timeless,
`snake_case` atoms. Use `camelCase` atoms for multi-word names that follow TMF
conventions (e.g. `:dataCentre`, not `:data_centre`).

### `pools do` — Instance only

Declares named assignable pools. Each pool maps to a `Diffo.Provider.AssignableCharacteristic`
node that is created automatically during the `build` action. Use this instead of declaring
`characteristic :name, AssignableCharacteristic` in `characteristics do`.

```elixir
provider do
  pools do
    pool :cores, :core   # pool name :cores, thing name :core
    pool :ports, :port
  end
end
```

- **`pool name, thing`** — `name` is the pool atom (also the AssignableCharacteristic name);
  `thing` is the atom identifying what is being assigned within the pool (stored on assignment
  Relationships as the `thing` attribute).
- Pool bounds (`first`, `last`, `algorithm`, `assignable_type`) are set via `Pool.update_pools/3`
  in a `:define` action; they are not declared in the DSL.
- Each Instance module gets `pools/0` (list of declarations) and `pool/1` (lookup by name)
  generated at compile time.

In the `:define` action, apply updates for both characteristics and pools:

```elixir
update :define do
  argument :characteristic_value_updates, {:array, :term}

  change after_action(fn changeset, result, _context ->
    with {:ok, result} <- Characteristic.update_all(result, changeset, characteristics()),
         {:ok, result} <- Pool.update_pools(result, changeset, pools()),
         {:ok, result} <- MyDomain.get_by_id(result.id),
         do: {:ok, result}
  end)
end
```

In assignment actions, use `Assigner.assign/3` (thing is looked up from the pool declaration):

```elixir
update :assign_core do
  argument :assignment, :struct, constraints: [instance_of: Assignment]

  change after_action(fn changeset, result, _context ->
    with {:ok, result} <- Assigner.assign(result, changeset, :cores),
         {:ok, result} <- MyDomain.get_by_id(result.id),
         do: {:ok, result}
  end)
end
```

### `behaviour do` — Instance only

Marks a named create action for build wiring. Declaring `create :name` injects the
`:specified_by`, `:features`, and `:characteristics` Ash action arguments automatically.
Do **not** declare these arguments in the action body.

```elixir
provider do
  behaviour do
    actions do
      create :build
    end
  end
end
```

## Generated functions on Instance resources

Every resource with a complete `specification do` block gets these compile-time generated
functions:

- `specification/0`, `characteristics/0`, `features/0`, `pools/0`, `parties/0`, `places/0`
- `characteristic/1`, `feature/1`, `feature_characteristic/2`, `pool/1`, `party/1`, `place/1`
- `build_before/1` — upserts the Specification node; creates Feature, Characteristic, and
  Party nodes; sets action argument ids. Called automatically before every create action.
- `build_after/2` — relates the created TMF entities to the new instance node. Called
  automatically after every create action.

**Never call `build_before/1` or `build_after/2` manually** in action bodies or changesets.
They are wired to every create action via global `BuildBefore` and `BuildAfter` changes on
`BaseInstance`.

## Runtime introspection

Use `Diffo.Provider.Extension.Info` to introspect any provider resource at runtime:

```elixir
Diffo.Provider.Extension.Info.provider_parties(MyApp.BroadbandService)
Diffo.Provider.Extension.Info.provider_places(MyApp.BroadbandService)
Diffo.Provider.Extension.Info.provider_instances(MyApp.RSP)
Diffo.Provider.Extension.Info.instance?(MyApp.BroadbandService)  # true
Diffo.Provider.Extension.Info.party?(MyApp.RSP)                  # true
```

The old `Instance.Extension.Info`, `Party.Extension.Info`, and `Place.Extension.Info`
modules are still available as thin delegating wrappers for backwards compatibility.

## Instance versioning

- **Minor/patch version bumps** — update `minor_version` or `patch_version` in `specification do`.
  The existing Specification node is updated in place. No instance changes required.
- **Major version bump** — create a new module (e.g. `BroadbandServiceV2`) with a new `id`
  and `major_version 2`. The original module and all its instances remain untouched.
- **Never change the `id`** of an existing specification. It is a stable cross-environment
  identity; changing it orphans existing instances.

## Complete example

```elixir
# Instance resource
defmodule MyApp.BroadbandService do
  use Ash.Resource, fragments: [Diffo.Provider.BaseInstance], domain: MyApp.Domain

  resource do
    description "An ADSL broadband service"
    plural_name :broadband_services
  end

  provider do
    specification do
      id "da9b207a-26c3-451d-8abd-0640c6349979"
      name "broadbandService"
      type :serviceSpecification
      major_version 1
      category "Network Service"
    end

    characteristics do
      characteristic :circuit, MyApp.CircuitValue
    end

    parties do
      party :provider, MyApp.RSP
      party_ref :owner, MyApp.Organization
    end

    places do
      place :installation_site, MyApp.GeographicSite
    end

    behaviour do
      actions do
        create :build
      end
    end
  end

  actions do
    create :build do
      accept [:name]
      argument :parties, {:array, :struct}
      argument :places, {:array, :struct}
    end
  end
end

# Party resource
defmodule MyApp.RSP do
  use Ash.Resource, fragments: [Diffo.Provider.BaseParty], domain: MyApp.Domain

  resource do
    description "A Retail Service Provider"
    plural_name :rsps
  end

  provider do
    instances do
      role :provider, MyApp.BroadbandService
    end
    parties do
      role :employer, MyApp.Organization
    end
  end

  actions do
    create :build do
      accept [:id, :name]
      change set_attribute(:type, :Organization)
    end
  end
end

# Place resource
defmodule MyApp.GeographicSite do
  use Ash.Resource, fragments: [Diffo.Provider.BasePlace], domain: MyApp.Domain

  resource do
    description "A geographic site"
    plural_name :geographic_sites
  end

  provider do
    instances do
      role :installation_site, MyApp.BroadbandService
    end
    parties do
      role :managed_by, MyApp.RSP
    end
  end

  actions do
    create :build do
      accept [:id, :name]
      change set_attribute(:type, :GeographicSite)
    end
  end
end
```

## Common mistakes

- **Do not use `structure do` or top-level `instances do`/`parties do`/`places do`** — these
  are the old pre-0.3.0 syntax. All declarations belong inside `provider do`.
- **Do not use `party :role, Type, reference: true`** — use `party_ref :role, Type` instead.
- **Do not use `place :role, Type, reference: true`** — use `place_ref :role, Type` instead.
- **Do not add raw Ash attributes for TMF-modelled data** — use `characteristics`, `features`,
  `parties`, and `places` in the DSL instead.
- **Do not declare `:specified_by`, `:features`, or `:characteristics` Ash action arguments**
  — the `behaviour do` block injects them automatically.
- **Do not call `build_before/1` / `build_after/2` yourself** — they run automatically.
- **Do not create a separate Specification resource manually** — the Specification node is
  managed entirely by the `build_before/1` generated function.
- **Do not use `party/1` in place of `parties/3`** (and vice versa) — `party` declares a
  singular role; `parties` declares a plural role. Mismatching causes compile-time errors.
- **Do not use `characteristic :name, Diffo.Provider.AssignableCharacteristic`** for assignable
  pools — use `pools do / pool :name, :thing / end` instead. The `pools do` section creates the
  `AssignableCharacteristic` node automatically during `build` and generates `pools/0` / `pool/1`.
- **Do not use the old `AssignableValue` TypedStruct** — it is removed. Use `pools do`.
- **Do not call `Assigner.assign/4` when a pool declaration exists** — prefer `Assigner.assign/3`
  which looks up the thing name from the pool automatically. `assign/4` is still available for
  cases without a `pools do` declaration.
- **Do not query `Diffo.Provider.Relationship` for `type: :assignedTo` records** — assignment
  relationships live on `Diffo.Provider.AssignedToRelationship`. Access them via `instance.assignments`.
- **Do not filter `instance.forward_relationships` for `type == :assignedTo`** — those records no
  longer exist there. `forward_relationships` contains only regular TMF relationships;
  `assignments` contains pool assignment relationships.
