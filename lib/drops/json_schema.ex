defmodule Drops.JsonSchema do
  @moduledoc false

  alias Drops.Types

  def to_json_schema(contract) when is_atom(contract) do
    %{
      "title" => get_title(contract)
    }
    |> Map.merge(to_property(contract.schema()))
  end

  defp get_title(contract) do
    contract |> Atom.to_string() |> String.split(".") |> List.last()
  end

  defp to_property(%Types.Primitive{constraints: constraints} = primitive) do
    constraints
    |> handle_predicate()
    |> maybe_add_description(primitive)
  end

  defp to_property(%Types.Map.Key{type: type} = key) do
    {key_name(key), to_property(type)}
  end

  defp to_property(%Types.List{member_type: type}) do
    %{"type" => "array", "items" => to_property(type)}
  end

  defp to_property(%Types.Map{keys: keys} = map) do
    properties =
      keys
      |> Enum.map(&to_property/1)
      |> Enum.into(%{})

    %{
      "type" => "object",
      "properties" => properties
    }
    |> maybe_add_required(map)
  end

  defp to_property(%Types.Union{left: left, right: right}) do
    %{"anyOf" => [to_property(left), to_property(right)]}
  end

  defp maybe_add_required(map, %Types.Map{keys: keys}) do
    required =
      keys
      |> Enum.filter(fn key -> key.presence == :required end)
      |> Enum.map(&key_name/1)

    case required do
      [_ | _] -> Map.put(map, "required", required)
      [] -> map
    end
  end

  defp key_name(%Types.Map.Key{path: [name]}) do
    Atom.to_string(name)
  end

  defp handle_predicate({:predicate, predicate}) when is_tuple(predicate),
    do: handle_predicate(predicate)

  defp handle_predicate({:type?, :string}), do: %{"type" => "string"}
  defp handle_predicate({:type?, :integer}), do: %{"type" => "integer"}
  defp handle_predicate({:type?, :float}), do: %{"type" => "number"}
  defp handle_predicate({:type?, :boolean}), do: %{"type" => "boolean"}
  defp handle_predicate({:type?, :atom}), do: %{"type" => "string"}
  defp handle_predicate({:type?, nil}), do: %{"type" => "null"}
  defp handle_predicate({:type?, :date}), do: %{"type" => "string", "format" => "date"}

  defp handle_predicate({:type?, :date_time}),
    do: %{"type" => "string", "format" => "date-time"}

  defp handle_predicate({:in?, list}) when is_list(list), do: %{"enum" => list}

  defp handle_predicate({:and, predicate}) when is_list(predicate) do
    handle_predicate(predicate)
  end

  defp handle_predicate(predicate) when is_list(predicate) do
    predicate
    |> Enum.map(&handle_predicate/1)
    |> Enum.reduce(%{}, &Map.merge/2)
  end

  defp handle_predicate(_), do: %{}

  defp maybe_add_description(map, %{description: description})
       when is_binary(description) do
    Map.put(map, "description", description)
  end

  defp maybe_add_description(map, _), do: map
end
