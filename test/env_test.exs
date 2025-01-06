defmodule EnvTest do
  use ExUnit.Case
  doctest Env

  test "load!/1 fails if env var is not set" do
    assert catch_error(Env.load!("THIS_VAR_SHOULD_NOT_BE_SET_1234567890"))
  end
end
