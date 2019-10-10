defmodule Lab42.StateMachine.Types do
  @moduledoc false

  defmacro __using__(_opts \\ []) do
    quote do

      @type maybe(a_type) :: a_type | nil

      @type ok_t :: {atom(), list(), any()}
      @type error_t :: {:error, list()|String.t, state_t()}
      @type result_t :: ok_t() | error_t()

      @type empty_t :: []

      @type incomplete_transition_t :: {trigger_t()} |
                                       {trigger_t(), symbolic_transformer_t()} |
                                       {trigger_t(), symbolic_transformer_t(), symbolic_updater_t()} |
                                       {trigger_t(), symbolic_transformer_t(), symbolic_updater_t(), state_t()}
      @type match_t :: {any(), any()}
      @type normalized_transitions_t :: [transition_t()| (incomplete_transition_t()|empty_t()) ]
      @type state_t :: atom()
      @type trigger_t :: true | Regex.t | (any() -> any())
      @type symbolic_transformer_t :: transformer_t() | atom()
      @type symbolic_updater_t :: updater_t() | atom()
      @type transformer_t :: (match_t() -> any())
      @type transition_t :: { trigger_t(), transformer_t(), updater_t(), state_t() }
      @type transition_map_t :: map()
      @type updater_t :: (any(), match_t() -> any())


    end
  end
end
