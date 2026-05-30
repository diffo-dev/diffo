<!-- 
SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## Unreleased

### Features

* **Service / Resource cascade — Phase A** (#4) — `Diffo.Provider.BaseInstance` is split into a shared base fragment plus two subtype fragments, `Diffo.Provider.Service` (TMF638) and `Diffo.Provider.Resource` (TMF639). A concrete instance composes `[BaseInstance, Service]` or `[BaseInstance, Resource]`. This fixes the long-standing modelling bug where a Resource carried a `service_state`: Resources now compose only the `Resource` fragment and have no service lifecycle at all.

  - **`Service` fragment** carries the `AshStateMachine` lifecycle (`state`, renamed from `service_state`), `operating_status` (renamed from `service_operating_status`), the lifecycle actions (feasibilityCheck/reserve/deactivate/activate/suspend/terminate/cancel/status), and the TMF638-shaped jason. A service **terminates** or **cancels** — it never "retires".
  - **`Resource` fragment** carries `lifecycle_state` (TMF639 v5 `lifecycleState`; ITU-T M.3701 lifecycle — `planned`/`installed`/`pendingRemoval`, with `nil` as both the initial and terminal state), the orthogonal TMF639 v4 X.731 status axes (`administrative_state`/`operational_state`/`usage_state`/`resource_status`) plus `resource_version` as nullable enums, the `lifecycle` action, and the TMF639-shaped jason. The status axes move independently (not a state machine); `resource_status` is kept `allow_nil?` as a v4 back-compat escape hatch. (The resource lifecycle is a state-machine candidate, deferred to #189.)
  - **`Diffo.Provider.Instance`** composes `[BaseInstance, Service]` — it is the generic Service and the abstract reader for projection. An instance is exactly one of Service or Resource (not both, not neither).
  - The jason wire shape is **byte-for-byte unchanged** (the `state` / `operatingStatus` keys were already those names); the renames are internal only.
  - The service-state vocabulary helper moved from `Diffo.Provider.Service` to **`Diffo.Provider.ServiceState`** (the former name now belongs to the fragment).
  - **Specification-kind guards** keep an instance and its specification on the same side of the divide: a Service must be specified by a `:serviceSpecification`, a Resource by a `:resourceSpecification`. Two complementary checks — a compile-time `Diffo.Provider.Extension.Verifiers.VerifySpecificationKind` (catches a consumer leaf mis-declaring its `specification do type`, failing their build) and a runtime `Diffo.Provider.Validations.ValidateSpecificationKind` on the `Service`/`Resource` fragments (catches the spec associated at create/specify — covering generic instances and `respecify`). Generic instances with no declared specification are not statically checked but are validated at runtime.

  **Consumer migration:** a service leaf now composes `fragments: [BaseInstance, Service]`; a resource leaf composes `fragments: [BaseInstance, Resource]` (previously `[BaseInstance]`).

  **API:** reads project to the concrete leaf — `Diffo.Provider.get_instance_by_id!/1` / `list_instances!/0` / `find_instances_by_*` return the concrete Service/Resource struct (via `AshNeo4j.worlds/1`). The lifecycle and record operations (`activate_service!`, `respecify_instance!`, `delete_instance!`, …) are now struct-dispatched functions on `Diffo.Provider` rather than code-interface definitions; existing call sites are unchanged.

  Known limitation: creating a generic instance with both features **and** characteristics is blocked by [ash_neo4j#284](https://github.com/diffo-dev/ash_neo4j/issues/284) (`AshStateMachine` + multiple same-label `manage_relationship` edges drops a `belongs_to` edge); 5 encode tests are skipped pending the upstream fix. The production consumer-leaf path (features/characteristics via the `provider do` DSL → `build_after`) is unaffected.

* **Inherited and reverse-inherited values now surface in the TMF JSON view** (#173) — a new sibling transformer `Diffo.Provider.Extension.Transformers.TransformInheritedJason` runs after `TransformInheritedRefs` (calc injection) and before `AshJason.Resource.Transformer` (encoder generation). For each inherited kind a resource declares, it injects a focused `jason.customize` step so loaded inherited calcs reach the consumer-visible array — no per-consumer customize required:

  - `inherited_place` → the `place` array, as a simulated `PlaceRef` (carries the declared role plus the inherited place's flattened identity; there is no backing ref node — the inheritance simulates it)
  - `inherited_party` → the `relatedParty` array, as a simulated `PartyRef`
  - `inherited_characteristic` / `reverse_inherited_characteristic` → the `serviceCharacteristic` / `resourceCharacteristic` array, as ordinary typed characteristics

  Surfaced entries appear after the instance's local entries. `%Diffo.Unknown{}` sentinels are filtered out before any ref wrapping — X-state is the Diffo diagnostic surface, not the TMF wire. Unloaded calcs (`%Ash.NotLoaded{}`) contribute nothing; load the calc to include it. Wire-shape concerns stay in this transformer; calc-shape concerns stay in `TransformInheritedRefs`.

### Bug Fixes

* **`Instance.Party.validate_constraints` skips inherited declarations** (#183) — the validator's `Enum.reject(&(&1.reference || &1.calculate))` was iterating ALL party declarations and KeyError'd on `InheritedPartyDeclaration` (which has no `:reference`/`:calculate` fields). Same shape of bug as the persister fix in #172 for inherited characteristics. Fix: filter to `Diffo.Provider.Extension.PartyDeclaration` before the reject — inherited variants are pre-validated by their declaration entity and have no min/max constraints to enforce.

### Behavior changes

* **`inherited_place` / `inherited_party` calcs now emit `%Diffo.Unknown{}` for reached-but-undeclared sources** (#183) — `Diffo.Provider.Calculations.InheritedPlace` and `InheritedParty` previously silently dropped source instances that didn't carry a `PlaceRef`/`PartyRef` at the declared `source_role`. The new `InheritedCharacteristic` / `ReverseInheritedCharacteristic` calcs (from #172) surface that case as `%Diffo.Unknown{}`; this aligns the older calcs with the same X-state discipline.

  Single reason vocabulary (no cross-world dispatch needed — PlaceRef/PartyRef are universal indirections):

  - `:role_not_declared` — source instance reached by alias traversal but its `PlaceRef`/`PartyRef` records carry no entry at `source_role`. Context: `%{source_id: id, role: source_role}`.

  `:world` is stamped at compile time via `TransformInheritedRefs` (previously passed only to the characteristic variants; now passed to all four inherited calcs).

  **Consumer impact**: code that `Enum.map`s `%Diffo.Provider.Place{}` (or `Party{}`) from an inherited_place/inherited_party result must now handle `%Diffo.Unknown{}` entries (filter, pattern-match, or let them propagate). The empty-list case (no sources reached at all) is unchanged — `Unknown` is reserved for "tried and couldn't determine," not "nothing to determine."

### Bug Fixes

* **Eliminate fragment-override warnings on cascade leaves** (#181) — Spark's `merge_with_warning` was firing during compile time whenever a subtype fragment (`BaseGeographicAddress`/`Site`/`Location`, `BaseOrganization`/`Individual`) declared a wider `jason.pick` / `outstanding.expect` than `BasePlace` / `BaseParty`. The merge logic has no opt-out for deliberate overrides. Fix: move `jason do` and `outstanding do` off `BasePlace` and `BaseParty` entirely; each concrete leaf carries its own declaration:

  - Abstract readers (`Provider.Place`, `Provider.Party`) now declare their own base-shape `jason do` and `outstanding do` (previously inherited from the base fragment)
  - Cascade subtype fragments continue to declare their own (no change)
  - Test-support consumer leaves were already declaring their own (audit confirmed)
  - `BasePlace.encode_geo_json/2` stays as a static helper that subtype fragments and consumer leaves reference from their own `jason.customize`

  Documented as cascade discipline in `usage-rules.md` and `AGENTS.md`. Zero behaviour change; 757 tests + 90 doctests still pass.

### Features

* **Party subtype cascade — `BaseParty` → typed subtype leaves** (#186) — TMF632 Organization and Individual now ship as concrete leaves built from fragment composition (`BaseParty` + `BaseOrganization` / `BaseIndividual`). Consumer leaves (e.g. `MyApp.Carrier`) compose the same two fragments alongside their own attributes.

  ```elixir
  defmodule Diffo.Provider.Organization do
    use Ash.Resource,
      fragments: [BaseParty, BaseOrganization],
      domain: Diffo.Provider
  end
  ```

  Attributes (TMF632 v5 cut, permissive defaults):
  - `BaseOrganization`: `trading_name`, `name_type`, `organization_type`, `is_legal_entity`, `is_head_office`
  - `BaseIndividual`: `given_name`, `family_name`, `middle_name`, `title`, `gender`, `birth_date`, `nationality`

  Deferred to follow-ups: nested arrays (`otherName[]`, `*Identification[]`, `disability[]`, `languageAbility[]`, `skill[]`), state machine attrs (pairs with `[[project_specification_lifecycle]]`), org parent/child relationships (via PartyRef machinery), richer demographics (`deathDate`, `placeOfBirth`, etc.), `existsDuring` (TimePeriod).

* **Party dispatcher API on `Diffo.Provider`** (#186) — mirrors the Place dispatcher exactly, with `:Entity` as an additional abstract-routed type alongside `:PartyRef`:

  ```elixir
  Diffo.Provider.create_party!(:Organization, %{id: "X", trading_name: "Acme"})
  Diffo.Provider.create_party!(:Individual, %{id: "Y", given_name: "Jane"})
  Diffo.Provider.create_party!(:PartyRef, %{id: "Z", referred_type: :Organization})
  Diffo.Provider.create_party!(:Entity, %{id: "E", name: "Aggregate"})

  Diffo.Provider.get_party_by_id!(id)         # returns concrete subtype struct via projection
  Diffo.Provider.list_parties!()              # mixed-subtype list, each projected

  Diffo.Provider.update_party!(record, attrs)  # struct-dispatched to :define
  Diffo.Provider.delete_party!(record)
  ```

* **`Diffo.Test.Party.Organization` → `Diffo.Test.Party.Enterprise`** (#186) — frees the canonical `Diffo.Provider.Organization` name and demonstrates consumer-style naming (paired with existing `Diffo.Test.Party.Person` which similarly demonstrates non-TMF naming for an Individual analogue).

### Breaking changes (Party)

* **`Diffo.Provider.create_party!/1` removed** — replaced by `create_party!/2`. Migration mirrors the Place migration in #185:

  ```elixir
  # Before
  Diffo.Provider.create_party!(%{type: :Organization, id: "X", ...})
  Diffo.Provider.create_party!(%{referred_type: :Individual, id: "Y"})

  # After
  Diffo.Provider.create_party!(:Organization, %{id: "X", ...})
  Diffo.Provider.create_party!(:PartyRef, %{referred_type: :Individual, id: "Y"})
  ```

* **All per-codedef Party actions on `Diffo.Provider` domain dropped** — replaced by the dispatcher functions of the same names (different arities for `create_party`).

* **`get_party_by_id/1`, `list_parties/0`, `find_parties_by_*/1` return concrete subtype structs** via `AshNeo4j.worlds/1` projection.

* **Type-change updates on cascade leaves are rejected** — typed Party leaves have fixed `:type`. PartyRef placeholders (`Provider.Party` records with `referred_type:`) still support `referred_type:` updates.

### Architectural notes (Party)

* **`Diffo.Provider.Party` stays in core minimally** — repurposed as the abstract reader for projection bootstrap + PartyRef-typed placeholder support + `:Entity` routing. Moduledoc rewritten to reflect this.
* **PartyRef typed `belongs_to` unchanged** (Option C carries over from #185) — graph integrity preserved.

* **Place subtype cascade — `BasePlace` → typed subtype leaves** (#185) — TMF675 GeographicAddress / GeographicSite / GeographicLocation now ship as concrete leaves built from fragment composition (`BasePlace` + `BaseGeographicX`). Consumer leaves (e.g. `MyApp.SydneyExchange`) compose the same two fragments alongside their own attributes.

  ```elixir
  defmodule Diffo.Provider.GeographicSite do
    use Ash.Resource,
      fragments: [BasePlace, BaseGeographicSite],
      domain: Diffo.Provider
    # …
  end
  ```

  Subtype fragments carry TMF-camelCase jason wire shape, tightened validations
  (e.g. `BaseGeographicLocation` requires location-xor-bounds set), and — on
  `BaseGeographicSite` — a projected `:address` calc that resolves to a concrete
  `GeographicAddress` (or consumer-domain Address leaf) at read time via
  `AshNeo4j.worlds/1`.

* **`Diffo.Provider.Calculations.ProjectedRef`** (#185) — reusable calculation
  for cross-resource references *without* a graph edge. Resolves an `id_field`
  to the outermost concrete world's resource struct via `AshNeo4j.worlds/1`.
  Three-state load surface: concrete struct on success, `%Diffo.Unknown{}` for
  resolution failures (`:no_target` / `:no_concrete_world` / `:projection_failed`),
  `%Ash.NotLoaded{}` until loaded. **Does NOT replace `belongs_to`** —
  AshNeo4j's `verify_relate` requires real Ash relationships to maintain edges,
  so typed `belongs_to` on PlaceRef/PartyRef stay intact (Option C).

* **Place dispatcher API on `Diffo.Provider`** (#185) — replaces per-subtype
  codedef explosion (7 codedefs × 3 subtypes = 21) with one function per CRUD
  verb that scales to N subtypes at constant API surface:

  ```elixir
  Diffo.Provider.create_place!(:GeographicSite, %{id: "X", site_type: :exchange})
  Diffo.Provider.create_place!(:PlaceRef, %{id: "Y", referred_type: :GeographicAddress})

  Diffo.Provider.get_place_by_id!(id)        # returns concrete subtype struct via projection
  Diffo.Provider.list_places!()              # mixed-subtype list, each projected

  Diffo.Provider.update_place!(record, attrs)  # struct-dispatched to :define action
  Diffo.Provider.delete_place!(record)
  ```

  Reads do inline projection (load via `Provider.Place` abstract reader → project
  via `AshNeo4j.worlds/1`). Unknown TMF type atoms raise `ArgumentError`.

* **Polymorphic-source ref dispatcher** (#185) — `create_place_ref!/1` /
  `create_party_ref!/1` accept a tagged-tuple or struct `source:` field that
  unpacks to the right FK column. `list_place_refs_from/1` /
  `list_place_refs_targeting/1` express read intent rather than per-FK
  (`list_place_refs_by_*_id`). Schema unchanged — the four FK columns stay.

  ```elixir
  Diffo.Provider.create_place_ref!(%{
    role: :installation_site,
    source: {:instance, "INST-001"},          # or {:party, ...}, {:place, ...}, or a struct
    target: place_or_id
  })

  Diffo.Provider.list_place_refs_from(source)
  Diffo.Provider.list_place_refs_targeting(target)
  ```

### Breaking changes

* **`Diffo.Provider.create_place!/1` removed** — replaced by `create_place!/2`
  (type-atom dispatcher). Migration:

  ```elixir
  # Before
  Diffo.Provider.create_place!(%{type: :GeographicSite, id: "X", ...})
  Diffo.Provider.create_place!(%{referred_type: :GeographicAddress, id: "Y"})

  # After
  Diffo.Provider.create_place!(:GeographicSite, %{id: "X", ...})
  Diffo.Provider.create_place!(:PlaceRef, %{referred_type: :GeographicAddress, id: "Y"})
  ```

* **All per-codedef Place actions on `Diffo.Provider` domain dropped**
  (`create_place`, `get_place_by_id`, `list_places`, `find_places_by_id`,
  `find_places_by_name`, `update_place`, `delete_place`) — replaced by the
  dispatcher functions of the same names (different arities for `create_place`).

* **`Diffo.Provider.get_place_by_id/1`, `list_places/0`, `find_places_by_id/1`,
  `find_places_by_name/1` now return concrete subtype structs** — projected via
  `AshNeo4j.worlds/1`, not the abstract `%Diffo.Provider.Place{}`. Tests that
  pattern-match on `%Provider.Place{}` need updating to `%Provider.GeographicSite{}`
  (etc.). Field-access assertions (`.id`, `.name`, `.type`) continue to work.

* **Type-change updates on cascade leaves are now rejected** — a typed Place
  leaf (e.g. `Provider.GeographicAddress`) cannot have its `:type` changed to
  `:GeographicSite` via `update_place!/2`; the typed leaves have fixed `:type`
  set by their `:build` action. PlaceRef-typed placeholders (`Provider.Place`
  records with `referred_type:`) still support `referred_type:` updates.

* **`GeographicLocation` now requires geometry** — `BaseGeographicLocation`
  validates that records with `type: :GeographicLocation` have `:location` or
  `:bounds` set. Pre-cascade `GeographicLocation`-typed records without geometry
  must be backfilled or re-classified as `:PlaceRef` placeholders.

### Architectural notes

* **`Diffo.Provider.Place` stays in core minimally** — repurposed as the
  abstract reader that backs projection bootstrap (symmetric with how
  `Provider.Instance` backs `inherited_characteristic`) and the PlaceRef-typed
  placeholder dispatcher path. Production code should use the typed subtype
  leaves or the dispatcher; `Provider.Place` is plumbing, not a recommendation.
  Moduledoc rewritten to reflect this.
* **`AGENTS.md` — Fat\* pattern section updated** — the original "don't split
  subtypes into fragments" advice was based on a misread of how fragment
  composition stacks. Fragment composition is additive at the leaf, not a
  budget spend. The Fat\* invariants (graph edges, indexability, no N²
  explosion) still hold under the cascade because typed `belongs_to` keeps
  pointing at the abstract reader (Option C).
* **Reanimates #4 "split Service and Resource"** — the cascade pattern
  established here is the reusable template for the Instance Service/Resource
  cascade in #4, with `ProjectedRef` + dispatcher as the shared artifacts.

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

