defmodule Dyd.Utils do
  @moduledoc false

  def to_datetime(age) do
    with {:ok, count, unit} <- split(age),
         {count, ""} <- Integer.parse(count),
         {:ok, offset} <- unit_to_second_offset(unit) do
      {:ok, DateTime.utc_now() |> DateTime.add(count * offset * -1, :second)}
    else
      :error -> {:error, :not_a_datetime}
      {:error, error} -> {:error, error}
    end
  end

  defp split(age) do
    case String.split(age, " ") do
      [count, unit | _] -> {:ok, count, unit}
      _other -> {:error, :not_a_datetime}
    end
  end

  defp unit_to_second_offset("day" <> _), do: {:ok, 60 * 60 * 24}
  defp unit_to_second_offset("week" <> _), do: {:ok, 60 * 60 * 24 * 7}
  defp unit_to_second_offset("year" <> _), do: {:ok, 60 * 60 * 24 * 365}
  defp unit_to_second_offset(_), do: {:error, :invalid_time_unit}
end
