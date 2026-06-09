# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

import Config

# Neo4j 2026.05 over BOLT 6.0 / Cypher 25 — docker neo4j-ash-bolt6 (host port 7689).
config :bolty, Bolt,
  uri: "bolt://localhost:7689",
  auth: [username: "neo4j", password: "password"],
  user_agent: "DiffoDev/1",
  pool_size: 15,
  max_overflow: 3,
  prefix: :default,
  name: Bolt,
  log: true,
  log_hex: true

level =
  if System.get_env("DEBUG") do
    :debug
  else
    :info
  end

config :logger, :console,
  # level: level,
  level: :debug,
  format: "$date $time [$level] $metadata$message\n"
