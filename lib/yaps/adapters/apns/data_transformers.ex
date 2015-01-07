defmodule Yaps.Adapters.Apns.DataTransformers do
  @max_payload_size 2048

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

    << 2 :: big-unsigned-8, byte_size(frame_data) :: big-unsigned-32 >> <> \
    frame_data
  end

  defp encode_atom(:device_token, value) when byte_size(value) == 32 do
    << 1 :: big-unsigned-8, 32 :: big-unsigned-16 >> <> value
  end

  defp encode_atom(:payload, value) when byte_size(value) <= @max_payload_size do
    << 2 :: big-unsigned-8, byte_size(value) :: big-unsigned-16 >> <> value
  end

  defp encode_atom(:identifier, value) when byte_size(value) == 4 do
    << 3 :: big-unsigned-8, 4 :: big-unsigned-16 >> <> value
  end

  defp encode_atom(:expiration, value) when is_integer(value) do
    << 4 :: big-unsigned-8, 4 :: big-unsigned-16, value :: big-unsigned-32 >>
  end

  defp encode_atom(:priority, :immediate) do
    << 5 :: big-unsigned-8, 1 :: big-unsigned-16, 10 :: big-unsigned-8 >>
  end
  defp encode_atom(:priority, :efficient) do
    << 5 :: big-unsigned-8, 1 :: big-unsigned-16, 5 :: big-unsigned-8 >>
  end

  defp encode_atom(command, _) do
    raise ArgumentError, message: "#{command} is not a valid atom."
  end
end
