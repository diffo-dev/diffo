<!-- 
SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

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

