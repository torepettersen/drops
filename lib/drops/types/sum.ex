defmodule Drops.Types.Union do
  @moduledoc ~S"""
  Drops.Types.Union is a struct that represents a union type with left and right types.

  ## Examples

      iex> Drops.Type.Compiler.visit([{:type, {:string, []}}, {:type, {:integer, []}}], [])
      %Drops.Types.Union{
        left: %Drops.Types.Primitive{
          primitive: :string,
          constraints: [predicate: {:type?, :string}]
        },
        right: %Drops.Types.Primitive{
          primitive: :integer,
          constraints: [predicate: {:type?, :integer}]
        },
        opts: []
      }

  """

  defmodule Validator do
    def validate(%{left: left, right: right}, input) do
      case Drops.Type.Validator.validate(left, input) do
        {:ok, value} ->
          {:ok, value}

        {:error, _} = left_error ->
          case Drops.Type.Validator.validate(right, input) do
            {:ok, value} ->
              {:ok, value}

            {:error, _} = right_error ->
              {:error, {:or, {left_error, right_error}}}
          end
      end
    end
  end

  defmacro __using__(spec) do
    quote do
      use Drops.Type do
        deftype([:left, :right, :opts])

        alias Drops.Type.Compiler
        import Drops.Types.Union

        def new(opts) do
          {:union, {left, right}} = unquote(spec)

          struct(__MODULE__, %{
            left: Compiler.visit(left, opts),
            right: Compiler.visit(right, opts),
            opts: opts
          })
        end

        defimpl Drops.Type.Validator, for: __MODULE__ do
          def validate(type, data), do: Validator.validate(type, data)
        end
      end
    end
  end

  use Drops.Type do
    deftype([:left, :right, :opts])

    def new(left, right) when is_struct(left) and is_struct(right) do
      struct(__MODULE__, left: left, right: right)
    end
  end

  defimpl Drops.Type.Validator, for: Union do
    def validate(type, input), do: Validator.validate(type, input)
  end
end
