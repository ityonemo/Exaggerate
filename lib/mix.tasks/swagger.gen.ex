defmodule Mix.Tasks.Swagger.Gen do
  use Mix.Task

  alias Exaggerate.AST
  alias Exaggerate.Endpoint
  alias Exaggerate.Router
  alias Exaggerate.Tools
  alias Exaggerate.Validator

  @shortdoc "generates an api from the supplied swaggerfile(s)"
  def run(params) do
    # do a really basic destructuring of the parameters
    [swaggerfile | _options] = params

    unless File.exists?(swaggerfile) do
      Mix.raise("No file error: can't find #{swaggerfile}")
    end

    {basename, spec_map} = load_from(swaggerfile)

    # retrieve the app name.
    appname = Mix.Project.get()
    |> apply(:project, [])
    |> Keyword.get(:app)
    |> Atom.to_string

    # create the module path
    module_dir = Path.join([
      File.cwd!,
      "lib",
      appname,
      basename <> "_web"
    ])
    File.mkdir_p(module_dir)

    # create the module base:
    module_base = Tools.camelize(appname <> "." <> basename <> "_web")

    # build the router file:
    router_code = module_base
    |> Router.module(spec_map, swaggerfile)
    |> AST.to_string

    module_dir
    |> Path.join("router.ex")
    |> File.write!(router_code)

    # build the endpoint file:
    endpoint_code = module_base
    |> Endpoint.module(spec_map, swaggerfile)
    |> AST.to_string

    module_dir
    |> Path.join("endpoint.ex")
    |> File.write!(endpoint_code)

    # build the validator file:
    validator_code = module_base
    |> Validator.module(spec_map, swaggerfile)
    |> AST.to_string

    module_dir
    |> Path.join("validator.ex")
    |> File.write!(validator_code)
  end

  @yaml_mod Application.get_env(:exaggerate, :yaml_parser_mod, YamlElixir)
  @yaml_fn  Application.get_env(:exaggerate, :yaml_parser_fn, :read_from_string!)
  def load_from(swaggerfile) do
    cond do
      swaggerfile =~ ~r/\.json$/ ->
        basename = Path.basename(swaggerfile, ".json")

        # decode the swagger file into a an Elixir spec_map
        spec_map = swaggerfile
        |> Path.expand
        |> File.read!
        |> Jason.decode!

        {basename, spec_map}

      swaggerfile =~ ~r/\.yaml$/ ->
        basename = Path.basename(swaggerfile, ".yaml")

        # decode the swagger file into a an Elixir spec_map
        yaml = swaggerfile
        |> Path.expand
        |> File.read!

        spec_map = apply(@yaml_mod, @yaml_fn, [yaml])

        {basename, spec_map}
    end
  end
end
