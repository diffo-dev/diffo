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

## Resource polymorphism — the Fat* pattern

Each Ash resource concept has exactly **one polymorphism budget** — the axis along
which concrete resources differ. Diffo consistently spends that budget on the
**extender's domain axis**, never on the TMF subtype axis.

### What this means

- **`BaseInstance`** — extenders define `MyApp.Avc`, `MyApp.Cvc`, `MyApp.NbnEthernet`
  as distinct resources. TMF638/639 subtypes (`:service` vs `:resource`) live as a
  `type` enum, with `service_state` and `resource_state` as optional attributes
  gated by `type`. The Assigner already exploits this — `Assigner.assignable_service_states/0`
  and `Assigner.assignable_resource_states/0` dispatch on the discriminator.
- **`BaseParty`** — extenders define `MyApp.RSP`, individuals, organisations as
  distinct resources. TMF632 subtypes (`:Organization`, `:Individual`) live as a
  `type` enum.
- **`BasePlace`** — extenders define `MyApp.CSA`, `MyApp.Warehouse`, `MyApp.HomeAddress`
  as distinct resources. TMF673/674/675 subtypes (`:GeographicAddress`,
  `:GeographicSite`, `:GeographicLocation`, `:PlaceRef`) live as a `type` enum, with
  subtype-specific attribute groups (e.g. `:location` / `:bounds` for
  `:GeographicLocation`) gated by `type` via Ash validations.

These bases grow wide ("Fat*") as new TMF subtype concerns become real work, but they
stay singular. A `:GeographicAddress` Place and a `:GeographicLocation` Place are the
same Ash resource — the `type` enum and which attribute group is populated tells them
apart. Storage cost is negligible: Neo4j doesn't store nil properties, so unused
attribute groups never touch disk.

### Wire-side TMF polymorphism still works

TMF wire forms carry their own polymorphism (`@type`, `@baseType`, `@referredType`
per the TMF API Design Guidelines). That polymorphism is **reconstructed at the JSON
encoder edge** rather than represented at the resource type. `Diffo.Provider.Place`'s
`customize/2` callback in its `jason do` block pattern-matches on which subtype
attributes are populated and synthesises the right TMF shape — e.g.
`@baseType: "GeographicLocation"` + `@type: "GeoJsonPoint"` + nested `geoJson` for a
populated `:location`. Same pattern extends to TMF673/674 shapes as those subtype
attribute groups grow on the base.

### Why this commitment is durable

- **Subtype-per-fragment doesn't work.** Splitting `BasePlace` into
  `BaseGeographicLocation` / `BaseGeographicSite` / `BaseGeographicAddress` would
  re-spend the polymorphism budget on the TMF axis. Every consumer would then have
  to compose differently per subtype, lose the "use the base, set `:type`, you have
  a Place" story, and face N² edge declarations for every Instance-to-Place or
  Place-to-Place role that could accept more than one subtype.
- **Generic edges survive.** Because the resource is singular, any Instance
  declaring `place :role, Diffo.Provider.Place` (or a domain extender's Place)
  can hold any TMF subtype with no combinatorial relationship explosion.
- **Storage stays indexable.** Each attribute is its own typed Neo4j property —
  `CREATE POINT INDEX ON (p:Place) ON p.bounds.bbSW` works for geometry; address
  fields would be indexable in their own way. A union-typed `:geometry` attribute
  would collapse to a JSON blob via Ash's `:ash_json` classifier and lose all
  indexability — that's the trap of `Ash.Type.Union` for spatial data.

### Implications for design work

- **New TMF subtype attribute group → new attributes on the existing base**,
  with a `validate attribute_equals(:type, :GeographicXxx), where: present([...], at_least: 1)`
  guard. Don't reach for a new fragment.
- **Subtype-specific behaviour → validations gated on `type` + encoder branches**, not
  new resources.
- **API-layer union sugar (so consumers can read/write a single `:geometry` shape)
  → action arguments + a calculation on the resource**, with storage staying as
  separate typed attributes underneath. Coupling AshNeo4j to that union would
  rightly be refused — TMF concerns belong in Diffo, not the data layer.

## DSL shape changes

Whenever you add, rename, or remove a DSL entity or section in `Diffo.Provider.Extension`
(or any Spark extension in this project), run this checklist in order:

1. **Update `.formatter.exs`** — add new entity names to `spark_locals_without_parens` with
   each supported arity. Without this, `mix format` will add unwanted parentheses to every
   DSL call site.

2. **Run `mix format`** — apply formatting across the codebase and verify the output looks
   correct. Run `mix format --check-formatted` to confirm nothing was missed.

3. **Run `mix spark.cheat_sheets`** — regenerates
   `documentation/dsls/DSL-Diffo.Provider.Extension.md`. This file is Spark-generated;
   never edit it by hand. Commit the regenerated file alongside the DSL change.

4. **Run `mix test`** — confirm no regressions.

Do not skip step 1 even for a "small" entity addition — the formatter will silently reformat
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
- Calling `Assigner.assign/3` on an instance that is not in the correct lifecycle state — the assigner enforces: resource instances must have `resource_state` of `:installing` or `:operating`; service instances must have `service_state` of `:feasibilityChecked`, `:reserved`, `:inactive`, `:active`, or `:suspended` (since 0.4.1). The full lists are exposed via `Assigner.assignable_resource_states/0` and `Assigner.assignable_service_states/0`. Lifecycle state transitions are an internal domain concern managed by the provider; assignment actions are external-facing.
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
