# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

Mix.Task.run("app.start")
ExUnit.start()
level = Application.get_env(:logger, :console) |> Keyword.get(:level)
Logger.put_application_level(:ash_neo4j, level)
