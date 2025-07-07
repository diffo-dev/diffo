import Config

config :boltx, Bolt,
  uri: "bolt://localhost:7687",
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
  level: level,
  format: "$date $time [$level] $metadata$message\n"
