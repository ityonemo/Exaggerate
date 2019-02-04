defmodule Exaggerate.Endpoint do

  alias Exaggerate.AST

  @type defmod_ast  :: {:defmodule, any, any}
  @type def_ast     :: {:def, any, any}
  @type endpointmap :: %{required(atom) => list(atom)}

  @doc """
  generates a skeleton endpoint module from an module name (string) and an
  endpoint map, which is a map structure representing atoms matched with a
  list of parameters to be passed into the map.

  Typically, the module name will derive from the basename of the json file
  from which the swagger template comes.  In general, this function will be
  called by `mix swagger` but not `mix swagger update`, which will parse out
  the existing functions first.
  """
  @spec module(String.t, endpointmap) :: defmod_ast
  def module(module_name, endpoints) do
    code = Enum.map(endpoints, &block/1)

    module = (module_name <> "_web")
    |> Macro.camelize
    |> Module.concat(Endpoint)

    quote do
      defmodule unquote(module) do
        unquote_splicing(code)
      end
    end
  end

  @doc """
  generates a skeleton endpoint block from an endpoint name (atom) and a
  list of matched variables.

  This block is intended to be filled out by the user.  @comment values
  are going to be swapped out, later in AST processing, for # comments.
  """
  @spec block({atom, [atom]}) :: def_ast
  def block({ep, v}), do: block(ep, v)
  @spec block(atom, [atom]) :: def_ast
  def block(endpoint, vars) do
    raise_str = "error: #{endpoint} not implemented"
    mvars = Enum.map(vars, fn var -> {var, [], Elixir} end)
    quote do
      def unquote(endpoint)(conn, unquote_splicing(mvars)) do
        @comment "autogen function."
        @comment "insert your code here, then delete"
        @comment "the next exception:"

        raise unquote(raise_str)
      end
    end
  end

  @doc """
  analyzes an existing module document and retrieves a list of implemented
  endpoints.
  """
  @spec list(String.t | iodata) :: [atom]
  def list(modulecode) when is_binary(modulecode) do
    modulecode
    |> Code.format_string!
    |> list
  end
  def list(["def", " ", endpoint | rest]) do
    [String.to_atom(endpoint) | list(rest)]
  end
  def list([]), do: []
  def list([_ | rest]), do: list(rest)

  @doc """
  pulls an existing file which contains an endpoint module and retrieves a
  list of implemented endpoints.
  """
  @spec list_file(Path.t) :: [atom]
  def list_file(filepath) do
    filepath
    |> Path.expand
    |> File.read!
    |> list
  end

  defp insert_routes(content, new_routes) do
    lines = String.split(content, "\n")

    last_end_idx = lines
    |> Enum.with_index
    |> Enum.filter(fn {str, _} -> String.contains?(str, "end") end)
    |> Enum.map(fn {_, idx} -> idx end)
    |> Enum.max

    lines
    |> Enum.slice(0..(last_end_idx - 1))
    |> Enum.concat(new_routes)
    |> Enum.concat(["end\n"])
    |> Enum.join("\n")
    |> Code.format_string!
  end

  @spec update(Path.t, map) :: :ok | {:error, any}
  def update(filepath, routespec) do
    existing_routes = list_file(filepath)

    new_routes = routespec
    |> Enum.reject(fn {k, _} -> k in existing_routes end)
    |> Enum.map(&block/1)
    |> Enum.map(&AST.to_string/1)

    updated_content = filepath
    |> File.read!
    |> insert_routes(new_routes)
    |> Enum.concat(["\n"])

    File.write!(filepath, updated_content)
  end

end
