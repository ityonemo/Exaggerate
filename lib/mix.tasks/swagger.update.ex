defmodule Mix.Tasks.Swagger.Update do
  use Mix.Task

  alias Exaggerate.AST
  alias Exaggerate.Endpoint
  alias Exaggerate.Tools
  alias Exaggerate.Updater
  alias Exaggerate.Validator
  alias Mix.Tasks.Swagger.Gen

  @shortdoc "updates an api from the supplied swaggerfile(s)"
  def run(params) do
    # do a really basic destructuring of the parameters
    [swaggerfile | _options] = params

    unless File.exists?(swaggerfile) do
      Mix.raise("No file error: can't find #{swaggerfile}")
    end

    {basename, spec_map} = Gen.load_from(swaggerfile)

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

    # create the module base:
    module_base = Tools.camelize(appname <> "." <> basename <> "_web")

    unless File.dir?(module_dir) do
      Mix.raise("Update file error: can't find directory #{module_dir}")
    end

    router_file = Path.join(module_dir, "router.ex")

    unless File.exists?(router_file) do
      Mix.raise("Update file error: can't find file #{router_file}")
    end

    endpoint_file = Path.join(module_dir, "endpoint.ex")

    unless File.exists?(router_file) do
      Mix.raise("Update file error: can't find file #{endpoint_file}")
    end

    # rebuild the router file:
    code = File.read!(router_file)
    new_code = Updater.update_router(module_base, code, spec_map)
    File.write!(router_file, new_code)

    # rebuild the endpoint file:
    endpoint_code = File.read!(endpoint_file)
    new_endpoint_code = Updater.update_endpoint(endpoint_code, spec_map)
    File.write!(endpoint_file, new_endpoint_code)

    # rebuild the validator file wholesale:
    validator_code = module_base
    |> Validator.module(spec_map, swaggerfile)
    |> AST.to_string

    module_dir
    |> Path.join("validator.ex")
    |> File.write!(validator_code)
  end
end


