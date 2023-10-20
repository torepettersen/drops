defmodule Drops.Contract.SchemaTest do
  use Drops.ContractCase

  describe "schema/1 with name" do
    contract do
      schema(:address) do
        %{
          required(:street) => string(),
          required(:city) => string(),
          required(:zip) => string(),
          required(:country) => string()
        }
      end

      schema do
        %{
          required(:name) => string(),
          required(:age) => integer(),
          required(:address) => @schemas.address
        }
      end
    end

    test "defines a named schema", %{contract: contract} do
      assert {:ok,
              %{
                name: "John",
                age: 21,
                address: %{
                  street: "Main St.",
                  city: "New York",
                  zip: "10001",
                  country: "USA"
                }
              }} =
               contract.conform(%{
                 name: "John",
                 age: 21,
                 address: %{
                   street: "Main St.",
                   city: "New York",
                   zip: "10001",
                   country: "USA"
                 }
               })
    end
  end

  describe "schema/1 with name and options" do
    contract do
      schema(:address, atomize: true) do
        %{
          required(:street) => string(),
          required(:city) => string(),
          required(:zip) => string(),
          required(:country) => string()
        }
      end

      schema(atomize: true) do
        %{
          required(:name) => string(),
          required(:age) => integer(),
          required(:address) => @schemas.address
        }
      end
    end

    test "defines a named schema", %{contract: contract} do
      assert {:ok,
              %{
                name: "John",
                age: 21,
                address: %{
                  street: "Main St.",
                  city: "New York",
                  zip: "10001",
                  country: "USA"
                }
              }} =
               contract.conform(%{
                 "name" => "John",
                 "age" => 21,
                 "address" => %{
                   "street" => "Main St.",
                   "city" => "New York",
                   "zip" => "10001",
                   "country" => "USA"
                 }
               })
    end
  end

  describe "required keys with types" do
    contract do
      schema do
        %{
          required(:name) => type(:string),
          required(:age) => type(:integer)
        }
      end
    end

    test "returns success with valid data", %{contract: contract} do
      assert {:ok, %{name: "Jane", age: 21}} = contract.conform(%{name: "Jane", age: 21})
    end

    test "defining required keys with types", %{contract: contract} do
      assert_errors(["age key must be present"], contract.conform(%{name: "Jane"}))
    end

    test "returns error with invalid data", %{contract: contract} do
      assert_errors(["name must be a string"], contract.conform(%{name: 312, age: 21}))
    end

    test "returns multiple errors with invalid data", %{contract: contract} do
      assert_errors(
        [
          "age must be an integer",
          "name must be a string"
        ],
        contract.conform(%{name: 312, age: "21"})
      )
    end
  end

  describe "required and optionals keys with types" do
    contract do
      schema do
        %{
          required(:email) => type(:string, [:filled?]),
          optional(:name) => type(:string, [:filled?])
        }
      end
    end

    test "returns success with valid data", %{contract: contract} do
      assert {:ok, %{email: "jane@doe.org", name: "Jane"}} =
               contract.conform(%{email: "jane@doe.org", name: "Jane"})
    end

    test "returns has_key? error when a required key key must be present", %{
      contract: contract
    } do
      assert_errors(["email key must be present"], contract.conform(%{}))
    end

    test "returns predicate errors", %{contract: contract} do
      assert_errors(
        ["email must be filled"],
        contract.conform(%{email: "", name: "Jane"})
      )

      assert_errors(
        ["name must be filled"],
        contract.conform(%{email: "jane@doe.org", name: ""})
      )
    end
  end

  describe "required keys with extra predicates" do
    contract do
      schema do
        %{
          required(:name) => type(:string, [:filled?]),
          required(:age) => type(:integer)
        }
      end
    end

    test "returns predicate errors", %{contract: contract} do
      assert_errors(
        ["age must be an integer", "name must be filled"],
        contract.conform(%{name: "", age: "21"})
      )
    end
  end

  describe "defining a nested schema - 1 level" do
    contract do
      schema do
        %{
          required(:user) => %{
            required(:name) => type(:string, [:filled?]),
            required(:age) => type(:integer)
          }
        }
      end
    end

    test "returns success with valid data", %{contract: contract} do
      assert {:ok, _} = contract.conform(%{user: %{name: "John", age: 21}})
    end

    test "returns nested errors", %{contract: contract} do
      assert_errors(["user key must be present"], contract.conform(%{}))

      assert_errors(["user must be a map"], contract.conform(%{user: nil}))

      assert_errors(
        ["user.name must be filled"],
        contract.conform(%{user: %{name: "", age: 21}})
      )
    end
  end

  describe "defining a nested schema - 2 levels" do
    contract do
      schema do
        %{
          required(:user) => %{
            required(:name) => string(:filled?),
            required(:age) => maybe(:integer),
            required(:address) => %{
              required(:city) => string(:filled?),
              required(:street) => string(:filled?),
              required(:zipcode) => maybe(:string, [:filled?])
            }
          }
        }
      end
    end

    test "returns success when valid", %{contract: contract} do
      assert {:ok, _} =
               contract.conform(%{
                 user: %{
                   name: "John",
                   age: 21,
                   address: %{
                     city: "New York",
                     street: "Central Park",
                     zipcode: "10001"
                   }
                 }
               })
    end

    test "returns deeply nested errors", %{contract: contract} do
      assert_errors(
        ["user.address.zipcode must be nil or user.address.zipcode must be filled"],
        contract.conform(%{
          user: %{
            name: "John",
            age: 21,
            address: %{
              city: "New York",
              street: "Broadway 121",
              zipcode: ""
            }
          }
        })
      )

      assert_errors(
        ["user.address.street must be filled", "user.name must be filled"],
        contract.conform(%{
          user: %{
            name: "",
            age: 21,
            address: %{
              city: "New York",
              street: "",
              zipcode: "10001"
            }
          }
        })
      )
    end
  end

  describe "schema for string maps" do
    contract do
      schema(atomize: true) do
        %{
          required(:user) => %{
            required(:name) => type(:string, [:filled?]),
            required(:age) => type(:integer),
            required(:address) => %{
              required(:city) => type(:string, [:filled?]),
              required(:street) => type(:string, [:filled?]),
              required(:zipcode) => type(:string, [:filled?])
            }
          },
          optional(:company) => %{
            required(:name) => type(:string)
          }
        }
      end
    end

    test "returns success when schema validation passed", %{contract: contract} do
      expected_output = %{
        user: %{
          name: "John",
          age: 21,
          address: %{
            city: "New York",
            street: "Central Park",
            zipcode: "10001"
          }
        }
      }

      assert {:ok, output} =
               contract.conform(%{
                 "user" => %{
                   "name" => "John",
                   "age" => 21,
                   "address" => %{
                     "city" => "New York",
                     "street" => "Central Park",
                     "zipcode" => "10001"
                   }
                 }
               })

      assert expected_output == output

      expected_output = %{
        user: %{
          name: "John",
          age: 21,
          address: %{
            city: "New York",
            street: "Central Park",
            zipcode: "10001"
          }
        },
        company: %{
          name: "Elixir Drops"
        }
      }

      assert {:ok, output} =
               contract.conform(%{
                 "user" => %{
                   "name" => "John",
                   "age" => 21,
                   "address" => %{
                     "city" => "New York",
                     "street" => "Central Park",
                     "zipcode" => "10001"
                   }
                 },
                 "company" => %{
                   "name" => "Elixir Drops"
                 }
               })

      assert expected_output == output

      assert_errors(
        [
          "user.address.street must be filled",
          "user.name must be filled"
        ],
        contract.conform(%{
          "user" => %{
            "name" => "",
            "age" => 21,
            "address" => %{
              "city" => "New York",
              "street" => "",
              "zipcode" => "10001"
            }
          }
        })
      )
    end
  end

  describe "nested sum of schemas" do
    contract do
      schema do
        %{
          required(:user) => [
            %{required(:name) => string()},
            %{required(:login) => string()}
          ]
        }
      end
    end

    test "returns success when either of the schemas passed", %{contract: contract} do
      assert {:ok, %{user: %{name: "John Doe"}}} =
               contract.conform(%{user: %{name: "John Doe"}})
    end

    test "returns error when both schemas didn't pass", %{contract: contract} do
      assert_errors(
        ["user.name key must be present or user.login key must be present"],
        contract.conform(%{user: %{}})
      )
    end
  end

  describe "nested sum of schemas when atomized" do
    contract do
      schema(atomize: true) do
        %{
          required(:user) => [
            %{required(:name) => string()},
            %{required(:login) => string()}
          ]
        }
      end
    end

    test "returns success when either of the schemas passed", %{contract: contract} do
      assert {:ok, %{user: %{name: "John Doe"}}} =
               contract.conform(%{"user" => %{"name" => "John Doe"}})

      assert {:ok, %{user: %{login: "john"}}} =
               contract.conform(%{"user" => %{"login" => "john"}})
    end

    test "returns error when both schemas didn't pass", %{contract: contract} do
      assert_errors(
        ["user.name key must be present or user.login key must be present"],
        contract.conform(%{"user" => %{}})
      )
    end
  end

  describe "using list shortcut for sum types" do
    contract do
      schema(:left) do
        %{required(:name) => string()}
      end

      schema(:right) do
        %{required(:login) => string()}
      end

      schema do
        %{
          required(:user) => [@schemas.left, @schemas.right]
        }
      end
    end

    test "returns success when either of the schemas passed", %{contract: contract} do
      assert {:ok, %{user: %{name: "John Doe"}}} =
               contract.conform(%{user: %{name: "John Doe"}})
    end

    test "returns error when both schemas didn't pass", %{contract: contract} do
      assert_errors(
        ["user.name key must be present or user.login key must be present"],
        contract.conform(%{user: %{}})
      )
    end
  end

  describe "sum of lists" do
    contract do
      schema do
        %{
          required(:values) => [
            list(:string),
            list(:integer)
          ]
        }
      end
    end

    test "returns success when either of the lists passed", %{contract: contract} do
      assert {:ok, %{values: ["hello", "world"]}} =
               contract.conform(%{values: ["hello", "world"]})

      assert {:ok, %{values: [1, 2]}} = contract.conform(%{values: [1, 2]})
    end

    test "returns error when both cases didn't pass", %{contract: contract} do
      assert_errors(
        ["values.0 must be a string or values.1 must be an integer"],
        contract.conform(%{values: [1, "hello"]})
      )
    end
  end

  describe "sum of list of schemas" do
    contract do
      schema(:left) do
        %{required(:name) => string()}
      end

      schema(:right) do
        %{required(:login) => string()}
      end

      schema do
        %{
          required(:values) => [list(@schemas.left), list(@schemas.right)]
        }
      end
    end

    test "returns success when either of cases passed", %{contract: contract} do
      assert {:ok, %{values: [%{name: "John Doe"}]}} =
               contract.conform(%{values: [%{name: "John Doe"}]})

      assert {:ok, %{values: [%{login: "john"}]}} =
               contract.conform(%{values: [%{login: "john"}]})
    end

    test "returns error when both cases didn't pass", %{contract: contract} do
      assert_errors(
        ["values.0.name must be a string or values.0.login key must be present"],
        contract.conform(%{values: [%{name: 1}]})
      )
    end
  end

  describe "sum of list of schemas nested" do
    contract do
      schema(:left) do
        %{required(:name) => string()}
      end

      schema(:right) do
        %{
          required(:login) => string(),
          required(:groups) => [
            list(:string),
            list(@schemas.left)
          ]
        }
      end

      schema do
        %{
          required(:values) => [
            list(@schemas.left),
            list(@schemas.right)
          ]
        }
      end
    end

    test "returns success when either of cases passed", %{contract: contract} do
      assert {:ok, %{values: [%{name: "John Doe"}]}} =
               contract.conform(%{values: [%{name: "John Doe"}]})

      assert {:ok, %{values: [%{login: "john", groups: ["admin"]}]}} =
               contract.conform(%{values: [%{login: "john", groups: ["admin"]}]})

      assert {:ok, %{values: [%{login: "john", groups: [%{name: "admin"}]}]}} =
               contract.conform(%{values: [%{login: "john", groups: [%{name: "admin"}]}]})
    end

    test "returns error when all cases didn't pass", %{contract: contract} do
      assert_errors(
        [
          "values.0.name key must be present or values.0.groups.0 must be a string or values.0.groups.0.name must be a string"
        ],
        contract.conform(%{values: [%{login: "jane", groups: [%{name: 1}]}]})
      )
    end
  end

  describe "sum of schemas" do
    contract do
      schema(:left) do
        %{required(:name) => string()}
      end

      schema(:right) do
        %{required(:login) => string()}
      end

      schema do
        [@schemas.left, @schemas.right]
      end
    end

    test "returns success when either of the schemas passed", %{contract: contract} do
      assert {:ok, %{name: "John Doe"}} = contract.conform(%{name: "John Doe"})
      assert {:ok, %{login: "john"}} = contract.conform(%{login: "john"})
    end

    test "returns error when both schemas didn't pass", %{contract: contract} do
      assert_errors(
        ["name key must be present or login key must be present"],
        contract.conform(%{})
      )
    end
  end
end
