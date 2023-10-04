defmodule Drops.Validator do
  defmacro __using__(_opts) do
    quote do
      alias Drops.{Casters, Predicates}
      alias Drops.Type
      alias Drops.Type.Schema
      alias Drops.Type.Schema.Key

      def validate(value, %Type.Cast{} = type, path: path) do
        %{input_type: input_type, output_type: output_type, opts: cast_opts} = type

        caster = cast_opts[:caster] || Casters

        case validate(value, input_type, path: path) do
          {:ok, _} ->
            casted_value =
              apply(
                caster,
                :cast,
                [input_type.primitive, output_type.primitive, value] ++ cast_opts
              )

            validate(casted_value, output_type, path: path)

          {:error, {predicate, value}} ->
            {:error, {predicate, path, value}}
        end
      end

      def validate(data, %Key{presence: :required, path: path} = key) do
        if Key.present?(data, key) do
          validate(get_in(data, path), key.type, path: path)
        else
          {:error, {[], :has_key?, path}}
        end
      end

      def validate(data, %Key{presence: :optional, path: path} = key) do
        if Key.present?(data, key) do
          validate(get_in(data, path), key.type, path: path)
        else
          :ok
        end
      end

      def validate(value, %Type{constraints: constraints}, path: path) do
        validate(value, constraints, path: path)
      end

      def validate(value, predicates, path: path) when is_list(predicates) do
        apply_predicates(value, predicates, path: path)
      end

      def validate(value, {:and, predicates}, path: path) do
        validate(value, predicates, path: path)
      end

      def validate(value, %Type.Sum{} = type, path: path) do
        case validate(value, type.left, path: path) do
          {:ok, _} = success ->
            success

          {:error, _} ->
            validate(value, type.right, path: path)
        end
      end

      def validate(value, %Type.List{member_type: member_type} = type, path: path) do
        case validate(value, type.constraints, path: path) do
          {:ok, {_, members}} ->
            result = List.flatten(
              Enum.with_index(members, &validate(&1, member_type, path: path ++ [&2]))
            )

            errors = Enum.reject(result, &is_ok/1)

            if length(errors) == 0,
              do: {:ok, {path, result}},
              else: errors

          error ->
            error
        end
      end

      defp apply_predicates(value, {:and, predicates}, path: path) do
        apply_predicates(value, predicates, path: path)
      end

      defp apply_predicates(value, predicates, path: path) do
        Enum.reduce(predicates, {:ok, {path, value}}, &apply_predicate(&1, &2))
      end

      defp apply_predicate({:predicate, {name, args}}, {:ok, {path, value}}) do
        apply_args =
          case args do
            [arg] -> [arg, value]
            [] -> [value]
            arg -> [arg, value]
          end

        if apply(Predicates, name, apply_args) do
          {:ok, {path, value}}
        else
          {:error, {path, name, apply_args}}
        end
      end

      defp apply_predicate(_, {:error, _} = error) do
        error
      end

      defp nest_errors(errors, root) do
        Enum.map(errors, fn
          {:error, {path, name, args}} ->
            {:error, {root ++ path, name, args}}

          {:error, [] = error_list} ->
            {:error, nest_errors(error_list, root)}
        end)
      end

      defp is_ok(:ok), do: true
      defp is_ok({:ok, _}), do: true
      defp is_ok(:error), do: false
      defp is_ok({:error, _}), do: false
    end
  end
end
