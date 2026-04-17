# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

import Config

config :ash, disable_async?: true
config :ash, :missed_notifications, :ignore

config :bolty, Bolt,
  uri: "bolt://localhost:7687",
  auth: [username: "neo4j", password: "password"],
  user_agent: "DiffoTest/1",
  pool_size: 15,
  max_overflow: 3,
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
