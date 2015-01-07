defmodule Yaps.Adapters.Apns.DataTransformers do
  @max_payload_size 2048

  import Yaps.Adapters.Apns.BinaryUtils

  def encode(recipient, payload, opts) do
    {opts, _} = Keyword.split(opts, [
      :device_token, :payload, :identifier, :expiration, :priority
    ])

    opts = opts
      |> Keyword.put(:device_token, recipient)
      |> Keyword.put(:payload, payload)

    frame_data = Enum.reduce(opts, "", fn(x, acc) ->
      {atom, value} = x
      acc <> encode_atom(atom, value)
    end)

    << 2 :: bytes(1), byte_size(frame_data) :: bytes(4) >> <> \
    frame_data
  end

  defp encode_atom(:device_token, value) when byte_size(value) == 32 do
    << 1 :: bytes(1), 32 :: bytes(2) >> <> value
  end

  defp encode_atom(:payload, value) when byte_size(value) <= @max_payload_size do
    << 2 :: bytes(1), byte_size(value) :: bytes(2) >> <> value
  end

  defp encode_atom(:identifier, value) when byte_size(value) == 4 do
    << 3 :: bytes(1), 4 :: bytes(2) >> <> value
  end

  defp encode_atom(:expiration, value) when is_integer(value) do
    << 4 :: bytes(1), 4 :: bytes(2), value :: big-unsigned-32 >>
  end

  defp encode_atom(:priority, :immediate) do
    << 5 :: bytes(1), 1 :: bytes(2), 10 :: bytes(1) >>
  end
  defp encode_atom(:priority, :efficient) do
    << 5 :: bytes(1), 1 :: bytes(2), 5 :: bytes(1) >>
  end

  defp encode_atom(command, _) do
    raise ArgumentError, message: "#{command} is not a valid atom."
  end
end
