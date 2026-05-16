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
lib/diffo/provider/
  extension.ex                  # Unified Spark DSL extension (provider do)
  extension/
    info.ex                     # Runtime introspection via Spark.InfoGenerator
    characteristic.ex           # Characteristic build helpers
    feature.ex                  # Feature build helpers
    instance_role.ex            # InstanceRole struct
    party_declaration.ex        # PartyDeclaration struct
    place_declaration.ex        # PlaceDeclaration struct
    party_role.ex               # PartyRole struct (Party/Place kinds)
    place_role.ex               # PlaceRole struct (Party/Place kinds)
    persisters/                 # Spark transformers — bake DSL state into module
    transformers/               # TransformBehaviour — action argument injection
    verifiers/                  # Compile-time DSL correctness checks
  base_instance.ex              # Ash Fragment for Instance resources
  base_party.ex                 # Ash Fragment for Party resources
  base_place.ex                 # Ash Fragment for Place resources
  components/
    base_characteristic.ex      # Ash Fragment for typed characteristic resources
    calculations/
      characteristic_value.ex   # Calculation: builds .Value TypedStruct from record fields
    instance/extension.ex       # Thin marker (sections: []) — kind identification
    party/extension.ex          # Thin marker
    place/extension.ex          # Thin marker

test/provider/extension/        # All provider extension tests
  instance_transformer_test.exs
  party_transformer_test.exs
  place_transformer_test.exs
  instance_verifier_test.exs
  party_verifier_test.exs
  place_verifier_test.exs
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

## Common agent mistakes

- Using old `structure do` / top-level `instances do` — use `provider do` only.
- Using `party :role, Type, reference: true` — use `party_ref :role, Type`.
- Using a plain `Ash.TypedStruct` as a `characteristic` DSL target — use a `BaseCharacteristic`-derived resource instead; the TypedStruct belongs in `<Module>.Value`.
- Calling `build_before/1` or `build_after/2` in actions — these run automatically.
- Declaring `:specified_by`, `:features`, `:characteristics` as action arguments.
- Editing `documentation/dsls/DSL-Diffo.Provider.Extension.md` — it is Spark-generated;
  run `mix spark.cheat_sheets` to regenerate it.
- Editing content between `<!-- usage-rules-start -->` markers in `CLAUDE.md` — that is
  auto-generated by `mix usage_rules.sync`.
