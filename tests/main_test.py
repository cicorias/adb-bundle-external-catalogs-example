from adb_reference_bundle.main import get_taxis


def test_main(spark):
    taxis = get_taxis(spark)
    assert taxis.count() > 5
