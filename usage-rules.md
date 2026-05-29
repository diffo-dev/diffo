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

## The recommended usage pattern

Build your own Ash domain. Do not add your resources to `Diffo.Provider` — that domain is
Diffo's internal plumbing and its API is intentionally closed. Your domain owns its own API,
which it exposes to consumers who need know nothing about Diffo or TMF internals. The Diffo
Provider is an implementation detail that your domain depends on, not something your consumers
touch directly.

```elixir
defmodule MyApp.SRM do
  use Ash.Domain, fragments: [Diffo.Provider.DomainFragment]

  resources do
    resource MyApp.BroadbandService
    resource MyApp.RSP
    resource MyApp.GeographicSite
    resource MyApp.SpeedCharacteristic
  end
end
```

`Diffo.Provider.DomainFragment` is **required** for any domain whose resources use the Diffo
base fragments. It causes AshNeo4j to write `:Provider` as an additional label on every node
in your domain at CREATE time. Without it, Ash's relationship management cannot resolve your
concrete resource nodes (e.g. `BroadbandService`) through the provider base type lookups
(e.g. `Diffo.Provider.Instance`) that Diffo uses internally — the lookups will silently return
not-found and relationships will fail to be established.

See `Diffo.Provider.DomainFragment` for the technical details.

### Neo4j database access policy

Neo4j Browser (or Neo4j Bloom) is an excellent way to **observe** your graph — explore
relationships, verify that nodes have the right labels and properties, debug unexpected
structure. Use it freely for this purpose.

**All data reads and writes must go through Ash and AshNeo4j.** Do not issue Cypher queries
directly from application code, scripts, or migrations to mutate or authoritatively read data.
AshNeo4j manages label consistency, relationship integrity, and type casting; bypassing it
produces nodes that Ash cannot find or interpret correctly.

## The three kinds of domain resource

| Kind | Base fragment | Marker extension |
|---|---|---|
| Instance (Service or Resource) | `Diffo.Provider.BaseInstance` | `Diffo.Provider.Instance.Extension` |
| Party (Organization, Individual) | `Diffo.Provider.BaseParty` | `Diffo.Provider.Party.Extension` |
| Place (GeographicAddress, Site, Location) | `Diffo.Provider.BasePlace` | `Diffo.Provider.Place.Extension` |

All three kinds use the same unified `Diffo.Provider.Extension` DSL with a single `provider do`
section. The marker extensions are zero-section extensions used only for kind identification
via `Ash.Resource.Info.extensions/1` — they carry no DSL of their own.

Do **not** use plain `Ash.Resource` + `AshNeo4j.DataLayer` directly for domain resources.
Always start from the appropriate base fragment:

```elixir
defmodule MyApp.BroadbandService do
  use Ash.Resource, fragments: [Diffo.Provider.BaseInstance], domain: MyApp.SRM
  ...
end
```

### Place subtype fragments (TMF675 cascade)

`BasePlace` composes with one of three subtype fragments to produce a TMF675
concrete Place. Diffo ships the three subtype leaves out of the box and the
matching consumer leaf is a sibling, not a child:

| Subtype | Subtype fragment | Concrete leaf in diffo |
|---|---|---|
| GeographicAddress | `Diffo.Provider.BaseGeographicAddress` | `Diffo.Provider.GeographicAddress` |
| GeographicSite | `Diffo.Provider.BaseGeographicSite` | `Diffo.Provider.GeographicSite` |
| GeographicLocation | `Diffo.Provider.BaseGeographicLocation` | `Diffo.Provider.GeographicLocation` |

```elixir
defmodule MyApp.SydneyExchange do
  use Ash.Resource,
    fragments: [Diffo.Provider.BasePlace, Diffo.Provider.BaseGeographicSite],
    domain: MyApp.SRM
  # consumer-specific attributes / actions here
end
```

Action naming convention on cascade leaves: `:build` for create, `:define` for
update, both accepting the union of base + subtype fields. `:build` sets the
TMF `:type` discriminator automatically.

### Provider.Place is plumbing — use the dispatcher API

`Diffo.Provider.Place` is **kept in core minimally** as the abstract reader
that backs projection bootstrap and PlaceRef-typed placeholders. It is *not*
a TMF subtype recommendation. Production code should use the type-atom
dispatcher on `Diffo.Provider`:

```elixir
# Writes — dispatch on TMF type atom
Diffo.Provider.create_place!(:GeographicSite, %{id: "X", site_type: :exchange})
Diffo.Provider.create_place!(:GeographicAddress, %{id: "Y", country: "AU"})
Diffo.Provider.create_place!(:GeographicLocation, %{id: "Z", location: %Geo.Point{...}})
Diffo.Provider.create_place!(:PlaceRef, %{id: "P", referred_type: :GeographicSite})

# Reads — open-world projection via AshNeo4j.worlds/1
Diffo.Provider.get_place_by_id!(id)          # returns concrete subtype struct
Diffo.Provider.list_places!()                # mixed-subtype list, each projected

# Update / destroy — dispatch on record's struct module
Diffo.Provider.update_place!(record, attrs)
Diffo.Provider.delete_place!(record)
```

### Party subtype fragments (TMF632 cascade)

`BaseParty` composes with one of two subtype fragments to produce a TMF632
concrete Party. Diffo ships the two subtype leaves out of the box and the
matching consumer leaf is a sibling, not a child:

| Subtype | Subtype fragment | Concrete leaf in diffo |
|---|---|---|
| Organization | `Diffo.Provider.BaseOrganization` | `Diffo.Provider.Organization` |
| Individual | `Diffo.Provider.BaseIndividual` | `Diffo.Provider.Individual` |

```elixir
defmodule MyApp.Carrier do
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseParty, Diffo.Provider.BaseOrganization],
    domain: MyApp.SRM
  # consumer-specific attributes / actions here
end
```

Same `:build` / `:define` action naming convention as the Place cascade.

### Provider.Party is plumbing — use the dispatcher API

`Diffo.Provider.Party` is **kept in core minimally** as the abstract reader
that backs projection bootstrap + PartyRef-typed placeholders + `:Entity`
routing. It is *not* a TMF subtype recommendation. Production code should use
the type-atom dispatcher on `Diffo.Provider`:

```elixir
# Writes — dispatch on TMF type atom
Diffo.Provider.create_party!(:Organization, %{id: "ORG-001", trading_name: "Acme"})
Diffo.Provider.create_party!(:Individual, %{id: "IND-001", given_name: "Jane", family_name: "Doe"})
Diffo.Provider.create_party!(:PartyRef, %{id: "REF-001", referred_type: :Organization})
Diffo.Provider.create_party!(:Entity, %{id: "ENT-001", name: "Aggregate"})

# Reads — open-world projection via AshNeo4j.worlds/1
Diffo.Provider.get_party_by_id!(id)          # returns concrete subtype struct
Diffo.Provider.list_parties!()               # mixed-subtype list, each projected

# Update / destroy — dispatch on record's struct module
Diffo.Provider.update_party!(record, attrs)
Diffo.Provider.delete_party!(record)
```

### Polymorphic-source ref API

`PlaceRef` and `PartyRef` use a polymorphic-source dispatcher that collapses
the four-FK source noise into one tagged-tuple `source:` field. The schema is
unchanged (four FK columns stay); only the API surface drops:

```elixir
Diffo.Provider.create_place_ref!(%{
  role: :installation_site,
  source: {:instance, "INST-001"},       # or {:party, ...}, {:place, ...}, or a struct
  target: "LOC-001"                       # or a Place struct
})

Diffo.Provider.list_place_refs_from(source)          # struct or {tag, id}
Diffo.Provider.list_place_refs_targeting(target)     # struct or id
```

### ProjectedRef for cross-resource refs without graph edges

`Diffo.Provider.Calculations.ProjectedRef` is a reusable calculation for
cross-resource references that don't have (and don't need) a graph edge — e.g.
`BaseGeographicSite.address` resolves to a concrete `GeographicAddress` (or
consumer-domain Address leaf) at read time via `AshNeo4j.worlds/1`.

**It does NOT replace `belongs_to`.** AshNeo4j requires a real `belongs_to`
relationship to maintain the Neo4j edge (`verify_relate` enforces this at
compile time). PlaceRef/PartyRef keep all eight typed `belongs_to` intact for
graph integrity; the dispatcher does projection on direct reads instead.

## The unified `provider do` DSL

All DSL declarations live inside a single `provider do` block. The sections available
depend on the resource kind:

- **Instance** — `specification`, `characteristics`, `features`, `pools`, `parties`, `places`, `relationships`, `behaviour`
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
its own attributes and a `:value` calculation. Default `:create` and `:update` actions
covering all public attributes (with `:name` on `:create` only and `:instance_id` /
`:feature_id` arguments wired to `manage_relationship`) are synthesised automatically —
declare your own only when you need a narrower accept list:

```elixir
defmodule MyApp.SpeedCharacteristic do
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: MyApp.SRM

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

For the `:define`, `:relate`, and `:assign_*` action patterns use the bundled change
modules. They wrap the standard after-action plumbing and reload via the resource's
primary `:read` action — no per-domain reader is required:

```elixir
update :define do
  argument :characteristic_value_updates, {:array, :term}
  change Diffo.Provider.Changes.Define
end

update :relate do
  argument :relationships, {:array, :struct}
  change Diffo.Provider.Changes.Relate
end

update :assign_core do
  argument :assignment, :struct, constraints: [instance_of: Assignment]
  change {Diffo.Provider.Changes.Assign, pool: :cores}
end
```

If you need to do more than the standard pattern, the underlying helpers
(`Characteristic.update_all/3`, `Pool.update_pools/3`, `Relationship.relate_instance/2`,
`Assigner.assign/3`) remain available for a hand-written `after_action`.

### `relationships do` — Instance only

Declares which relationship roles this Instance kind may participate in as a **source** or
**target** in TMF `Relationship` records. Omitting the section defaults both directions to
`:none`, which blocks any update action that passes `argument :relationships, {:array, :struct}`.

Declarations form a pipeline — `source` and `target` steps may each be repeated; **the last
declaration per direction wins**.

```elixir
provider do
  relationships do
    source [:provides, :requires]   # last step overrides earlier ones
    target :all
  end
end
```

Each step accepts `:all`, `:none`, or a non-empty list of role-name atoms (relationship aliases):

| Value | Meaning |
|---|---|
| `:all` | any alias is permitted in this direction |
| `:none` | no relationships are permitted (default when section is omitted) |
| `[:provides, :requires]` | only these alias atoms are permitted |

`ValidateRelationshipPermitted` is automatically injected by the DSL into every update action
that carries `argument :relationships, {:array, :struct}`. It enforces `permitted_source_roles/0`
on the source resource before the action runs.

**The Assigner is not affected** — assignment actions use `argument :assignment`, not
`argument :relationships`, and write `DefinedSimpleRelationship` records directly via the
Provider domain. `relationships do` permissions are never checked during assignment.

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
- `relationships/0` — raw ordered list of `RelationshipStep` pipeline entries
- `permitted_source_roles/0`, `permitted_target_roles/0` — resolved permission (`:all`, `:none`, or list of atoms)
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

## Neo4j label naming convention

AshNeo4j derives each resource's primary node label from the **last segment** of the module
name. If two different resource kinds share the same last segment, all reads and writes for
one will also match nodes belonging to the other — a silent data corruption.

**Always suffix the module with its resource kind** so the derived label is unique:

| Kind | Pattern | Example |
|------|---------|---------|
| Instance | `…Instance` | `MyApp.Instance.WidgetInstance` → `:WidgetInstance` |
| Characteristic | `…Characteristic` | `MyApp.Characteristic.SpeedCharacteristic` → `:SpeedCharacteristic` |
| Party | `…Party` or unique name | `MyApp.Party.ProviderOrganization` → `:ProviderOrganization` |
| Place | `…Place` or unique name | `MyApp.Place.InstallationSite` → `:InstallationSite` |

If a domain has both `MyApp.Instance.Card` and `MyApp.Characteristic.Card`, both resolve to
label `:Card` and queries are ambiguous. Rename to `CardInstance` and `CardCharacteristic`.

## Complete example

```elixir
# Domain — include the fragment so manage_relationship resolves across domains
defmodule MyApp.SRM do
  use Ash.Domain, fragments: [Diffo.Provider.DomainFragment]

  resources do
    resource MyApp.BroadbandService
    resource MyApp.RSP
    resource MyApp.GeographicSite
  end
end

# Instance resource
defmodule MyApp.BroadbandService do
  use Ash.Resource, fragments: [Diffo.Provider.BaseInstance], domain: MyApp.SRM

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
  use Ash.Resource, fragments: [Diffo.Provider.BaseParty], domain: MyApp.SRM

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
  use Ash.Resource, fragments: [Diffo.Provider.BasePlace], domain: MyApp.SRM

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

## Aliases on relationships

Both `AssignmentRelationship` and `DefinedSimpleRelationship` carry an optional `:alias`
attribute — an atom given to a relationship slot by the consuming (target) side.

An alias is the consumer's stable name for a slot before (or when) the relationship is
bound. It survives the relationship's lifetime unchanged. Think of it as a "baby name"
for a slot: the AVC says "I have a slot called `:svlan`"; when the CVC assigns a VLAN to
that AVC, the `AssignmentRelationship` record carries `alias: :svlan`. No matter which
CVC fills the slot or how many times the assignment is changed, the alias stays fixed.

Identity constraints enforce uniqueness:
- `AssignmentRelationship` — `[:target_id, :alias]` — at most one assignment per
  (target, alias) pair. This is how the consumer guarantees slot uniqueness.
- `DefinedSimpleRelationship` — `[:source_id, :alias]` — at most one outgoing
  relationship per (source, alias) pair.

Aliases are the join key for the first-order expectation system (issue #74): an
expectation declares an alias for a slot it expects to be filled; the actual relationship
carries the same alias, so intent and fulfilment can be matched precisely. Without the
expectation system in place, aliases appear to be optional metadata — with it, they are
the primary correlation key.

```elixir
# Assigning with an alias — the AVC names its SVLAN slot :svlan
Servo.assign_port(cvc, %{
  assignment: %Assignment{
    assignee_id: avc.id,
    operation: :auto_assign,
    alias: :svlan
  }
})
```

## `inherited_place` and `inherited_party` DSL

Declare `inherited_place` or `inherited_party` inside `places do` / `parties do` on an
Instance resource to generate an Ash calculation that traverses the assignment graph and
inherits a place or party from the source instance.

No `PlaceRef` or `PartyRef` edge is created on the consuming instance — the calculation
IS the reference. The result is a list (consistent with all traversal calculations).

```elixir
provider do
  places do
    # Single-hop: traverses AssignmentRelationship where alias = :installation_site,
    # reads PlaceRef with role :location from the source instance
    inherited_place :installation_site, source_role: :location

    # Explicit alias (same as above written long-form)
    inherited_place :exchange, via: [:exchange], source_role: :location

    # Multi-hop: :primary slot on this instance → :uplink slot on that instance →
    # reads :location PlaceRef from the final source
    inherited_place :exchange, via: [:primary, :uplink], source_role: :location
  end

  parties do
    inherited_party :provider, source_role: :provider
  end
end
```

Options:
- `source_role:` *(required)* — the `PlaceRef`/`PartyRef` role to read from the resolved
  source instance.
- `via:` *(optional)* — explicit list of alias atoms for multi-hop traversal. When
  omitted, the role name itself is used as the single alias step.

The DSL entity must be declared in the correct section (`places do` for `inherited_place`,
`parties do` for `inherited_party`). The generated calculation name matches the declared role.

## Field calculation modules

Three general-purpose calculation modules cover reading fields across the assignment and
relationship graph. Declare them in a `calculations do` block on any Instance resource.

### `FieldFromAssignment`

Reads a field directly from an `AssignmentRelationship` record — no hop to the source
instance. Use this when you want a value that lives on the relationship itself.

```elixir
# Port number assigned to this service under the :svlan slot
calculate :assigned_vlan, {:array, :integer},
  {Diffo.Provider.Calculations.FieldFromAssignment, [alias: :svlan, field: :value]}

# Pool name for every assignment on this instance (no alias filter)
calculate :assignment_pools, {:array, :atom},
  {Diffo.Provider.Calculations.FieldFromAssignment, [field: :pool]}
```

Options: `field:` (required), `alias:` (optional).

### `FieldViaAssignedRelationship`

Traverses `AssignmentRelationship` in reverse (target → source) and reads a field from
each source instance. Use this when you want a field that belongs to the assigning
instance, not the relationship record.

```elixir
# Name of the CVC holding the :svlan assignment slot on this AVC
calculate :cvc_id, {:array, :string},
  {Diffo.Provider.Calculations.FieldViaAssignedRelationship, [via: [:svlan], field: :name]}
```

Options: `field:` (required), `via:` (optional list of alias steps — omit for unaliased).

### `FieldViaRelationship`

Traverses `DefinedSimpleRelationship` in the forward direction (source → target) filtered
by `alias:` and/or `type:`, and reads a field from each target instance.

```elixir
# Name of the target reached via the :provides alias
calculate :downstream_name, {:array, :string},
  {Diffo.Provider.Calculations.FieldViaRelationship, [alias: :provides, field: :name]}

# Name narrowed by both type and alias
calculate :assigned_node_name, {:array, :string},
  {Diffo.Provider.Calculations.FieldViaRelationship,
   [type: :assignedTo, alias: :node, field: :name]}
```

Options: `field:` (required), `alias:` (optional), `type:` (optional). Provide at least
one of `alias:` or `type:` — querying by `source_id` alone returns all forward
relationships mixed together, which is rarely useful.

### Choosing between the three

| I want… | Use |
|---------|-----|
| A value stored on the assignment record itself (`:value`, `:pool`, `:alias`) | `FieldFromAssignment` |
| A field from the instance that assigned something to me | `FieldViaAssignedRelationship` |
| A field from the instance I have a forward relationship to | `FieldViaRelationship` |
| A place/party inherited from the assigning instance | `inherited_place` / `inherited_party` DSL |

## Common mistakes

- **Do not add your resources to `Diffo.Provider`** — that domain is closed. Build your own
  domain using `fragments: [Diffo.Provider.DomainFragment]` and put your resources there.
- **Do not omit `Diffo.Provider.DomainFragment` from your domain** — without it, `manage_relationship`
  calls on resources with `belongs_to :instance, Diffo.Provider.Instance` (and similar) will
  fail at runtime with not-found errors because AshNeo4j cannot match your concrete nodes
  through the provider base type label pair. See the **recommended usage pattern** section.
- **Do not issue Cypher queries directly from application code** — all reads and writes must
  go through Ash and AshNeo4j. Neo4j Browser is for observation only.
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
  records live on `Diffo.Provider.DefinedSimpleRelationship`. Access them via `instance.assignments`.
- **Do not filter `instance.forward_relationships` for `type == :assignedTo`** — those records no
  longer exist there. `forward_relationships` contains only regular TMF `Relationship` nodes;
  `instance.assignments` contains `DefinedSimpleRelationship` pool assignment records.
- **Do not write `update :relate` actions without a `relationships do` section** — omitting the
  section defaults `permitted_source_roles` to `:none`, causing all calls to that action to fail.
  Add `relationships do source :all end` (or a specific list of roles) to permit relates.
- **Do not add `relationships do` to Party or Place resources** — the section is for Instance
  kinds only; it is not enforced on Party/Place resources and has no effect there.
