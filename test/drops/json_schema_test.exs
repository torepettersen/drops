defmodule Drops.JsonSchemaTest do
  use Drops.ContractCase, async: true

  alias Drops.JsonSchema

  describe "to_json_schema/1" do
    contract do
      schema do
        %{
          required(:some_atom) => type(:atom, description: "some_atom description"),
          required(:some_boolean) => boolean(description: "some_boolean description"),
          optional(:some_float) => float(description: "some_float description"),
          optional(:some_integer) => integer(description: "some_integer description"),
          optional(:some_nil) => type(nil, description: "some_nil description"),
          optional(:some_string) => string(description: "some_string description"),
          optional(:some_date) => type(:date, description: "some_date description"),
          optional(:some_date_time) =>
            type(:date_time, description: "some_date_time description"),
          optional(:some_list) => list(:string, description: "some_list description"),
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
                 "some_atom" => %{
                   "type" => "string",
                   "description" => "some_atom description"
                 },
                 "some_boolean" => %{
                   "type" => "boolean",
                   "description" => "some_boolean description"
                 },
                 "some_float" => %{
                   "type" => "number",
                   "description" => "some_float description"
                 },
                 "some_integer" => %{
                   "type" => "integer",
                   "description" => "some_integer description"
                 },
                 "some_nil" => %{
                   "type" => "null",
                   "description" => "some_nil description"
                 },
                 "some_string" => %{
                   "type" => "string",
                   "description" => "some_string description"
                 },
                 "some_date" => %{
                   "type" => "string",
                   "format" => "date",
                   "description" => "some_date description"
                 },
                 "some_date_time" => %{
                   "type" => "string",
                   "format" => "date-time",
                   "description" => "some_date_time description"
                 },
                 "some_list" => %{
                   "type" => "array",
                   "items" => %{
                     "type" => "string",
                     "description" => "some_list description"
                   }
                 },
                 "nested_map" => %{
                   "properties" => %{
                     "nested_property" => %{"type" => "string"}
                   },
                   "required" => ["nested_property"]
                 }
               },
               "required" => ["nested_map", "some_atom", "some_boolean"]
             } =
               contract.json_schema()
    end
  end
end
