defmodule Env do
  @moduledoc """
    Helper to fetch and parse env var values to configure digiforma
  """

  @bool_true_values ~w(true 1 enable enabled yes)
  @bool_false_values ~w(false 0 disable disabled no)

  # rename load to fetch ?
  # rename to string/x integer/x boolean/x

  # will raise on prod start if env var is not defined
  def load_but_prod_mandatory(var_name, default \\ nil) do
    if Application.get_env(:digiforma, :env) == :prod do
      load!(var_name)
    else
      load(var_name, default)
    end
  end

  def load!(var_name) do
    IO.puts("MUST USE ENV #{var_name}")
    System.fetch_env!(var_name)
  end

  def load(var_name, default \\ nil), do: get_env(var_name, default)

  def load_into_integer!(var_name) do
    var_name
    |> System.fetch_env!()
    |> parse_strict_integer!(var_name)
  end

  def load_into_integer(var_name, default \\ nil)

  def load_into_integer(_, default) when not is_nil(default) and not is_integer(default), do: raise("default value must be integer")

  def load_into_integer(var_name, default) do
    case get_env(var_name) do
      nil -> default
      str_var -> parse_strict_integer!(str_var, var_name)
    end
  end

  def load_into_atom!(var_name) do
    var_name
    |> System.fetch_env!()
    |> String.to_atom()
  end

  def load_into_atom(var_name, default \\ nil) do
    var_name
    |> load(default)
    |> case do
      str when is_binary(str) -> String.to_atom(str)
      _ -> error_message_atom(var_name, default)
    end
  end

  def load_into_boolean(var_name, default \\ nil)

  def load_into_boolean(_var_name, default) when not is_boolean(default) and not is_nil(default) do
    raise "default value must be boolean"
  end

  def load_into_boolean(var_name, default) do
    str_var = load(var_name)

    case str_var do
      nil -> default
      str -> load_boolean_from_string(str, var_name)
    end
  end

  def load_into_boolean!(var_name) do
    var_name
    |> load!()
    |> load_boolean_from_string(var_name)
  end

  defp get_env(var_name, default \\ nil)
  # using a whitelist of env var allowed, this will not use local env var while running in test env
  # can't use guard, because env is compile before everything (even configuration itself)
  defp get_env(var_name, default) do
    cond do
      Application.get_env(:digiforma, :env) != :test || var_name in Application.get_env(:digiforma, :whitelist_test_env_vars) ->
        var_name
        |> System.get_env(default)

      true ->
        default
    end
  end

  defp load_boolean_from_string(str, var_name) do
    str
    |> String.downcase()
    |> case do
      b when b in @bool_true_values -> true
      b when b in @bool_false_values -> false
      _ -> raise error_message_boolean(var_name, str)
    end
  end

  defp parse_strict_integer!(var_content, var_name) do
    case Integer.parse(var_content) do
      {int_val, ""} -> int_val
      {_val, _} -> raise error_message_integer(var_name, var_content)
      :error -> raise error_message_integer(var_name, var_content)
    end
  end

  defp error_message_boolean(var_name, var_content) do
    """
      #{var_name} value is not a parsable boolean: #{var_content}
      The only recognized values are:
        - #{Enum.join(@bool_true_values, ", ")} -> true
        - #{Enum.join(@bool_false_values, ", ")} -> false
    """
  end

  defp error_message_integer(var_name, var_content) do
    "#{var_name} value is not a parsable integer: #{var_content}"
  end

  defp error_message_atom(var_content, var_name) do
    "#{var_name} value is not a parsable atom: #{var_content}"
  end
end
