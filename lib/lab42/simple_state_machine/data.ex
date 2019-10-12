defmodule Lab42.SimpleStateMachine.Data do
  @moduledoc """
  Represents the matched input and all data to be passed between
  state machine loops
  """

  defstruct matched: nil, data: nil, input: nil

  def from_data(data) do
    %__MODULE__{data: data}
  end
end
