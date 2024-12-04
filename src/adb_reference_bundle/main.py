from pyspark.sql import SparkSession, DataFrame
from utilities.spark import get_spark


def get_taxis(spark: SparkSession) -> DataFrame:
    return spark.read.table("samples.nyctaxi.trips")


def main():
    get_taxis(get_spark()).show(5)


# def main():
#     try:
#         from utilities import get_spark

#         get_taxis(get_spark()).show(5)
#     except ImportError:
#         from .utilities import get_spark

#         get_taxis(get_spark()).show(5)


if __name__ == "__main__":
    main()
