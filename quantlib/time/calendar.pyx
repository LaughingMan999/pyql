"""
 Copyright (C) 2011, Enthought Inc
 Copyright (C) 2011, Patrick Henaff

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the license for more details.
"""

from cython.operator cimport dereference as deref, preincrement as inc
from libcpp cimport bool
from libcpp.vector cimport vector

from quantlib cimport ql

cimport quantlib.time.date as date

from quantlib.time.calendars.null_calendar import NullCalendar

import quantlib.time.calendars.germany as ger
import quantlib.time.calendars.united_states as us
import quantlib.time.calendars.united_kingdom as uk
import quantlib.time.calendars.japan as jp
import quantlib.time.calendars.switzerland as sw

from quantlib.util.prettyprint import prettyprint

# BusinessDayConvention:
cdef public enum BusinessDayConvention:
    Following         = ql.Following
    ModifiedFollowing = ql.ModifiedFollowing
    Preceding         = ql.Preceding
    ModifiedPreceding = ql.ModifiedPreceding
    Unadjusted        = ql.Unadjusted

cdef class Calendar:
    '''This class provides methods for determining whether a date is a
    business day or a holiday for a given market, and for
    incrementing/decrementing a date of a given number of business days.

    A calendar should be defined for specific exchange holiday schedule
    or for general country holiday schedule. Legacy city holiday schedule
    calendars will be moved to the exchange/country convention.
    '''

    def __dealloc__(self):
        if self._thisptr is not NULL:
            del self._thisptr
            self._thisptr = NULL

    property name:
        def __get__(self):
            return self._thisptr.name().c_str()

    property code:
        def __get__(self):
            return self._inv_code[self.name]

    def __str__(self):
        return self.name

    def is_holiday(self, date.Date test_date):
        '''Returns true iff the weekday is part of the
        weekend for the given market.
        '''
        cdef ql.Date* c_date = (<date.Date>test_date)._thisptr.get()
        return self._thisptr.isHoliday(deref(c_date))

    def is_weekend(self,  int week_day):
        '''Returns true iff the date is last business day for the
        month in given market.
        '''
        return self._thisptr.isWeekend(<ql.Weekday>week_day)

    def is_business_day(self, date.Date test_date):
        '''Returns true iff the date is a business day for the
        given market.
        '''
        return self._thisptr.isBusinessDay(deref(test_date._thisptr.get()))

    def is_end_of_month(self, date.Date test_date):
        '''Is this date the last business day of the month to which the given
        date belongs
        '''
        return self._thisptr.isBusinessDay(deref(test_date._thisptr.get()))

    def business_days_between(self, date.Date date1, date.Date date2,
            include_first=True, include_last=False):
        """ Returns the number of business days between date1 and date2. """

        return self._thisptr.businessDaysBetween(
            deref((<date.Date>date1)._thisptr.get()),
            deref((<date.Date>date2)._thisptr.get()),
            include_first,
            include_last
        )

    def end_of_month(self, date.Date current_date):
        """ Returns the ending date for the month that contains the given
        date.
        
        """

        cdef ql.Date* c_date = (<date.Date>current_date)._thisptr.get()
        cdef ql.Date eom_date = self._thisptr.endOfMonth(deref(c_date))

        return date.date_from_qldate(eom_date)

    def add_holiday(self, date.Date holiday):
        '''Adds a date to the set of holidays for the given calendar. '''
        cdef ql.Date* c_date = (<date.Date>holiday)._thisptr.get()
        self._thisptr.addHoliday(deref(c_date))

    def remove_holiday(self, date.Date holiday):
        '''Removes a date from the set of holidays for the given calendar.'''
        cdef ql.Date* c_date = (<date.Date>holiday)._thisptr.get()
        self._thisptr.removeHoliday(deref(c_date))

    def adjust(self, date.Date given_date, int convention=Following):
        '''Adjusts a non-business day to the appropriate near business day
            with respect to the given convention.
        '''
        cdef ql.Date* c_date = (<date.Date>given_date)._thisptr.get()
        cdef ql.Date adjusted_date = self._thisptr.adjust(deref(c_date),
                <ql.BusinessDayConvention> convention)

        return date.date_from_qldate(adjusted_date)

    def advance(self, date.Date given_date, int step=0, int units=-1,
               date.Period period=None, int convention=Following,
               end_of_month=False):
        '''Advances the given date of the given number of business days,
        or period and returns the result.

        You must provide either a step and unit or a Period.

        '''
        cdef ql.Date* c_date = (<date.Date>given_date)._thisptr.get()
        cdef ql.Date advanced_date

        # fixme: add better checking on inputs
        if period is None and units > -1:
            advanced_date = self._thisptr.advance(deref(c_date),
                    step, <ql.TimeUnit>units,
                    <ql.BusinessDayConvention>convention, end_of_month)
        elif period is not None:
            advanced_date = self._thisptr.advance(deref(c_date),
                    deref((<date.Period>period)._thisptr.get()),
                    <ql.BusinessDayConvention>convention, end_of_month)
        else:
            raise ValueError(
                'You must at least provide a step and unit or a Period!'
            )

        return date.date_from_qldate(advanced_date)

    _lookup = dict([(cal.name, cal) for cal in
                [TARGET(), NullCalendar(),
                 ger.Germany(), ger.Germany(ger.EUREX),
                 ger.Germany(ger.FrankfurtStockExchange),
                 ger.Germany(ger.SETTLEMENT), ger.Germany(ger.EUWAX),
                 ger.Germany(ger.XETRA),
                 uk.UnitedKingdom(),
                 uk.UnitedKingdom(uk.EXCHANGE), uk.UnitedKingdom(uk.METALS),
                 uk.UnitedKingdom(uk.SETTLEMENT),
                 us.UnitedStates(), us.UnitedStates(us.GOVERNMENTBOND),
                 us.UnitedStates(us.NYSE), us.UnitedStates(us.NERC), 
                 us.UnitedStates(us.SETTLEMENT),
                 jp.Japan(), sw.Switzerland()]])

    #ISO-3166 country codes (http://en.wikipedia.org/wiki/ISO_3166-1)
    _code = dict([('TARGET', TARGET().name),
                  ('NULL', NullCalendar().name),
                  ('DEU', ger.Germany().name),
                  ('EUREX', ger.Germany(ger.EUREX).name),
                  ('FSE', ger.Germany(ger.FrankfurtStockExchange).name),
                  ('EUWAX', ger.Germany(ger.EUWAX).name),
                  ('XETRA', ger.Germany(ger.XETRA).name),
                  ('GBR', uk.UnitedKingdom().name),
                  ('LSE', uk.UnitedKingdom(uk.EXCHANGE).name),
                  ('LME', uk.UnitedKingdom(uk.METALS).name),
                  ('USA', us.UnitedStates().name),
                  ('USA-GOVT-BONDS', us.UnitedStates(us.GOVERNMENTBOND).name),
                  ('NYSE', us.UnitedStates(us.NYSE).name),
                  ('NERC', us.UnitedStates(us.NERC).name),
                  ('JPN', jp.Japan().name),
                  ('CHE', sw.Switzerland().name)])

    _inv_code = {v:k for k, v in _code.items()}
    
    @classmethod
    def help(cls):
        tmp = map(list, zip(*cls._code))
        res = "Valid calendar names are:\n\n" + prettyprint(('Code', 'Calendar'), 'ss', tmp)
        return res
    
    @classmethod
    def from_name(cls, code):
        cdef Calendar ca = cls._lookup[cls._code[code]]
        return ca

cdef class DateList:
    '''Provides an interator interface on top of a vector of QuantLib dates.

    fixme : add safety checks on _dates usage
    todo : implement __len__, __getitem__ and __getslice__
    '''

    def __cinit__(self):
        self._pos = 0

    cdef _set_dates(self, vector[ql.Date]& dates):
        # fixme : would be great to be able to do that at construction time ...
        # but Cython does not allow to pass C object in the __cinit__ method
        self._dates = new vector[ql.Date](dates)

    def __dealloc__(self):
        if self._dates is not NULL:
            del self._dates
            self._dates = NULL

    def __iter__(self):
        return self

    def __next__(self):
        # when Cython will allow to create objects on the stack in loops, this
        # method will be refactored as a generator.
        if self._pos == self._dates.size():
            raise StopIteration()

        cdef ql.Date d = deref(self._dates).at(self._pos)
        self._pos += 1
        return date.date_from_qldate(d)


def holiday_list(Calendar calendar, date.Date from_date, date.Date to_date,
        bool include_weekends=False):
    '''Returns the holidays between two dates. '''

    cdef vector[ql.Date] dates = ql.Calendar_holidayList(
        deref((<Calendar>calendar)._thisptr),
        deref((<date.Date>from_date)._thisptr.get()),
        deref((<date.Date>to_date)._thisptr.get()),
        include_weekends
    )
    t = DateList()
    t._set_dates(dates)
    return t

cdef class TARGET(Calendar):
    '''TARGET calendar

    Holidays (see http://www.ecb.int):

     * Saturdays
     * Sundays
     * New Year's Day, January 1st
     * Good Friday (since 2000)
     * Easter Monday (since 2000)
     * Labour Day, May 1st (since 2000)
     * Christmas, December 25th
     * Day of Goodwill, December 26th (since 2000)
     * December 31st (1998, 1999, and 2001)
    '''

    def __cinit__(self):
        self._thisptr = <ql.Calendar*> new ql.TARGET()

