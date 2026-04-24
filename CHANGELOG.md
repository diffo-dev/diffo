<!-- 
SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v0.1.0](https://github.com/diffo-dev/diffo/compare/v0.1.0...v0.1.0) (2025-08-11)

### Features:
* initial version on AshNeo4j DataLayer

## [v0.1.1](https://github.com/diffo-dev/diffo/compare/v0.1.0...v0.1.1) (2025-09-09)

### Features:
* update for AshNeo4j DSL changes
* refactor specification relationships
* characteristic value schemas
* customise instance via specification
* improve relationships to avoid circular loads

## [v0.1.2](https://github.com/diffo-dev/diffo/compare/v0.1.1...v0.1.2) (2025-10-20)

### Features

* REUSE compliant

## [v0.1.3](https://github.com/diffo-dev/diffo/compare/v0.1.2...v0.1.3) (2025-12-01)

### Features

* place_ref source party or place
* party_ref source place or party
* instance events

### Maintenance

* remove access domain

## [v0.1.4](https://github.com/diffo-dev/diffo/compare/v0.1.3...v0.1.4) (2026-03-12)

### Features

* assigner unassign operation

### Maintenance

* updated ash_neo4j, uses bolty rather than boltx

## [v0.1.5](https://github.com/diffo-dev/diffo/compare/v0.1.4...v0.1.5) (2026-03-19)

### Fixes

* fixed relationship enrichment inconsistent across neo4j versions

## [v0.2.0](https://github.com/diffo-dev/diffo/compare/v0.1.6...v0.2.0) (2026-04-24)

### Breaking Changes

* Updated to ash_neo4j 0.3.1 and bolty 0.0.10 — no database compatibility with prior versions due to significant changes in the data layer and Bolt protocol handling

### Features

* `Diffo.Type.Value` — union of `Diffo.Type.Primitive` and `Diffo.Type.Dynamic`, enabling mixed primitive and typed-struct values on characteristics and other resources
* `Diffo.Type.Primitive` — typed union of string, integer, float, boolean, date, time, datetime, duration
* `Diffo.Type.Dynamic` — runtime-typed struct for Ash.Type.NewType values

### Fixes

* `Diffo.Type.Value` nil update — override `handle_change/3` to prevent Ash union type from wrapping nil in the previous member type, which caused malformed JSON to be written to Neo4j
* `Diffo.Type.Dynamic` nil safety — added nil clauses to `cast_stored/2` and `dump_to_native/2`

### Maintenance

* bolty 0.0.10 — native DateTime handling for both BOLT 4.x and BOLT 5.x

## [v0.1.6](https://github.com/diffo-dev/diffo/compare/v0.1.5...v0.1.6) (2026-03-19)

### Fixes

* incorrect domain label

### Maintenance

* improved error handling