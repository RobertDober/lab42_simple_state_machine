defmodule Lab42.StateMachine.Types do
  @moduledoc false

  defmacro __using__(_opts \\ []) do
    quote do

      @type ok_t :: {atom(), list(), any()}
      @type error_t :: {:error, list()|String.t, state_t()}
      @type result_t :: ok_t() | error_t()

      @type match_t :: {list(String.t), String.t}
      @type state_t :: atom()
      @type trigger_t :: true | Regex.t
      @type transformer_t :: (match_t() -> any())
      @type transition_t :: { trigger_t(), transformer_t(), updater_t(), state_t() }
      @type transition_map_t :: map()
      @type updater_t :: (any(), match_t() -> any())

    end
  end
end
