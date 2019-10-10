defmodule StateMachine.MakeMachineTest do
  use ExUnit.Case

  import Lab42.StateMachine
  
  describe "make machine" do
    test "does not need an explicit data value" do
      machine = make_machine(copier()) 
      input   = ~w(alpha beta)

      assert machine.(input) == {:start, input, nil}
    end
  end

  defp copier, do: %{
    start: [{true}]
  }
end
