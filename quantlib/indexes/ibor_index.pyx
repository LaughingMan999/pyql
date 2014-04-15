include '../types.pxi'

from quantlib cimport ql

from quantlib.indexes.interest_rate_index cimport InterestRateIndex
from quantlib.termstructures.yields.yield_term_structure cimport YieldTermStructure
from quantlib.time.date cimport Period
from quantlib.time.daycounter cimport DayCounter
from quantlib.currency cimport Currency
from quantlib.time.calendar cimport Calendar

from quantlib.market.conventions.swap import SwapData


cdef class IborIndex(InterestRateIndex):

    property business_day_convention:
        def __get__(self):
            cdef ql.IborIndex* ref = <ql.IborIndex*>self._thisptr.get()
            return ref.businessDayConvention()

    property end_of_month:
        def __get__(self):
            cdef ql.IborIndex* ref = <ql.IborIndex*>self._thisptr.get()
            return ref.endOfMonth()

    @classmethod
    def from_name(self, market, term_structure=None, **kwargs):
        """
        Create default IBOR for the market, modify attributes if provided
        """

        row = SwapData.params(market)
        row = row._replace(**kwargs)

        # could use a dummy term structure here?
        if term_structure is None:
            term_structure = YieldTermStructure(relinkable=False)
        # may not be needed at this stage...
        # term_structure.link_to(FlatForward(settlement_date, 0.05,
        #                                       Actual365Fixed()))

        if row.currency == 'EUR':
            from quantlib.indexes.euribor import Euribor
            ibor_index = Euribor(Period(row.floating_leg_period), term_structure)
        else:
            label = row.currency + ' ' + row.floating_leg_reference
            from quantlib.indexes.libor import Libor
            ibor_index = Libor(label,
                               Period(row.floating_leg_period),
                               row.settlement_days,
                               Currency.from_name(row.currency),
                               Calendar.from_name(row.calendar),
                               DayCounter.from_name(row.floating_leg_daycount),
                               term_structure)
        return ibor_index


cdef class OvernightIndex(IborIndex):
    pass

