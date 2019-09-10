# Exaggerate

** A OpenAPI (swagger) -> Plug code generator for Elixir **

Works in progress:

- `mix swagger.update`
- support for internal `$ref` structures
- support for server definitions
- code checking during `test` phases to ensure output complies with spec.

## Installation

This library requires Elixir 1.6 (because of code prettification)

## Running

```bash
  mix swagger <swaggerfile>
```

The swaggerfile should be in the root directory.  Creates two files, `routes.ex`
and `endpoints.ex`, which are in `$ROOT/lib/$MODULE` where module is generated
from the swaggerfile prefix.

### Example (swagger.io petshop)

```bash
  mix new myproject --sup

  cd myproject
  # edit the mix.exs file (see below)
  # edit the lib/myproject/application.ex file (see below)

  mix deps.get

  #grab the petshop swaggerfile
  wget http://petstore.swagger.io/v2/swagger.json

  mix swagger swagger.json
```

- modified, minimal mix.exs settings:

```elixir
  def application do
    [
      applications: [:cowboy, :plug],
      extra_applications: [:logger],
      mod: {Myproject.Application, []}
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0.0", only: :test},
      {:exaggerate, git: "https://github.com/ityonemo/exaggerate.git"},
      {:yaml_elixir, "~> 2.4"}  # if you want to read yaml files
    ]
  end
```

If you want to use yaml as your input format, you'll have to include a YAML
parser.  This library defaults to "yamilixir" but you can specify your own
by setting the `:yaml_parser` application variable.

Note that if you use a yaml file, you cannot have your error codes be numerical
literals, they must be surrounded by quotation marks.

- modified application.ex settings

```elixir
  children = [
    Plug.Adapters.Cowboy.child_spec(:http, Swagger.Routes, [], [port: 4001])
  ]
```

## Testing

- basic mix-based unit and integration tests

```bash
  mix test
```

- integration tests (bash script)

```bash
  ./lib/integration-test.sh
```

## response encoding.

the default response encoding for JSON is Jason.
