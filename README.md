# Diffo

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

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `diffo` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:diffo, "~> 0.1.0"}
  ]
end
```

You should need [Neo4j](https://github.com/neo4j/neo4j) available. We recommend the Neo4j Community 5 latest, available at [Neo4j Deploymnent Centre](https://neo4j.com/deployment-center/) which can be installed locally. You can also configure connection to a cloud based database service such as [Neo4j AuraDB](https://neo4j.com/product/auradb/).

## Tutorial

To get started you need a running instance of [Livebook](https://livebook.dev/)

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fdiffo%2Ddev%2Fdiffo%2Fblob%2Fdev%2Fdiffo.livemd)


## Future Work

We plan to support:
* an intent based interface for managing both consumer and provider expectations
* expose MCP so that services and resources can be defined by your agent
* incorporate an an agent based framework so that your TMF service and resource instances are backed by co-operating intelligent agents
* embedded diffo, enabling intelligent network elements that natively communicate with TMF protocols

## Contributions

Contributions are welcome, please start with either a [discussion](https://github.com/diffo-dev/diffo/issues) or [issue](https://github.com/diffo-dev/diffo/issues)

## Acknowledgements

Thanks to [Telstra](https://www.telstra.com.au/) for supporting innovation in orchestration and inventory shared-tech which resulted in the award winning difference engine [2024 TMF Excellence Award in Autonomous Networks](https://www.tmforum.org/about/awards-and-recognition/excellence-awards/winners-2024/) powering three network service entities enabling outstanding product experience [2025 TMF Excellence Award in Customer Experience](https://www.tmforum.org/about/awards-and-recognition/excellence-awards/winners-2025/) and inspiring both this open source and internal shared-tech.

Thanks to the [Ash Core](https://github.com/ash-project) for [ash](https://github.com/ash-project/ash) 🚀

Thanks to [Sagastume](https://github.com/sagastume) for [boltx](https://github.com/tiagodavi/ex4j) which is used by the [Ash Neo4j DataLayer](https://github.com/diffo-dev/ash_neo4j)

Thanks to the [Neo4j Core](https://github.com/neo4j) for [neo4j](https://github.com/neo4j/neo4j) and pioneering work on graph databases.

## Links

[Diffo.dev](https://www.diffo.dev)
[Neo4j Deployment Centre](https://neo4j.com/deployment-center/)
[TMF](https://www.tmforum.org)

