# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

import Config

config :ash, disable_async?: true
config :ash, :missed_notifications, :ignore

# Neo4j 2026.05 over BOLT 6.0 / Cypher 25 — docker neo4j-ash-bolt6 (host port 7689).
#
# AshNeo4j.Sandbox gives each async test a dedicated connection held open for its whole
# (uncommitted) transaction, so peak concurrent connections == ExUnit's max_cases, which
# defaults to 2 * System.schedulers_online(). If the pool is smaller than the core count
# the async suite starves ("connection not available ... dropped from queue") — sharper
# against 2026.05/BOLT 6, which serves each connection more slowly than 5.26 did. Size the
# pool to the scheduler count (+ headroom) so it scales with the machine / CI runner.
bolt_pool_size = System.schedulers_online() * 2 + 2

config :bolty, Bolt,
  uri: "bolt://localhost:7689",
  auth: [username: "neo4j", password: "password"],
  user_agent: "DiffoTest/1",
  pool_size: bolt_pool_size,
  max_overflow: 4,
  prefix: :default,
  name: Bolt,
  log: false,
  log_hex: false

level =
  if System.get_env("DEBUG") do
    :debug
  else
    :info
  end

config :logger, level: level

config :logger, :console,
  level: level,
  format: "$date $time [$level] $metadata$message\n"
