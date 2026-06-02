<!--
SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# AGENTS.md — Diffo

AI agent guidance for the Diffo source repository.

## What this project is

Diffo is a Telecommunications Management Forum (TMF) Service and Resource Manager, built
on [Ash Framework](https://www.ash-hq.org/) + [AshNeo4j](https://github.com/diffo-dev/ash_neo4j) + [Neo4j](https://github.com/neo4j/neo4j). It models TMF 638/639 Service and Resource inventory and provides a Spark DSL for defining domain-specific instance, party, and place kinds.

## Before making changes

1. Read `usage-rules.md` — Diffo-specific DSL rules.
2. Read `CLAUDE.md` — dependency usage rules (Ash, Elixir, OTP, AshNeo4j, Spark).
3. Consult the skill at `.claude/skills/diffo-framework/` for Ash ecosystem patterns.
4. Run `mix test` before and after your change to confirm nothing regressed.

## Updating dependencies

When updating a dependency (e.g. bumping `ash_neo4j`, `ash`, `spark` in `mix.exs`), always
run `mix usage_rules.sync` immediately after `mix deps.get`. Dependencies publish their own
usage rules; syncing pulls those changes into `CLAUDE.md` so you are working from the
up-to-date guidance before touching any code.

## Releasing

Releases are driven by [`git_ops`](https://hexdocs.pm/git_ops) — a dev-only dependency
configured in `config/config.exs`. The changelog is built from
[Conventional Commits](https://www.conventionalcommits.org), so write commit subjects with a
type prefix (`fix:`, `feat:`, `deps:`, `chore:`, `refactor:`, `test:`, `docs:`).

To cut a release from `dev`:

1. `mix git_ops.release --dry-run` — preview the computed version and changelog without
   writing anything. The bump follows semver from the commit types since the last `v*` tag
   (`fix:` → patch, `feat:` → minor).
2. `mix git_ops.release` — bumps `@version` in `mix.exs`, inserts the new section into
   `CHANGELOG.md` after the `<!-- changelog -->` marker, commits, and tags `vX.Y.Z`.
3. Curate the generated entries. git_ops seeds each from the commit *subject* — often a
   branch name — so rewrite the `feat:`/`fix:` lines into the curated prose this changelog
   uses (bold lead, `(#issue)`, an em-dash explanation), then `git commit --amend --no-edit`
   and `git tag -f vX.Y.Z` to fold the edits in (safe while unpushed).
4. Open a PR `dev` → `main`, merge, then `mix hex.publish` from `main`.

Only `feat`/`fix`/`deps` surface in the changelog; `chore`/`refactor`/`test`/`docs` are
accepted but hidden, so test-only work (e.g. verifier coverage) doesn't clutter it.
Non-Conventional subjects and merge commits are logged as "Unparseable" and skipped — that
is expected, not an error.

## Fixing bugs

Before writing any fix, review existing test coverage for the affected behaviour. If the bug
has no test, write the failing test first — this confirms the reproduction and guards the
fix against regression. Only then implement the fix and verify the test passes.

## Designing intricate changes — the spelunking pattern

For any change that touches more than one layer (Spark DSL extension / transformers /
persisters / verifiers / base fragments / AshNeo4j sandbox / consumer-domain resources),
don't work top-down or bottom-up alone — work from both ends and meet in the middle
(stalagmite + stalactite). Both ends carry unknowns that compound when you discover them
late.

**Bottom (stalagmite) — start with a focused test against the lowest layer that doesn't
involve the consumer surface.** Examples for diffo:

- A direct introspection call against `Diffo.Provider.Extension.Info` or
  `Spark.Dsl.Extension.get_entities/2` to confirm a transformer/persister bakes the shape
  you expect.
- An `AshNeo4j.Sandbox` round-trip against a minimal `BaseInstance` / `BaseParty` /
  `BasePlace` / `BaseCharacteristic`-derived resource that exercises only the primitive you
  are changing.
- A raw `AshNeo4j.Sandbox.run/2` (or `Bolty.query!/2`) when the surprise might be at the
  Cypher / driver layer.

This isolates DSL- and graph-level surprises before they ripple up into a consumer domain.

**Top (stalactite) — write an exploratory consumer-domain test with `IO.inspect` inside
your transformer, persister, calculation, or change callback.** Surfaces shape assumptions
you have wrong about how DSL state arrives, what the change context contains, or what Ash
hands the callback. Throw the test away once it has taught you the shape.

**Meet in the middle.** Once both ends are settled, the connecting commit is small and
focused — write the bridge code, run the existing end tests plus a new end-to-end one
through a consumer-style resource.

Use this pattern whenever a change spans more than one layer.

## Project structure

```
lib/diffo/type/
  primitive.ex             # Diffo.Type.Primitive — discriminated union of primitive Elixir types
  value.ex                 # Diffo.Type.Value — union of Primitive and Dynamic
  dynamic.ex               # Diffo.Type.Dynamic — runtime-typed value (NewType with map storage)
  name_value_primitive.ex        # Diffo.Type.NameValuePrimitive — name/Primitive pair TypedStruct
  name_value_array_primitive.ex  # Diffo.Type.NameValueArrayPrimitive — name/[Primitive] pair TypedStruct

lib/diffo/provider/
  extension.ex                  # Unified Spark DSL extension (provider do)
  extension/
    info.ex                     # Runtime introspection via Spark.InfoGenerator
    characteristic.ex           # Characteristic build helpers
    feature.ex                  # Feature build helpers
    pool.ex                     # Pool struct + create_pools/2 + update_pools/3
    instance_role.ex            # InstanceRole struct
    party_declaration.ex        # PartyDeclaration struct
    place_declaration.ex        # PlaceDeclaration struct
    party_role.ex               # PartyRole struct (Party/Place kinds)
    place_role.ex               # PlaceRole struct (Party/Place kinds)
    relationship_step.ex        # RelationshipStep struct — pipeline step for relationships do
    persisters/                 # Terminal bakers — run after all transformers; only read DSL state and bake module functions
    transformers/
      transform_relationships.ex    # TransformRelationships — resolves relationships pipeline, bakes permitted_source_roles/0 and permitted_target_roles/0
      transform_inherited_refs.ex   # TransformInheritedRefs — injects calculations for inherited_place/inherited_party declarations
    inherited_place_declaration.ex  # DSL entity struct for inherited_place
    inherited_party_declaration.ex  # DSL entity struct for inherited_party
    verifiers/
      verify_relationships.ex     # Verifies relationship role declarations are atoms
  validations/
    validate_relationship_permitted.ex  # ValidateRelationshipPermitted — enforces relationships do policy on relate actions
  assigner/
    assigner.ex                 # Diffo.Provider.Assigner — assign/3 (pools do) and assign/4
    assignable_characteristic.ex # AssignableCharacteristic — pool bounds + algorithm
  base_instance.ex              # Ash Fragment for Instance resources
  base_party.ex                 # Ash Fragment for Party resources
  base_place.ex                 # Ash Fragment for Place resources
  components/
    base_characteristic.ex      # Ash Fragment for typed characteristic resources
    base_relationship.ex        # Ash Fragment for shared Relationship structure
    defined_simple_relationship.ex    # DefinedSimpleRelationship — relationship with one optional embedded characteristic, frozen at creation
    assignment_relationship.ex        # AssignmentRelationship — pool assignment relationship with top-level pool/thing/value/alias scalar attributes
    relationship.ex                   # Relationship — mutable TMF service/resource relationship with graph Characteristic nodes
    calculations/
      characteristic_value.ex              # Calculation: builds .Value TypedStruct from record fields
      assigned_values.ex                   # Calculation: returns list of assigned integers for a pool+thing
      inherited_place.ex                   # Calculation: backing impl for inherited_place DSL
      inherited_party.ex                   # Calculation: backing impl for inherited_party DSL
      field_from_assignment.ex             # Calculation: field from AssignmentRelationship record
      field_via_assigned_relationship.ex   # Calculation: field from source instance via assignment traversal
      field_via_relationship.ex            # Calculation: field from target instance via DefinedSimpleRelationship
    instance/extension.ex       # Thin marker (sections: []) — kind identification
    party/extension.ex          # Thin marker
    place/extension.ex          # Thin marker

test/provider/
  defined_simple_relationship_test.exs # Integration: DefinedSimpleRelationship create/destroy + DefinedCharacteristic encoding

test/provider/extension/        # All provider extension tests
  instance_transformer_test.exs
  party_transformer_test.exs
  place_transformer_test.exs
  instance_verifier_test.exs
  party_verifier_test.exs
  place_verifier_test.exs
  relationship_dsl_test.exs     # Transformer baking, verifier errors, integration enforcement
  party_test.exs                # Integration: parties enforcement
  place_test.exs                # Integration: places enforcement
  specification_test.exs        # Integration: spec roundtrip
  characteristic_test.exs       # Integration: characteristic creation
  feature_test.exs              # Integration: feature creation
  assigner_test.exs             # Integration: resource assignment

test/support/
  resources/                    # Test domain resources (Shelf, Card, Organization, etc.)
  domains/                      # Test domains (Servo, Nbn)
```

## The unified `provider do` DSL

All DSL declarations use a single `provider do` section — there is no `structure do`,
top-level `behaviour do`, or bare `instances/parties/places do`.

### Instance resources (`BaseInstance`)

```elixir
provider do
  specification do
    id "da9b207a-..."   # stable UUID4 — never change after first commit
    name "myService"    # camelCase
    type :serviceSpecification
    major_version 1
    description "..."
    category "..."
  end

  characteristics do
    characteristic :slot_value, MyApp.SlotCharacteristic
    characteristic :ports, {:array, MyApp.PortCharacteristic}
  end

  pools do
    pool :cores, :core   # assignable pool; thing name is :core
    pool :vlans, :vlan
  end

  relationships do
    source [:provides, :requires]   # pipeline — last step wins; omitting defaults to :none
    target :all
  end

  features do
    feature :advanced_routing, is_enabled?: false do
      characteristic :policy, MyApp.RoutingPolicy
    end
  end

  parties do
    party :provider, MyApp.RSP           # singular, direct edge
    parties :engineers, MyApp.Engineer, constraints: [min: 1, max: 5]
    party_ref :owner, MyApp.Organization # no direct edge
    party :operator, MyApp.RSP, calculate: :derive_operator
  end

  places do
    place :installation_site, MyApp.GeographicSite
    place_ref :billing_address, MyApp.GeographicAddress
    # Inherited — generates a calculation that traverses AssignmentRelationship
    # by alias and reads PlaceRef from the source instance. No PlaceRef edge is created.
    inherited_place :exchange, source_role: :location         # alias = role name (single-hop default)
    inherited_place :nni_site, via: [:uplink], source_role: :location  # explicit alias
  end

  behaviour do
    actions do
      create :build    # injects :specified_by, :features, :characteristics
    end
  end
end
```

### Party and Place resources (`BaseParty` / `BasePlace`)

```elixir
provider do
  instances do
    role :provider, MyApp.BroadbandService
    instance_ref :manages, MyApp.InternalService  # no direct edge
  end
  parties do
    role :employer, MyApp.Organization
  end
  places do
    role :headquarters, MyApp.GeographicSite
  end
end
```

## Three usage scenarios

Diffo supports three distinct usage patterns. Every test is tagged with one or more of these
atoms — absence of all three means the test has not yet been classified.

| Tag | Scenario | Description |
|-----|----------|-------------|
| `:provider_only` | Vanilla Provider | Uses `Diffo.Provider` resources as-is. No custom domains, no extensions. Good for basic TMF inventory and for introducing Diffo incrementally. |
| `:provider_extended` | Extended within Provider | New resource types defined inside `Diffo.Provider` itself, extending base fragments (e.g. `DefinedSimpleRelationship`). Pain point: external users can't add to the Provider domain without forking Diffo. |
| `:domain_extended` | True domain extension | The **recommended pattern**. An external domain (e.g. `MyApp.SRM`) owns resources using `BaseInstance`, `BaseParty`, `BasePlace`, and `BaseCharacteristic` fragments. Exposes its own API; consumers need not know about Diffo internals. |

Tests may carry `:provider_extended` and `:domain_extended` together when they span both.
`:provider_only` is mutually exclusive with the other two.

## Domain extension pattern (scenario 3)

Any domain whose resources carry `belongs_to :instance, Diffo.Provider.Instance` (or
`belongs_to :party, Diffo.Provider.Party`) and use `manage_relationship` to relate them
**must** include `Diffo.Provider.DomainFragment`:

```elixir
defmodule MyApp.SRM do
  use Ash.Domain, fragments: [Diffo.Provider.DomainFragment]
  ...
end
```

**Why this is necessary.** AshNeo4j 0.6.0 matches nodes using
`label_pair = [domain_label, module_label]`. `Ash.get(Diffo.Provider.Instance, uuid)` builds
`MATCH (n:Provider:Instance {uuid: $uuid})`. A `ShelfInstance` node in `MyApp.SRM` has
labels `[:SRM, :ShelfInstance, :Instance]` — `:Provider` is absent, so the lookup returns
not-found and `manage_relationship` fails.

`Diffo.Provider.DomainFragment` tells AshNeo4j to write `:Provider` as an extra label on
every node in the domain at CREATE time. `ShelfInstance` then carries
`[:SRM, :ShelfInstance, :Instance, :Provider]`. Neo4j matches nodes that have **all**
specified labels regardless of extras, so `MATCH (n:Provider:Instance {uuid: $uuid})` finds
it. `label_pair` for direct reads on `ShelfInstance` is still `[:SRM, :ShelfInstance]` —
its own-domain reads remain correctly scoped.

### has_many and the accessing_from path

A separate constraint applies when a `has_many` relationship uses `manage_relationship` on
the source side: AshNeo4j 0.6.0's `accessing_from` path calls
`Ash.Resource.Info.reverse_relationship/2`, which does a strict type-equality check. If
`Characteristic.belongs_to :instance` targets `Diffo.Provider.Instance` but the actual
source is `ShelfInstance`, the check fails and the edge is not created.

The fix used in Diffo's extension helpers (`Characteristic.relate_instance`,
`Feature.relate_instance`) is to bypass `manage_relationship` on the source side entirely
and call `AshNeo4j.Neo4jHelper.relate_nodes/6` directly, using the concrete
`result.__struct__` label pair. See
`lib/diffo/provider/components/instance/extension/characteristic.ex` and `feature.ex`.

## Running tests

Integration tests require a running Neo4j instance.

```sh
mix test                              # full suite
mix test --only domain_extended       # scenario 3 tests only
mix test --only provider_only         # vanilla provider tests only
mix test --only provider_extended     # extended-within-provider tests only
mix test test/provider/extension/     # extension directory only
mix test path/to/test.exs:LINE        # single test
mix test --max-failures 5             # stop early
```

## Formatting, docs, and the DSL toolchain

Diffo is a Spark DSL library, so formatting and docs have DSL-aware steps. Run these
after any change that touches the `Diffo.Provider.Extension` DSL (adding/removing/renaming
an entity or its args), and before a release:

```sh
mix format                            # format all code (uses .formatter.exs)
mix spark.formatter                   # regenerate .formatter.exs locals_without_parens, then format it
mix spark.cheat_sheets                # regenerate documentation/dsls/DSL-Diffo.Provider.Extension.md
mix docs                              # spark.cheat_sheets + ex_doc + spark.replace_doc_links
```

- **`.formatter.exs`** carries the `Spark.Formatter` plugin and a `locals_without_parens`
  list of every DSL entity/arity (e.g. `party_ref: 2`, `inherited_characteristic: 2`,
  `via: 1`). It is **committed** and must stay in sync with the DSL —
  if it drifts, `mix format` adds spurious parens to DSL calls. `mix spark.formatter`
  (the alias regenerates the list and re-formats the file) is the source of truth; run it
  whenever you change the extension, and commit the result.
- **`mix format --check-formatted`** must pass in CI/pre-release. The `mix test` alias runs
  `ash.setup` first; formatting is separate.
- **The DSL cheat sheet** (`documentation/dsls/DSL-Diffo.Provider.Extension.md`) is generated
  by `mix spark.cheat_sheets` and **committed** — regenerate and commit it after DSL changes
  so it doesn't go stale (a no-diff regenerate means it's current).
- **`mix docs`** output lands in `doc/`, which is **gitignored** — generated HTML and the
  livebooks copied there are not tracked. The source livebooks live in `documentation/how_to/`
  and the root `diffo.livemd`; edit those, not `doc/`.

## Module naming and Neo4j labels

AshNeo4j derives a node label from the **last segment** of the module name. Two resources
whose names end in the same word get the same label, which causes read collisions.

**Rule:** suffix every resource module with its kind so the last segment is unique:
- Instance resources: `MyApp.Instance.WidgetInstance` (not `MyApp.Instance.Widget`)
- Characteristic resources: `MyApp.Characteristic.WidgetCharacteristic` (not `MyApp.Characteristic.Widget`)
- Party/Place resources: follow the same convention if ambiguity is possible.

E.g. `Diffo.Test.Instance.CardInstance` → label `:CardInstance`,
and `Diffo.Test.Characteristic.CardCharacteristic` → label `:CardCharacteristic` — no collision.

## Spark transformer vs persister pipeline

Spark runs two separate pipelines during compilation, in this order:

1. **Transformers** (`transformers:` in the extension) — run in dependency order via `before?`/`after?`. Can read and modify DSL state. May also call `Transformer.persist/3` to bake results — a transformer that had to compute something to do its job should persist that result rather than delegating to a separate persister.
2. **Persisters** (`persisters:` in the extension) — always run after ALL transformers from ALL extensions. `before?`/`after?` ordering works relative to other persisters only — ordering declarations targeting transformers are silently ignored.
3. **Verifiers** — read-only, run last.

**Rules:**
- A module that injects into actions, modifies DSL state, or needs to order itself relative to Ash's own transformers belongs in `transformers:`.
- A module that only reads final DSL state and bakes module functions belongs in `persisters:`.
- A transformer that needs to expose baked state does not need a separate persister — call `Transformer.persist/3` inline and emit the module function via `Transformer.eval/3`.
- Do not put a transformer in `persisters:` hoping `after?` declarations will order it relative to transformers — those declarations are silently ignored across pipeline boundaries.

New transformers go under `transformers:`. New persisters go under `persisters:`.

## Resource polymorphism — the cascade refinement of the Fat* pattern

> **Note (post-#185):** The original Fat* pattern argued *against* subtype-per-fragment
> on the grounds it would re-spend the polymorphism budget on the TMF axis. The Place
> cascade (#185) showed this was overstated — **fragment composition is additive at
> the leaf**, not a budget spend. A consumer leaf composes BasePlace + BaseGeographicSite +
> its own attributes in one resource, no budget re-spent. The Fat* invariants still hold
> (graph edges intact, storage indexable, no N² explosion) under the cascade because we
> deliberately keep typed `belongs_to` pointing at the abstract reader (Option C). The
> sections below have been updated to reflect this refinement.

Each Ash resource concept has a **polymorphism budget** — the axis along which concrete
resources differ. Diffo spends that budget on the **extender's domain axis**. TMF
subtype identity is layered on top via compile-time fragment composition (the cascade),
which doesn't compete with the extender's axis because fragments compose at the leaf.

### What this means

- **`BaseInstance`** — the shared base. TMF638/639 subtypes ship as cascade
  fragments: a Service composes `BaseInstance + Service` (lifecycle state machine
  on `state` / `operating_status`), a Resource composes `BaseInstance + Resource`
  (`lifecycle_state`). An instance is exactly one of Service or Resource; the
  `type` enum still records which. Extenders define `MyApp.Avc`, `MyApp.Cvc`,
  `MyApp.NbnEthernet` as distinct Service/Resource leaves. `Provider.Instance`
  is the generic Service + projection reader. The Assigner dispatches on the
  discriminator — `Assigner.assignable_service_states/0` /
  `assignable_resource_states/0`.
- **`BaseParty`** — extenders define `MyApp.Carrier`, `MyApp.Customer`,
  `MyApp.NetworkOperator` as distinct resources. TMF632 subtypes
  (`:Organization`, `:Individual`) ship as cascade leaves
  (`Provider.Organization`, `Provider.Individual`) composing
  `BaseParty + BaseOrganization|Individual`. Diffo also extends the TMF type
  enum with `:Entity` (party-like aggregates) and the placeholder `:PartyRef`,
  both routing to the abstract `Provider.Party` via the dispatcher.
- **`BasePlace`** — extenders define `MyApp.CSA`, `MyApp.Warehouse`, `MyApp.HomeAddress`
  as distinct resources. TMF673/674/675 subtypes (`:GeographicAddress`,
  `:GeographicSite`, `:GeographicLocation`, `:PlaceRef`) live as a `type` enum, with
  subtype-specific attribute groups (e.g. `:location` / `:bounds` for
  `:GeographicLocation`) gated by `type` via Ash validations.

These bases grow wide ("Fat*") for behaviours that span all subtypes (graph wiring,
TMF base attributes, the encoder hook). Subtype-specific attribute groups now live
on **subtype fragments** (`BaseGeographicAddress`, `BaseGeographicSite`,
`BaseGeographicLocation`) that compose with `BasePlace` at the consumer leaf —
each subtype is its own resource with its own labels and its own concrete struct.
Storage cost remains negligible: unused base attributes still don't touch disk
because Neo4j skips nil properties, and the subtype-specific fields live only on
the leaves where they apply.

### Wire-side TMF polymorphism still works

TMF wire forms carry their own polymorphism (`@type`, `@baseType`, `@referredType`
per the TMF API Design Guidelines). That polymorphism is **reconstructed at the JSON
encoder edge**: `BasePlace.encode_geo_json/2` pattern-matches on geometry to emit
`@baseType: "GeographicLocation"` + `@type: "GeoJsonPoint"` + nested `geoJson` for
populated `:location`/`:bounds`. Each subtype fragment in the cascade
(`BaseGeographicAddress`, `BaseGeographicSite`, `BaseGeographicLocation`) declares
its own `jason do` block selecting base + subtype fields, with TMF camelCase
renames; the `encode_geo_json/2` customize is inherited from `BasePlace` so
geometry rebranding works uniformly.

### Why this commitment is durable (refined)

- **Subtype-per-fragment is the cascade pattern.** Splitting `BasePlace` into
  `BaseGeographicAddress` / `BaseGeographicSite` / `BaseGeographicLocation` is the
  *correct* answer when those subtypes carry distinct attribute groups. Fragment
  composition at the leaf means a consumer's `MyApp.SydneyExchange` composes
  `BasePlace + BaseGeographicSite + its own attrs` — three layers in one resource,
  one polymorphism budget. The original "don't split" advice was based on a misread
  of how fragment composition stacks; #185 corrected this.
- **Generic edges still survive — via the dispatcher and `Provider.Place`.**
  Typed `belongs_to` on PlaceRef/PartyRef stays pointing at the abstract
  `Diffo.Provider.Place` reader (Option C — see "PlaceRef / PartyRef belongs_to
  stay at the abstract reader" below). No N² edge explosion because diffo never
  enumerates consumer leaves in `belongs_to`; instead, the dispatcher does inline
  projection on reads via `AshNeo4j.worlds/1`.
- **Storage stays indexable.** Each attribute is its own typed Neo4j property —
  `CREATE POINT INDEX ON (p:Place) ON p.bounds.bbSW` works for geometry; address
  fields would be indexable in their own way. A union-typed `:geometry` attribute
  would collapse to a JSON blob via Ash's `:ash_json` classifier and lose all
  indexability — that's the trap of `Ash.Type.Union` for spatial data. The same
  indexes work uniformly across the cascade because all subtype leaves carry
  `:Place` (or `:Party`, `:Instance`) labels via `BasePlace` fragment composition
  — a `:Place` index covers both the abstract reader and every concrete leaf.

### Implications for design work

- **New TMF subtype → new `BaseXxx` fragment + new `Provider.Xxx` leaf**. The
  subtype fragment carries that subtype's attribute group, jason wire shape, and
  any tightened validations; the leaf composes `BaseKind + BaseXxx`, sets the TMF
  `:type` discriminator via its `:build` action, and accepts the union of base +
  subtype fields.
- **Subtype-specific behaviour → validations on the subtype fragment + encoder
  branches**. BasePlace still handles geometry encoding via its `customize` hook;
  subtype fragments tighten validations (e.g. `BaseGeographicLocation` requires
  location-xor-bounds set).
- **Use the dispatcher API**: `Diffo.Provider.create_place!/2` dispatches by TMF
  type atom; `update_place!/2` / `delete_place!/1` dispatch by record struct;
  reads (`get_place_by_id!/1`, `list_places!/0`) project to concrete subtype via
  `AshNeo4j.worlds/1`. The dispatcher only knows TMF blessed types — consumer
  leaves create/update through their own domain APIs but reads surface them
  transparently via projection.

### Fragment composition discipline — `jason do` / `outstanding do` live on leaves

Spark's `merge_with_warning` (`deps/spark/lib/spark/dsl.ex:794`) is
unconditional — there is no "this override is deliberate" opt-out. Whenever
two fragments write different values to the same `jason.pick` /
`outstanding.expect` opt, a compile-time warning fires regardless of intent.

The cascade pattern requires every subtype fragment (`BaseGeographicAddress`
etc.) and every consumer leaf to declare a wider `jason.pick` /
`outstanding.expect` than any base default would provide. To avoid noise,
**`BasePlace` / `BaseParty` / `BaseInstance` do not declare `jason do` or
`outstanding do`**. Each concrete leaf carries its own:

- Abstract readers (`Provider.Place`/`Provider.Party`/`Provider.Instance`)
  ship the base shape — id, href, name, referred_type, type — for placeholder
  records and projection bootstrap.
- Cascade subtype fragments declare the union of base + subtype fields with
  TMF camelCase renames.
- Consumer leaves declare their own union per their domain shape.

`BasePlace.encode_geo_json/2` stays as a static helper on `BasePlace` (not in
a `jason do` block) — subtype fragments and consumer leaves reference it
from their own `jason.customize`. Same idiom would apply to any future helper
on `BaseParty` / `BaseInstance`.

This is a deliberate departure from the "fragments carry defaults" idiom
some Ash extensions use. It came out of #181.

### PlaceRef / PartyRef belongs_to stay at the abstract reader (Option C)

The cascade does **not** migrate the typed `belongs_to` on PlaceRef/PartyRef to
`ProjectedRef` calcs. `AshNeo4j`'s `relate` block requires a real Ash relationship
to maintain the Neo4j edge (`verify_relate` enforces this at compile time).
Dropping the `belongs_to` would kill the edge — the graph becomes nodes with id
pointers and no connectivity, which guts the whole point of using a graph DB.

The right separation:

- **`belongs_to` for graph integrity.** PlaceRef/PartyRef keep all eight typed
  `belongs_to` (4 each), pointing at the abstract `Diffo.Provider.Place` /
  `Diffo.Provider.Party` / `Diffo.Provider.Instance` readers. Edges stay intact,
  Ash filter/sort/join through still works.
- **`ProjectedRef` calc for cross-resource refs *without* a graph edge.** E.g.
  `BaseGeographicSite.address` resolves an `address_id` FK to a concrete
  `GeographicAddress` (or consumer-domain Address leaf) at read time — no edge,
  open-world projection, three-state load surface
  (struct / `%Diffo.Unknown{}` / `%Ash.NotLoaded{}`).
- **Dispatcher's inline projection for typed reads via abstract reader.**
  `get_place_by_id!/1` loads via `Provider.Place`, then projects via
  `AshNeo4j.worlds/1` to return the concrete subtype struct. The abstract reader
  bootstraps; the dispatcher provides the typed surface. `Provider.Place` is
  plumbing, not a recommendation.

## Cross-domain lookups and the `Diffo.Unknown` primitive

Calculations that cross resource or domain boundaries (e.g. `inherited_characteristic`
reading a typed characteristic from a source instance reached via the assignment graph)
face two structural constraints:

1. **The target resource may not exist at the consumer's compile time.** A generic
   upstream resource declaring a cross-resource lookup will be consumed by downstream
   domains whose resources don't exist yet when the upstream compiles. Compile-time
   resolution of "which module does this role on the source map to?" is architecturally
   wrong — not just fragile.
2. **Failure modes are world-local.** The vocabulary for *why* a lookup didn't yield a
   value (source not reached, role not declared on source, source not Instance-derived,
   etc.) is domain-specific. Centralising a canonical enumeration of failure reasons in
   a shared module would force every domain to fit its semantics into a foreign
   vocabulary.

The Diffo response is `Diffo.Unknown` — a sentinel for "we tried and couldn't determine
this value, in this context, in this domain."

### Shape

```elixir
defmodule Diffo.Unknown do
  defstruct [:world, :reason, :context]

  @type t :: %__MODULE__{
    world: module(),  # the outermost Resource module that produced this Unknown
    reason: atom(),   # world-local atom; vocabulary owned by the producing world
    context: term()   # world-local diagnostic data
  }
end
```

`:world` is the **outermost `(Domain, Resource)` pair** the Unknown was produced under,
stored as the Resource module since the Domain is derivable via
`Ash.Resource.Info.domain/1`. The Domain alone is insufficient — within a single
Domain, multiple concrete resources can extend the same base fragment (e.g.
`Diffo.Provider.AssignmentRelationship` and `Diffo.Provider.DefinedSimpleRelationship`
both share `Relationship` infrastructure but are distinct worlds in the same Domain).
The Resource alone is also insufficient — the Domain anchors which polymorphism axis
the Resource lives on. Together they identify the producer uniquely.

The structure is **N-world by construction.** A node in the graph can participate in
many `(Domain, Resource)` worlds simultaneously (one per base-fragment / concrete
combination it carries labels for). A calc produces an Unknown stamped with its own
outermost world; consumers see the projection. Today the practical count is two (e.g.
Diffo's `Diffo.Provider` and a consumer's `MyApp` domains) but the shape doesn't
encode that limit.

`:reason` is `atom()` at the structural level only — no
`@type reason :: :a | :b | ...` narrowing. Each calc moduledoc declares its own reason
vocabulary; the central type stays open.

`:context` is `term()` — each world decides what to put there. Diagnostic, not
load-bearing.

### Discipline

- **Compile-time stamping of `:world`.** The transformer that injects a cross-boundary
  calc passes the resource it's injecting into as an opt (the resource being compiled
  is statically known to the transformer); the calc stamps that resource on every
  Unknown it emits. No runtime resource lookup needed for the world tag.
- **Calcs are total.** A calc that crosses a boundary never raises on missing data — it
  returns the value, `nil`, or `%Diffo.Unknown{}`. The consumer pattern-matches.
- **Projection across worlds, free composition within.** An outer-world calc that
  encounters an inner-world Unknown wraps it
  (`%Diffo.Unknown{world: OuterResource, reason: :inner_unknown, context: %{inner: original}}`);
  calcs within the same world share vocabulary and can read each other's `:reason`
  directly without projecting through. Worlds are determined by the outermost
  `(Domain, Resource)` pair, so calcs on `Diffo.Provider.AssignmentRelationship`
  vs `Diffo.Provider.DefinedSimpleRelationship` are distinct worlds even though they
  share a Domain.
- **No central reason registry.** Resist the urge to enumerate `Diffo.Unknown` reasons
  anywhere shared. Each world documents its own vocabulary in the moduledocs of the
  calcs that produce it.
- **No permanent roles.** The structure describes states (currently-inside-a-world,
  currently-outside) not identities. The same module may produce an Unknown in one call
  and consume one in another; nothing in the design should bake static insider/outsider
  distinctions.

### Relationship to `Ash.NotLoaded`

`Ash.NotLoaded` represents the load-lifecycle "uninitialised" state — we haven't tried
to load this slot yet. `Diffo.Unknown` represents the post-resolution "we tried and
couldn't determine" state — the calc ran, the answer is "not determinable in this
context." Both are explicit values; consumers pattern-match them as distinct outcomes
alongside concrete values and `nil`.

## DSL shape changes

Whenever you add, rename, or remove a DSL entity or section in `Diffo.Provider.Extension`
(or any Spark extension in this project), run this checklist in order:

1. **Run `mix spark.formatter`** — regenerates `spark_locals_without_parens` in
   `.formatter.exs` from the live extension (and re-formats the file). Prefer this over
   hand-editing: it **adds new** entity/arities **and removes** ones you renamed or deleted.
   Hand-adding only catches additions — a removed entity (e.g. retiring
   `reverse_inherited_characteristic`) or a dropped option (`assignment_alias`) leaves stale
   locals behind. Without an up-to-date list, `mix format` adds unwanted parentheses to DSL
   call sites.

2. **Run `mix format`** — apply formatting across the codebase. Run
   `mix format --check-formatted` to confirm nothing was missed.

3. **Run `mix spark.cheat_sheets`** — regenerates
   `documentation/dsls/DSL-Diffo.Provider.Extension.md`. This file is Spark-generated;
   never edit it by hand. Commit the regenerated file alongside the DSL change (a no-diff
   regenerate means it was already current).

4. **Update `usage-rules.md`** — the consumer-facing DSL reference is hand-written, not
   generated; update it for new/changed/removed entities and options (and any migration
   notes for a breaking change).

5. **Run `mix test`** — confirm no regressions.

Do not skip step 1 even for a "small" entity change — the formatter will silently reformat
every call site in CI and produce noisy diffs in future PRs.

## Raising upstream bugs

When a bug is found in a dependency (e.g. AshNeo4j, Bolty), raise a GitHub issue on that
repository. Use **diffo issue #125** as the style reference:

- **## Description** — explain what the system does, what the code path is, and where it
  breaks. Include a short code snippet if it makes the failure concrete.
- **## What we need** — state the correct behaviour plainly.
- **## Why it matters** — explain the practical impact on Diffo and why fixing it unblocks
  real work.
- Optionally add **## A possible direction** if there is a plausible fix worth suggesting.

Do not use a step-by-step reproduction template; write in the same explanatory prose style
as #125.

Once the issue is raised, stop. Do not attempt to locate or fix the root cause in the
dependency — the upstream maintainers have the full context of their own codebase; you do
not. Add any useful hypotheses as a follow-up comment on the issue, then leave it with them.

## Common agent mistakes

- Using old `structure do` / top-level `instances do` — use `provider do` only.
- Using `party :role, Type, reference: true` — use `party_ref :role, Type`.
- Using a plain `Ash.TypedStruct` as a `characteristic` DSL target — use a `BaseCharacteristic`-derived resource instead; the TypedStruct belongs in `<Module>.Value`.
- Using `characteristic :name, Diffo.Provider.AssignableCharacteristic` for pools — use `pools do / pool :name, :thing / end` instead.
- Using the removed `AssignableValue` TypedStruct — it no longer exists; use `pools do`.
- Calling `Assigner.assign/4` when a `pools do` declaration exists — prefer `Assigner.assign/3` which looks up the thing automatically.
- Hand-writing the `:define` / `:relate` / `:assign_*` after-action plumbing — use `Diffo.Provider.Changes.Define`, `Diffo.Provider.Changes.Relate`, and `{Diffo.Provider.Changes.Assign, pool: :name}` (since 0.4.1). The change modules thread `Characteristic.update_all/3`, `Pool.update_pools/3`, `Relationship.relate_instance/2` and `Assigner.assign/3` together and reload via the resource's primary `:read` action.
- Hand-writing the `:create` / `:update` accept lists on a `BaseCharacteristic`-derived resource — they are synthesised from the resource's public attributes (since 0.4.1). Declare your own only when you need a narrower accept list.
- Calling `Assigner.assign/3` on an instance that is not in the correct lifecycle state — the assigner enforces: resource instances must have `lifecycle_state` of `:planned` or `:installed`; service instances must have `state` of `:feasibilityChecked`, `:reserved`, `:inactive`, `:active`, or `:suspended`. The full lists are exposed via `Assigner.assignable_resource_states/0` and `Assigner.assignable_service_states/0`. Lifecycle state transitions are an internal domain concern managed by the provider; assignment actions are external-facing.
- Wondering why `Relationship` and `AssignmentRelationship` both have an `alias` attribute with a `[:source_id, :alias]` / `[:target_id, :alias]` identity — alias is a "baby name" given to a relationship slot before (or when) the target is bound. Its full purpose becomes clear alongside the first-order expectation system (see issue #122): the expectation declares the alias for a slot it expects to be filled, and the actual relationship carries the same alias so the two can be matched. Without expectations in place, aliases look like optional metadata; with them, they are the join key between intent and fulfilment.
- Using `characteristic :pool_name, Diffo.Provider.AssignedToRelationship` — `AssignedToRelationship` no longer exists; use `pools do / pool :name, :thing / end` instead.
- Querying `Diffo.Provider.Relationship` for assignment records — assignments are stored as `Diffo.Provider.DefinedSimpleRelationship`; access them via `instance.assignments`.
- Filtering `instance.forward_relationships` for `type == :assignedTo` — those records no longer exist there; use `instance.assignments` directly.
- Calling `build_before/1` or `build_after/2` in actions — these run automatically.
- Declaring `:specified_by`, `:features`, `:characteristics` as action arguments.
- Using module names (e.g. `MyApp.CardInstance`) as role values in `relationships do` — roles are atoms like `:provides`, not module references.
- Forgetting that `relationships do` omitted means `:none` for both source and target — any update action with `argument :relationships, {:array, :struct}` will fail unless the resource declares permissions.
- Thinking the Assigner requires `relationships do` permissions — it does not. The Assigner writes `DefinedSimpleRelationship` records directly via the Provider domain; `ValidateRelationshipPermitted` only runs on actions that carry `argument :relationships, {:array, :struct}`, which the Assigner's `assign_*` actions do not.
- Editing `documentation/dsls/DSL-Diffo.Provider.Extension.md` — it is Spark-generated.
  See the **DSL shape changes** section above for the full checklist.
- Editing content between `<!-- usage-rules-start -->` markers in `CLAUDE.md` — that is
  auto-generated by `mix usage_rules.sync`.
- Forgetting `Diffo.Provider.DomainFragment` on a scenario 3 domain — any domain whose
  resources relate back to Provider base types (`belongs_to :instance, Diffo.Provider.Instance`
  etc.) via `manage_relationship` will get `Ash.Error.Query.NotFound` at runtime without it.
  See the **Domain extension pattern** section above.
- Bypassing `manage_relationship` by replacing `argument + manage_relationship` with bare
  `accept` for relationship IDs in scenario 3 resources — the correct fix is the domain
  fragment, not removing the relationship management.
- Writing `Ash.Resource.Validation` with fail-fast short-circuits between independent checks —
  Ash uses Splode to accumulate errors, so all independent validations should run and all
  errors should be collected before returning. Resist the imperative instinct to return on
  the first failure; instead collect errors from every check and return the full list in one
  `{:error, errors}`. Only short-circuit when a later check genuinely cannot run without the
  earlier one succeeding (e.g. the earlier check resolves data the later check depends on).
- Using `Ash.Resource.Change` for pure permission or constraint checks — anything that only
  decides valid/invalid with no side effects belongs in `Ash.Resource.Validation`, not a
  change. Changes are for mutations.
- Using `inherited_place` or `inherited_party` without an assignment alias in place — the
  traversal filters by alias; if the assignment was created without an alias (or with a
  different alias), the calculation returns an empty list. Ensure the `alias:` field on
  `Assignment` matches the declared role (or the `via:` step) before expecting results.
- Referencing `Diffo.Provider.Calculations.InheritedPlace` or `InheritedParty` directly in
  `calculations do` — these are internal modules injected by the transformer. Use the
  `inherited_place` / `inherited_party` DSL entities in `places do` / `parties do` instead.
- Reaching for `FieldViaRelationship` to traverse an `AssignmentRelationship` — that module
  traverses `DefinedSimpleRelationship` (forward, source → target). For assignments
  (reverse, target → source) use `FieldViaAssignedRelationship` or `FieldFromAssignment`.
- Querying `FieldViaRelationship` without supplying `alias:` or `type:` — a source instance
  typically has many forward `DefinedSimpleRelationship` records pointing to unrelated things.
  Without at least one filter the result is a noisy mix. Always supply `alias:`, `type:`, or
  both.
