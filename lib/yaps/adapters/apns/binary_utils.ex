defmodule Yaps.Adapters.Apns.BinaryUtils do
  defmacro bytes(num) do
    quote do: big-unsigned-(unquote 8*num)
  end
end
