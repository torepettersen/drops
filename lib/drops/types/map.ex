defmodule Drops.Types.Map do
  @moduledoc ~S"""
  Drops.Types.Map is a struct that represents a map type with optional constraints.

  ## Examples

      iex> Drops.Type.Compiler.visit({:type, {:map, []}}, [])
      %Drops.Types.Primitive{primitive: :map, constraints: [predicate: {:type?, :map}]}

      iex> Drops.Type.Compiler.visit(%{
      ...>   {:required, :name} => {:type, {:string, []}},
      ...>   {:optional, :age} => {:type, {:integer, []}}
      ...> }, [])
      %Drops.Types.Map{
        primitive: :map,
        constraints: [predicate: {:type?, :map}],
        keys: [
          %Drops.Types.Map.Key{
            path: [:age],
            presence: :optional,
            type: %Drops.Types.Primitive{
              primitive: :integer,
              constraints: [predicate: {:type?, :integer}]
            }
          },
          %Drops.Types.Map.Key{
            path: [:name],
            presence: :required,
            type: %Drops.Types.Primitive{
              primitive: :string,
              constraints: [predicate: {:type?, :string}]
            }
          }
        ],
        atomize: false
      }

  """

  alias Drops.Predicates
  alias Drops.Types.Map.Key

  use Drops.Type do
    deftype(:map, keys: [], atomize: false)

    def new(keys, opts) when is_list(keys) do
      atomize = opts[:atomize] || false
      struct(__MODULE__, keys: keys, atomize: atomize)
    end
  end

  defimpl Drops.Type.Validator, for: Map do
    def validate(%{atomize: true, keys: keys} = type, data) do
      case apply_predicates(Map.atomize(data, keys), type.constraints) do
        {:ok, result} ->
          results = Enum.map(type.keys, &Key.validate(&1, result)) |> List.flatten()
          errors = Enum.reject(results, &is_ok/1)

          if Enum.empty?(errors),
            do: {:ok, {:map, results}},
            else: {:error, {:map, results}}

        {:error, errors} ->
          {:error, errors}
      end
    end

    def validate(type, data) do
      case apply_predicates(data, type.constraints) do
        {:ok, result} ->
          results = Enum.map(type.keys, &Key.validate(&1, result)) |> List.flatten()
          errors = Enum.reject(results, &is_ok/1)

          if Enum.empty?(errors),
            do: {:ok, {:map, results}},
            else: {:error, {:map, results}}

        {:error, {value, meta}} ->
          {:error, Keyword.merge([input: value], meta)}

        {:error, errors} ->
          {:error, errors}
      end
    end

    defp apply_predicates(value, {:and, predicates}) do
      apply_predicates(value, predicates)
    end

    defp apply_predicates(value, predicates) do
      Enum.reduce(predicates, {:ok, value}, &apply_predicate(&1, &2))
    end

    defp apply_predicate({:predicate, {name, args}}, {:ok, value}) do
      apply_args =
        case args do
          [arg] -> [arg, value]
          [] -> [value]
          arg -> [arg, value]
        end

      if apply(Predicates, name, apply_args) do
        {:ok, value}
      else
        {:error, {value, predicate: name, args: apply_args}}
      end
    end

    defp apply_predicate(_, {:error, _} = error) do
      error
    end

    defp is_ok(results) when is_list(results), do: Enum.all?(results, &is_ok/1)
    defp is_ok(:ok), do: true
    defp is_ok({:ok, _}), do: true
    defp is_ok(:error), do: false
    defp is_ok({:error, _}), do: false
  end

  def atomize(data, keys, initial \\ %{}) do
    Enum.reduce(keys, initial, fn %{path: path} = key, acc ->
      stringified_key = Key.stringify(key)

      if Key.present?(data, stringified_key) do
        put_in(acc, path, get_in(data, stringified_key.path))
      else
        acc
      end
    end)
  end
end
