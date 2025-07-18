Mix.Task.run("app.start")
ExUnit.start()
level = Application.get_env(:logger, :console) |> Keyword.get(:level)
Logger.put_application_level(:ash_neo4j, level)
