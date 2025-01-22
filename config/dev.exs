import Config

config :diffo, Diffo.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "diffo_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
