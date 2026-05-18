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
      transform_relationships.ex  # TransformRelationships — resolves relationships pipeline, bakes permitted_source_roles/0 and permitted_target_roles/0
    verifiers/
      verify_relationships.ex     # Verifies relationship role declarations are atoms
  changes/
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
    relationship.ex                   # Relationship — mutable TMF service/resource relationship with graph Characteristic nodes
    calculations/
      characteristic_value.ex   # Calculation: builds .Value TypedStruct from record fields
      assigned_values.ex        # Calculation: returns list of assigned integers for a pool+thing
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

## Running tests

Integration tests require a running Neo4j instance.

```sh
mix test                          # full suite
mix test test/provider/extension/ # extension tests only
mix test path/to/test.exs:LINE    # single test
mix test --max-failures 5         # stop early
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

**Current state:** `TransformBehaviour` is misregistered under `persisters:` — a known issue tracked for refactoring. New transformers go under `transformers:`.

## Common agent mistakes

- Using old `structure do` / top-level `instances do` — use `provider do` only.
- Using `party :role, Type, reference: true` — use `party_ref :role, Type`.
- Using a plain `Ash.TypedStruct` as a `characteristic` DSL target — use a `BaseCharacteristic`-derived resource instead; the TypedStruct belongs in `<Module>.Value`.
- Using `characteristic :name, Diffo.Provider.AssignableCharacteristic` for pools — use `pools do / pool :name, :thing / end` instead.
- Using the removed `AssignableValue` TypedStruct — it no longer exists; use `pools do`.
- Calling `Assigner.assign/4` when a `pools do` declaration exists — prefer `Assigner.assign/3` which looks up the thing automatically.
- Forgetting to call `Pool.update_pools/3` in `:define` actions when the resource has `pools do` — pool bounds (`first`, `last`, `algorithm`) are set here.
- Using `characteristic :pool_name, Diffo.Provider.AssignedToRelationship` — `AssignedToRelationship` no longer exists; use `pools do / pool :name, :thing / end` instead.
- Querying `Diffo.Provider.Relationship` for assignment records — assignments are stored as `Diffo.Provider.DefinedSimpleRelationship`; access them via `instance.assignments`.
- Filtering `instance.forward_relationships` for `type == :assignedTo` — those records no longer exist there; use `instance.assignments` directly.
- Calling `build_before/1` or `build_after/2` in actions — these run automatically.
- Declaring `:specified_by`, `:features`, `:characteristics` as action arguments.
- Using module names (e.g. `MyApp.CardInstance`) as role values in `relationships do` — roles are atoms like `:provides`, not module references.
- Forgetting that `relationships do` omitted means `:none` for both source and target — any update action with `argument :relationships, {:array, :struct}` will fail unless the resource declares permissions.
- Thinking the Assigner requires `relationships do` permissions — it does not. The Assigner writes `DefinedSimpleRelationship` records directly via the Provider domain; `ValidateRelationshipPermitted` only runs on actions that carry `argument :relationships, {:array, :struct}`, which the Assigner's `assign_*` actions do not.
- Editing `documentation/dsls/DSL-Diffo.Provider.Extension.md` — it is Spark-generated;
  run `mix spark.cheat_sheets` to regenerate it. Whenever you add, rename, or remove a DSL
  entity or section, also check `.formatter.exs` — new entity names must be added to
  `spark_locals_without_parens` (with each arity) so the Spark formatter omits parentheses.
  Run `mix format` afterward to verify.
- Editing content between `<!-- usage-rules-start -->` markers in `CLAUDE.md` — that is
  auto-generated by `mix usage_rules.sync`.
