defmodule ExaggerateTest.AstTest do
  use ExUnit.Case

  alias Exaggerate.AST

  describe "constructing with blocks" do
    test "in the simplest case" do

      clauses = [quote do {:ok, a} <- my_function(b) end]
      coda = quote do do_stuff() end

      assert """
      with {:ok, a} <- my_function(b) do
        do_stuff()
      end
      """ == clauses
      |> AST.generate_with(coda)
      |> AST.to_string
    end

    test "more than one check cases" do
      clauses = [quote do {:ok, a} <- my_function(b) end,
                 quote do {:ok, c} <- my_function(a) end]
      coda = quote do do_stuff(c) end

      assert """
      with {:ok, a} <- my_function(b), {:ok, c} <- my_function(a) do
        do_stuff(c)
      end
      """ == clauses
      |> AST.generate_with(coda)
      |> AST.to_string
    end

    test "with a single else case" do
      clauses = [quote do {:ok, a} <- my_function(b) end]
      coda = quote do do_stuff() end
      ecases = [quote do {:error, abc} -> Logger.error(abc) end]

      assert """
      with {:ok, a} <- my_function(b) do
        do_stuff()
      else
        {:error, abc} ->
          Logger.error(abc)
      end
      """ == clauses
      |> AST.generate_with(coda, ecases)
      |> AST.to_string
    end

    test "with a multiple else cases" do
      clauses = [quote do {:ok, a} <- my_function(b) end]
      coda = quote do do_stuff() end
      ecases = [quote do {:error, abc} -> Logger.error(abc) end,
                quote do {:error, :hi} -> Logger.error("hi") end]

      assert """
      with {:ok, a} <- my_function(b) do
        do_stuff()
      else
        {:error, abc} ->
          Logger.error(abc)

        {:error, :hi} ->
          Logger.error("hi")
      end
      """ == clauses
      |> AST.generate_with(coda, ecases)
      |> AST.to_string
    end
  end

  @doc """
  normalizes an ast.
  """
  def n(ast) do
    ast |> Macro.to_string |> Code.format_string!
  end

  describe "decommenting operation" do
    test "simple stuff is untouched" do
      q = quote do
        defmodule M do
          def f(x) do
            x + 1
          end
        end
      end

      assert n(q) == n(AST.decomment(q))
    end

    test "module level comments are removed" do
      q1 = quote do
        defmodule M do
          @comment "bad comment"
          def f(x), do: x + 1
        end
      end
      q2 = quote do
        defmodule M do
          def f(x), do: x + 1
        end
      end

      assert n(q2) == n(AST.decomment(q1))
    end

    test "empty comments are removed" do
      q1 = quote do
        defmodule M do
          @comment
          @comment "bad comment"
          def f(x), do: x + 1
        end
      end
      q2 = quote do
        defmodule M do
          def f(x), do: x + 1
        end
      end

      assert n(q2) == n(AST.decomment(q1))
    end

    test "function-level comments are removed" do
      q1 = quote do
        defmodule M do
          def f(x) do
            @comment "bad comment"
            x + 1
          end
        end
      end
      q2 = quote do
        defmodule M do
          def f(x) do
            x + 1
          end
        end
      end

      assert n(q2) == n(AST.decomment(q1))
    end
  end
end
