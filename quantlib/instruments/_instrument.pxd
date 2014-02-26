include '../types.pxi'

from quantlib.handle cimport shared_ptr
from quantlib.pricingengines._pricing_engine cimport PricingEngine
from quantlib.time._date cimport Date

cdef extern from 'ql/instrument.hpp' namespace 'QuantLib':
    cdef cppclass Instrument:
        Instrument()

        Real NPV()
        const Date& valuationDate() except +
        void setPricingEngine(shared_ptr[PricingEngine]&)


