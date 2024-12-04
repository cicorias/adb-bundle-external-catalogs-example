import logging
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.functions import col


# Create a new Databricks Connect session. If this fails,
# check that you have configured Databricks Connect correctly.
# See https://docs.databricks.com/dev-tools/databricks-connect.html.
def get_spark() -> SparkSession:
    try:
        from databricks.connect import DatabricksSession

        return DatabricksSession.builder.getOrCreate()
    except ImportError:
        logging.warning(
            "Databricks Connect not found. Falling back to local SparkSession."
        )
        return SparkSession.builder.getOrCreate()


def filter_dataframe(df: DataFrame, column_name: str, threshold: int) -> DataFrame:
    """Filter rows where the value in `column_name` is greater than the threshold."""
    return df.filter(col(column_name) > threshold)
