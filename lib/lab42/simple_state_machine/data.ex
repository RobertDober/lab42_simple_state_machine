defmodule Lab42.SimpleStateMachine.Data do
  @moduledoc """
  Represents the matched input and all data to be passed between
  state machine loops
  """

  defstruct matched: nil, data: nil, input: nil

  @type t :: %__MODULE__{matched: any(), data: any(), input: any()}

  def from_data(data) do
    %__MODULE__{data: data}
  end
end
