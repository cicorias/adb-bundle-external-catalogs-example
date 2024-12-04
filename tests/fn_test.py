from utilities.spark import filter_dataframe


def test_filter_dataframe(spark):
    # Input data for testing
    input_data = [(1, "Alice", 10), (2, "Bob", 20), (3, "Charlie", 5)]
    input_schema = ["id", "name", "value"]

    # Create a DataFrame
    input_df = spark.createDataFrame(input_data, input_schema)

    # Apply the function
    result_df = filter_dataframe(input_df, "value", 10)

    # Collect the results to validate
    result_data = result_df.collect()

    # Expected output
    expected_data = [(2, "Bob", 20)]

    # Assert the results
    assert len(result_data) == len(expected_data)
    for row, expected_row in zip(result_data, expected_data):
        assert row.asDict() == dict(zip(input_schema, expected_row))
