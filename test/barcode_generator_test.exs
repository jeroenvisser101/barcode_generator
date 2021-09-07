defmodule BarcodeGeneratorTest do
  use ExUnit.Case, async: true
  doctest BarcodeGenerator

  describe "BarcodeGenerator.valid?/1" do
    test "with known valid barcodes" do
      valid_integer_barcodes = [
        6_291_041_500_206,
        6_291_041_500_213,
        6_291_041_500_220,
        6_291_041_500_237,
        6_291_041_500_244,
        6_291_041_500_251,
        6_291_041_500_268,
        6_291_041_500_275,
        6_291_041_500_282,
        6_291_041_500_299
      ]

      valid_binary_barcodes = [
        "6291041500206",
        "6291041500213",
        "6291041500220",
        "6291041500237",
        "6291041500244",
        "6291041500251",
        "6291041500268",
        "6291041500275",
        "6291041500282",
        "6291041500299"
      ]

      for barcode <- valid_integer_barcodes, do: assert(BarcodeGenerator.valid?(barcode))
      for barcode <- valid_binary_barcodes, do: assert(BarcodeGenerator.valid?(barcode))
    end

    test "with known invalid barcodes" do
      valid_integer_barcodes = [
        6_291_041_500_206,
        6_291_041_500_213,
        6_291_041_500_220,
        6_291_041_500_237,
        6_291_041_500_244,
        6_291_041_500_251,
        6_291_041_500_268,
        6_291_041_500_275,
        6_291_041_500_282,
        6_291_041_500_299
      ]

      # Find all possible invalid barcodes with the same base but different check digit
      invalid_integer_barcodes =
        for valid_barcode <- valid_integer_barcodes,
            first = div(valid_barcode, 10) * 10,
            last = first + 9,
            barcode <- first..last,
            barcode != valid_barcode,
            do: barcode

      for barcode <- invalid_integer_barcodes do
        refute BarcodeGenerator.valid?(barcode)
        refute BarcodeGenerator.valid?(to_string(barcode))
      end
    end
  end

  describe "BarcodeGenerator.generate/2" do
    test "generates valid barcodes" do
      # GTIN-12
      barcodes = BarcodeGenerator.generate(619_659_161_415, 619_659_161_509)

      assert length(barcodes) == 10
      assert Enum.all?(barcodes, &BarcodeGenerator.valid?/1)

      # GTIN-13
      barcodes = BarcodeGenerator.generate(6_291_041_500_200, 6_291_041_500_299)

      assert length(barcodes) == 10
      assert Enum.all?(barcodes, &BarcodeGenerator.valid?/1)

      # GTIN-14
      barcodes = BarcodeGenerator.generate(62_910_415_000_200, 62_910_415_000_299)

      assert length(barcodes) == 10
      assert Enum.all?(barcodes, &BarcodeGenerator.valid?/1)
    end

    test "handles stack-exceeding barcodes" do
      # GTIN-12
      barcodes = BarcodeGenerator.generate(619_659_161_415, 619_659_162_509)

      assert length(barcodes) == 110
      assert Enum.all?(barcodes, &BarcodeGenerator.valid?/1)

      # GTIN-13
      barcodes = BarcodeGenerator.generate(6_291_041_500_200, 6_291_041_501_299)

      assert length(barcodes) == 110
      assert Enum.all?(barcodes, &BarcodeGenerator.valid?/1)

      # GTIN-14
      barcodes = BarcodeGenerator.generate(62_910_415_000_200, 62_910_415_001_299)

      assert length(barcodes) == 110
      assert Enum.all?(barcodes, &BarcodeGenerator.valid?/1)
    end
  end

  describe "BarcodeGenerator.generate_stream/2" do
    test "generates valid barcodes" do
      # GTIN-12
      barcode_stream = BarcodeGenerator.generate_stream(619_659_161_415, 619_659_161_509)

      assert Enum.count(barcode_stream) == 10
      assert Enum.all?(barcode_stream, &BarcodeGenerator.valid?/1)

      # GTIN-13
      barcode_stream = BarcodeGenerator.generate_stream(6_291_041_500_200, 6_291_041_500_299)

      assert Enum.count(barcode_stream) == 10
      assert Enum.all?(barcode_stream, &BarcodeGenerator.valid?/1)

      # GTIN-14
      barcode_stream = BarcodeGenerator.generate_stream(62_910_415_000_200, 62_910_415_000_299)

      assert Enum.count(barcode_stream) == 10
      assert Enum.all?(barcode_stream, &BarcodeGenerator.valid?/1)
    end

    test "handles stack-exceeding barcodes" do
      # GTIN-12
      barcode_stream = BarcodeGenerator.generate_stream(619_659_161_415, 619_659_162_509)

      assert Enum.count(barcode_stream) == 110
      assert Enum.all?(barcode_stream, &BarcodeGenerator.valid?/1)

      # GTIN-13
      barcode_stream = BarcodeGenerator.generate_stream(6_291_041_500_200, 6_291_041_501_299)

      assert Enum.count(barcode_stream) == 110
      assert Enum.all?(barcode_stream, &BarcodeGenerator.valid?/1)

      # GTIN-14
      barcode_stream = BarcodeGenerator.generate_stream(62_910_415_000_200, 62_910_415_001_299)

      assert Enum.count(barcode_stream) == 110
      assert Enum.all?(barcode_stream, &BarcodeGenerator.valid?/1)
    end
  end

  describe "BarcodeGenerator.generate_flow/2" do
    test "generates valid barcodes" do
      # GTIN-12
      barcode_flow = BarcodeGenerator.generate_flow(619_659_161_415, 619_659_161_509)

      assert %Flow{} = barcode_flow
      assert Enum.count(barcode_flow) == 10
      assert Enum.all?(barcode_flow, &BarcodeGenerator.valid?/1)

      # GTIN-13
      barcode_flow = BarcodeGenerator.generate_flow(6_291_041_500_200, 6_291_041_500_299)

      assert %Flow{} = barcode_flow
      assert Enum.count(barcode_flow) == 10
      assert Enum.all?(barcode_flow, &BarcodeGenerator.valid?/1)

      # GTIN-14
      barcode_flow = BarcodeGenerator.generate_flow(62_910_415_000_200, 62_910_415_000_299)

      assert %Flow{} = barcode_flow
      assert Enum.count(barcode_flow) == 10
      assert Enum.all?(barcode_flow, &BarcodeGenerator.valid?/1)
    end

    test "handles stack-exceeding barcodes" do
      # GTIN-12
      barcode_flow = BarcodeGenerator.generate_flow(619_659_161_415, 619_659_162_509)

      assert %Flow{} = barcode_flow
      assert Enum.count(barcode_flow) == 110
      assert Enum.all?(barcode_flow, &BarcodeGenerator.valid?/1)

      # GTIN-13
      barcode_flow = BarcodeGenerator.generate_flow(6_291_041_500_200, 6_291_041_501_299)

      assert %Flow{} = barcode_flow
      assert Enum.count(barcode_flow) == 110
      assert Enum.all?(barcode_flow, &BarcodeGenerator.valid?/1)

      # GTIN-14
      barcode_flow = BarcodeGenerator.generate_flow(62_910_415_000_200, 62_910_415_001_299)

      assert %Flow{} = barcode_flow
      assert Enum.count(barcode_flow) == 110
      assert Enum.all?(barcode_flow, &BarcodeGenerator.valid?/1)
    end
  end
end
