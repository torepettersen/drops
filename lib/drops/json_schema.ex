defmodule Drops.JsonSchema do
  alias Drops.Types

  def to_json_schema(contract) when is_atom(contract) do
    dbg(contract.schema)

    %{
      "title" => get_title(contract)
    }
    |> Map.merge(to_property(contract.schema()))
  end

  defp get_title(contract) do
    contract |> Atom.to_string() |> String.split(".") |> List.last()
  end

  defp to_property(%Types.Primitive{primitive: type}) do
    to_json_type(type)
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
      "properties" => properties,
      "required" => get_required(map)
    }
  end

  defp get_required(%Types.Map{keys: keys}) do
    keys
    |> Enum.filter(fn key -> key.presence == :required end)
    |> Enum.map(&key_name/1)
  end

  defp key_name(%Types.Map.Key{path: [name]}) do
    Atom.to_string(name)
  end

  defp to_json_type(:string), do: %{"type" => "string"}
  defp to_json_type(:integer), do: %{"type" => "integer"}
  defp to_json_type(:float), do: %{"type" => "number"}
  defp to_json_type(:boolean), do: %{"type" => "boolean"}
  defp to_json_type(:atom), do: %{"type" => "string"}
  defp to_json_type(:date), do: %{"type" => "string", "format" => "date"}
  defp to_json_type(:date_time), do: %{"type" => "string", "format" => "date-time"}
  defp to_json_type(nil), do: %{"type" => "null"}
end
