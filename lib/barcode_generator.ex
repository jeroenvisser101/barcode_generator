defmodule BarcodeGenerator do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  import Integer, only: [is_odd: 1]

  @type digit() :: 0..9
  @type stack_item() :: {digit(), index :: non_neg_integer(), sum :: non_neg_integer()}
  @type stack() :: [stack_item()]
  @type stack_with_base() :: {stack(), non_neg_integer()}

  @doc """
  Validates a barcode

  Checks if the barcode has a valid check digit.

  ## Examples

      iex> BarcodeGenerator.valid?("6291041500206")
      true

      iex> BarcodeGenerator.valid?(6291041500206)
      true

      iex> BarcodeGenerator.valid?("6291041500200")
      false

      iex> BarcodeGenerator.valid?(6291041500200)
      false
  """
  @spec valid?(integer() | String.t()) :: boolean()
  def valid?(barcode) when is_binary(barcode), do: barcode |> String.to_integer() |> valid?()

  def valid?(barcode) do
    base = base(barcode)

    sum =
      base
      |> Integer.digits()
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.reduce(0, fn
        {digit, index}, acc when is_odd(index) -> acc + digit
        {digit, _index}, acc -> acc + digit * 3
      end)

    valid_check_digit = rem(10 - rem(sum, 10), 10)
    check_digit = rem(barcode, 10)

    check_digit == valid_check_digit
  end

  @doc """
  Generates a list of barcodes

  Given the first and last barcode, will return a list of valid barcodes in that range.

  ## Examples

      iex> BarcodeGenerator.generate(6_291_041_500_200, 6_291_041_500_299)
      [6291041500206, 6291041500213, 6291041500220, 6291041500237, 6291041500244,
      6291041500251, 6291041500268, 6291041500275, 6291041500282, 6291041500299]
  """
  @spec generate(non_neg_integer(), non_neg_integer()) :: [non_neg_integer()]
  def generate(starting_barcode, ending_barcode) do
    start_range = base(starting_barcode)
    end_range = base(ending_barcode)

    {barcodes, _stack_with_base} =
      Enum.map_reduce(
        start_range..end_range,
        fetch_stack(start_range, nil),
        fn base, stack_with_base ->
          stack_with_base = {stack, _stack_base} = fetch_stack(base, stack_with_base)
          barcode = calculate_barcode(base, stack)

          {barcode, stack_with_base}
        end
      )

    barcodes
  end

  @doc """
  Generates a stream of barcodes

  Given the first and last barcode, will return a stream of valid barcodes in that range.

  ## Examples

      iex> stream = BarcodeGenerator.generate_stream(6_291_041_500_200, 6_291_041_500_299)
      iex> Enum.to_list(stream)
      [6291041500206, 6291041500213, 6291041500220, 6291041500237, 6291041500244,
      6291041500251, 6291041500268, 6291041500275, 6291041500282, 6291041500299]
  """
  @spec generate_stream(non_neg_integer(), non_neg_integer()) :: Enumerable.t()
  def generate_stream(starting_barcode, ending_barcode) do
    start_range = base(starting_barcode)
    end_range = base(ending_barcode)

    Stream.resource(
      fn -> {start_range, fetch_stack(start_range, nil)} end,
      fn
        {base, stack_with_base} when base <= end_range ->
          stack_with_base = {stack, _stack_base} = fetch_stack(base, stack_with_base)
          barcode = calculate_barcode(base, stack)

          {[barcode], {base + 1, stack_with_base}}

        _done ->
          {:halt, :done}
      end,
      fn :done -> :ok end
    )
  end

  if Code.ensure_loaded?(Flow) do
    @doc """
    Generates barcodes in parallel in a Flow

    Given the first and last barcode, will return a Flow that emits valid barcodes in that range.

    When generating in a Flow, the ordering of the barcodes isn't guaranteed. The algorithm
    distributes batches of barcodes to be generated across different partitions. It reuses
    calculations done for the previous barcode (because only the last digit of the base changes)
    to efficiently generate large ranges of barcodes.

    Optionally accepts custom options passed to `Flow.from_enumerable/2`, defaults to
    `max_demand: 1000`.

    ## Examples

        iex> flow = BarcodeGenerator.generate_flow(6_291_041_500_200, 6_291_041_500_299)
        iex> Enum.to_list(flow) |> Enum.sort()
        [6291041500206, 6291041500213, 6291041500220, 6291041500237, 6291041500244,
        6291041500251, 6291041500268, 6291041500275, 6291041500282, 6291041500299]
    """
    @spec generate_flow(non_neg_integer(), non_neg_integer(), keyword()) :: Flow.t()
    def generate_flow(starting_barcode, ending_barcode, opts \\ [max_demand: 1000]) do
      start_range = base(starting_barcode)
      end_range = base(ending_barcode)

      start_range..end_range
      |> Flow.from_enumerable(opts)
      |> Flow.emit_and_reduce(
        fn -> nil end,
        fn base, stack_with_base ->
          stack_with_base = {stack, _stack_base} = fetch_stack(base, stack_with_base)
          barcode = calculate_barcode(base, stack)

          {[barcode], stack_with_base}
        end
      )
      |> Flow.on_trigger(fn acc -> {[], acc} end)
    end
  end

  @spec calculate_barcode(non_neg_integer(), stack()) :: non_neg_integer()
  defp calculate_barcode(base, [
         {_first_digit, index, _acc},
         {_second_digit, _index, acc} | _stack
       ]) do
    sum = (acc + rem(base, 10) * multiplicator(index)) |> rem(10)
    check_digit = rem(10 - sum, 10)

    base * 10 + check_digit
  end

  @compile {:inline, multiplicator: 1}
  @spec multiplicator(integer()) :: 3 | 1
  defp multiplicator(index) when is_odd(index), do: 3
  defp multiplicator(_index), do: 1

  @spec fetch_stack(non_neg_integer(), stack_with_base() | nil) :: stack_with_base()
  defp fetch_stack(base, nil), do: {init_stack(base), div(base, 10)}

  defp fetch_stack(base, {stack, stack_base} = stack_with_base) do
    case div(base, 10) do
      ^stack_base -> stack_with_base
      stack_base -> {update_stack(stack, base), stack_base}
    end
  end

  @spec init_stack(non_neg_integer() | [digit()]) :: stack()
  defp init_stack(base_or_digits, offset \\ 0, sum \\ 0)

  defp init_stack(base, offset, sum) when is_integer(base),
    do: base |> Integer.digits() |> init_stack(offset, sum)

  defp init_stack(digits, offset, sum) do
    digits
    |> Enum.with_index(offset)
    |> Enum.map_reduce(sum, fn
      {digit, index}, acc when is_odd(index) ->
        acc = acc + digit * 3

        {{digit, index, acc}, acc}

      {digit, index}, acc ->
        acc = acc + digit

        {{digit, index, acc}, acc}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  @spec update_stack(stack(), non_neg_integer()) :: stack()
  defp update_stack(stack, base) do
    stack = Enum.reverse(stack)
    digits = Integer.digits(base)

    do_update_stack(digits, stack, [])
  end

  @spec do_update_stack([digit()], stack(), stack()) :: stack()
  defp do_update_stack([], _stack, acc), do: acc

  defp do_update_stack([digit | digits], [{digit, _index, _acc} = stack_item | stack], acc) do
    do_update_stack(digits, stack, [stack_item | acc])
  end

  defp do_update_stack(digits, [{prev_digit, index, sum} | _stack], acc) do
    init_stack(digits, index, sum - multiplicator(index) * prev_digit) ++ acc
  end

  @compile {:inline, base: 1}
  @spec base(non_neg_integer()) :: non_neg_integer()
  defp base(code), do: div(code, 10)
end
