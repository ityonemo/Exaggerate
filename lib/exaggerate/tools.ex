defmodule Exaggerate.Tools do

  alias Plug.Conn
  @type error :: {:error, integer, String.t}

  @spec get_path(Plug.Conn.t, String.t, :string) :: {:ok, String.t}
  @spec get_path(Plug.Conn.t, String.t, :integer) :: {:ok, integer} | error
  def get_path(conn, index, format \\ :string) do
    conn
    |> Map.get(:path_params)
    |> Map.get(index)
    |> check_format(format)
    |> handle_result(index)
  end

  @spec get_query(Plug.Conn.t, String.t, :string) :: {:ok, String.t}
  @spec get_query(Plug.Conn.t, String.t, :integer) :: {:ok, integer} | error
  def get_query(conn, index, format \\ :string) do
    conn
    |> Conn.fetch_query_params
    |> Map.get(:query_params)
    |> Map.get(index)
    |> check_format(format)
    |> handle_result(index)
  end

  @spec get_header(Plug.Conn.t, String.t, :string) :: {:ok, String.t} | error
  def get_header(conn, index, format \\ :string) do
    conn.req_headers
    |> find_header(index)
    |> check_format(format)
    |> handle_result(index)
  end

  @spec find_header([{String.t, String.t}], String.t) :: String.t
  defp find_header(headers, index) do
    Enum.find_value(headers, fn
      {k, v} -> if k == String.downcase(index), do: v end)
  end

  @spec get_cookie(Plug.Conn.t, String.t, :string) :: {:ok, String.t} | error
  def get_cookie(conn, index, format \\ :string) do
    conn
    |> Conn.fetch_cookies
    |> Map.get(:cookies)
    |> Map.get(index)
    |> check_format(format)
    |> handle_result(index)
  end

  @spec match_mimetype(Plug.Conn.t, [String.t])::{:ok, String.t} | error
  def match_mimetype(conn, _mimetypes) do
    IO.inspect(conn, label: "matchmimetype")
    {:ok, "application/json"}
  end

  @spec get_body(Plug.Conn.t) :: {:ok, any}
  def get_body(conn) do
    IO.inspect(conn, label: "conn")
    IO.inspect(conn.body_params, label: "conn/body_params")
    handle_result(conn.body_params, "content")
  end

  ###############################################################
  ## general helper utility functions

  defp check_format(nil, _), do: nil
  defp check_format(v, :string), do: v
  defp check_format(v, :integer) do
    v
    |> Integer.parse
    |> case do
      {int_val, ""} -> int_val
      _ -> {:error, 400, "invalid integer: #{v}"}
    end
  end

  defp handle_result(nil, index), do: {:error, 400, "missing value: #{index}"}
  defp handle_result(e = {:error, _, _}, _), do: e
  defp handle_result(%{"_json" => v}, _), do: {:ok, v}
  defp handle_result(v, _), do: {:ok, v}
end