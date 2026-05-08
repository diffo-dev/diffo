<!--
SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Diffo

[![Module Version](https://img.shields.io/hexpm/v/diffo)](https://hex.pm/packages/diffo)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen)](https://hexdocs.pm/diffo/)
[![License](https://img.shields.io/hexpm/l/diffo)](https://github.com/diffo-dev/diffo/blob/master/LICENSES/MIT.md)
[![REUSE status](https://api.reuse.software/badge/github.com/diffo-dev/diffo)](https://api.reuse.software/info/github.com/diffo-dev/diffo)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/diffo-dev/diffo)

Diffo is a Telecommunications Management Forum (TMF) Service and Resource Manager, built for autonomous networks.

It is implemented using the [Ash Framework](https://www.ash-hq.org) leveraging core and community extensions including some created and maintained by [diffo-dev](https://github.com/diffo-dev/). As such it is highly customizable using Spark DSL and as necessary Elixir.

Diffo models relationships between all domain entities (Ash resources) and persists these in [Neo4j](https://github.com/neo4j/neo4j), an open source graph based database.

Diffo comes with all Ash resources to implement:
  * TMF638 Service Inventory Management
  * TMF639 Resource Inventory Management

Diffo can simply be used as an inventory system paired with conventional orchestration, and while this is a good starting point, we recommend dynamic orchestration, where orchestration (or rather choreography) is done in order to ensure goals are met autonomously.

Diffo can be used to implement 'a difference engine' which allows closed loop autonomy by acting on outstanding goals. Intents can be expressed as persistent expectations, and these are compared with actual instances to compute an outstanding instance, which simply contains unmet expectations in the original structure. This can then be used to derive the next task, which typically impacts actual but may also refine our expectations. In this way the workflow is synthesized from small tasks.

Expected and actual instances are compared using the [Elixir Outstanding Protocol](https://github.com/diffo-dev/outstanding), via the [Ash Outstanding Extension](https://github.com/diffo-dev/ash_outstanding)

Diffo can be used for any combination of service-service, service-resource and resource-resource, where expectations can be held for internal or external actual services and/or resources. 

Diffo is especially suited for use in organisations with loosely coupled 'entity based' enterprise architecture where network entities can run diffo inside their entity without requiring or expecting other entities to do so.

## Installation

The recommended way to install Diffo is with [Igniter](https://hexdocs.pm/igniter):

```bash
mix igniter.install diffo
```

This will add the dependency, configure Neo4j (via `ash_neo4j`), register the custom expression, and set up the Spark formatter.

Alternatively, add `diffo` to your list of dependencies in `mix.exs` manually:

```elixir
def deps do
  [
    {:diffo, "~> 0.2.1"}
  ]
end
```

You will need [Neo4j](https://github.com/neo4j/neo4j) available. We recommend the Neo4j Community 5 latest, available at [Neo4j Deploymnent Centre](https://neo4j.com/deployment-center/) which can be installed locally. You can also configure connection to a cloud based database service such as [Neo4j AuraDB](https://neo4j.com/product/auradb/).

## Tutorial

To get started you need a running instance of [Livebook](https://livebook.dev/)

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fdiffo%2Ddev%2Fdiffo%2Fblob%2Fdev%2Fdiffo.livemd)

### Diffo.Type — no Neo4j required

Explore `Diffo.Type.Value`, `Diffo.Type.Primitive`, and `Diffo.Type.Dynamic` in pure Elixir without a database connection.

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fdiffo%2Ddev%2Fdiffo%2Fblob%2Fdev%2Fdocumentation%2Fhow_to%2Fuse_diffo_type.livemd)


## Future Work

We plan to support:
* an intent based interface for managing both consumer and provider expectations
* expose MCP so that services and resources can be defined by your agent
* incorporate an an agent based framework so that your TMF service and resource instances are backed by co-operating intelligent agents
* embedded diffo, enabling intelligent network elements that natively communicate with TMF protocols

## Contributions

Contributions are welcome, please start with either a [discussion](https://github.com/diffo-dev/diffo/issues) or [issue](https://github.com/diffo-dev/diffo/issues)

## Acknowledgements

Thanks to my colleagues in the Telco industry, in particular those who I've collaborated with in the Telco industry.

Thanks to the vibrant Elixir and Ash communities, and in particular the [Ash Core](https://github.com/ash-project) for [ash](https://github.com/ash-project/ash) 🚀

Thanks to [Florin Patrascu](https://github.com/florinpatrascu) for [bolt_sips](https://github.com/florinpatrascu/bolt_sips) and[Luis Sagastume](https://github.com/sagastume) for [boltx](https://github.com/sagastume/boltx), both forerunners of [bolty](https://github.com/diffo-dev/bolty) the bolt driver for neo4j.

Thanks to the [Neo4j Core](https://github.com/neo4j) for [neo4j](https://github.com/neo4j/neo4j) and pioneering work on graph databases.

## Links

[Diffo.dev](https://www.diffo.dev)
[Neo4j Deployment Centre](https://neo4j.com/deployment-center/)
[TMF](https://www.tmforum.org)

