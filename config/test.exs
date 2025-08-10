import Config

config :logger, level: :warning
config :ash, disable_async?: true
config :ash, :missed_notifications, :ignore

config :boltx, Bolt,
  uri: "bolt://localhost:7687",
  auth: [username: "neo4j", password: "password"],
  user_agent: "DiffoTest/1",
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
  level: level,
  format: "$date $time [$level] $metadata$message\n"
