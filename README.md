# BarcodeGenerator

[Online documentation](https://hexdocs.pm/barcode_generator) | [Hex.pm](https://hex.pm/packages/barcode_generator)

<!-- MDOC !-->

`BarcodeGenerator` generates a list of barcodes from a given start and end barcode.

This library allows you to generate GTIN barcodes by passing it the first and last barcode of a
range.

## Examples

### Validating

`BarcodeGenerator` allows simple check-digit validation for GTIN barcodes, both in binary and
numeric format:

```elixir
BarcodeGenerator.valid?("6291041500206")
# true

BarcodeGenerator.valid?(6291041500206)
# true

BarcodeGenerator.valid?("6291041500200")
# false

BarcodeGenerator.valid?(6291041500200)
# false
```

### Generating

`BarcodeGenerator` can generate barcodes in three different ways:

#### Plain list

`BarcodeGenerator.generate/2` generates barcodes in a simple list format.

```elixir
BarcodeGenerator.generate(6_291_041_500_200, 6_291_041_500_299)
```

#### Stream

`BarcodeGenerator.generate_stream/2` returns a `Stream` that can be enumerated. Barcodes are
generated as the stream is consumed, reducing memory footprint.

```elixir
stream = BarcodeGenerator.generate_stream(6_291_041_500_200, 6_291_041_500_299)
barcodes = Enum.to_list(stream)
```

#### Flow (optional dependency)

`BarcodeGenerator.generate_flow/3` returns a `Flow`, but requires that
[`flow`](https://hex.pm/packages/flow) is present as dependency. Generating barcodes using Flow is
heavily optimized to use all available resources to generate as quickly as possible.

`BarcodeGenerator.generate_flow/3` accepts an optional third argument, `opts`, which is passed to
`Flow.from_enumerable/2`, and defaults to `max_demand: 1000`.

```elixir
# Assuming `{:flow, "~> 1.0"}` is in mix.exs
flow = BarcodeGenerator.generate_flow(6_291_041_500_200, 6_291_041_500_299)
barcodes = Enum.to_list(flow)
```

<!-- MDOC !-->

## Installation

Add `barcode_generator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:barcode_generator, "~> 1.0.0"}]
end
```

## License

This library is MIT licensed. See the
[LICENSE](https://raw.github.com/jeroenvisser101/barcode_generator/main/LICENSE)
file in this repository for details.
