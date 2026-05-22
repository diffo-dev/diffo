<!-- 
SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v0.4.1](https://github.com/diffo-dev/diffo/compare/v0.4.0...v0.4.1) (2026-05-22)

### Bug Fixes

* **Assigner lifecycle** (#168) — broadened the lifecycle states permitted to make assignments. Services may now assign from `:feasibilityChecked`, `:reserved`, `:inactive`, `:active`, or `:suspended` (was `:active` / `:inactive` only). Resources may now assign from `:installing` or `:operating` (was `:operating` only). `Assigner.assignable_state?/1` exposes the policy directly.

### Features

* **`Diffo.Provider.Changes.Define` / `Relate` / `Assign`** (#170) — change modules that wrap the standard after-action patterns every Instance consumer writes. Replace the hand-written `after_action` body threading `Characteristic.update_all` / `Pool.update_pools` / `Relationship.relate_instance` / `Assigner.assign` together with a one-liner:

  ```elixir
  update :define do
    argument :characteristic_value_updates, {:array, :term}
    change Diffo.Provider.Changes.Define
  end

  update :relate do
    argument :relationships, {:array, :struct}
    change Diffo.Provider.Changes.Relate
  end

  update :assign_port do
    argument :assignment, :struct, constraints: [instance_of: Assignment]
    change {Diffo.Provider.Changes.Assign, pool: :ports}
  end
  ```

  Reload happens via the resource's primary `:read` action, so no consumer-specific reader is needed.
* **BaseCharacteristic auto-generated `:create` / `:update` actions** (#171) — `BaseCharacteristic`-derived resources now get default `:create` and `:update` actions synthesised from their public attributes. `:create` accepts `[:name | <public_attrs>]` with `:instance_id` / `:feature_id` arguments and `manage_relationship` changes; `:update` accepts `<public_attrs>`. Consumers may still declare their own actions to override the defaults.
* **Typed characteristics and pools in Instance JSON** (#169) — `BaseInstance` now loads two new calculations (`:typed_characteristics`, `:pool_characteristics`) by default and the jason customize merges their values into the `serviceCharacteristic` / `resourceCharacteristic` array. Typed `BaseCharacteristic` records and `AssignableCharacteristic` pool records that were already present in the graph are now visible at the TMF JSON surface.

### Notable Changes

* `Diffo.Provider.Calculations.TypedCharacteristics` and `Diffo.Provider.Calculations.PoolCharacteristics` — new calc modules backing the JSON surfacing for #169.
* Regression test added for #62 (characteristic update validation) — typed `BaseCharacteristic` updates now reject unknown fields and invalid types through Ash's standard changeset machinery.

## [v0.4.0](https://github.com/diffo-dev/diffo/compare/v0.3.0...v0.4.0) (2026-05-20)

### Breaking Changes

* `Diffo.Provider.AssignedToRelationship` replaced by `Diffo.Provider.AssignmentRelationship` — stores pool assignments with top-level `pool`, `thing`, `value`, and `alias` scalar attributes, enabling graph-level filtering in AshNeo4j queries. Any existing graph data on `AssignedToRelationship` nodes must be migrated.
* `create_assigned_to_relationship` code interface removed — use `create_assignment_relationship` instead.
* `instance.assignments` now returns `AssignmentRelationship` records (struct name change only).

### Features

* **`DefinedSimpleRelationship`** — new resource for relationships carrying an optional single embedded `NameValuePrimitive` characteristic, frozen at creation. Used by the Assigner and available as a general-purpose committed-relationship primitive. Accessible via `instance.assignments`.
* **`AssignmentRelationship` aliases** — the `alias` attribute on `AssignmentRelationship` (identity `[:target_id, :alias]`) gives a consuming instance a stable name for an assignment slot. Mirrors the `[:source_id, :alias]` identity on `DefinedSimpleRelationship`. Alias semantics are the foundation of the first-order expectation system (#74).
* **`relationships do` DSL** — source and target validation pipeline for Instance resources. `ValidateRelationshipPermitted` is injected automatically into relate actions. Supports `:all`, `:none`, and explicit role-name lists.
* **Resource lifecycle states** — `resource_state` attribute on Instance resources with standard TMF states (`:installed`, `:operating`, `:retired`, etc.). The Assigner enforces `:operating` before allowing assignment.
* **`inherited_place` / `inherited_party` DSL** — declare inside `places do` / `parties do` on an Instance resource to generate an Ash calculation that traverses the assignment graph by alias and inherits a place or party from the source instance. No `PlaceRef`/`PartyRef` edge is created — the calculation is the reference. Supports single-hop (default: role name as alias) and multi-hop (`via:` list).
* **`FieldFromAssignment`** (`Diffo.Provider.Calculations.FieldFromAssignment`) — reads a field directly from an `AssignmentRelationship` record (`:value`, `:pool`, `:thing`, `:alias`). Filtered by optional `alias:`. Returns a list.
* **`FieldViaAssignedRelationship`** (`Diffo.Provider.Calculations.FieldViaAssignedRelationship`) — traverses `AssignmentRelationship` in reverse (target → source) and reads a named field from each source instance. Supports multi-hop `via:` traversal. Returns a list.
* **`FieldViaRelationship`** (`Diffo.Provider.Calculations.FieldViaRelationship`) — traverses `DefinedSimpleRelationship` forward (source → target) filtered by optional `alias:` and/or `type:`, and reads a named field from each target instance. Returns a list.

### Notable Changes

* Assigner rearchitected — `AssignmentRelationship` carries `pool`, `thing`, `value`, `alias` as top-level attributes for AshNeo4j-level filtering; `assigned_values` and `free_values` use query-level filtering rather than in-memory computation where possible.
* `TransformBehaviour` moved from persister pipeline to transformer pipeline for correct Spark ordering relative to Ash's own transformers.
* Characteristic type verifier improved — rejects `characteristic` DSL declarations whose type module is not derived from `BaseCharacteristic`.

### Documentation

* `usage-rules.md` — new sections covering alias semantics, `inherited_place`/`inherited_party` DSL, and all three field calculation modules including a decision table.
* `AGENTS.md` — updated project structure, DSL inline examples for inherited refs, and new common mistakes section entries.
* Provider Extension livebook — new section "Aliases, Inherited DSL, and Field Calculations" with Compute-domain examples.

### What's Changed

* defined_simple_relationship by @matt-beanland in https://github.com/diffo-dev/diffo/pull/142
* refactored assigner using defined_simple_relationship by @matt-beanland in https://github.com/diffo-dev/diffo/pull/143
* relationships DSL by @matt-beanland in https://github.com/diffo-dev/diffo/pull/146
* relationships target side validation by @matt-beanlanda in https://github.com/diffo-dev/diffo/pull/148
* clean code by @matt-beanland in https://github.com/diffo-dev/diffo/pull/150
* improved assigner using aggregates by @matt-beanland in https://github.com/diffo-dev/diffo/pull/151
* refactor transformers and persisters by @matt-beanland in https://github.com/diffo-dev/diffo/pull/152
* resource lifecycle state by @matt-beanland in https://github.com/diffo-dev/diffo/pull/154
* inherited party and place via instance DSL by @matt-beanland in https://github.com/diffo-dev/diffo/pull/155
* agent guidance by @matt-beanland in https://github.com/diffo-dev/diffo/pull/161
* FieldViaAssignedRelationship calculation by @matt-beanland in https://github.com/diffo-dev/diffo/pull/162
* FieldViaRelationship calculation by @matt-beanland in https://github.com/diffo-dev/diffo/pull/165
* FieldFromAssignment calculation by @matt-beanland in https://github.com/diffo-dev/diffo/pull/164
* docs pass — inherited DSL, aliases, and field calculations by @matt-beanland in https://github.com/diffo-dev/diffo/pull/166

## [v0.3.0](https://github.com/diffo-dev/diffo/compare/v0.2.2...v0.3.0) (2026-05-17)

### Breaking Changes

* `Diffo.Provider.Relationship` no longer stores assignment records. Assignment relationships are now on `Diffo.Provider.AssignedToRelationship`. Any existing graph data with `type: :assignedTo` on `Relationship` nodes will need to be migrated.
* `instance.forward_relationships` no longer contains assignment records — use `instance.assignments` instead.
* `Diffo.Provider.create_assignment_relationship` removed — use `Diffo.Provider.create_assigned_to_relationship`.

### Notable Changes

* `Diffo.Provider.BaseRelationship` — new Ash Resource Fragment providing common attributes and behaviour for all relationship types
* `Diffo.Provider.AssignedToRelationship` — new dedicated resource for pool assignment relationships, split out from `Diffo.Provider.Relationship`
* `Diffo.Provider.Relationship` — now TMF-only; `pool`, `thing`, `assigned` attributes and `:create_assignment` action removed
* `instance.assignments` — new `has_many` on `BaseInstance` for pool assignment relationships; included in JSON encoding and default loads
* `Diffo.Provider.BaseCharacteristic` — new Ash Resource Fragment for typed characteristic resources; `ShelfCharacteristic`, `CardCharacteristic` etc. now extend this rather than using plain `Ash.TypedStruct`
* `pools do` DSL — new section on Instance resources replacing the old `characteristic :name, AssignableValue` pattern; generates `pools/0` and `pool/1` introspection functions
* Module naming convention — Instance resources must be suffixed `…Instance`, Characteristic resources `…Characteristic` to avoid Neo4j label collisions (documented in `usage-rules.md` and `AGENTS.md`)
* `Diffo.Provider.Extension` — unified Spark DSL extension consolidating the prior per-kind extensions

### What's Changed

* provider extension consolidation by @matt-beanland in https://github.com/diffo-dev/diffo/pull/130
* base characteristic by @matt-beanland in https://github.com/diffo-dev/diffo/pull/133
* assigner refactor — BaseRelationship, AssignedToRelationship, pools DSL, resource naming by @matt-beanland in https://github.com/diffo-dev/diffo/pull/135

## [v0.2.2](https://github.com/diffo-dev/diffo/compare/v0.2.1...v0.2.2) (2026-05-08)

## Notable Changes
* Updated to ash_neo4j 0.5.0 with async test support
* Igniter installer — `mix igniter.install diffo` now sets up Neo4j config, custom expressions, and Spark DSL formatter
* Spark DSL formatter configured for all provider extensions; `mix format` enforced across the codebase
* `usage-rules.md` added for AI coding assistant guidance when working with Diffo

## What's Changed
* async tests by @matt-beanland in https://github.com/diffo-dev/diffo/pull/114
* igniter by @matt-beanlanda in https://github.com/diffo-dev/diffo/pull/116
* spark formatter by @matt-beanlanda in https://github.com/diffo-dev/diffo/pull/117
* usage_rules by @matt-beanlanda in https://github.com/diffo-dev/diffo/pull/118

## [v0.2.1](https://github.com/diffo-dev/diffo/compare/v0.2.0...v0.2.1) (2026-05-06)

## Notable Changes
* Updated to ash_neo4j 0.4.1 and bolty 0.0.12, now supporting transactions and test sandbox
* Improvements to provider DSL and documentation

## What's Changed
* base party and related DSL and livebook by @matt-beanland in https://github.com/diffo-dev/diffo/pull/82
* Instance DSL parties — multiplicity, validation, and enforcement by @matt-beanland in https://github.com/diffo-dev/diffo/pull/89
* 86 transformers persisters verifiers by @matt-beanland in https://github.com/diffo-dev/diffo/pull/92
* 91 place dsl by @matt-beanland in https://github.com/diffo-dev/diffo/pull/93
* 79 provider instance specification doesnt set description by @matt-beanland in https://github.com/diffo-dev/diffo/pull/95
* 94 provider instance specification dsl additional fields by @matt-beanland in https://github.com/diffo-dev/diffo/pull/97
* document instance versioning lifecycle by @matt-beanland in https://github.com/diffo-dev/diffo/pull/98
* accept raw dynamic by @matt-beanland in https://github.com/diffo-dev/diffo/pull/100
* removed duplicate tests by @matt-beanland in https://github.com/diffo-dev/diffo/pull/108
* 105 latest ash neo4j by @matt-beanland in https://github.com/diffo-dev/diffo/pull/109


## [v0.2.0](https://github.com/diffo-dev/diffo/compare/v0.1.6...v0.2.0) (2026-04-24)
### Breaking Changes

* Updated to ash_neo4j 0.3.1 and bolty 0.0.10 — no database compatibility with prior versions due to significant changes in the data layer and Bolt protocol handling

### Features

* `Diffo.Type.Value` — union of `Diffo.Type.Primitive` and `Diffo.Type.Dynamic`, enabling mixed primitive and typed-struct values on characteristics and other resources
* `Diffo.Type.Primitive` — typed union of string, integer, float, boolean, date, time, datetime, duration
* `Diffo.Type.Dynamic` — runtime-typed struct for Ash.Type.NewType values
* `Diffo.Type.Dynamic.is_valid?/1` — predicate to check whether a module is a valid Dynamic type (Ash.Type.NewType with storage_type :map) before constructing a value
* `Characteristic.values` — homogeneous array of `Diffo.Type.Value` on a characteristic, with `is_array` boolean flag; supports morphing between scalar and array representations
* `Diffo.Unwrap` on `List` — unwraps each element, enabling `Diffo.Unwrap.unwrap/1` to reduce nested wrapped lists to plain Elixir values in one call
* Provider instance extension DSL — characteristic and feature characteristic value types now accept `{:array, Module}` in addition to plain module references

### Fixes

* `Diffo.Type.Value` nil update — override `handle_change/3` to prevent Ash union type from wrapping nil in the previous member type, which caused malformed JSON to be written to Neo4j
* `Diffo.Type.Value` nil array update — added nil guards to `handle_change_array/3` and `prepare_change_array/3` to prevent enumeration errors when setting an array characteristic to nil
* `Diffo.Type.Dynamic` nil safety — added nil clauses to `cast_stored/2` and `dump_to_native/2`

### Maintenance

* bolty 0.0.10 — native DateTime handling for both BOLT 4.x and BOLT 5.x
* `Diffo.Unwrap` protocol documentation — recursive unwrap behaviour, custom implementation guide, and array examples added to livebook and module docs

## [v0.1.6](https://github.com/diffo-dev/diffo/compare/v0.1.5...v0.1.6) (2026-03-19)

### Fixes

* incorrect domain label

### Maintenance

* improved error handling

 [v0.1.5](https://github.com/diffo-dev/diffo/compare/v0.1.4...v0.1.5) (2026-03-19)

### Fixes

* fixed relationship enrichment inconsistent across neo4j versions

## [v0.1.4](https://github.com/diffo-dev/diffo/compare/v0.1.3...v0.1.4) (2026-03-12)

### Features

* assigner unassign operation

### Maintenance

* updated ash_neo4j, uses bolty rather than boltx

## [v0.1.3](https://github.com/diffo-dev/diffo/compare/v0.1.2...v0.1.3) (2025-12-01)

### Features

* place_ref source party or place
* party_ref source place or party
* instance events

### Maintenance

* remove access domain

## [v0.1.2](https://github.com/diffo-dev/diffo/compare/v0.1.1...v0.1.2) (2025-10-20)

### Features

* REUSE compliant

## [v0.1.1](https://github.com/diffo-dev/diffo/compare/v0.1.0...v0.1.1) (2025-09-09)

### Features:
* update for AshNeo4j DSL changes
* refactor specification relationships
* characteristic value schemas
* customise instance via specification
* improve relationships to avoid circular loads

## [v0.1.0](https://github.com/diffo-dev/diffo/compare/v0.1.0...v0.1.0) (2025-08-11)

### Features:
* initial version on AshNeo4j DataLayer

