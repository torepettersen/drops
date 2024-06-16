defmodule Drops.JsonSchemaTest do
  use Drops.ContractCase, async: true

  @types [
    atom: %{"type" => "string"},
    boolean: %{"type" => "boolean"},
    float: %{"type" => "number"},
    integer: %{"type" => "integer"},
    nil: %{"type" => "null"},
    string: %{"type" => "string"},
    date: %{"type" => "string", "format" => "date"},
    date_time: %{"type" => "string", "format" => "date-time"}
  ]

  for {type, properties} <- @types do
    describe "contract with type #{type}" do
      contract do
        schema do
          %{
            optional(:test) => type(unquote(type))
          }
        end
      end

      test "generates json schema type", %{contract: contract} do
        assert contract.json_schema() == %{
                 "title" => "TestContract",
                 "type" => "object",
                 "properties" => %{
                   "test" => unquote(Macro.escape(properties))
                 }
               }
      end
    end
  end

  describe "contract with type :list" do
    contract do
      schema do
        %{
          optional(:test) => list(:string)
        }
      end
    end

    test "generates json schema type", %{contract: contract} do
      assert contract.json_schema() == %{
               "title" => "TestContract",
               "type" => "object",
               "properties" => %{
                 "test" => %{
                   "type" => "array",
                   "items" => %{
                     "type" => "string"
                   }
                 }
               }
             }
    end
  end

  describe "contract with nested map" do
    contract do
      schema do
        %{
          optional(:map) => %{
            optional(:test) => string()
          }
        }
      end
    end

    test "generates json schema nested map", %{contract: contract} do
      assert contract.json_schema() == %{
               "title" => "TestContract",
               "type" => "object",
               "properties" => %{
                 "map" => %{
                   "type" => "object",
                   "properties" => %{
                     "test" => %{
                       "type" => "string"
                     }
                   }
                 }
               }
             }
    end
  end

  describe "contract with maybe" do
    contract do
      schema do
        %{
          optional(:test) => maybe(:string)
        }
      end
    end

    test "generates json schema with anyOf", %{contract: contract} do
      assert contract.json_schema() == %{
               "title" => "TestContract",
               "type" => "object",
               "properties" => %{
                 "test" => %{
                   "anyOf" => [
                     %{"type" => "null"},
                     %{"type" => "string"}
                   ]
                 }
               }
             }
    end
  end

  describe "contract with description" do
    contract do
      schema do
        %{
          optional(:test) => type(:atom, description: "some description")
        }
      end
    end

    test "generates json schema with description", %{contract: contract} do
      assert contract.json_schema() == %{
               "title" => "TestContract",
               "type" => "object",
               "properties" => %{
                 "test" => %{
                   "type" => "string",
                   "description" => "some description"
                 }
               }
             }
    end
  end

  describe "contract with required field" do
    contract do
      schema do
        %{
          required(:test) => string()
        }
      end
    end

    test "generates json schema with required field", %{contract: contract} do
      assert contract.json_schema() == %{
               "title" => "TestContract",
               "type" => "object",
               "properties" => %{
                 "test" => %{"type" => "string"}
               },
               "required" => ["test"]
             }
    end
  end

  describe "contract with in?" do
    contract do
      schema do
        %{
          required(:test) => string(in?: ["foo", "bar"])
        }
      end
    end

    test "generates json schema with enum", %{contract: contract} do
      assert contract.json_schema() == %{
               "title" => "TestContract",
               "type" => "object",
               "properties" => %{
                 "test" => %{"type" => "string", "enum" => ["foo", "bar"]}
               },
               "required" => ["test"]
             }
    end
  end
end
