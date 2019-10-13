defmodule Lab42.SimpleStateMachine.Types do

  alias Lab42.SimpleStateMachine.Data
  
  @moduledoc false

  defmacro __using__(_opts \\ []) do
    quote do
      @type maybe(t) :: t | nil

      @type function_t :: (any() -> any())
      @type transition_fn_t :: ( Data.t ) :: any()

      @type state_t :: atom()
      @type complete_transition_t :: {trigger_t(), transition_fn_t(), state_t()}
      @type transition_t :: complete_transition_t() |
                               {trigger_t(), transition_fn_t()} |
                               {trigger_t()}
      @type trigger_t :: true | Regex.t | function_t
    end
  end
end
