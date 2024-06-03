defmodule Drops.JsonSchemaTest do
  use Drops.ContractCase, async: true

  alias Drops.JsonSchema

  describe "to_json_schema/1" do
    contract do
      schema do
        %{
          required(:some_atom) => type(:atom),
          required(:some_boolean) => boolean(),
          optional(:some_float) => float(),
          optional(:some_integer) => integer(),
          optional(:some_nil) => type(nil),
          optional(:some_string) => string(),
          optional(:some_date) => type(:date),
          optional(:some_date_time) => type(:date_time),
          optional(:some_list) => list(:string),
          required(:nested_map) => %{
            required(:nested_property) => string()
          }
        }
      end
    end

    test "creates json schema", %{contract: contract} do
      assert %{
               "title" => "TestContract",
               "type" => "object",
               "properties" => %{
                 "some_atom" => %{"type" => "string"},
                 "some_boolean" => %{"type" => "boolean"},
                 "some_float" => %{"type" => "number"},
                 "some_integer" => %{"type" => "integer"},
                 "some_nil" => %{"type" => "null"},
                 "some_string" => %{"type" => "string"},
                 "some_date" => %{"type" => "string", "format" => "date"},
                 "some_date_time" => %{"type" => "string", "format" => "date-time"},
                 "some_list" => %{"type" => "array", "items" => %{"type" => "string"}},
                 "nested_map" => %{
                   "properties" => %{
                     "nested_property" => %{"type" => "string"}
                   },
                   "required" => ["nested_property"]
                 }
               },
               "required" => ["nested_map", "some_atom", "some_boolean"]
             } =
               JsonSchema.to_json_schema(contract)
    end
  end
end
