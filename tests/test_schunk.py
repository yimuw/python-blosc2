########################################################################
#
#       Created: May 26, 2021
#       Author:  The Blosc development team - blosc@blosc.org
#
########################################################################

import numpy
import pytest

import blosc2
from tests import utilities


@pytest.mark.parametrize("contiguous", [True, False])
@pytest.mark.parametrize("urlpath", [None, "b2frame"])
@pytest.mark.parametrize(
    "cparams, dparams, nchunks",
    [
        ({"compcode": blosc2.LZ4, "clevel": 6}, {}, 0),
        ({}, {"nthreads": 4}, 1),
        ({"splitmode": blosc2.ALWAYS_SPLIT, "nthreads": 5}, {"schunk": None}, 5),
        ({"compcode": blosc2.LZ4HC, "typesize": 4}, {}, 10),
    ],
)
def test_schunk_numpy(contiguous, urlpath, cparams, dparams, nchunks):
    storage = {"contiguous": contiguous, "urlpath": urlpath, "cparams": cparams, "dparams": dparams}
    utilities.remove_schunk(contiguous, urlpath)

    schunk = blosc2.SChunk(**storage)
    for i in range(nchunks):
        buffer = i * numpy.arange(200 * 1000)
        nchunks_ = schunk.append_buffer(buffer)
        assert nchunks_ == (i + 1)

    for i in range(nchunks):
        buffer = i * numpy.arange(200 * 1000)
        bytes_obj = buffer.tobytes()
        res = schunk.decompress_chunk(i)
        assert res == bytes_obj

        dest = numpy.empty(buffer.shape, buffer.dtype)
        schunk.decompress_chunk(i, dest)
        assert numpy.array_equal(buffer, dest)

        schunk.decompress_chunk(i, memoryview(dest))
        assert numpy.array_equal(buffer, dest)

        dest = bytearray(buffer)
        schunk.decompress_chunk(i, dest)
        assert dest == bytes_obj

    for i in range(nchunks):
        schunk.get_chunk(i)

    utilities.remove_schunk(contiguous, urlpath)


@pytest.mark.parametrize("contiguous", [True, False])
@pytest.mark.parametrize("urlpath", [None, "b2frame"])
@pytest.mark.parametrize(
    "nbytes, cparams, dparams, nchunks",
    [
        (7, {"compcode": blosc2.LZ4, "clevel": 6}, {}, 0),
        (641091, {}, {"nthreads": 4}, 1),
        (136, {}, {}, 5),
        (1231, blosc2.cparams_dflts, blosc2.dparams_dflts, 10),
    ],
)
def test_schunk(contiguous, urlpath, nbytes, cparams, dparams, nchunks):
    storage = {"contiguous": contiguous, "urlpath": urlpath, "cparams": cparams, "dparams": dparams}

    utilities.remove_schunk(contiguous, urlpath)

    schunk = blosc2.SChunk(**storage)
    for i in range(nchunks):
        bytes_obj = b"i " * nbytes
        nchunks_ = schunk.append_buffer(bytes_obj)
        assert nchunks_ == (i + 1)

    for i in range(nchunks):
        bytes_obj = b"i " * nbytes
        res = schunk.decompress_chunk(i)
        assert res == bytes_obj

        dest = bytearray(bytes_obj)
        schunk.decompress_chunk(i, dst=dest)
        assert dest == bytes_obj

    for i in range(nchunks):
        schunk.get_chunk(i)

    utilities.remove_schunk(contiguous, urlpath)
